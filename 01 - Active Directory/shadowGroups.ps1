<#
.NOTES
    NAME: shadowGroups.ps1
    AUTHOR: Rich Johnson
    EMAIL: rich.johnson@upwell.com
    REQUIREMENTS:
    Change Log:
        2018-01-25 - Added Tier to servers
        2018-01-08 - Initial Creation

.SYNOPSIS
    This script manages shadowgroup creation and membership in Active Directory.

.DESCRIPTION
    What does this sript do?
    - This script would run as a scheduled task on a domain controller.
    - Creates shadow groups for computer objects in Active Directory. OU structure is very important.
    - Adds computers to the appropriate groups. Also nests groups.
    - Disables computer objects and moves them to a specified OU if inactive.
    - Creates shadow groups for user objects in Active Directory.  OU structure, again, is very important.
    - Adds users to the appropriate groups. Also nests groups.
    - Adds users to appropriate chat groups for open fire server.
    - Moves all disabled users to the DisabledUsers OU
    - Removes all group membership of disabled user accounts
    - Removes all disabled users from the GAL
    - All actions are logged to C:\ProgramData\shadogroups.txt.  Use this log file to troubleshoot problems.

    What do I need to do?
    - Search this script for <changeme> and replace it with the required data.
    - This script heavily relies on an accurate and well organized Active Directory heiarchy.  For this example, we will use the following tree structure:

    DOMAIN.COM
    ├── Domain Controllers
    └── Company
        ├── Computers
        │   ├── Disabled-Computers - - - Will hold all disabled computer accounts
        │   └── Location A
        │       ├── PAW
        │       │   ├── Tier 0   - - - - Will hold Tier 0 PAWs (for domain admins)
        │       │   ├── Tier 1   - - - - Will hold Tier 1 PAWs (for server admins)
        │       │   └── Tier 2   - - - - Will hold Tier 2 PAWs (for Helpdesk admins)
        │       ├── Servers
        │       │   ├── Tier 0   - - - - Will hold Tier 0 servers (but not DCs!)
        │       │   └── Tier 1   - - - - Will hold Tier 1 servers (most member servers)
        │       ├── Workstations - - - - Put all workstation objects here, in you own hierarchy
        │       └── VMs          - - - - All VMs, including your PAWs day-to-day VM
        ├── Groups
        │   └── Security Groups
        │       ├── PAW          - - - - All groups related to PAW management
        │       ├── AD           - - - - All groups that have explicite permissions throughout AD (like helpdesk guys and the scheduled task account)
        │       ├── Shadowgroups-Computers - - - Computer object's shadowgroups
        │       ├── Shadowgroups-Servers - - - - Server object's shadowgroups
        │       └── Shadowgroups-Users - - - - - User's object's shadowgroups
        └── Users
            ├── Employees        - - - - Will hold all Employee accounts.  Feel free to organize your own heirarchy.  For this example, we use <Locale>\<Department>
            │   └── Tier 0       - - - - Will hold Tier 1 user accounts (for domain admins)
            │   └── Tier 1       - - - - Will hold Tier 1 user accounts (for server admins)
            ├── Disabled-Users   - - - - Will hold all disabled user accounts
            ├── ServiceAccounts  - - - - Will hold all service accounts, and special use accounts (like accounts that run scheduled tasks)
            └── PAW Accounts
                ├── Tier 0       - - - - Will hold Tier 1 user accounts (for domain admins)
                ├── Tier 1       - - - - Will hold Tier 1 user accounts (for server admins)
                └── Tier 2       - - - - Will hold Tier 1 user accounts (for server admins)

    - Scripts should never be run as a Domain Admin.  Though is the world of PAWs and a correctly setup Tier 0 environment, I don't see why not.
      However, if you decide you want to run this script as a dedicated user account (good idea!), here are the requirements to set that up:
        - Create the user account that will run this script in the DOMAIN.COM\Company\Users\ServiceAccounts OU.
        - Create the following groups in DOMAIN.COM\Company\Groups\SecurityGroups\AD OU:
            - AD-Company-Computers--DeleteComputerObjects
            - AD-Company-Computers-DisabledComputers--CreateComputerObjects
            - AD-Company-Groups-ShadowGroupsComputers--Modify
            - AD-Company-Groups-ShadowGroupsServers--Modify
            - AD-Company-Groups-ShadowGroupsUsers--Modify
            - AD-Company-Users--DeleteUserObjects
            - AD-Company-Users-DisabledUsers--CreateUserObjects
            - Add the taskrunner-shadowgroup user to all the above groups

.EXAMPLE
    - This script requires no parameters.
    - This script is called via a scheduled task with the following details:
        General Tab
            - runas: taskrunner-shadowgroup (does not require 'run as highest privileges')
            - Run whether user is logged in or not
            - Keep the other defaults
        Triggers Tab
            - Begin the task: On a schedule
            - One Time
            - Advanced settings
                - Repeat the task: every 15 minutes (You decide)
                - for a duration of: Indefinitely
                - Stop task if it runs longer than: 30 minutes
                - Enabled
            - Keep the other defaults
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\shadowgroups.ps1
        Settings Tab
            - Allow task to be run on demand
            - Keep the other defaults
#>

# Location where this script will log to
$logLocation = "C:\ProgramData\shadowgroups.txt"

# Turn this to on if you want additional debug logging.  Off will overwrite On if you uncomment the <debug = "off"> line.
# Debug logging will show you the value of all variables so you can see if varable logic problems exist
#$debug = "on"
$debug = "off"

# Used to set the description when disabling inactive computer accounts
$Today = Get-Date -Format "yyyy-MM-dd HH:mm"

# Server name of your main Domain Controller.  For example: $ADServer = "dc01"
$ADServer = "<changeme>"

# LDAP domain: DC=Domain,DC=COM
$ldapDomain = (Get-ADRootDSE).rootDomainNamingContext

# Static group names
$topLevelUsers = "All-Employees"
$allEmployeesRemote = "All-Employees-Remote"
$topLevelComputers = "All-Workstations"
$topLevelServers = "All-Servers"
$tabletComputers = "All-Tablets"
$laptopComputers = "All-Laptops"
$desktopComputers = "All-Desktops"
$VMComputers = "All-VMs"
$remoteComputers = "All-Workstations-Remote"

# Name of the top level Company OU (the OU directly under Domain.com).
# This is the OU that will hold Users, Computers, Groups...
# For example: $company = "Company"
$company = "<changeme>"

# Location of the OU that contain employee accounts
$allEmployeesOU = "OU=Employees,OU=Users,OU=$company,$ldapDomain"

# Location of the OU that conatians computer accounts
$allComputersOU = "OU=Computers,OU=$company,$ldapDomain"

# Location of the OU that will contain computer shadow groups
$shadowGroupsComputersOU = "OU=ShadowGroups-Computers,OU=SecurityGroups,OU=Groups,OU=$company,$ldapDomain"

# Location of the OU that will contain server shadow groups
$shadowGroupsServersOU = "OU=ShadowGroups-Servers,OU=SecurityGroups,OU=Groups,OU=$company,$ldapDomain"

# Location of the OU that will contain user shadow groups
$shadowGroupsUsersOU = "OU=ShadowGroups-Users,OU=SecurityGroups,OU=Groups,OU=$company,$ldapDomain"

# Location of the OU that will contain disabled computer objects
$disabledComputersOU = "OU=Disabled-Computers,OU=Computers,OU=$company,$ldapDomain"

# Location of the OU that will contain disabled user objects
$disabledUsersOU = "OU=Disabled-Users,OU=Users,OU=$company,$ldapDomain"

# Description of groups.  You will want to specify these groups as shadow groups so admins don't try to hand modify them.
$description = "Created $today. This is a managed dynamic group that is built based on OU membership. ALL MODIFICATIONS WILL BE OVERWRITTEN!"

# Computer Objects
$allWorkstationOUs = Get-ADOrganizationalUnit -Server $ADServer -SearchBase $allComputersOU -Filter 'Name -like "*Workstations*"'
$allComputers = $allWorkstationOUs | ForEach-Object { Get-ADComputer -Server $ADServer -Filter "*" -SearchBase $_ -Properties "*" }

# Server Objects
$allServerOUs = Get-ADOrganizationalUnit -Server $ADServer -SearchBase $allComputersOU -Filter 'Name -like "*Servers*"'
$allServers = $allServerOUs | ForEach-Object { Get-ADComputer -Server $ADServer -Filter "*" -SearchBase $_ -Properties "*" }

# User Objects
$allUsers = Get-ADUser -Server $ADServer -Filter * -SearchBase $allEmployeesOU -Properties "*"

###########
# Functions
###########

# All actions are logged by calling this function
function logging ($level, $text) {
    if ($debug -ne "on" -and $level -eq "D") {
        return
    }
    $timeStamp = get-date -Format "yyyy-MM-dd HH:mm:ss.fff"

    if ($blurb -ne "yes") {
        # Override the existing log file so it does not grow out of control
        Write-Output "$timeStamp I New log created" > $logLocation
        $script:blurb = "yes"
    }

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
            logging "I" "Added $objectType $memberName to group $groupName, 'addToGroup'"
        }
    }
}

# Remove group from group
function removeGroupFromGroup ($membership, $groupNameCN, $groupName, $member, $memberName, $objectType) {
    if (($membership -match $groupNameCN)) {
        Remove-ADGroupMember -Server $ADServer $groupName -Members $member -Confirm:$false
        if($?) {
            logging "I" "Removed $objectType $memberName from group $groupName via function, 'removeGroupFromGroup'"
        }
    }
}

# Remove object from group
function removeFromGroup ($membership, $groupName, $member, $memberName, $objectType) {
    if (($membership -match $groupName)) {
        Remove-ADGroupMember -Server $ADServer $groupName -Members $member -Confirm:$false
        if($?) {
            logging "I" "Removed $objectType $memberName from group $groupName via function, 'removeFromGroup'"
        }
    }
}

function Computers {
    logging "I" "##### Processing Computers #####"

    # Create the All-Workstations group
    createGroup $topLevelComputers "Global" "security" $description $shadowGroupsComputersOU

    # Create the All-Workstations-Remote group
    createGroup $remoteComputers "Global" "security" $description $shadowGroupsComputersOU

    # Add the All-Workstations-Remote group to the All-Workstations group
    $gMember = (Get-ADGroup -Server $ADServer $remoteComputers -Properties memberof).memberof
    $parentGroup = $topLevelComputers
    $parentGroupCN = "CN=$parentGroup,"
    addGroupToGroup $gMember $parentGroupCN $parentGroup $remoteComputers "group"

    ########################################
    # Create all the computer Shadow Groups!
    ########################################
    foreach ( $computer in $allComputers ) {

        # Get the group membership of the computer
        $member = (Get-ADComputer $computer -Properties memberof).memberof

        # Define attributes about the computer to be used for building the group names
        #                  0  1             2  3  4  5  6  7            8  9    10 11        12 13      14 15     16 17
        # example of a DN: CN=Workstation01,OU=IT,OU=VM,OU=Workstations,OU=Utah,OU=Computers,OU=Company,DC=DOMAIN,DC=COM
        $computerName = $computer.Name
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

        # Remove it from the All-Tablets group if it is not a VM
        if (!( $dn -like "*OU=Tablets*" )) {
            removeFromGroup $member $VMComputers $computer $computerName "computer"
        }

        # Remove computer from any Local-Department-Platform groups of which it no longer belongs
        foreach ( $group in (Get-ADGroup -Server $ADServer -SearchBase $shadowGroupsComputersOU -Filter { Name -notlike "All-*" }) ) {
            $groupLocale = ($group.Name -split '-')[0]
            $groupPlatform = ($group.Name -split '-')[-1]
            $groupDepartment = ($group.Name -split '-')[-2]
            $groupName = $group.Name
            $groupNameCN = "CN=$groupName,"
            if ( $groupLocale -notlike $locale -or $groupDepartment -notlike $department -or $groupPlatform -notlike $platform) {
                removeGroupFromGroup $member $groupNameCN $groupName $computer $computerName "computer"
            }
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
    logging "I" "##### Processing Disabled Computer Accounts #####"

    $description = "Account disabled via shadowgroups script due to inactivity on $Today"

    # Disable computer accounts within the DisabledComputers OU if not already disabled...just in case!
    Get-ADComputer -Server $ADServer -Filter * -SearchBase "$DisabledComputersOU" | Where -Property enabled | Disable-ADAccount

    # Disable Remote computers that have not logged on to corpnet for more than 365 days
    # You should descide on how to do this for your organization.  In our case, remote employees come to the office at least once a year for annual training.  So if they don't authenticate for over 1 year, disable the account.
    Search-ADAccount -Server $ADServer -AccountInactive -TimeSpan 365.00:00:00 -SearchBase $allComputersOU | where {($_.distinguishedname -like "*Remote*") -and ($_.distinguishedname -notlike "*OU=Disabled-Computers,*") -and ($_.lastLogonDate) -and !($_.lastLogonDate -ge (Get-Date).AddDays(-365))} | foreach {
        Disable-ADAccount $_
        if($?) {
            logging "I" "Disabled remote workstation: $($_.name) becuase it has been inactive for more than 365 days."
        }
        Set-ADObject $_ -Description $description
        Move-ADObject $_ -TargetPath $disabledComputersOU
        if($?) {
            logging "I" "Moved $($_.name) to the Disabled-Computers OU"
        }
    }

    # Disable Local computers that have not logged on to corpnet for more than 45 days
    # You should descide on how to do this for your organization.  In our case, I have found that a good number to disable computers is 45 days
    Search-ADAccount -Server $ADServer -AccountInactive -TimeSpan 45.00:00:00 -SearchBase $allComputersOU | where {($_.distinguishedname -notlike "*Remote*") -and ($_.distinguishedname -notlike "*OU=Disabled-Computers,*") -and ($_.lastLogonDate) -and !($_.lastLogonDate -ge (Get-Date).AddDays(-45)  ) } | foreach {
        Disable-ADAccount $_
        if($?) {
            logging "I" "Disabled local workstation: $($_.name) becuase it has been inactive for more than 45 days."
        }
        Set-ADObject $_ -Description $description
        Move-ADObject $_ -TargetPath $disabledComputersOU
        if($?) {
            logging "I" "Moved $($_.name) to the Disabled-Computers OU"
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

function Servers {
    logging "I" "##### Processing Servers #####"

    # Create the All-Servers group
    createGroup $topLevelServers "Global" "security" $description $shadowGroupsServersOU

    ########################################
    # Create all the computer Shadow Groups!
    ########################################
    foreach ( $server in $allServers ) {

        # Get the group membership of the computer
        $member = (Get-ADComputer $server -Properties memberof).memberof

        # Define attributes about the computer to be used for building the group names
        #                  0  1        2  3     4  5          6  7       8  9    10 11        12 13      14 15      16 17
        # example of a DN: CN=Server01,OU=Tier1,OU=Production,OU=Servers,OU=Utah,OU=Computers,OU=Company,DC=Company,DC=COM
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
            $groupName = $group.Name
            $groupNameCN = "CN=$groupName,"
            if ( $groupLocale -notlike $locale -or $groupCategory -notlike $category ) {
                removeGroupFromGroup $member $groupNameCN $groupName $server $serverName "server"
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
    logging "I" "##### Processing Users #####"

    # Create the All-Employees group
    createGroup $topLevelUsers "Global" "security" $description $shadowGroupsUsersOU

    # Create the All-Employees-Remote group
    createGroup $allEmployeesRemote "Global" "security" $description $shadowGroupsUsersOU

    ####################################
    # Create all the user Shadow Groups!
    ####################################
    foreach ( $user in $allUsers ) {

        # Get the group membership of the user
        $member = (Get-ADUser $user -Properties memberof).memberof

        # Define attributes about the user to be used for building the group names
        #                  0  1        2  3  4  5    6  7         8  9     10 11      12 13      14 15
        # example of a DN: CN=Bob Hope,OU=IT,OU=Utah,OU=Employees,OU=Users,OU=Company,DC=Company,DC=COM
        $username = $user.name
        $dn = $user.distinguishedname
        $department = ($dn -split '[,\=]')[3]
        $locale = ($dn -split '[,\=]')[5]
        if ( $dn -like "*Remote*" ) {
            $remote = '-Remote'
            $isRemote = "yes"
        }
        else { $remote = '' }

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
            if ($groupName -like "*Remote*") { $remote = "-Remote" }
            else { $remote = '' }
            $groupLocale = ($groupName -split '-')[1] + $remote
            $groupDepartment = ($groupName -split '-')[-1]
            $groupNameCN = "CN=$groupName,"

            if ( $groupLocale -notlike $locale -or $groupDepartment -notlike $department ) {
                removeGroupFromGroup $member $groupNameCN $groupName $user $userName "user"
            }
        }

        # If user is disabled, move to Disabled-Users OU
        if ( $user.Enabled -eq $false  ) {
            Move-ADObject -Identity $user -TargetPath $disabledUsersOU
            if($?) {
                logging "I" "Moved user $userName to the Disabled-Users OU"
            }
        }
    }

    #########################################
    # Begin processing disabled user accounts
    #########################################

    # NOTE: We will NEVER delete any user accounts, even disabled!

    logging "I" "##### Processing Disabled User Accounts #####"

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

#################
# Aaaaand Action!
#################

try {

    # Import AD module if not already
    If (!(Get-module ActiveDirectory )) {
        Import-Module ActiveDirectory
    }

    # Comment any of these function calls out for troubleshooting or testing.  For example, if you want to only run the users function then comment Servers and Computers.
    Servers
    Computers
    Users
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}
finally {
    logging "I" "Exiting Script"
}
