## Local Users and Groups
Create the following accounts on each PAW:
* **a local user account** - used as a backup in case any domain trust issues occur that knock the computer off the domain.  It must be a standard user because local admins cannot log in.  Only elevate.  When using fingerprints, this will be their left hand “index finger”.
* **a local admin account (Separate from Default Local Admin)** - PAW user will use this account for all administrative purposes.  When using fingerprints, this will be their left hand “middle finger”.  We don't want to use the default local admin because that password will change every 30 days via LAPS.

These accounts will only be used if domain trust issues happen and a user cannot log into their PAW with their domain account.  Becuase of the logon restrictions we will place on PAWs, local admin accounts will not be able to logon.

## Group Policy

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Local Groups - PAW** with the following setings:

*Computer Configuration > Preferences > Control Panel Settings > Local Users and Groups*
* New Group
    * Administrators (built-in)
        * Order 1
        * Action: Update
        * Description: All Tier 0 PAW Admins
        * Delete all member users: checked
        * Delete al member groups: checked
        * Members > Add > ... button > PAW-Tier0Admins
        * Item-level targeting
            * The computer is a member of the security group DOMAIN\PAW-Tier0Computers

2. Administrators (built-in)  - You will add a new one of these for every PAW user that needs local admin on their PAW
      1- Order: 2
      2- Action: Update
      3- Description: Rich's PAW Local Admins
      4- Delete all users and groups: Unchecked
      5- Members: <username>.admin
      6- Item-level targeting
            1. The NetBIOS computer name is <Select User's PAW computer object>

3. Backup Operators (built-in)
      1- Order: 3
      2- Action: Update
      3- Description: All PAW Backup Operators
      4- Delete all member user and groups: Checked
      5- Members: None
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

4. Cryptographic Operators (built-in)
      1- Order: 4
      2- Action: Update
      3- Description: All PAW Cryptographic Operators
      4- Delete all member user and groups: Checked
      5- Members: None
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

5. Network Configuration Operators (built-in)
      1- Order: 5
      2- Action: Update
      3- Description: All PAW Network Configuration Operators
      4- Delete all member user and groups: Checked
      5- Members: None
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

6. Power Users (built-in)
      1- Order: 6
      2- Action: Update
      3- Description: All PAW Power Users
      4- Delete all member user and groups: Checked
      5- Members: None
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

7. Remote Desktop Users (built-in)
      1- Order: 7
      2- Action: Update
      3- Description: All PAW Demote Desktop Users
      4- Delete all member user and groups: Checked
      5- Members: None
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

8. Replicators (built-in)
      1- Order: 8
      2- Action: Update
      3- Description: All PAW Replicators
      4- Delete all member user and groups: Checked
      5- Members: None
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-AllPAWComputers

9. Hyper-V Administrators
      1- Order: 9
      2- Action: Update
      3- Description: PAW Tier 0 Hyper-V Admins
      4- Delete all member user and groups: Checked
      5- Members: DOMAIN\PAW-Tier0Users
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-Tier-0Computers

10. Hyper-V Administrators
      1- Order: 10
      2- Action: Update
      3- Description: PAW Tier 1 Hyper-V Admins
      4- Delete all member user and groups: Checked
      5- Members: DOMAIN\PAW-Tier1Users
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-Tier-1Computers

11. Hyper-V Administrators
      1- Order: 11
      2- Action: Update
      3- Description: PAW Tier 2 Hyper-V Admins
      4- Delete all member user and groups: Checked
      5- Members: DOMAIN\PAW-Tier2Users
      6- Item-level targeting
            1. the computer is a member of the security group DOMAIN\PAW-Tier-2Computers
