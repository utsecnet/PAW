## What is this?
To maintain the Clean Source Principal, you must deny PAW users full internet access, and ensure that whereever they are, they only have limited access to the domains they need in order to do thier job from the PAW machine.  We can do that by enforcing all domains not specified in a whitelist to point to a proxy server that doesnt exist on the PAW.

Note: This process does not affect the VM on which the PAW resides.  It will still have full access to the internet.

## Procy.pac
Download the proxy.pac file above and make any changes or additions that will suite your needs.  Store it on a webserver that is accessible to the whole internet.  Your PAWs will need to be able to access this if they leave the office.

I recommend hosting the file on a local file server, then syncing it up to your web server.

# Configure Proxy settings

Create a new GPO on the DOMAIN.COM\Company\Users\PAW Accounts OU called **Security -Proxy - PAW Users** with the following settings:

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

	It should look like this:
	```
	This collection is true
		the user is not a member of the security group DOMAIN\PAW-AzureAdmins
		AND the ser is a member of the security group DOMAIN\PAW-Users
	```

***User Configuration > Preferences > Control Panel Settings > Internet Settings > New > Internet Explorer 10***
Right click > New > Internet Explorer 10 > Connection Tab > LAN Settings
* Automaticallly detect settings: Checked
* Address: http://<your url>/proxy.pac
* Use a proxy server for your LAN: checked
* Address: 127.0.0.1
* Port: 80

Click *Advanced...*
* HTTP: 127.0.0.1 : 80
* Exceptions
* Use the same proxy for all protocols: Checked

You need to put all the same URLs from your proxy.pac into this box, seperated by a ***;***

```
*.aspnetcdn.com;*.aadrm.com;*.appex.bing.com;*.appex-rf.msn.com;*.assets-yammer.com;*.azure.com;*.azurecomcdn.net;*.cloudappsecurity.com;*.c.bing.com;*.gfx.ms;*.live.com;*.live.net;*.lync.com;maodatafeedsservice.cloudapp.net;*.microsoft.com;*.microsoftonline.com;*.microsoftonline-p.com;*.microsoftonline-p.net;*.microsoftonlineimages.com;*.microsoftonlinesupport.net;ms.tific.com;*.msecnd.net;*.msedge.net;*.msft.net;*.msocdn.com;*.onenote.com;*.outlook.com;*.office365.com;*.office.com;*.office.net;*.onmicrosoft.com;partnerservices.getmicrosoftkey.com;*.passport.net;*.phonefactor.net;*.s-microsoft.com;*.s-msn.com;*.sharepoint.com;*.sharepointonline.com;*.s-msn.com;spoprod-a.akamaihd.net;*.symcb.com;*.yammer.com;*.yammerusercontent.com;*.verisign.com;*.windows.com;*.windows.net;*.windowsazure.com;*.windowsupdate.com;*.upwell.com;*.alliancehealth.com;*.ingrammed.com;ingrammedical.com;*.lync.com;*.cqd.lync.com;*.infra.lync.com;*.online.lync.com;*.resources.lync.com;*.config.skype.com;*.skypeforbusiness.com;*.pipe.aria.microsoft.com;config.edge.skype.com;pipe.skype.com;s-0001.s-msedge.net;s-0004.s-msedge.net;*.azureedge.net;*.sfbassets.com;*.urlp.sfbassets.com;skypemaprdsitus.trafficmanager.net;quicktips.skypeforbusiness.com;swx.cdn.skype.com;*.api.skype.com;*.users.storage.live.com;skypegraph.skype.com;*.broadcast.skype.com;broadcast.skype.com;browser.pipe.aria.microsoft.com;aka.ms;amp.azure.net;*.keydelivery.mediaservices.windows.net;*.msecnd.net;*.streaming.mediaservices.windows.net;ajax.aspnetcdn.com;mlccdn.blob.core.windows.net;crl.godaddy.com
```

Click OK

Back on the *LAN Settings* screen, cLick *F5* to underline each field green.  See [this site](https://blogs.technet.microsoft.com/grouppolicy/2008/10/13/red-green-gp-preferences-doesnt-work-even-though-the-policy-applied-and-after-gpupdate-force/) for details on what this means.

Click OK twice

Close the policy window.

On the scope tab:
* Ensure the Link to the PAW Accounts OU is Enabled.
* Ensure **Authenticated Users** shows up under *Security Filtering*.
* Ensure there is no WMI filter applied

On the Details tab:
* Set GPO status to: **Computer configuration settings disabled**