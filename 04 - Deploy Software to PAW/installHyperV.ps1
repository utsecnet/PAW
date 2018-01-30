<#
.NOTES
    NAME: installHyperV.ps1
    AUTHOR: Rich Johnson
    EMAIL: rjohnson@upwell.com
    Change Log:
        2018-01-03 - Initial creation

.SYNOPSIS
    This script enables the Windows-Hyper-V feature if it is Disabled.
    This script is called via a scheduled task or an immediate task (via GPO) with the following details:
        General Tab
            - runas: SYSTEM (does not require 'run as highest privileges')
        Actions Tab
            - Program/script: powershell.exe
            - Arguments: -executionpolicy bypass -command \\server\share\installHyperV.ps1

.DESCRIPTION 
    What does this script do?
    - Checks to see if the Hyper-V role is enabled on the machine
    - Enables it if not

    What do I need to do?
    - Nothing.  This script relies on on external resources.

.PARAMETERS
    - This script takes no parameters

.Example
    >.\installHyperV
    Runs the script
#>

# Location where this script will log to
$logLocation = "$env:ProgramData\installHyperV.txt"

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

# Check to see if the feature is installed and enabled
function checkFeature {
    if ((Get-WindowsOptionalFeature -FeatureName $feature -Online).state -eq "Enabled") {
        $featureState = $true
    }
    else {
        $featureState = $false
    }
    logging "D" "featureState: $featureState"
    return $featureState
}

###########
# Variables
###########

$feature = "Microsoft-Hyper-V"

################
# Aaaand Action!
################

try {
    # if Hyper-V feature is disabled, enable it
    if (!(checkFeature -eq $true)) {
        logging "I" "$feature is not installed. Installing..."
        
        # Install command
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All

        # Confirm feature was correctly installed
        if (!(checkFeature -eq $true)) {
            logging "E" "Failed to install $feature."
        }
        else {
            logging "I" "Successfully installed $feature."
        }
    }
    else {
        logging "I" "$feature is already installed."
    }
}
catch {
    logging "E" $Error[0]
}
finally {
    logging "I" "Exiting script."
}