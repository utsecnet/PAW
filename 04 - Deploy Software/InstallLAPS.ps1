<#
.NOTES
    NAME: installLAPS.ps1
    AUTHOR: Rich Johnson
    EMAIL: rjohnson@upwell.com
    Change Log:
        2018-01-19 - Initial creation 
        
.SYNOPSIS
    Runs a task that installs the LAPS admin GUI on PAWs and registers the admpwd.dll file on all other clients.  We don't want the
    GUI on standard user workstations, so they only get the dll.
        General Tab
            - runas: SYSTEM (does not require 'run as highest privileges'
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\installLAPS.ps1 <org>
.DESCRIPTION 
    What does this script do?
    - Checks to see if the LAPS dll is registered.  If not, it registers it.
    - If the computer is a PAW, it installs the LAPS GUI tool to C:\Program Files\LAPS
    What do I need to do?
    - Read the LAPS Administration guide which will walk you through extending your AD schema and setting permissions in AD for users to read your LAPS passwords
    - Download the LAPS files, extract them, and place them on a network share
    - Search this script for <changeme> and replace it with the required data.

.PARAMETER location
    No parameters required

.Example
    >.\installLAPS
    This will install the client on a Draper workstation
#>

############
# Functions
############

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

# Check if program is installed
function checkDllIsRegistered {
    if (Test-Path $dllPath\$file4) {
        $pathExists = $true
    }
    else {
        $pathExists = $false
    }
    logging "D" "pathExists: $pathExists"
    return $pathExists
}

# Install LAPS client
function installLapsClient {

    # Install the LAPS client
    #################################
    if(test-path $remoteFile4) {
        Copy-Item $remoteFile4 $localFile4 -Force
        if ($?) {
            logging "I" "Copied $remoteFile4 to $localFile4"

            # Register dll
            Start-Process -FilePath 'regsvr32.exe' -ArgumentList "/s $localFile4" -Wait
            if ($?) {
                logging "I" "Successfully Registererd DLL."
            }
            else {
                logging "E" "Failed to register DLL."
                exit
            }
        }
        else {
            logging "E" "Failed to copy file!"
            exit
        }
    }
    else {
        logging "E" "$remoteFile4 does not exist!  Check your network connection."
        exit
    }
}

# Install LAPS GUI
function installLapsGUI {

    # Copy some extra files in order to make the GUI work correctly for PAW users
    ############################################################################
    logging "I" "Computer is a PAW."

    if ((Test-Path $remoteFile2) -and (Test-Path $remoteFile3)) {
        
        if (!(Test-Path $localPath)) {
            # Create the directory where the subsequint files will go
            [void](New-Item $localPath -ItemType Directory)
            if ($?) {
                logging "I" "Created $localPath."
            }
            else {
                logging "E" "Failed to create $localPath."
            }
        }
        
        if (!(Test-Path $localFile2)) {
            # Copy the AdmPwd.Utils.dll file to the LAPS directory
            Copy-Item $remoteFile2 $localFile2 -Force -Recurse
            if ($?) {
                logging "I" "Copied $remoteFile2 to $localFile2"
            }
            else {
                logging "E" "Failed to Copy $remoteFile2 to $localFile2"
            }
        }
        else {
            logging "I" "$localFile2 already exists."
        }
        
        if (!(Test-Path $localFile3)) {
            # Copy the AdmPwd.UI.exe file to the LAPS directory
            Copy-Item $remoteFile3 $localFile3 -Force -Recurse
            if ($?) {
                logging "I" "Copied $remoteFile3 to $localFile3"
            }
            else {
                logging "E" "Failed to Copy $remoteFile3 to $localFile3"
            }
        }
        else {
            logging "I" "$localFile2 already exists."
        }
    }
    else {
        logging "E" "Could not access $remoteFile2 or $remoteFile3."
    }
}

######################
# Set global variables
######################

# Location where this script will log to
# This is different than the msiexec installation log file, which you specify in the install command
$logLocation = "c:\programdata\installLAPS.txt"

# Turn this to on if you want additional debug logging.  Off will overwrite On if you uncomment the <debug = "off"> line.
# Debug logging will show you the value of all variables so you can see if varable logic problems exist
$debug = "on"
#$debug = "off"

# Computer Name
$computerName = $env:computername
logging "D" "computername: $computername"

# Distinguished Name - cant use the activedirectory module, as all computers in the domain do not have this installed
$filter = "(&(objectCategory=computer)(objectClass=computer)(cn=$computerName))"
$dn = ([adsisearcher]$filter).FindOne().Properties.distinguishedname
logging "D" "dn: $dn"

# Set the name of the file server.  For example: $fileServer = "serverdfs01"
$fileServer = "<changeme>"

# Set the path to the file share where the install files and logs exist
$remotePath = "\\$fileServer\share\LAPS"
logging "D" "remotePath: $remotePath"

# Set the install directory
$localPath = "C:\Program Files\LAPS"
logging "D" "localPath: $localPath"

# Set the DLL path
$dllPath = "C:\Windows\system32"
logging "D" "dllPath: $dllPath"

# Files that need to be copied over, both the full path to the remote file and full path to local file
#$file1 = "AdmPwd.Utils.config"
$file2 = "AdmPwd.Utils.dll"
$file3 = "AdmPwd.UI.exe"
$file4 = "AdmPwd.dll"
$remoteFile2 = "$remotePath\$file2"
$remoteFile3 = "$remotePath\$file3"
$remoteFile4 = "$remotePath\$file4"
$localFile1 = "$localPath\$file1"
$localFile2 = "$localPath\$file2"
$localFile3 = "$localPath\$file3"
$localFile4 = "$dllPath\$file4"

#########
# ACTION!
#########

try {
        
    # TODO actually search the registry for the DLL name rather than seeing if it's copied to the local machine
        
    # Check if c:\windows\sytem32\admpwd.dll exists
    if (checkDllIsRegistered) {
        # DLL exists
        logging "I" "LAPS client is already installed."
    }
    else {
        logging "I" "LAPS client is not currently installed."

        # Install client
        installLapsClient
            
        # Confirm client was installed successfully
        if (checkDllIsRegistered) {
            logging "I" "LAPS client was successfully installed."
        }
        else {
            logging "E" "Failed to install LAPS client."
        }
    }

    # Install GUI if device is a PAW
    if ($dn -like "*,OU=PAW,*") {
        installLapsGUI
    }
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}
finally {
    logging "I" "Exiting script."
}