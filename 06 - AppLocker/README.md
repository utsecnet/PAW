## Special Thanks
First things first.  A ***HUGE*** thanks to [Sami Laiho](http://blog.win-fu.com/), Chief Sr. Principal Technical Fellow.  Without his help this section would not exist since I would not have wanted to go down the long dark path of configuring these policies myself.  

## What is this?
AppLocker is a Microsoft product, built into Windows, that allows administrators to whitelist or blacklist applications.  In the world of PAWs we want the most security, and so opt for a whitelist.

## AppLocker Warning
Applocker is not a perfect product, and can be bypassed.  GitHub user [pi0cradle](https://github.com/api0cradle/UltimateAppLockerByPassList/commits?author=api0cradle) has compiled his [Ultimate AppLocker ByPass List](https://github.com/api0cradle/UltimateAppLockerByPassList).  You should be aware.

## Best Practices

### Configure policies on the container, not the item
If you find yourself configuring policies for individual bypasses (single executable files or scripts), you are probably making AppLocker administration more difficult than it needs to be. Instead, focus more on the publisher and in very rare cases (with additional security controls) a path.  Going by hash focuses on the individual item and requires you to update the hash with each product update.

### Confirm directory whitelisting with accesschk
When you create the default rule set, AppLocker creates a set of policies that whitelist the *Program Files* and *Windows* directories.  When you whitelist a directory it is important that the user not be able to modify the contents of that directory, else they could run any program they want.  I bet you thought the Windows directory was *read only* to standard users, eh?  Download systenternals and run the following command:

```batch
C:\Tools> accesschk -w users c:\windows
```
 Default results look like this:

```batch
RW C:\windows\Tasks
RW C:\windows\Temp
RW C:\windows\tracing
```

This means users have WRITE (RW) access to these three directories under C:\Windows.  If you import my policy.xml, you will see these directories (and others) have been added to the exception tab of the *Allow everyone all files located in the Windows folder*. If you don't import my policy, ensure you add these exceptions.

I would recommend using the *accesschk* tool any time you whitelist a directory to ensure users do not have Write access.

## Configure AppLocker whitelist

Create a new GPO on the DOMAIN.COM\Company\Computers OU called **Security - AppLocker - PAW** with the following settings:

***Computer Configuration > Policies > Administrative Templates > System > Logon***
* Turn on convenience PIN sign-in: **Enabled**