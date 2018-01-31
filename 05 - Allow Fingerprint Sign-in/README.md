## What is this?
Moving to the PAW paradigm opens up a slew of changes regarding how you will administrate your network.  One of those changes is the number of credentials you have to keep track of.  A typical Tier 0 administrator could have up to 6 accounts:

* Local user - contingency for if you ever lose trust in your domain.  You can log on with this account and rejoin the domain.
* Local administrator user - contingency for if you ever lose trust in your domain.  You log in with the above account and elevate with this account to rejoin the domain.
* Tier 0 admin user
* Tier 1 admin user
* Tier 2 admin user
* standard user account

Fingerprints help alleviate some of the frustration with having to remember so many account passwords.

## Allowing biometrics for local users and domain users

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Allow Fingerprint Sign in** with the following settings:

***Computer Configuration > Policies > Administrative Templates > System > Logon***
* Turn on convenience PIN sign-in: **Enabled**

***Computer Configuration > Policies > Administrative Templates > Windows Components > Biometrics***
* Allow domain users to log on using biometrics: **Enabled**
* Allow the use of biometrics: **Enabled**
* Allow users to log on using biometrics: **Enabled**

***Computer Configuration > Policies > Administrative Templates > Windows Components > Biometrics > Facial Features***
* Configure enhanced anti-spoofing: **Enabled**

Close the policy window.

On the scope tab:
* Ensure the Link to the Computers OU is Enabled.  
* Remove **Authenticated Users** from the **Security Filtering** section and add **All-Workstations** and **PAW-AllPAWComputers**.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **User configuration settings disabled**

On the Delegation tab:
* Add **Authenticated Users** and give it READ permissions.