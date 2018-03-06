<#
.NOTES
    NAME: installVIClient.ps1
    AUTHOR: Rich Johnson
    EMAIL: rjohnson@upwell.com
    Change Log:
        2018-02-05 - Initial creation

.SYNOPSIS
    This script copies the VI Client installation file to your workstation's temp directory.
    This script is called via a scheduled task or an immediate task (via GPO) with the following details:
        General Tab
            - runas: SYSTEM (does not require 'run as highest privileges')
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\installVIClient.ps1

.DESCRIPTION
    What does this script do?
    - Checks to see if the VMware VI Client is installed
    - If not, it copies the install file to the temp directory then installs

    What do I need to do?
    - Download the latest installer for your environment (https://kb.vmware.com/s/article/2089791)
    - put the install file on your network file share
    - Search this script for <changeme> and replace it with the required data.

.PARAMETERS
    - This script takes no parameters

.Example
    >.\installVIClient
    Runs the script
#>

# Location where this script will log to
$logLocation = "$env:ProgramData\installVIClient.txt"

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

# Copy the installer to temp and installs
function installVIClient {
    # Copy the install file to temp

    if (!(test-path -Path $tempDir\$fileName)) {
        logging "I" "Copying $remotePath to $tempDir..."
        Copy-Item $remotePath $tempDir -ErrorAction Stop
    }
    else {
        logging "I" "$tempDir\$fileName already exists.  Will not copy." 
    }

    # Install
    $argList = "/q", "/s", "/w", "/L1033", "/v", "/qr"
    Start-Process -Wait -FilePath "$tempDir\$fileName" -ArgumentList $argList

    # Delete the temp archive
    logging "I" "Deleting $tempDir\$fileName..."
    Remove-Item $tempDir\$fileName
}

###########
# Variables
###########

# Name of the program
$programName = "VMware VI Client"

# Installation directory
$localDir = "C:\Program Files (x86)\VMware\Infrastructure\Virtual Infrastructure Client"
logging "D" "localDir: $localDir"

# Set the name of the file server.  For example: $fileServer = "serverdfs01"
$fileServer = "<changeme>"

# Remote directory
$remoteDir =  "\\$fileServer\share\vmware"
logging "D" "remoteDir: $remoteDir"

# Get the name of the install file
$fileName = (get-item $remoteDir\*.exe).Name
logging "D" "fileName: $fileName"

# Full Path to install file
$remotePath = "$remoteDir\$fileName"
logging "D" "remotePath: $remotePath"

# Temp directory, where we will copy the zip file before extracting to its final destination
$tempDir = $env:TEMP
logging "D" "tempDir: $tempDir"

################
# Aaaand Action!
################

try {
    # Check if VI Client exists on local system
    if (!(test-path -path $localDir)) {
        logging "I" "$programName is not installed."

        # Install
        installVIClient

        # Confirm it installed correctly
        if (!(test-path -path $localDir)) {
            logging "E" "Failed to install $programName."
        }
        else {
            logging "I" "Successfully installed $programName."
        }

    }
    else {
        logging "I" "$programName is already installed."
    }
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}
finally {
    logging "I" "Exiting Script."
}