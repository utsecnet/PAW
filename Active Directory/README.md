## Active Directory

If you want to use Shadow Groups to aide in managing your devices, you will need to keep your PAW devices seperate from your day-to-day devices.  This is how I have AD setup:

```
DOMAIN.COM
└── Company
    ├── Computers
    │   └── Location A
    │       ├── PAW
    │       ├── Servers
    │       ├── Workstations
    │       └── VMs
    ├── Groups
    │   └── Security Groups
    │       └── PAW
    └── Users
        └── PAW Accounts
            ├── Tier 0
            ├── Tier 1
            └── Tier 2

## Users

Each Domain Admin will have the following accounts:
   ◇ 0 account: Member of domain admins, but also only a local user on the Tier 0 PAW.  does not have admin rights on PAW itself.
   ◇ Tier 0 - Maintenance account:  allows the admin to elevate to perform administrative tasks on the PAW, since the Tier 0 account will be a standard user on the Tier 0 PAW.
   ◇ Tier 1 account: Used to allow the user to RDP to Tier 1 member servers.
   ◇ Tier 2 account (optional): If the user will ever log on to employee workstations, they will need this account.
   ◇ Normal domain user account: used for logging into the PAW VM to do day-to-day tasks.

Each server administrator will have:
   ◇ Tier 1 accont: They will log into thier PAW with this account and RDP (with Remote Admin mode) to Tier 1 servers.
   ◇ Normal domain user account: used for logging into the PAW VM to do day-to-day tasks.
   ◇ Access to server LAPS account.  They can use this if RDP with RA is too restrictive.

Each Helpdesk user will have:
   ◇ Tier 2 account: They will log into their PAW with this account and RDP (with Remote Admin mode to Tier 2 workstations.
   ◇ Normal domain user account: used for logging into the PAW VM to do day-to-day tasks.
   ◇ Access to workstation LAPS account.  They can use this if RDP with RA is too restrictive.  

## Groups

The following groups must be created in Company > Groups > SecurityGroups > RBAC-PAW.  The sub-bullet point are the members of the specified group.

   ◇ PAW-AllPAWComputers - Members of this group include all PAW Tier groups.  It is a collection of all PAW machines.
      ▪ PAW-Tier0Computers
      ▪ PAW-Tier1Computers
      ▪ PAW-Tier2Computers
   ◇ PAW-BlockPowershell - Members of this group are blocked from using Powershell via GPO.
      ▪ PAW-Users
   ◇ PAW-AzureAdmins - Members of this group are permitted to connect to pre-identified cloud services via Privileged Access Workstations
      ▪ not sure yet.
   ◇ PAW-Tier0Admins - Members of this group are Tier 0 admins.  They can administrate Tier 0 PAWs.
      ▪ All Tier 0 Maintenance user accounts
   ◇ PAW-Tier0Computers - Members of this group are Tier 0 Computers.  Used mainly for GPO filtering.
      ▪ All Tier 0 PAWs
   ◇ PAW-Tier0Users - Members of this group are tier 0 users.  They can log into Tier 0 PAWs and servers.
      ▪ All Tier 0 user accounts (Domain Controller and AD admins)
   ◇PAW-Tier1Admins - Members of this group are Tier 1 Admins.  They can administrate Tier 1 PAWs.
      ▪ All Tier 1 Maintenance user accounts
   ◇ PAW-Tier1Computers - Members of this group are Tier 1 Computers.  Used mainly for GPO filtering.
      ▪ All Tier 1 PAWs
   ◇ PAW-Tier1Users - Members of this group are Tier 1 users.  They can log into Tier 1 PAWs and member servers.
      ▪ All Tier 1 user accounts (Domain Controller and AD admins)
   ◇ PAW-Tier2Admins - Members of this group are Tier 2 Administrators.  They can administrate Tier 2 PAWs.
      ▪ All Tier 2 Maintenance user accounts
   ◇ PAW-Tier2Computers - Members of this group are Tier 0 Computers.  Used mainly for GPO filtering.
      ▪ All Tier 2 PAWs
   ◇ PAW-Tier2Users - Members of this group are Tier 2 Users.  They can log into Tier 2 PAWs.
      ▪ All Tier 2 user accounts (Domain Controller and AD admins)
   ◇ PAW-Users - Members of this groups include all the Tier 0, 1, and 2 Users
      ▪ PAW-Tier0Users
      ▪ PAW-Tier1Users
      ▪ PAW-Tier2Users
