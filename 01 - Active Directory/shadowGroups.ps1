<#
.NOTES
    NAME: shadowGroups.ps1
    AUTHOR: Rich Johnson
    EMAIL: rich.johnson@alliance.com
    REQUIREMENTS:
    Change Log:
        2018-08-20 - Changed any call to function removeGroupFromGroup to removeFromGroup.  I cant remember why I 
                     had to have that function to begin with, but no where do we remove groups from groups.
        2018-05-01 - Added log rotation functionality
        2018-04-05 - Added Mac-Computers group and functionality to add Macs to this group -Rich
        2018-03-07 - Added PAW shadow group functionality - Rich
        2018-03-05 - Added functionality to process Pharmacy users and computers -Rich
        2018-01-25 - Added Tier to servers -Rich
        2018-01-08 - Initial Creation -Rich

    TODO
        -Log rotation - Should keep no more than 1 years wworth of logs
        
.SYNOPSIS
    Build user and computer shadow groups in AD.
    shadowGroups.ps1
    AUthor: Rich Johnson | UpWell

.DESCRIPTION
    - Creates shadow groups for computer objects in Active Directory. OU structure is very important.
    - Adds computers to the appropriate groups. Also nests groups.
    - Disables computer objects and moves them to a specified OU if inactive.
    - Creates shadow groups for user objects in Active Directory.  OU structure, again, is very important.
    - Adds users to the appropriate groups. Also nests groups.
    - Adds users to appropriate chat groups for open fire server.
    - Moves all disabled users to the DisabledUsers OU
    - Removes all group membership of disabled user accounts
    - Removes all disabled users from the GAL
#>

###########
# Functions
###########

# All actions are logged by calling this function
function logging ($level, $text) {
    if ($debug -ne "on" -and $level -eq "D") {
        return
    }
    $timeStamp = get-date -Format "yyyy-MM-dd HH:mm:ss.fff"

    <#if ($blurb -ne "yes") {
        # Override the existing log file so it does not grow out of control
        Write-Output "$timeStamp I New log created" > $logLocation
        $script:blurb = "yes"
    }#>

    Write-Output "$timeStamp $level $text" >> $logLocation
}

# Creates new groups if they don't already exist
function createGroup ($GroupName, $groupScope, $groupCategory, $description, $path) {
    if (!(Get-ADGroup -Server $ADServer -filter { Name -eq $GroupName })) {
        New-ADGroup -Server $ADServer -Path $path -Name $GroupName -GroupScope $groupScope -GroupCategory $groupCategory -Description $description
        if($?) {
            logging "I" "Created group $GroupName via function, 'createGroup'"
        }
    }
}

# Add group to group
function addGroupToGroup ($gMember, $parentGroupCN, $parentGroup, $GroupName, $objectType) {
    if (!($gMember -match $parentGroupCN)) {
        Add-ADGroupMember -Server $ADServer -Identity $parentGroup -Members $GroupName
        if($?) {
            logging "I" "Added $objectType $GroupName to group $parentGroup via function, 'addGroupToGroup'"
        }
    }
}

# Add object to group
function addToGroup ($membership, $groupName, $member, $memberName, $objectType) {
    if (!($membership -match $groupName)) {
        Add-ADGroupMember -Server $ADServer $GroupName -Members $member
        if($?) {
            logging "I" "Added $objectType $memberName to group $groupName via function, 'addToGroup'"
        }
    }
}

<#
# Remove group from group
function removeGroupFromGroup ($membership, $groupNameCN, $groupName, $member, $memberName, $objectType) {
    if (($membership -match $groupNameCN)) {
        Remove-ADGroupMember -Server $ADServer $groupName -Members $member -Confirm:$false
        if($?) {
            logging "I" "Removed $objectType $memberName from group $groupName via function, 'removeGroupFromGroup'"
        }
    }
}#>

# Remove object from group
function removeFromGroup ($membership, $groupName, $member, $memberName, $objectType) {
    if (($membership -match $groupName)) {
        Remove-ADGroupMember -Server $ADServer $groupName -Members $member -Confirm:$false
        if($?) {
            logging "I" "Removed $objectType $memberName from group $groupName via function, 'removeFromGroup'"
        }
    }
}

# Create Distribution List
function createDL ($DLGroupName, $groupType, $moderationEnabled, $moderator, $joinRestriction, $departRestriction, $managedBy, $description) {
    if (!(Get-ADGroup -Server $ADServer -filter { Name -eq $DLGroupName })) {
        [void] ( New-DistributionGroup -DomainController $ADServer -name $DLGroupName -OrganizationalUnit $shadowGroupsDLOU -SamAccountName $DLGroupName -Type $groupType -DisplayName $DLGroupName -ModerationEnabled:$moderationEnabled -ModeratedBy $moderator -MemberJoinRestriction $joinRestriction -MemberDepartRestriction $departRestriction -ManagedBy $managedBy )
        if($?) {
            logging "I" "Created DL $DLGroupName via function, 'createDL'"
        }
        # Set a description
        Set-ADGroup -Server $ADServer $DLGroupName -Description $description
    }
}

# Create session to exchange servers
function createExchangeSession ($exchangeServer) {
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$exchangeServer.domain.local/PowerShell -Authentication Kerberos -Name $exchangeServer
    [void] (Import-PSSession $session -AllowClobber)
    if($?) {
        logging "I" "Created new PSSession to $exchangeServer via function, 'createExchangeSession'."
    }
}

function Computers {
    # Create the All-Workstations group
    createGroup $topLevelComputers "Global" "security" $description $shadowGroupsComputersOU

    # Create the All-Workstations-Remote group
    createGroup $remoteComputers "Global" "security" $description $shadowGroupsComputersOU

    # Create the All-Mac group
    createGroup $macComputers "Global" "Security" $description $shadowGroupsComputersOU

    # Add the All-Workstations-Remote group to the All-Workstations group
    $gMember = (Get-ADGroup -Server $ADServer $remoteComputers -Properties memberof).memberof
    $parentGroup = $topLevelComputers
    $parentGroupCN = "CN=$parentGroup,"
    addGroupToGroup $gMember $parentGroupCN $parentGroup $remoteComputers "group"

    ########################################
    # Create all the computer Shadow Groups!
    ########################################
    foreach ( $computer in $allComputers ) {
        
        # This bit can help  debug issues if you only want to see certain debug logs
        #if ($computer.name -eq "lmccinf-00361") { $debug = "on" }
        #else { $debug = "off" }

        # Get the group membership of the computer
        $member = (Get-ADComputer $computer -Properties memberof).memberof

        # Define attributes about the computer to be used for building the group names
        #                  0  1               2  3  4  5  6  7            8  9                 10 11        12 13        14 15     16 17     18 19
        # example of a DN: CN=VWSJ1INF-RJOH01,OU=IT,OU=VM,OU=Workstations,OU=CottonwoodHeights,OU=Corporate,OU=Computers,OU=UpWell,DC=UPWELL,DC=COM
        $computerName = $computer.Name
        $os = $computer.operatingsystem
        $dn = $computer.DistinguishedName
        $department = ($dn -split '[,\=]')[3]
        $platform = ($dn -split '[,\=]')[5]
        $locale = ($dn -split '[,\=]')[9]
        if ( $dn -like "*Remote*" ) { 
            $remote = '-Remote' 
            $isRemote = "yes"
        }
        else { $remote = '' }

        logging "D" "computerName: $computerName"
        logging "D" "operating system: $os"
        logging "D" "dn: $dn"
        logging "D" "department: $department"
        logging "D" "platform: $platform"
        logging "D" "locale: $locale"
        logging "D" "remote: $remote"

        # Create the All-Department-Workstations group
        $computerGroupName = "All-$department-Workstations"
        createGroup $computerGroupName "Global" "security" $description $shadowGroupsComputersOU

        # Create the All-Department-Platform group
        $computerGroupName = "All-$department-$platform"
        createGroup $computerGroupName "Global" "security" $description $shadowGroupsComputersOU

        # Add the All-Department-Platform group to the All-Department-Workstations group
        $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
        $parentGroup = "All-$department-Workstations"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"

        # Create the All-Locale-Workstations group
        $computerGroupName = "All-$locale-Workstations"
        createGroup $computerGroupName "Global" "security" $description $shadowGroupsComputersOU

        # Add the All-Locale-Workstations group to the All-Workstations group
        $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
        $parentGroup = $topLevelComputers
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"

        # Create the All-Platform group
        $computerGroupName = "All-$platform"
        createGroup $computerGroupName "Global" "security" $description $shadowGroupsComputersOU

        # If it is a remote workstation
        # Create the All-Platform-Remote group
        # Add the All-Platform-Remote group to the All-Workstations-Remote group
        if ( $isRemote -eq "yes" ) {
            # Create the All-Platform-Remote group
            $computerGroupName = "All-$platform$Remote"
            createGroup $computerGroupName "Global" "security" $description $shadowGroupsComputersOU

            # Add the All-Platform-Remote group to the All-Workstations-Remote group
            $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
            $parentGroup = "All-Workstations-Remote"
            $parentGroupCN = "CN=$parentGroup,"
            addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"
        }

        # Create the All-Locale-Platform group
        $computerGroupName = "All-$locale-$platform"
        createGroup $computerGroupName "Global" "security" $description $shadowGroupsComputersOU

        # Add the All-Locale-Platform group to the All-Platform group
        $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
        $parentGroup = "All-$platform"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"

        # Add the All-Locale-Platform group to the All-Locale-Workstations group
        $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
        $parentGroup = "All-$locale-Workstations"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"

        # If it is a remote workstation
        # Add the All-Locale-Platform group to the All-Platform-Remote group, 
        if ( $isRemote -eq "yes" ) {
            $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
            $parentGroup = "All-$platform$remote"
            $parentGroupCN = "CN=$parentGroup,"
            addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"
        }

        # Create the Locale-Department-Platform group
        $computerGroupName = "$locale-$department-$platform"
        createGroup $computerGroupName "Global" "security" $description $shadowGroupsComputersOU

        # Add the Locale-Department-Platform group to the All-Locale-Platform group
        $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
        $parentGroup = "All-$locale-$platform"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"

        # Add the Locale-Department-Platform group to the All-Department-Platform group
        $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
        $parentGroup = "All-$department-$platform"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"

        # Add computer to Local-Department-Platform group if not already a member
        addToGroup $member $computerGroupName $computer $computerName "computer"
        
        # Remove computer from the All-Laptops group if it is not a laptop (A laptop could HIR to a desktop)
        if (!( $dn -like "*OU=Laptops*" )) {
            removeFromGroup $member $laptopComputers $computer $computerName "computer"
        }

        # Remove it from the All-Desktops group if it is not a desktop (A desktop could HIR to a laptop)
        if (!( $dn -like "*OU=Desktops*" )) {
            removeFromGroup $member $desktopComputers $computer $computerName "computer"
        }
                
        # Remove it from the All-VM group if it is not a VM
        if (!( $dn -like "*OU=VM*" )) {
            removeFromGroup $member $VMComputers $computer $computerName "computer"
        }

        # Remove it from the All-Tablets group if it is not a Tablet
        if (!( $dn -like "*OU=Tablets*" )) {
            removeFromGroup $member $tabletComputers $computer $computerName "computer"
        }

        # Remove computer from any Local-Department-Platform groups of which it no longer belongs
        foreach ( $group in (Get-ADGroup -Server $ADServer -SearchBase $shadowGroupsComputersOU -Filter { Name -notlike "All-*" }) ) {
            if ( $($group.Name) -like "*-Remote*") {
                $groupRemote = "-Remote"

            }
            else {$groupRemote = ""}
            
            $groupLocale = ($group.Name -split '-')[0]
            $groupPlatform = ($group.Name -split '-')[-1]
            $groupDepartment = ($group.Name -split '-')[-2]
            $groupName = $group.Name

            logging "D" "computerName: $computerName"
            logging "D" "groupName: $groupName"
            logging "D" "   groupLocale: $groupLocale"
            logging "D" "   locale: $locale"
            logging "D" "   groupDepartment: $groupDepartment"
            logging "D" "   department: $department"
            logging "D" "   groupPlatform: $groupPlatform"
            logging "D" "   platform: $platform"
            logging "D" "   member: $member"

            if ( $groupLocale -notlike $locale -or $groupDepartment -notlike $department -or $groupPlatform -notlike $platform) {
                removeFromGroup $member $groupName $computer $computerName "computer"
            }
        }

        # If the computer is a Mac, add it to the All-Mac group
        if ( $os -eq "OS X" ) {
            addToGroup $member $macComputers $computer $computerName "computer"
        }

        # If computer is disabled, move to Disabled-Computers OU
        if ( $computer.Enabled -eq $false  ) {
            Move-ADObject -Identity $computer -TargetPath $disabledComputersOU
            if($?) {
                logging "Moved computer $computerName to the Disabled-Computers OU"
            }
        }
    }

    #####################################
    # Begin processing disabled computers
    #####################################
    $description = "Account disabled via shadowgroups script due to inactivity on $Today"

    # Disable computer accounts within the DisabledComputers OU if not already disabled...just in case!
    Get-ADComputer -Server $ADServer -Filter * -SearchBase "$DisabledComputersOU" | Where -Property enabled | Disable-ADAccount

    # Disable Remote computers that have not logged on to corpnet for more than 365 days
    Search-ADAccount -Server $ADServer -AccountInactive -TimeSpan 365.00:00:00 -SearchBase $allComputersOU | where {($_.distinguishedname -like "*Remote*") -and ($_.distinguishedname -notlike "*OU=Disabled-Computers,*") -and ($_.lastLogonDate) -and !($_.lastLogonDate -ge (Get-Date).AddDays(-365))} | foreach {
        Disable-ADAccount $_
        if($?) {
            logging "I" "Disabled remote workstation: $($_.name) becuase it has been inactive for more than 365 days."
        }
        Set-ADObject $_ -Description $description
        Move-ADObject $_ -TargetPath $disabledComputersOU
        if($?) {
            logging "I" "Moved $($_.name) to the AccountsDisabled OU"
        }
    }

    # Disable Local computers that have not logged on to corpnet for more than 45 days
    Search-ADAccount -Server $ADServer -AccountInactive -TimeSpan 45.00:00:00 -SearchBase $allComputersOU | where {($_.distinguishedname -notlike "*Remote*") -and ($_.distinguishedname -notlike "*OU=Disabled-Computers,*") -and ($_.lastLogonDate) -and !($_.lastLogonDate -ge (Get-Date).AddDays(-45)  ) } | foreach {
        Disable-ADAccount $_
        if($?) {
            logging "I" "Disabled local workstation: $($_.name) becuase it has been inactive for more than 45 days."
        }
        Set-ADObject $_ -Description $description
        Move-ADObject $_ -TargetPath $disabledComputersOU
        if($?) {
            logging "I" "Moved $($_.name) to the AccountsDisabled OU"
        }
    }

    # Remove disabled computer accounts from any groups they may be a member of
    $disabledComputers = Get-ADComputer -Server $ADServer -SearchBase $DisabledComputersOU -Filter *
    foreach ($computer in $disabledComputers) {
        $DN = $computer.DistinguishedName
        $computerName = $computer.Name
        Get-ADGroup -Server $ADServer -LDAPFilter "(member=$DN)" | ForEach-Object {
            if ($_.name -ne "Domain Computers") {
                Remove-ADGroupMember -Server $ADServer -identity $_.name -member $DN -Confirm:$false
                if($?) {
                    logging "I" "Removed computer $computerName from $($_.name)"
                }
            }
        }
    }
} # Close function Computers

function PAW {

    # Create the PAW-AllPAWComputers group
    createGroup $topLevelPAW "Global" "security" $description $shadowGroupsPAWOU

    ########################################
    # Create all the computer Shadow Groups!
    ########################################
    foreach ( $computer in $allPAWs ) {

        # Get the group membership of the computer
        $member = (Get-ADComputer $computer -Properties memberof).memberof

        # Define attributes about the computer to be used for building the group names
        #                  0  1              2  3     4  5   6  7                 8  9         10 11        12 13     14 15     16 17
        # example of a DN: CN=LWCH1INF-00206,OU=Tier0,OU=PAW,OU=CottonwoodHeights,OU=Corporate,OU=Computers,OU=UpWell,DC=UPWELL,DC=COM
        $computerName = $computer.Name
        $dn = $computer.DistinguishedName
        $tier = ($dn -split '[,\=]')[3]

        logging "D" "computerName: $computerName"
        logging "D" "dn: $dn"
        logging "D" "tier: $department"

        # Create the PAW-Tier#-Computers group
        $computerGroupName = "PAW-$tier-Computers"
        createGroup $computerGroupName "Global" "security" $description $shadowGroupsPAWOU

        # Add the PAW-Tier#-Computers group to the PAW-AllPAWComputers group
        $gMember = (Get-ADGroup -Server $ADServer $computerGroupName -Properties memberof).memberof
        $parentGroup = $topLevelPAW
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $computerGroupName "group"

        # Add the PAW to the PAW-Tier#-Computers group
        addToGroup $member $computerGroupName $computer $computerName "PAW"

        # Remove computer from the PAW-Tier0-Computers group if it is no longer a Tier 0 PAW
        if ( $tier -ne "Tier0" ) {
            removeFromGroup $member "PAW-Tier0-Computers" $computer $computerName "computer"
        }

        # Remove computer from the PAW-Tier1-Computers group if it is no longer a Tier 1 PAW
        if ( $tier -ne "Tier1" ) {
            removeFromGroup $member "PAW-Tier1-Computers" $computer $computerName "computer"
        }

        # Remove computer from the PAW-Tier2-Computers group if it is no longer a Tier 2 PAW
        if ( $tier -ne "Tier2" ) {
            removeFromGroup $member "PAW-Tier2-Computers" $computer $computerName "computer"
        }
    }
} # Close function PAW

function Servers {
    # Create the All-Servers group
    createGroup $topLevelServers "Global" "security" $description $shadowGroupsServersOU

    ########################################
    # Create all the computer Shadow Groups!
    ########################################
    foreach ( $server in $allServers ) {

        # Get the group membership of the computer
        $member = (Get-ADComputer $server -Properties memberof).memberof

        # Define attributes about the computer to be used for building the group names
        #                  0  1           2  3     4  5          6  7       8  9        10 11        12 13     14 15     16 17        18 19
        # example of a DN: CN=PSLWSADFS01,OU=Tier1,OU=Production,OU=Servers,OU=SaltLake,OU=Corporate,OU=Computers,OU=UpWell,DC=UPWELL,DC=COM
        $serverName = $server.Name
        $dn = $server.DistinguishedName
        $tier = ($dn -split '[,\=]')[3]
        $category = ($dn -split '[,\=]')[5]
        $locale = ($dn -split '[,\=]')[9]
        

        logging "D" "serverName: $serverName"
        logging "D" "dn: $dn"
        logging "D" "category: $category"
        logging "D" "locale: $locale"

        # Create the All-Locale-Servers group
        $serverGroupName = "All-$locale-Servers"
        createGroup $serverGroupName "Global" "security" $description $shadowGroupsServersOU

        # Add the All-Locale-Servers group to the All-Servers group
        $gMember = (Get-ADGroup -Server $ADServer $serverGroupName -Properties memberof).memberof
        $parentGroup = $topLevelServers
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $serverGroupName "group"

        # Create the All-Category-Servers group
        $serverGroupName = "All-$category-Servers"
        createGroup $serverGroupName "Global" "security" $description $shadowGroupsServersOU

        # Create the All-Tier-Servers group
        $serverGroupName = "All-$tier-Servers"
        createGroup $serverGroupName "Global" "security" $description $shadowGroupsServersOU

        # Create the Locale-Category-Tier-Servers group
        $serverGroupName = "$locale-$category-$tier-Servers"
        createGroup $serverGroupName "Global" "security" $description $shadowGroupsServersOU

        # Add the Locale-Category-Tier-Servers group to the All-Category-Servers group
        $gMember = (Get-ADGroup -Server $ADServer $serverGroupName -Properties memberof).memberof
        $parentGroup = "All-$category-Servers"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $serverGroupName "group"

        # Add the Locale-Category-Tier-Servers group to the All-Locale-Servers group
        $gMember = (Get-ADGroup -Server $ADServer $serverGroupName -Properties memberof).memberof
        $parentGroup = "All-$locale-Servers"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $serverGroupName "group"

        # Add the Locale-Category-Tier-Servers group to the All-Tier-Servers group
        $gMember = (Get-ADGroup -Server $ADServer $serverGroupName -Properties memberof).memberof
        $parentGroup = "All-$tier-Servers"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $serverGroupName "group"

        # Add the server to the Locale-Category-Tier-Servers group
        addToGroup $member $serverGroupName $server $serverName "server"

        # Remove server from any Locale-Category-Tier-Servers groups of which it no longer belongs
        foreach ( $group in (Get-ADGroup -Server $ADServer -SearchBase $shadowGroupsServersOU -Filter { Name -notlike "All-*" }) ) {
            $groupLocale = ($group.Name -split '-')[0]
            $groupCategory = ($group.Name -split '-')[1]
            $groupTier = ($group.Name -split '-')[2]
            $groupName = $group.Name
            if ( $groupLocale -notlike $locale -or $groupCategory -notlike $category -or $groupTier -notlike $tier) {
                removeFromGroup $member $groupName $server $serverName "server"
            }
        }

        # If server is disabled, move to Disabled-Computers OU
        if ( $server.Enabled -eq $false  ) {
            Move-ADObject -Identity $server -TargetPath $disabledComputersOU
            if($?) {
                logging "Moved server $serverName to the Disabled-Computers OU"
            }
        }
    }
} # Close function Servers

function Users {
    # Create the All-Employees group
    createGroup $topLevelUsers "Global" "security" $description $shadowGroupsUsersOU

    # Create the All-Employees-Remote group
    createGroup $allEmployeesRemote "Global" "security" $description $shadowGroupsUsersOU

    # Create the All-Employees-Pharmacy group
    createGroup $topLevelPharmacyUsers "Global" "security" $description $shadowGroupsUsersOU

    ####################################
    # Create all the user Shadow Groups!
    ####################################
    foreach ( $user in $allUsers ) {

        # Get the group membership of the user
        $member = (Get-ADUser $user -Properties memberof).memberof

        # Define attributes about the user to be used for building the group names
        #                  0  1            2  3  4  5           6  7         8  9     10 11     12 13     14 15
        # example of Employee User: CN=Rich Johnson,OU=IT,OU=SouthJordan,OU=Corporate,OU=Users,OU=UpWell,DC=UPWELL,DC=COM 

        #                           0  1          2  3          4  5        6  7          8  9     10 11     12 13     14 15
        # example of Pharmacy User: CN=Peter Boam,OU=Pharmacist,OU=Site0001,OU=Pharmacies,OU=Users,OU=UpWell,DC=UPWELL,DC=COM
        $username = $user.name
        $dn = $user.distinguishedname
        $department = ($dn -split '[,\=]')[3]
        $locale = ($dn -split '[,\=]')[5]
        if ( $dn -like "*Remote*" ) { 
            $remote = '-Remote' 
            $isRemote = "yes"
        }
        else { $remote = '' }
        if ( $dn -like "*OU=Pharmacies*" ) {
            $isPharmacy = "yes"
        }

        logging "D" "username: $username"
        logging "D" "dn: $dn"
        logging "D" "department: $department"
        logging "D" "locale: $locale"
        logging "D" "remote: $remote"

        # Create the All-Employees-Department groups
        $userGroupName = "All-Employees-$department"
        createGroup $userGroupName "Global" "security" $description $shadowGroupsUsersOU

        # Create the All-Employees-Locale groups
        $userGroupName = "All-Employees-$locale"
        createGroup $userGroupName "Global" "security" $description $shadowGroupsUsersOU

        # Add the All-Employees-Locale group to the All-Employees group, if not allready
        $gMember = (Get-ADGroup -Server $ADServer $userGroupName -Properties memberof).memberof
        $parentGroup = $topLevelUsers
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $userGroupName "group"

        # If the employee is remote
        # Add the All-Employees-Locale to the All-Employees-Remote group
        if ( $isRemote -eq "yes" ) {
            
            # Add the All-Employees-Locale group to the All-Employees-Remote group
            $gMember = (Get-ADGroup -Server $ADServer $userGroupName -Properties memberof).memberof
            $parentGroup = $allEmployeesRemote
            $parentGroupCN = "CN=$parentGroup,"
            addGroupToGroup $gMember $parentGroupCN $parentGroup $userGroupName "group"
        }

        # If the employee works at a Pharmacy
        # Add the All-Employees-Locale to the All-Employees-Pharmacy group
        if ( $isPharmacy -eq "yes" ) {
            
            # Add the All-Employees-Locale group to the All-Employees-Pharmacy group
            $gMember = (Get-ADGroup -Server $ADServer $userGroupName -Properties memberof).memberof
            $parentGroup = $topLevelPharmacyUsers
            $parentGroupCN = "CN=$parentGroup,"
            addGroupToGroup $gMember $parentGroupCN $parentGroup $userGroupName "group"
        }

        # Create the Employees-Locale-Department group if not already, and manage the membership
        $userGroupName = "Employees-$locale-$department"
        $userGroupNameCN = "CN=$userGroupName,"
        createGroup $userGroupName "Global" "security" $description $shadowGroupsUsersOU

        # Add the Employees-Locale-Department group to the All-Employees-Department group, if not allready
        $gMember = (Get-ADGroup -Server $ADServer $userGroupName -Properties memberof).memberof
        $parentGroup = "All-Employees-$department"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $userGroupName "group"
        
        # Add the Employees-Locale-Department group to the All-Employees-Locale group, if not allready
        $gMember = (Get-ADGroup -Server $ADServer $userGroupName -Properties memberof).memberof
        $parentGroup = "All-Employees-$locale"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $userGroupName "group"

        # Add user to Employees-Locale-Department group if not already a member
        addToGroup $member $userGroupName $user $username "user"

        # Remove user from any Employees-Locale-Department groups of which they no longer belong
        foreach ( $group in (Get-ADGroup -Server $ADServer -SearchBase $shadowGroupsUsersOU -Filter { Name -notlike "All-*" }) ) {
            $groupName = $group.name
            if ($groupName -like "*Remote*") { 
                $remote = "-Remote"
            }
            else { $remote = "" }

            $groupLocale = ($groupName -split '-')[1] + $remote
            $groupDepartment = ($groupName -split '-')[-1]

            logging "D" "username: $username"
            logging "D" "groupName: $groupName"
            logging "D" "   groupName: $groupName"
            logging "D" "   groupLocale: $groupLocale"
            logging "D" "   locale: $locale"
            logging "D" "   groupDepartment: $groupDepartment"
            logging "D" "   department: $department"

            if ( $groupLocale -notlike $locale -or $groupDepartment -notlike $department ) {
                removeFromGroup $member $groupName $user $userName "user"
            }
        }

        # If user is disabled, move to Disabled-Users OU
        if ( $user.Enabled -eq $false  ) {
            Set-ADUser -Identity $user -Company $null
            if($?) {
                logging "I" "Cleared company from $userName"
            }
            Move-ADObject -Identity $user -TargetPath $disabledUsersOU
            if($?) {
                logging "I" "Moved user $userName to the Disabled-Users OU"
            }
        }
    }

    #########################################
    # Begin processing disabled user accounts
    #########################################
    # Remove users from all groups within the Disabled-Users OU
    $disabledUsers = get-aduser -server $ADServer -Filter * -SearchBase $disabledUsersOU -Properties memberOf
    foreach ( $user in $disabledUsers ) {

        # For debugging
        $userName = $user.Name
        logging "D" "userName: $username"

        $Groups = $user.memberOf | ForEach-Object { Get-ADGroup $_ }
        foreach ( $group in $groups ) {
            $groupName = $group.Name
            Remove-ADGroupMember -Server $ADServer -Identity $group -Members $user -Confirm:$false
            if($?) {
                logging "I" "Removed user $userName from group: $groupName"
            }
        }
    }

    # Remove disabled users from GAL
    Get-ADUser -Server $ADServer -filter * -SearchBase $DisabledUsersOU | Set-ADUser -Server $ADServer -Replace @{msExchHideFromAddressLists=$true}
    Get-ADUser -Server $ADServer -filter * -SearchBase $DisabledUsersOU | Set-ADObject -Server $ADServer -Clear showinAddressBook

} # Close function users

function DistributionLists {

    # Becuase most of the DLs will have a different description than other groups...
    $description = "Created $today. This is a managed dynamic group that is built based on OU membership.  You can safely modify membership of this group."

    # Create a remote Powershell session to the Exchange servers so we can add the DLs in exchange and modify them
    # Note: If this script terminates early, we will need to manually remove the session.
    createExchangeSession "pslwsexchange01"                                                                                                                                                                                                               # Update

    # Create the DL-All-Employees group
    createDL $topLevelDL "distribution" $true $moderator "closed" "closed" "admin" $description

    # Create the DL-All-RemoteEmployees group
    createDL $topLevelDLRemote "distribution" $true $moderator "closed" "closed" "admin" $description
   
    #################################
    # Create all the rest of the DLs!
    #################################
    foreach ( $user in $allUsers ) {
    
        # Get the group membership of the user
        $member = (Get-ADUser $user -Properties memberof).memberof

        # Define attributes about the user to be used for building the group names
        #                  0  1            2  3  4  5                 6  7         8  9     10 11     12 13     14 15
        # example of a DN: CN=Rich Johnson,OU=IT,OU=CottonwoodHeights,OU=Corporate,OU=Users,OU=UpWell,DC=UPWELL,DC=COM
        $username = $user.name
        $dn = $user.distinguishedname
        $department = ($dn -split '[,\=]')[3]
        $locale = ($dn -split '[,\=]')[5]
        if ( $dn -like "*Remote*" ) { $remote = '-Remote' }
        else { $remote = '' }

        logging "D" "username: $username"
        logging "D" "dn: $dn"
        logging "D" "department: $department"
        logging "D" "locale: $locale"
        logging "D" "remote: $remote"

        # Create the DL-All-Locale groups
        $DLGroupName = "DL-All-$locale"
        createDL $DLGroupName "distribution" $true $moderator "closed" "closed" "admin" $description
        
        # Add the DL-All-Locale groups to the DL-All-Employees group if not already a member
        $gMember = (Get-ADGroup -Server $ADServer $DLGroupName -Properties memberof).memberof
        $parentGroup = $topLevelDL
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $DLGroupName "DL"

        # Add the DL-All-Locale groups to the DL-All-RemoteEmployees group if not already a member
        $gMember = (Get-ADGroup -Server $ADServer $DLGroupName -Properties memberof).memberof
        $parentGroup = $topLevelDLRemote
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $DLGroupName "DL"

        # Create the DL-All-Department groups
        $DLGroupName = "DL-All-$department"
        if (!(Get-ADGroup -Server $ADServer -filter { Name -eq $DLGroupName })) {
            [void] ( New-DistributionGroup -DomainController $ADServer -name $DLGroupName -OrganizationalUnit $shadowGroupsDLOU -SamAccountName $DLGroupName -Type distribution -DisplayName $DLGroupName -MemberJoinRestriction closed -MemberDepartRestriction closed -ManagedBy admin )
            if($?) {
                logging "Created DL: $DLGroupName"
            }

            # Set a description
            Set-ADGroup -Server $ADServer $DLGroupName -Description $description
        }

        # Create the DL-Locale-Department groups
        $DLGroupName = "DL-$locale-$department"
        if (!(Get-ADGroup -Server $ADServer -filter { Name -eq $DLGroupName })) {
            [void] ( New-DistributionGroup -DomainController $ADServer -name $DLGroupName -OrganizationalUnit $shadowGroupsDLOU -SamAccountName $DLGroupName -Type distribution -DisplayName $DLGroupName -MemberJoinRestriction closed -MemberDepartRestriction closed -ManagedBy admin )
            if($?) {
                logging "Created DL: $DLGroupName"
            }

            # Set a description
            Set-ADGroup -Server $ADServer $DLGroupName -Description $description
        }

        # Add the DL-Locale-Department group to the DL-All-Department group if not already a member
        $gMember = (Get-ADGroup -Server $ADServer $DLGroupName -Properties memberof).memberof
        $parentGroup = "DL-All-$department"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $DLGroupName "DL"

        # Add the DL-Locale-Department group to the DL-Locale group if not already a member
        $gMember = (Get-ADGroup -Server $ADServer $DLGroupName -Properties memberof).memberof
        $parentGroup = "DL-All-$locale"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $DLGroupName "DL"

        # Create the DDL-Locale-Department groups
        $DLGroupName = "DDL-$locale-$department"
        if (!(Get-ADGroup -Server $ADServer -filter { Name -eq $DLGroupName })) {
            [void] ( New-DistributionGroup -DomainController $ADServer -name $DLGroupName -OrganizationalUnit $shadowGroupsDLOU -SamAccountName $DLGroupName -Type distribution -DisplayName $DLGroupName -MemberJoinRestriction closed -MemberDepartRestriction closed -ManagedBy admin )
            if($?) {
                logging "Created DL: $DLGroupName"
            }

            # Set a description
            Set-ADGroup -Server $ADServer $DLGroupName -Description "Created $today. This is a managed dynamic group that is built based on OU membership. ALL MODIFICATIONS WILL BE OVERWRITTEN!"
        }

        # Add the DDL-Locale-Department group to the DL-Locale-Department group if not already a member
        $gMember = (Get-ADGroup -Server $ADServer $DLGroupName -Properties memberof).memberof
        $parentGroup = "DL-$locale-$department"
        $parentGroupCN = "CN=$parentGroup,"
        addGroupToGroup $gMember $parentGroupCN $parentGroup $DLGroupName "DL"

        # Add user to the DDL-Locale-Department group if not already a member
        $DLGroupName = "DDL-$locale-$department"
        if (!($member -match $DLGroupName)) {
            Add-ADGroupMember -Server $ADServer $DLGroupName -Members $user
            if($?) {
                logging "Added user $userName to group: $DLGroupName"
            }
        }

        # Remove user from the DDL-Local-Department group if no longer a member
        foreach ( $group in (Get-ADGroup -Server $ADServer -SearchBase $shadowGroupsDLOU -Filter { Name -like "DDL-*" }) ) {
            $groupName = $group.name
            if ($groupName -like "*Remote*") { $remote = "-Remote" }
            else { $remote = '' }
            $gLocale = ($groupName -split '-')[1] + $remote
            $gDepartment = ($groupName -split '-')[-1]
            $groupNameCN = "CN=$groupName,"

            # TODO - maybe change the "-notlike" to "-ne" in the below line
            if ( $gLocale -notlike $locale -or $gDepartment -notlike $department ) {
                if ($member -match $groupNameCN) {
                    Remove-ADGroupMember -Server $ADServer $groupName -Members $user -Confirm:$false
                    if($?) {
                        logging "Removed user $userName from DL: $groupName"
                    }
                }
            }
        }

    # Grant the group MB-AllEmployeeCalendars--Read read access to the user's mailbox
    try {
            if (get-mailbox -Identity $username -ErrorAction silentlycontinue) {
                $perms = Get-MailboxFolderPermission -Identity "$($username):\Calendar" -User MB-AllEmployeeCalendars--Read -ErrorAction silentlycontinue
                if (!($perms.IsValid -eq $true -and $perms.AccessRights -eq "Reviewer")) {
                    Add-mailboxfolderpermission -identity "$($username):\Calendar" -user "MB-AllEmployeeCalendars--Read" -AccessRights Reviewer
                    if($?) {
                        logging "Granted MB-AllEmployeeCalendars--Read read access on $username's mailbox."   
                    }
                }
            }
        }
        catch {
            logging $Error[0]
        }
    }

    # Close PSSession to exchange server
    Get-PSSession | ForEach-Object {
        Remove-PSSession $_
        if($?) {
            logging D "Removed PSSession."
        }
    }
} # Close function DistributionLists

function LogCleanUp {

    Get-ChildItem $logPath | Where-Object {$_.LastWriteTime -lt (get-date).AddDays(-365)} | ForEach-Object { 
        $oldLog = "$logPath\$_"
        Remove-Item $oldLog -Force
        logging I "Removing old log: $_."
    }
} # Close function LogCleanUp

###########
# Variables
###########

# Used in the $logLocation variable, so each day gets a new log
$shortDate = Get-Date -Format "yyyy-MM-dd"

# Location where this script will log to
# This is different than the msiexec installation log file, which you specify in the install command
$logPath = "C:\ProgramData\ShadowGroup Script Logs"
$logFile = "$shortDate.txt"
$logLocation = "$logPath\$logFile"

# Turn this to on if you want additional debug logging.  Off will overwrite On if you uncomment the <debug = "off"> line.
# Debug logging will show you the value of all variables so you can see if varable logic problems exist
#$debug = "on"
$debug = "off"

# Used to set the description when disabling inactive computer accounts
$Today = Get-Date -Format "yyyy-MM-dd HH:mm"

# Server name of your main Domain Controller
$ADServer = "pslwsdc01"

# LDAP domain: DC=Domain,DC=COM
$ldapDomain = (Get-ADRootDSE).rootDomainNamingContext

# Define who will moderate sending to DLs
#$moderator = "stewart.grow"

# Static group names
$topLevelDL = "DL-All-Employees"
$topLevelDLRemote = "DL-All-EmployeesRemote"
$topLevelUsers = "All-Employees"
$topLevelPharmacyUsers = "All-Employees-Pharmacy"
$allEmployeesRemote = "All-Employees-Remote"
$topLevelComputers = "All-Workstations"
$topLevelServers = "All-Servers"
$topLevelPAW = "PAW-AllPAWComputers"
$tabletComputers = "All-Tablets"
$laptopComputers = "All-Laptops"
$desktopComputers = "All-Desktops"
$VMComputers = "All-VMs"
$remoteComputers = "All-Workstations-Remote"
$macComputers = "All-Mac"

# Location of the OU that contain employee accounts
$allEmployeesOU = "OU=Users,OU=UpWell,$ldapDomain"

# Location of the OU that conatians computer accounts
$allComputersOU = "OU=Computers,OU=UpWell,$ldapDomain"

# Location of the OU that will contain computer shadow groups
$shadowGroupsComputersOU = "OU=ShadowGroups-Computers,OU=SecurityGroups,OU=Groups,OU=UpWell,$ldapDomain"

# Location of the OU that will contain PAW shadow groups
$shadowGroupsPAWOU = "OU=RBAC-PAW,OU=SecurityGroups,OU=Groups,OU=UpWell,$ldapDomain"

# Location of the OU that will contain server shadow groups
$shadowGroupsServersOU = "OU=ShadowGroups-Servers,OU=SecurityGroups,OU=Groups,OU=UpWell,$ldapDomain"

# Location of the OU that will contain user shadow groups
$shadowGroupsUsersOU = "OU=ShadowGroups-Users,OU=SecurityGroups,OU=Groups,OU=UpWell,$ldapDomain"

# Location of the OU that will contain distribution list shadow groups
$shadowGroupsDLOU = "OU=ShadowGroups-DLs,OU=DistributionGroups,OU=Groups,OU=UpWell,$ldapDomain"

# Location of the OU that will contain disabled computer objects
$disabledComputersOU = "OU=Disabled-Computers,OU=Computers,OU=UpWell,$ldapDomain"

# Location of the OU that will contain disabled user objects
$disabledUsersOU = "OU=Disabled-Users,OU=Users,OU=UpWell,$ldapDomain"

# Description of groups.  You will want to specify these groups as shadow groups so admins don't try to hand modify them.
$description = "Created $today. This is a managed dynamic group that is built based on OU membership. ALL MODIFICATIONS WILL BE OVERWRITTEN!"

# Computer Objects
$allWorkstationOUs = Get-ADOrganizationalUnit -Server $ADServer -SearchBase $allComputersOU -Filter 'Name -like "*Workstations*"'
$allComputers = $allWorkstationOUs | ForEach-Object { Get-ADComputer -Server $ADServer -Filter "*" -SearchBase $_ -Properties "*" }

# PAW Objects
$allPAWOUs = Get-ADOrganizationalUnit -Server $ADServer -SearchBase $allComputersOU -Filter 'Name -eq "PAW"'
$allPAWs = $allPAWOUs | ForEach-Object { Get-ADComputer -Server $ADServer -Filter "*" -SearchBase $_ -Properties "*" }

# Server Objects
$allServerOUs = Get-ADOrganizationalUnit -Server $ADServer -SearchBase $allComputersOU -Filter 'Name -like "*Servers*"'
$allServers = $allServerOUs | ForEach-Object { Get-ADComputer -Server $ADServer -Filter "*" -SearchBase $_ -Properties "*" }

# User Objects
$allUsersOUs = Get-ADOrganizationalUnit -Server $ADServer -SearchBase $allEmployeesOU -Filter "(Name -like 'Corporate') -OR (Name -like 'Pharmacies')"
$allUsers = $allUsersOUs | ForEach-Object { Get-ADUser -Server $ADServer -SearchBase $_ -Filter * }

#################
# Aaaaand Action!
#################

try {
    # Import AD module if not already
    If (!(Get-module ActiveDirectory )) {
        Import-Module ActiveDirectory
    }
    Servers
    Computers
    PAW
    Users
    #DistributionLists
    LogCleanUp
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}