##Get-MacInfo Docs

The Get-MacInfo is a module that attempts to replicate the functionality of the Windows Get-ComputerInfo command. 

Obviously, this is a macOS-only module, it does test for that when run.

The keys it returns are:

macOSBuildLabEx  
macOSCurrentVersion  
macOSCurrentBuildNumber  
macOSProductName  
macOSDarwinVersion  
SystemFirmwareVersion  
T2FirmwareVersion  
OSLoaderVersion  
HardwareSerialNumber  
HardwareUUID  
ProvisioningUDID  
HardwareModelName  
HardwareModelID  
ActivationLockStatus  
CPUArchitecture  
CPUName  
CPUSpeed (Intel Only)  
CPUCount (Intel Only)  
CPUCoreCount  
CPUL2CacheSize (Intel Only)  
CPUBrandString  
L3CacheSize (Intel Only)  
HyperThreadingEnabled (Intel Only)  
RAMAmount  
AppMemoryUsedGB  
VMPageFile  
VMSwapInUseGB  
BootDevice  
FileVaultStatus  
SIPStatus  
EFICurrentLanguage  
DSTStatus  
TimeZone  
UTCOffset  
DNSHostName  
LocalHostName  
NetworkServiceList  
CurrentUserName  
CurrentUserUID  
CurrentDateTime  
LastBootDateTime  
Uptime  
  
The basic usage is just "Get-MacInfo" by itself, which will return all the keys listed as a hashtable. If you only want one of the results, then: "Get-MacInfo Uptime" will return just the uptime. For multiple keys, separate by commas. 

Note that regardless of how you call the command, all the information is pulled. On the last Intel MacBook Pro, this takes maybe 2 seconds. It's somewhat faster on Apple Silicon. Each architecture returns the appropriate values. For example, if run on Apple Silicon, you won't see an entry for HyperThreadingEnabled, nor will you see CPUPerformanceCoreCount on Intel.

I'll work on adding more items as I can, sussing this stuff out in a usable fashion can be rather annoying.