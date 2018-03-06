<#
.NOTES
    NAME: installRSAT.ps1
    AUTHOR: Rich Johnson
    EMAIL: rjohnson@upwell.com
    Change Log:
        2017-12-15 - Initial creation

.SYNOPSIS
    This script installs RSAT for Windows 10 1709+.  
    This script is called via a scheduled task or an immediate task (via GPO) with the following details:
        General Tab
            - runas: SYSTEM (does not require 'run as highest privileges')
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\installRSAT.ps1

.DESCRIPTION 
    What does this script do?
    - Checks to see if RSAT is installed, if so it exits
    - Copies the isntallation file to the local machine (installation is faster)
    - Installs RSAT via wusa.exe
    - Confirms correct installation

    What do I need to do?
    - Download RSAT (https://www.microsoft.com/en-us/download/details.aspx?id=45520)
    - Place the .msu file on your network file share
    - Search this script for <changeme> and replace it with the required data

.PARAMETERS
    - This script takes no parameters

.Example
    >.\installRSAT
    Runs the script and installs RSAT, assuming the installation file exists on the remote share


#>

# Location where this script will log to
$logLocation = "$env:ProgramData\installRSAT.txt"

# Turn this to on if you want additional debug logging.  Off will overwrite On if you uncomment the <debug = "off"> line.
# Debug logging will show you the value of all variables so you can see if varable logic problems exist
$debug = "on"
#$debug = "off"

###########
# Functions
###########

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


###########
# Variables
###########

# Get the OS Version.  Used to determine which installation package to use
$osVersion = [System.Environment]::OSVersion.Version.Build
logging "D" "OSVersion: $osVersion"

# NOTE!!!
# This part may be making it more complicated than it needs.  I'm not sure if the 1709 is backwards compatible.  
# If it is, then this section can be removed.  No time to test...

# The RSAT isntallation package is different for different builds of Windows 10
# 16299 = 1709
# 15063 = 1703
if ($osVersion -eq 16299) {
    $hotfix = "WindowsTH-RSAT_WS_1709-x64.msu" 
}
logging "D" "hotfix: $hotfix"

# Directory we want to copy RSAT installation file to
$localPath = "C:\tools\RSAT"
logging "D" "localPath: $localPath"

# Set the name of the file server.  For example: $fileServer = "serverdfs01"
$fileServer = "<changeme>"

# Directory we want to copy RSAT installation file from
$remotePath =  "\\$fileServer\share\RSAT"
logging "D" "remotePath: $remotePath"

################
# Aaaand Action!
################

try {
    # See if RSAT is installed.  If not, install.
    if (!(Get-HotFix -id kb2693643)) {
        logging "I" "RSAT is not currently installed."
        
        # if $localPath does not exist, create it
        if (!(test-path -path $localPath)) {
            logging "I" "$localPath does not exist!  Will create."
            new-Item $localPath -ItemType Directory
            if (!(test-path -path $localPath)) {
                logging "E" "Failed to create $localPath!"
                exit
            }
        }
        else {
            logging "I" "$localPath already exists."
        }

        # if instalation file does not exist on machine, copy it
        if (!(Test-Path -Path $localPath\$hotfix)) {
            logging "I" "Copying RSAT installation file..."
            Copy-Item $remotePath\$hotfix $localPath
            if (!(Test-Path -Path $localPath\$hotfix)) {
                logging "I" "Successfully copied file."
            }
            else {
                logging "E" "Failed to copy file!"
                exit
            }
        }
        else {
            logging "I" "RSAT installation file already exists at $localPath."
        }
        
        logging "I" "Attempting to install RSAT..."

        # Install RSAT, and wait until finished before continuing
        Start-Process -FilePath $env:SystemRoot\system32\wusa.exe -ArgumentList ("$localPath\$hotfix", '/quiet') -Wait
        
        # Check to see if RSAT installed successfully
        if (!(Get-HotFix -id kb2693643)) {
            logging "E" "Failed to install RSAT!"
            exit
        }
        else {
            logging "I" "Successfully installed RSAT."
        }
    }
    else {
        logging "I" "RSAT is already installed."
    }
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}
finally {
    logging "I" "Exiting Script."
}