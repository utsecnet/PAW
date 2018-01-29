## Shadow Groups
If you want to use Shadow Groups to aide in managing your devices, you will need to keep your PAW devices separate from your day-to-day devices.  This means a separate OU for your PAW devices and a separate OU for all your other workstations.  

What are Shadow Groups?

Shadow Groups are groups that mirror the membership of an Active Directory OU.  If you have ever administrated a Novel Netware network, you will recall that you can apply the membership of an OU to a network object's ACL.  Thus, giving access to an object based on the users in an OU.  Active Directory does not allow you to add OUs to ACLs.  Thus, if we wanted to replicate this behavior in AD, we need shadow groups.  With shadow groups you now have all members of each department in a group.  All departmental computers in their own groups.  All laptops in their own groups.  All Tablets in their own groups...

What else can you do with Shadow Groups?

* Apply GPO security filtering to shadow groups rather than **Authenticated Users**.  Now you can apply the GPO to a higher level OU, and have it apply to only certain child OUs without the need for complicated WMI filters.
* More effectively manage NPS 802.1x policies.  
* Quicker reporting for auditors.  All employees are in thier own group, filtering out things like service accounts, contacts, and contractors which are members of the **Domain Users** group.  Same for computers and the **Domain Computers** group.
* Rule the world

How are Shadow Groups managed?

A scheduled task runs on a regular interval and creates groups based on your Active Directory OU hierarchy.  It then takes the members of the OU and adds them as members of the group.  Lastly, it removes group members that may have moved to a different OU, keeping your group membership accurate.

## Recommended Active Directory Hierarchy
```
DOMAIN.COM
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
    │       ├── Workstations - - - - Will hold all Computer accounts.  Feel free to organize your own hierarchy.  For this example, we use <Locale>\<Department>
    │       │   └── Location     - - - - Each office location will have its own OU
    │       │       └── Department   - - Each department will hold the computer accounts for that department
    │       └── VMs          - - - - All VMs, including your PAWs day-to-day VM
    ├── Groups
    │   └── Security Groups
    │       ├── PAW          - - - - All groups related to PAW management
    │       ├── Shadowgroups-Computers - - - Computer object's shadowgroups
    │       ├── Shadowgroups-Servers - - - - Server object's shadowgroups
    │       └── Shadowgroups-Users - - - - - User's object's shadowgroups
    └── Users
        ├── Employees        - - - - Will hold all Employee accounts.  Feel free to organize your own hierarchy.  For this example, we use <Locale>\<Department>
        │   └── Location     - - - - Each office location will have its own OU
        │       └── Department   - - Each department will hold the user accounts for that department
        ├── Disabled-Users   - - - - Will hold all disabled user accounts
        ├── ServiceAccounts  - - - - Will hold all service accounts, and special use accounts (like accounts that run scheduled tasks)
        └── PAW Accounts
            ├── Tier 0       - - - - Will hold Tier 1 user accounts (for domain admins)
            ├── Tier 1       - - - - Will hold Tier 1 user accounts (for server admins)
            └── Tier 2       - - - - Will hold Tier 1 user accounts (for server admins)
```
## Active Directory Permissions
Modify AD Advanced Security Permissions of the following OUs (should probably be scripted in the future...)

**COMPANY.COM\Company\Computers**
* ACL 1
  * Principal: AD-Company-Computers--DeleteComputerObjects
  * Type: Allow
  * Applies to: Descendant Computer Objects
  * Properties: Write Name, and Write name (capitol and lower case N & n)
* ACL 2
  * Principal: AD-Company-Computers--DeleteComputerObjects
  * Type: Allow
  * Applies to: This object and all descendant Objects
  * Permissions: Delete Computer objects
* ACL 3
  * Principal: AD-Company-Computers--DeleteComputerObjects
  * Type: Allow
  * Applies to: Descendant Computer Objects
  * Permissions: Read all properties

**COMPANY.COM\Company\Users\Employees**
* ACL 1
  * Principal: AD-Company-Users--DeleteUserObjects
  * Type: Allow
  * Applies to: Descendant User Objects
  * Properties: Write Name, and Write name (capitol and lower case N & n)
* ACL 2
  * Principal: AD-Company-Users--DeleteUserObjects
  * Type: Allow
  * Applies to: This object and all descendant objects
  * Permissions: Delete user objects
* ACL 3
  * Principal: AD-Company-Users--DeleteUserObjects
  * Type: Allow
  * Applies to: Descendant User Objects
  * Properties: Read all properties

**COMPANY.COM\Company\Computers\Disabled-Computers**
* ACL 1
  * Principal: AD-Company-Computers-DisabledComputers--CreateComputerObjects
  * Type: Allow
  * Applies to: This object and all descendandt objects
  * Permissions: Create Computer objects
* ACL 2
  * Principal: AD-Company-Computers-DisabledComputers--CreateComputerObjects
  * Type: Allow
  * Applies to: This object and all descendandt objects
  * Permissions: List contents, Read all properties, write all properties, read permissions

**COMPANY.COM\Company\Groups\SecurityGroups\ShadowGroups-Computers**
* ACL 1
  * Principal: AD-Company-Groups-ShadowGroupsComputers--Modify
  * Type: Allow
  * Applies to: This object and all descendandt objects
  * Permissions: Create Group objects, Delete Group objects
* ACL 2
  * Principal: AD-Company-Groups-ShadowGroupsComputers--Modify
  * Type: Allow
  * Applies to: Descendant Group objects
  * Permissions: Full control

**COMPANY.COM\Company\Groups\SecurityGroups\ShadowGroups-Servers**
* ACL 1
  * Principal: AD-Company-Groups-ShadowGroupsServers--Modify
  * Type: Allow
  * Applies to: This object and all descendandt objects
  * Permissions: Create Group objects, Delete Group objects
* ACL 2
  * Principal: AD-Company-Groups-ShadowGroupsServers--Modify
  * Type: Allow
  * Applies to: Descendant Group objects
  * Permissions: Full control

**COMPANY.COM\Company\Groups\SecurityGroups\ShadowGroups-Users**
* ACL 1
  * Principal: AD-Company-Groups-ShadowGroupsUsers--Modify
  * Type: Allow
  * Applies to: This object and all descendandt objects
  * Permissions: Create Group objects, Delete Group objects
* ACL 2
  * Principal: AD-Company-Groups-ShadowGroupsUsers--Modify
  * Type: Allow
  * Applies to: Descendant Group objects
  *  Permissions: Full control   

**COMPANY.COM\CompanyUsers\Disabled-Users**
* ACL 1
  * Principal: AD-Company-Users-DisabledUsers--CreateUserObjects
  * Type: Allow
  * Applies to: This object only
  * Permissions: Create User objects
* ACL 2
  * Principal: AD-Company-Users-DisabledUsers--CreateUserObjects
  * Type: Allow
  * Applies to: This object and all descendant objects
  * Permissions: Full control
## Users
Each Domain Admin will have the following accounts:

* **Tier 0 account**: Member of domain admins, but also only a local user on the Tier 0 PAW.  Does not have admin rights on PAW itself.
* **Tier 0 - Maintenance account**:  This account is an administrator on all Tier 0 PAWs.  It is also the account I like to use to elevate my standard user to perform admin tasks on my PAW since my Tier 0 account does not have local admin access.
* **Tier 1 account**: Used to allow the user to RDP to Tier 1 member servers.
* **Tier 2 account (optional)**: If the user will ever log on to employee workstations, they will need this account.
* **Normal domain user account**: used for logging into the PAW VM to do day-to-day tasks.
* **Local user account**: Used as a contingency for any lost domain trusts.  In other words, if you fubar the domain and you can no longer log in to your PAW, this is the account you would use.
* **Local administrator account**: This account will be managed by LAPS.  Also used for fixing domain trust issues.  You would login with the local user account and elevate to this account to do admin stuff.

Each server administrator will have:

* **Tier 1 account**: They will log into their PAW with this account and RDP (with Remote Admin mode) to Tier 1 servers.
* **Tier 1 - Maintenance account**: This account is an administrator on all Tier 1 PAWs.  It is also the account I like to use to elevate my standard Tier 1 user to perform admin tasks on my PAW since my Tier 0 account does not have local admin access.
* **Normal domain user account**: used for logging into the PAW VM to do day-to-day tasks.
* **Access to server LAPS accounts**.  They can use this if RDP with RA is too restrictive.

Each Helpdesk user will have:

* **Tier 2 account**: They will log into their PAW with this account and RDP (with Remote Admin mode to Tier 2 workstations.
* **Normal domain user account**: used for logging into the PAW VM to do day-to-day tasks.
* **Access to all workstation LAPS accounts**.  They can use this if RDP with RA is too restrictive.  

## Groups
The following groups must be created in Company > Groups > SecurityGroups > RBAC-PAW.  The sub-bullet point are the members of the specified group.

* **PAW-AllPAWComputers** - Members of this group include all PAW Tier groups.  It is a collection of all PAW machines.
* PAW-Tier0Computers
* PAW-Tier1Computers
* PAW-Tier2Computers
* **PAW-BlockPowershell** - Members of this group are blocked from using PowerShell via GPO.
* PAW-Users
* **PAW-AzureAdmins** - Members of this group are permitted to connect to pre-identified cloud services via Privileged Access Workstations
* not sure yet.
* **PAW-Tier0Admins** - Members of this group are Tier 0 admins.  They can administrate Tier 0 PAWs.
* All Tier 0 Maintenance user accounts
* **PAW-Tier0Computers** - Members of this group are Tier 0 Computers.  Used mainly for GPO filtering.
* All Tier 0 PAWs
* **PAW-Tier0Users** - Members of this group are tier 0 users.  They can log into Tier 0 PAWs and servers.
* All Tier 0 user accounts (Domain Controller and AD admins)
* **PAW-Tier1Admins** - Members of this group are Tier 1 Admins.  They can administrate Tier 1 PAWs.
* All Tier 1 Maintenance user accounts
* **PAW-Tier1Computers** - Members of this group are Tier 1 Computers.  Used mainly for GPO filtering.
* All Tier 1 PAWs  
* **PAW-Tier1Users** - Members of this group are Tier 1 users.  They can log into Tier 1 PAWs and member servers.
* All Tier 1 user accounts (Domain Controller and AD admins)
* **PAW-Tier2Admins** - Members of this group are Tier 2 Administrators.  They can administrate Tier 2 PAWs.
* All Tier 2 Maintenance user accounts
* **PAW-Tier2Computers** - Members of this group are Tier 0 Computers.  Used mainly for GPO filtering.
* All Tier 2 PAWs
* **PAW-Tier2Users** - Members of this group are Tier 2 Users.  They can log into Tier 2 PAWs.
* All Tier 2 user accounts (Domain Controller and AD admins)
* **PAW-Users** - Members of this groups include all the Tier 0, 1, and 2 Users
* PAW-Tier0Users
* PAW-Tier1Users
* PAW-Tier2Users

## Additional Resources
For more information on what accounts count as Tier 0, see [Microsoft's recommendations here](https://docs.microsoft.com/en-us/windows-server/identity/securing-privileged-access/securing-privileged-access-reference-material#T0E_BM).
