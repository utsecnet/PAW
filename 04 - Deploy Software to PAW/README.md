## What is this?
PAWs often requires software that the standard workstation does not.  Among these are remote administrative software and diagnostics software.  Unless you have a software deployment tool like PDQ Deploy or SCCM, Group Policy will be our main go to for deployment.  From a single GPO using Group Policy Preferences (GPP), we can schedule the installation and configuration of many software made easy by Item Level Targeting.  However, for this guide, and in the real world, I recommend splitting the software deployment to the different groups of computers.  This table indicates the GPOs and on which Groups they filter:

Device | Groups
----|----
Servers | All-Servers, Domain Controllers
PAWs | PAW-AllPAWComputers
workstations | All-Workstations
