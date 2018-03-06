## What is this?
LAPS is an agent-based control designed to prevent Pass-the-hash attacks and other similar internal pivoting attacks.  It does this by automatically assigning a unique password to the local administrator account.  The password policy is configured via the Group Policy MMC snap-in.  The LAPS agent is installed via a scheduled task that calls a powershell script.  Read access to the passwords are delegated via Active Directory ACLs, much like NTFS permissions on a file share. Passwords are accessed via one of three ways:

1. From the LAPS UI (installed on PAWs)
2. From AD (object properties > Attribute Editor > find the LAPS password in the list)
3. PowerShell

***NOTE***: *Currently, there is no native way to access the LAPS password from a phone or other mobile device.  Normally, you could enable RDP on a workstation or jump-box with one of the three above tools, but this would break our clean-source principal so I do not recommend it or go over how to do this in this guide.*

## Aquare LAPS software
The LAPS Software can be [downloaded here](https://www.microsoft.com/en-us/download/details.aspx?id=46899).

## Step by step guide for deploying LAPS
I'm not going to re-write what has already been written.  The point of this guide is to adapt your LAPS deployment to meet the security requirements for PAW deployment.  You can download a very thorough guide [here](https://encrypted.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwiFhqTc2djZAhVE5YMKHQ7TAKoQFggoMAA&url=https%3A%2F%2Fgallery.technet.microsoft.com%2FStep-by-Step-Deploy-Local-7c9ef772%2Ffile%2F150657%2F1%2FStep%2520by%2520Step%2520Guide%2520to%2520Deploy%2520Microsoft%2520LAPS.pdf&usg=AOvVaw1oFbhKjAgDhW8We0LLPNax).  The guide is also available in the file list above, just in case it ever gets taken off line.

## Configuring AD Permissions
When you get to the section titled, "How to configure Active directory for LAPS", you will deviate from the instruction and follow these instruction instead:

### Create AD Groups
Create the following AD groups under DOMAIN.COM/Company/Groups/SecurityGroups/LAPS-RBACK:
* AD-Company-Computers-AllLocations-Servers-Tier1--LAPSPassword
* AD-Company-Computers-AllLocations-WKS--LAPSPassword

***NOTE***: The Tier 0 server will not need delegation to a specific group, since your Tier 0 Admin user is alrady a member of Domain Admins, which has full access to the LAPS password attribute.

### Run the following PowerShell commands to set the ACLs
```powershell
Set-AdmPwdReadPasswordPermission -OrgUnit "OU=Tier1,OU=Servers,OU=Location1,OU=Computers,OU=Company,DC=DOMAIN,DC=COM" -AllowedPrincipals AD-Company-Computers-AllLocations-Servers-Tier1--LAPSPassword
Set-AdmPwdReadPasswordPermission -OrgUnit "OU=Workstations,OU=Location 1,OU=Computers,OU=Company,DC=DOMAIN,DC=COM" -AllowedPrincipals AD-UpWell-Computers-AllLocations-Workstations--LAPSPassword
```

Repeat as needed for your various locations throughout AD.  

***NOTE***: *If you mess up and need to undo the permission, you can right click the OU > Properties > Security Tab > Advanced button.  There will be two ACLs you need to remove.*

## Install the LAPS agent
Follow the instruction in the section titled, "04 - Deploy Software to PAW" regarding LAPS.  The script above will also be found in that section.