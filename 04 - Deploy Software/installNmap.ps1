<#
.NOTES
    NAME: installNmap.ps1
    AUTHOR: Rich Johnson
    EMAIL: rjohnson@upwell.com
    Change Log:
        2017-12-18 - Initial creation
        
.SYNOPSIS
    This script isntalls Nmap.
    This script is called via a scheduled task or an immediate task (via GPO) with the following details:
        General Tab
            - runas: SYSTEM (does not require 'run as highest privileges')
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\installNmap.ps1

.DESCRIPTION 
    What does this script do?
    - Checks if Nmap is already installed. If not, it installs
    - Creates several registry keys for performance
    - Adds the Nmap directory to Windows PATH

    What do I need to do?
    - Search this script for <changeme> and replace it with the required data.

.PARAMETERS
    - This script takes no parameters

.Example
    >.\installNmap
    Runs the script
#>

# Location where this script will log to
$logLocation = "$env:ProgramData\installNmap.txt"

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

# Check if directory exists
function checkPath ($pathItem) {
    if (test-path -path $pathItem) {
        $pathExists = $true
    }
    else {
        $pathExists = $false
    }
    logging "D" "$pathItem exists: $pathExists"
    return $pathExists
}

# Rename the Nmap installation Directory if it is not "Nmap"
function renameItem {
    $installDir = (Get-Item $localDir\nmap*).Name
    logging "D" "installDir: $installDir"
    Rename-Item $localDir\$installDir $localDir\$programName
    logging "I" "Renamed the installation directory from $localDir\$installDir to $localDir\$programName."
    
}

# Modify PATH variable
function changePath ($action, $addendum) {
    $regLocation = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"
    logging "D" "regLocation: $regLocation"

    $path = (Get-ItemProperty -Path $regLocation -Name PATH).path
    logging "D" "Old Path: $path"
    
    # Add an item to PATH
    if ($action -eq "add") {
        logging "I" "Adding $addendum to PATH variable..."
        $path = "$path;$addendum"
        Set-ItemProperty -Path $regLocation -Name PATH -Value $path
    }

    # Remove an item from PATH
    if ($action -eq "remove") {
        logging "I" "Removing $addendum from PATH variable..."
        $path = ($path.Split(';') | Where-Object { $_ -ne "$addendum" }) -join ';'
        Set-ItemProperty -Path $regLocation -Name PATH -Value $path
    }
    
    $path = (Get-ItemProperty -Path $regLocation -Name PATH).path
    logging "I" "New Path: $path"
}

# Install Nmap and npcap
function installNmap {
    # Copy the zip file to temp
    logging "I" "Copying $remotePath to $tempDir..."
    Copy-Item $remotePath $tempDir -ErrorAction Stop

    # Extract the archive
    logging "I" "Extracting $tempDir\$fileName to $localDir..."
    Expand-Archive $tempDir\$fileName $localDir -ErrorAction Stop -Force
    
    # Delete the temp archive
    logging "I" "Deleting $tempDir\$fileName..."
    Remove-Item $tempDir\$fileName

    # Rename the install directory
    renameItem

    # Install npcap
    logging "I" "Installing npcap..."
    $npcapInstaller = (Get-Item $localPath\npcap*.exe).Name
    & $localPath\$npcapInstaller /S
    
    # Install the Microsoft Visual C++ 2013 Redistributable Package
    logging "I" "Installing the Microsoft Visual C++ 2013 Redistributable Package..."
    $vcredistInstaller = "vcredist_x86.exe"
    & $localPath\$vcredistInstaller /q

    # Add registry changes for performance improvements
    $regFile = "nmap_performance.reg"
    logging "I" "Importing registry settings with the following command: reg.exe import $localPath\$regFile"
    & reg.exe import $localPath\$regFile

    # Add to PATH if not already
    changePath "add" $localPath
}

function uninstallNmap {
    # uninstall Nmap
    logging "I" "Uninstalling $programName..."
    Remove-Item -Recurse $localPath -Force
    if (!(test-path -path $localPath)) {
        logging "I" "Successfully deleted $localPath."
    }
    else {
        logging "E" "Failed to delete $localPath."
    }

    # Uninstall npcap
    logging "I" "Uninstalling npcap..."
    $pathToNpcap = "$env:ProgramFiles\npcap"
    & $pathToNpcap\uninstall.exe /q
    Remove-Item -Recurse $pathToNpcap -Force
    if (!(test-path -path $pathToNpcap)) {
        logging "I" "Successfully deleted $pathToNpcap."
    }
    else {
        logging "E" "Failed to delete $pathToNpcap."
    }
    
    # Remove Nmap from PATH
    changePath "remove" $localPath

    # TODO - do we really need to remove the registry changes?  I don't think so...

}

function checkUpToDate {
    # Get the remote verion
    $remoteVersion = ($remotePath).Split('-')[1]
    logging "D" "remoteVersion: $remoteVersion"

    # Get the local version
    $localVersion = (Get-Item $localPath\nmap.exe).VersionInfo.FileVersion
    logging "D" "localVersion: $localVersion"

    # Compair versions and return $upToDate
    if ($localVersion -eq $remoteVersion) {
        $upToDate = $true
    }
    else {
        $upToDate = $false
    }
    logging "D" "upToDate: $upToDate"
    return $upToDate
}

###########
# Variables
###########

# Program Name
$programName = "Nmap"

# Set the name of the file server.  For example: $fileServer = "serverdfs01"
$fileServer = "<changeme>"

# Location of the remote install file
$remoteDir = "\\$fileServer\share\Nmap"
$fileName = (get-item $remoteDir\nmap*.zip).Name
$remotePath =  "$remoteDir\$fileName"
logging "D" "fileName: $fileName"
logging "D" "remotePath: $remotePath"

# Location of the local install directory
$localDir = $env:ProgramFiles
$localPath = "$localDir\$programName"
logging "D" "localPath: $localPath"

# Temp directory, where we will copy the zip file before extracting to its final destination
$tempDir = $env:TEMP
logging "D" "tempDir: $tempDir"

################
# Aaaand Action!
################

try {

    # Check if Nmap is installed
    if (checkPath $localPath) {
        logging "I" "Nmap is installed."

        # Check if Nmap is current
        if (checkUpToDate) {
            logging "I" "Nmap is up to date."
        }
        else {
            logging "I" "Nmap is out of date."

            # Uninstall Nmap
            uninstallNmap

            # Install Nmap and dependancies
            installNmap

            # Confirm Nmap is current
            if (checkUpToDate) {
                logging "I" "Nmap is up to date."
            }
            else {
                logging "D" "Failed to update Nmap!"
            }

        }
    }
    else {
        logging "I" "Nmap is not installed."
        
        # Install Nmap and dependancies
        installNmap

        # Confirm Nmap is current
        if (checkUpToDate) {
            logging "I" "Nmap is up to date."
        }
        else {
            logging "D" "Failed to update Nmap!"
        }
    }
}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    logging "E" "Caught exception: $($Error[0]) at line $line"
}
finally {
    logging "I" "Exiting script."
}