## What is this?
To maintain the Clean Source Principal, you must deny PAW users full internet access, and ensure that whereever they are, they only have limited access to the domains they need in order to do thier job from the PAW machine.  We can do that by enforcing all domains not specified in a whitelist to point to a proxy server that doesnt exist on the PAW.

Note: This process does not affect the VM on which the PAW resides.  It will still have full access to the internet.

## Procy.pac
Download the proxy.pac file above and make any changes or additions that will suite your needs.  Store it on a webserver that is accessible to the whole internet.  Your PAWs will need to be able to access this if they leave the office.

I recommend hosting the file on a local file server, then syncing it up to your web server.

# Configure Proxy settings

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - Allow Fingerprint Sign in** with the following settings:

***User Configuration > Policies > Administrative Templates > Windows Components > Internet Explorer***
* Disable changing Automatic Configuration settings: **Enabled**
* Prevent changing proxy settings: **Enabled**

***User Configuration > Preferences > Windows Settings > Registry***

### ProxyEnable
Right click > New
* Hive: HKEY_CURRENT_USER
* KeyPath: Software\Microsoft\Windows\CurrentVersion\Internet Settings
* Default: unchecked
* Value name: ProxyEnable
* Value type: REG_DWORD
* Value Data: 00000001
* Base: Hexadecimal

Common tab
* Remove this item when it is no longer applied: checked
* Item-level targeting
	* Click *Add Collection*
	* Click *New item > Security Group* 
	* Select the *DOMAIN\PAW-AzureAdmins* group
	* Highlight the group and click *Item Options > Is Not*
	* Click *New item > Security Group* 
	* Select the *DOMAIN\PAW-Users* group
	* Move both of these items under *this collection is true*
	* Click *OK* twice

	It should look like this:
	```
	This collection is true
		the user is not a member of the security group DOMAIN\PAW-AzureAdmins
		AND the ser is a member of the security group DOMAIN\PAW-Users
	```

### ProxyServer
Right click > New
* Hive: HKEY_CURRENT_USER
* KeyPath: Software\Microsoft\Windows\CurrentVersion\Internet Settings
* Default: unchecked
* Value name: ProxyServer
* Value type: REG_SZ
* Value Data: 127.0.0.1:80

Common tab
* Remove this item when it is no longer applied: checked
* Item-level targeting
	* Click *Add Collection*
	* Click *New item > Security Group* 
	* Select the *DOMAIN\PAW-AzureAdmins* group
	* Highlight the group and click *Item Options > Is Not*
	* Click *New item > Security Group* 
	* Select the *DOMAIN\PAW-Users* group
	* Move both of these items under *this collection is true*
	* Click *OK* twice