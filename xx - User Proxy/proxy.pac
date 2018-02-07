function FindProxyForURL(url, host) {

// Company owned domains
if (shExpMatch(host, "*.domain1.com") ||
	shExpMatch(host == "domain1.com") ||
	shExpMatch(host, "*.domain2.com") ||
	shExpMatch(host == "domain2.com") ||
	shExpMatch(host, "*.domain3.com") ||
	shExpMatch(host == "domain3.com") ||
	shExpMatch(host, "*.domain4.com") ||
	shExpMatch(host == "domain5.com"))
	{ return "DIRECT"; }

// Do not proxy non-routable addresses (RFC 3300)
if (isInNet(hostIP, '0.0.0.0', '255.0.0.0') ||
	isInNet(hostIP, '10.0.0.0', '255.0.0.0') ||
	isInNet(hostIP, '127.0.0.0', '255.0.0.0') ||
	isInNet(hostIP, '169.254.0.0', '255.255.0.0') ||
	isInNet(hostIP, '172.16.0.0', '255.240.0.0') ||
	isInNet(hostIP, '192.0.2.0', '255.255.255.0') ||
	isInNet(hostIP, '192.88.99.0', '255.255.255.0') ||
	isInNet(hostIP, '192.168.0.0', '255.255.0.0') ||
	isInNet(hostIP, '198.18.0.0', '255.254.0.0') ||
	isInNet(hostIP, '224.0.0.0', '240.0.0.0') ||
	isInNet(hostIP, '240.0.0.0', '240.0.0.0'))
	{ return 'DIRECT'; }
 
// Microsoft Domains
if (shExpMatch(host, "*.aspnetcdn.com") ||
	shExpMatch(host, "*.aadrm.com") ||
	shExpMatch(host, "*.appex.bing.com") ||
	shExpMatch(host, "*.appex-rf.msn.com") ||
	shExpMatch(host, "*.assets-yammer.com") ||
	shExpMatch(host, "*.azure.com") ||
	shExpMatch(host, "*.azurecomcdn.net") ||
	shExpMatch(host, "*.cloudappsecurity.com") ||
	shExpMatch(host, "*.c.bing.com") ||
	shExpMatch(host, "*.gfx.ms") ||
	shExpMatch(host, "*.live.com") ||
	shExpMatch(host, "*.live.net") ||
	shExpMatch(host, "*.lync.com") ||
	shExpMatch(host, "maodatafeedsservice.cloudapp.net") ||
	shExpMatch(host, "*.microsoft.com") ||
	shExpMatch(host, "*.microsoftonline.com") ||
	shExpMatch(host, "*.microsoftonline-p.com") ||
	shExpMatch(host, "*.microsoftonline-p.net") ||
	shExpMatch(host, "*.microsoftonlineimages.com") ||
	shExpMatch(host, "*.microsoftonlinesupport.net") ||
	shExpMatch(host, "ms.tific.com") ||
	shExpMatch(host, "*.msecnd.net") ||
	shExpMatch(host, "*.msedge.net") ||
	shExpMatch(host, "*.msft.net") ||
	shExpMatch(host, "*.msocdn.com") ||
	shExpMatch(host, "*.onenote.com") ||
	shExpMatch(host, "*.outlook.com") ||
	shExpMatch(host, "*.office365.com") ||
	shExpMatch(host, "*.office.com") ||
	shExpMatch(host, "*.office.net") ||
	shExpMatch(host, "*.onmicrosoft.com") ||
	shExpMatch(host, "partnerservices.getmicrosoftkey.com") ||
	shExpMatch(host, "*.passport.net") ||
	shExpMatch(host, "*.phonefactor.net") ||
	shExpMatch(host, "products.office.com")) ||
	shExpMatch(host, "*.s-microsoft.com") ||
	shExpMatch(host, "*.s-msn.com") ||
	shExpMatch(host, "*.sharepoint.com") ||
	shExpMatch(host, "*.sharepointonline.com") ||
	shExpMatch(host, "*.s-msn.com") ||
	shExpMatch(host, "*.symcb.com") ||
	shExpMatch(host, "*.yammer.com") ||
	shExpMatch(host, "*.yammerusercontent.com") ||
	shExpMatch(host, "*.verisign.com") ||
	shExpMatch(host, "*.windows.com") ||
	shExpMatch(host, "*.windows.net") ||
	shExpMatch(host, "*.windowsazure.com") ||
	shExpMatch(host, "*.windowsupdate.com")	
	{ return "DIRECT"; }

// Skype for Buisiness 
if (shExpMatch(host, "*.lync.com") ||
	shExpMatch(host, "*.cqd.lync.com") ||
	shExpMatch(host, "*.infra.lync.com") ||
	shExpMatch(host, "*.online.lync.com") ||
	shExpMatch(host, "*.resources.lync.com") ||
	shExpMatch(host, "*.config.skype.com") ||
	shExpMatch(host, "*.skypeforbusiness.com") ||
	shExpMatch(host, "*.pipe.aria.microsoft.com") ||
	shExpMatch(host, "config.edge.skype.com") ||
	shExpMatch(host, "pipe.skype.com") ||
	shExpMatch(host, "s-0001.s-msedge.net") ||
	shExpMatch(host, "s-0004.s-msedge.net") ||
	shExpMatch(host, "*.azureedge.net") ||
	shExpMatch(host, "*.sfbassets.com") ||
	shExpMatch(host, "*.urlp.sfbassets.com") ||
	shExpMatch(host, "skypemaprdsitus.trafficmanager.ne") ||
	shExpMatch(host, "quicktips.skypeforbusiness.com") ||
	shExpMatch(host, "swx.cdn.skype.com") ||
	shExpMatch(host, "*.api.skype.com") ||
	shExpMatch(host, "*.users.storage.live.com") ||
	shExpMatch(host, "skypegraph.skype.com") ||
	shExpMatch(host, "*.broadcast.skype.com") ||
	shExpMatch(host, "broadcast.skype.com") ||
	shExpMatch(host, "browser.pipe.aria.microsoft.com") ||
	shExpMatch(host, "aka.ms") ||
	shExpMatch(host, "amp.azure.net") ||
	shExpMatch(host, "*.keydelivery.mediaservices.windows.net") ||
	shExpMatch(host, "*.msecnd.net") ||
	shExpMatch(host, "*.streaming.mediaservices.windows.net") ||
	shExpMatch(host, "ajax.aspnetcdn.com") ||
	shExpMatch(host, "mlccdn.blob.core.windows.net")) 
	{ return "DIRECT"; }

// Certificate CRL for exchange
if (shExpMatch(host, "*.godaddy.com")) { return "DIRECT"; }

// DEFAULT RULE: All other traffic, use below proxy
return "PROXY 127.0.0.2:8080";
}