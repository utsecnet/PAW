## Active Directory

If you want to use Shadow Groups to aide in managing your devices, you will need to keep your PAW devices separate from your day-to-day devices.  What are Shadow Groups?  It is a group that is automatically created and whose membership is automated based on OU membership.  In other words, a scheduled task runs on a regular interval and creates groups based on your Active Directory OU hierarchy.  It then takes the members of the OU and adds them as memebers of the group.  Lastly, it removes group members that may have moved to a different OU, keeping your group membership accurate.

This is how I have AD setup:

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
    │       ├── Workstations - - - - Put all workstation objects here, in you own hierarchy
    │       └── VMs          - - - - All VMs, including your PAWs day-to-day VM
    ├── Groups
    │   └── Security Groups
    │       ├── PAW          - - - - All groups related to PAW management
    │       ├── Shadowgroups-Computers - - - Computer object's shadowgroups
    │       ├── Shadowgroups-Servers - - - - Server object's shadowgroups
    │       └── Shadowgroups-Users - - - - - User's object's shadowgroups
    └── Users
        ├── Employees        - - - - Will hold all Employee accounts.  Feel free to organize your own heirarchy.  For this example, we use <Locale>\<Department>
        │   ├── Tier 0       - - - - Will hold Tier 1 user accounts (for domain admins)
        │   └── Tier 1       - - - - Will hold Tier 1 user accounts (for server admins)
        ├── Disabled-Users   - - - - Will hold all disabled user accounts
        ├── ServiceAccounts  - - - - Will hold all service accounts, and special use accounts (like accounts that run scheduled tasks)
        └── PAW Accounts
            ├── Tier 0       - - - - Will hold Tier 1 user accounts (for domain admins)
            ├── Tier 1       - - - - Will hold Tier 1 user accounts (for server admins)
            └── Tier 2       - - - - Will hold Tier 1 user accounts (for server admins)
```

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
