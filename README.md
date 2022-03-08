# Get-MacInfo
This is a powershell module for PS on macOS that, as much as possible, replicates "Get-ComputerInfo". That's a really handy thing to have, and it not being available on the Mac is annoying as heck. So this is my attempt. It's both a module and a script that grabs info out of a few things and shoves them all into a hashtable. Running it gets you everything, but the idea will be that like Get-Computerinfo, once this is a module, you can import it, and then within powershell, get one or more hardware properties for your mac.

There are things that are in Get-Computerinfo that are not here, some because they don't make sense on a mac, some because I didn't see the initial value in adding them.

This is pretty thoroughly commented, so if you read those, you should have a good idea of what is going on.

This is pulling data from uname, sw_ver, system_profiler, osascript, sysctl, and a number of built-in powershell functions. Currently, the keys it has are:

AppMemoryUsedGB

BootDevice

CPUArchitecture

CPUBrandString

CPUCoreCount

CPUCount

CPUL2CacheSize

CPUName

CPUSpeed

CurrentDateTime

CurrentUserName

CurrentUserUID

DNSHostName

DSTStatus

EFICurrentLanguage

EFIVersion

FileVaultStatus

HardwareModelID

HardwareModelName

HardwareSerialNumber

HardwareUUID

L3CacheSize

LastBootDateTime

LocalHostName

macOSBuildLabEx

macOSCurrentBuildNumber

macOSCurrentVersion

macOSDarwinVersion

macOSProductName

RAMAmount

SMCVersion

TimeZone

Uptime

UTCOffset

VMPageFile

VMSwapInUseGB

obviously, this list is expandable.


20 May 2020 update
added - 
  Comment-based help (it's a bit odd, but it gives you an idea of what's going on)
  The ability to get one, some, or all the key/value pairs as a result
  Set up the hashtable as an ordered hashtable, so the output order for the full result makes a bit more sense in terms of grouping
  
27 May 2020 update
IT'S ALIVE! IT WORKS AS A MODULE! 
