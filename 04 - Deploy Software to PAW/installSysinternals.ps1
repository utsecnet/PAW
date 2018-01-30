<#
.NOTES
    NAME: installSysinternals.ps1
    AUTHOR: Rich Johnson
    EMAIL: rjohnson@upwell.com
    Change Log:
        2017-12-15 - Initial creation

.SYNOPSIS
    This script copies the Sysinternals files to your workstation.
    This script is called via a scheduled task or an immediate task (via GPO) with the following details:
        General Tab
            - runas: SYSTEM (does not require 'run as highest privileges')
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\installSysinternals.ps1

.DESCRIPTION 
    What does this script do?
    - Checks to see if the SysinternalsSuite directory exists on local machine (C:\Tools\Sysinternals)
    - Copies the tool's zip file to the local machine and extracts to the C:\Tools\Sysinternals location
    - Adds 

    What do I need to do?
    - Download the latest stable command-line zipfile (https://nmap.org/download.html) NOT the self-installer!!
    - put the zip file on your network file share
    - Search this script for <changeme> and replace it with the required data.

.PARAMETERS
    - This script takes no parameters

.Example
    >.\installSysinternals
    Runs the script
#>

# Location where this script will log to
$logLocation = "$env:ProgramData\installSysinternals.txt"

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

# Copy the zip, extract to c:\tools
function installSI {
    # Copy the zip file to temp
    logging "I" "Copying $remotePath to $tempDir..."
    Copy-Item $remotePath $tempDir -ErrorAction Stop

    # Extract the archive
    logging "I" "Extracting $tempDir\$fileName to $localPath..."
    Expand-Archive $tempDir\$fileName $localPath -ErrorAction Stop -Force
    
    # Delete the temp archive
    logging "I" "Deleting $tempDir\$fileName..."
    Remove-Item $tempDir\$fileName
}

# Compair the creation dates of two folders to determine is sync is needed
function compairCreation {
    $remoteCreation = (Get-ItemProperty $remotePath).CreationTime
    logging "D" "$remotePath creation time: $remoteCreation"

    $localCreation = (Get-ItemProperty $localPath).CreationTime
    logging "D" "$localPath creation time: $localCreation"

    if ($localCreation -eq $remoteCreation) {
        $sameDate = $true
    }
    else {
        $sameDate = $false
    }
    logging "D" "sameDate: $sameDate"
    return $sameDate
}

 # Set the creationTime of localPath to that of remotePath
 function setCreation {
    $remoteCreation = (Get-ItemProperty $remotePath).CreationTime
    Set-ItemProperty $localPath -Name CreationTime -Value $remoteCreation

    # Confirm creation date is the same for both remote and localPath
    if (compairCreation) {
        logging "I" "Creation dates are the same."
    }
    else {
        logging "E" "Creation dates are still not the same.  Check your installation script."
    }
 }

# Add string to PATH
function changePath ($addendum) {
    $regLocation = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"
    $oldPath = (Get-ItemProperty -Path $regLocation -Name PATH).path
    logging "D" "oldPath: $oldPath"
    if ($oldPath -like "*$addendum*") { 
        logging "I" "Looks like $addendum is already in PATH.  Will not add."
    }
    else {
        $newPath = "$oldPath;$addendum"
        Set-ItemProperty -Path $regLocation -Name PATH -Value $newPath
        logging "D" "newPath: $newPath"
    }
}

###########
# Variables
###########

# Name of the program
$programName = "SysinternalsSuite"

# Directory we will put Sysinternals
$localDir = "$env:SystemDrive\Tools"
logging "D" "localDir: $localDir"

# Full path to local sysinternal directory
$localPath = "$localDir\$programName"
logging "D" "localPath: $localPath"

# Set the name of the file server.  For example: $fileServer = "serverdfs01"
$fileServer = "<changeme>"

# Directory we want to copy Sysinternals directory from
$remoteDir =  "\\$fileServer\share\$programName"
logging "D" "remoteDir: $remoteDir"

# Get the name of the .zip file
$fileName = (get-item $remoteDir\*.zip).Name
logging "D" "fileName: $fileName"

# Full Path to .zip file
$remotePath = "$remoteDir\$fileName"
logging "D" "remotePath: $remotePath"

# Temp directory, where we will copy the zip file before extracting to its final destination
$tempDir = $env:TEMP
logging "D" "tempDir: $tempDir"

################
# Aaaand Action!
################

try {
    # Check if Sysinternals Suite exists on local system
    if (!(test-path -path $localPath)) {
        logging "I" "$programName is not installed."

        # Copy and extract the SI tools
        installSI

        # Set creation date on localPath
        setCreation

        # Add to PATH
        changePath $localPath
    }
    else {
        logging "I" "$programName is already installd."

        # Check creation date.  If they are different, delete and re-install
        # if they are the same, exit
        if (compairCreation) {
            logging "I" "Creation dates are the same."
        }
        else {
            logging "W" "Creation dates are not the same. Must recopy files."

            # Delete localPath
            Remove-Item -Recurse $localPath
            if (!(test-path -path $localPath)) {
                logging "I" "Successfully deleted $localPath."
            }
            else {
                logging "E" "Failed to delete $localPath."
            }

            # Copy and extract the SI tools
            installSI

            # Set creation date on localPath
            setCreation
        }
    }
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}
finally {
    logging "I" "Exiting Script."
}