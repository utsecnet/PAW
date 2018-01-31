## What is this?
Most of your UAC settings will be inherited from your baseline GPOS (e.g., STIG or CIS).  There is one thing we need to make an over-ride for, however.  By default, the following UAC setting is applied:

***Computer Configuration > Policies > Windows Settings > Local Policies > Security Options***
* User Account Control: Behavior of the elevation prompt for standard users: **Automatically deny elevation requests**

We will want to be able to elevate as admin on our PAWs.  Therefore, we need an override policy.

## Override Policy

Create a new GPO on the DOMAIN.COM\Company\Users\PAW Accounts OU called **Security - UAC - PAW** with the following settings:

***Computer Configuration > Policies > Windows Settings > Local Policies > Security Options***
* User Account Control: Behavior of the elevation prompt for standard users: **Prompt for credentials on the secure desktop**

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **PAW-AllPAWComputers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.