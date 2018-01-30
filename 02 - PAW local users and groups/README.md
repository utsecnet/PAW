## Local Users and Groups
Create the following accounts on each PAW:
* **a local user account** - used as a backup in case any domain trust issues occur that knock the computer off the domain.  It must be a standard user because local admins cannot log in.  Only elevate.  When using fingerprints, this will be their left hand “index finger”.
* **a local admin account (Separate from Default Local Admin)** - PAW user will use this account for all administrative purposes.  When using fingerprints, this will be their left hand “middle finger”.  We don't want to use the default local admin because that password will change every 30 days via LAPS.

These accounts will only be used if domain trust issues happen and a user cannot log into their PAW with their domain account.  Becuase of the logon restrictions we will place on PAWs, local admin accounts will not be able to logon.

## Group Policy

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Local Groups - PAW** with the following setings:

*Computer Configuration > Preferences > Control Panel Settings > Local Users and Groups*

Create the following new groups

* Administrators (built-in)
    * Order 1
    * Action: Update
    * Description: All Tier 0 PAW Admins
    * Delete all member users: checked
    * Delete al member groups: checked
    * Members > Add > ... button > PAW-Tier0Admins
    * Item-level targeting
        * The computer is a member of the security group DOMAIN\PAW-Tier0Computers

* Administrators (built-in)  - You will add a new one of these for every PAW user that needs local admin on their PAW
    * Order: 2
    * Action: Update
    * Description: Rich's PAW Local Admins
    * Delete all users and groups: Unchecked
    * Members: <username>.admin
    * Item-level targeting
        * The NetBIOS computer name is <Select User's PAW computer object>

* Backup Operators (built-in)
    * Order: 3
    * Action: Update
    * Description: All PAW Backup Operators
    * Delete all member user and groups: Checked
    * Members: None
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

* Cryptographic Operators (built-in)
    * Order: 4
    * Action: Update
    * Description: All PAW Cryptographic Operators
    * Delete all member user and groups: Checked
    * Members: None
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

* Network Configuration Operators (built-in)
    * Order: 5
    * Action: Update
    * Description: All PAW Network Configuration Operators
    * Delete all member user and groups: Checked
    * Members: None
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

* Power Users (built-in)
    * Order: 6
    * Action: Update
    * Description: All PAW Power Users
    * Delete all member user and groups: Checked
    * Members: None
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

* Remote Desktop Users (built-in)
    * Order: 7
    * Action: Update
    * Description: All PAW Demote Desktop Users
    * Delete all member user and groups: Checked
    * Members: None
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

* Replicators (built-in)
    * Order: 8
    * Action: Update
    * Description: All PAW Replicators
    * Delete all member user and groups: Checked
    * Members: None
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

* Hyper-V Administrators
    * Order: 9
    * Action: Update
    * Description: PAW Tier 0 Hyper-V Admins
    * Delete all member user and groups: Checked
    * Members: DOMAIN\PAW-Tier0Users
    * Item-level targeting
          * the computer is a member of the security group DOMAIN\PAW-Tier-0Computers

* Hyper-V Administrators
    * Order: 10
    * Action: Update
    * Description: PAW Tier 1 Hyper-V Admins
    * Delete all member user and groups: Checked
    * Members: DOMAIN\PAW-Tier1Users
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-Tier-1Computers

* Hyper-V Administrators
    * Order: 11
    * Action: Update
    * Description: PAW Tier 2 Hyper-V Admins
    * Delete all member user and groups: Checked
    * Members: DOMAIN\PAW-Tier2Users
    * Item-level targeting
        * the computer is a member of the security group DOMAIN\PAW-Tier-2Computers
