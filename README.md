This is a powershell module for PS on macOS that, as much as possible, replicates "Get-ComputerInfo". That's a really handy thing to have, and it not being available on the Mac is annoying as heck. So this is my attempt. It's both a module and a script that grabs info out of a few things and shoves them all into a hashtable. Running it gets you everything, but the idea will be that like Get-Computerinfo, once this is a module, you can import it, and then within powershell, get one or more hardware properties for your mac.

There are things that are in Get-Computerinfo that are not here, some because they don't make sense on a mac, some because I didn't see the initial value in adding them.

This is pretty thoroughly commented, so if you read those, you should have a good idea of what is going on.

20221001 Added support for differences between Apple Silicon and Intel

This is pulling data from uname, sw_ver, system_profiler, osascript, sysctl, and a number of built-in powershell functions. Currently, the keys it has are:

macOSBuildLabEx  
macOSCurrentVersion  
macOSCurrentBuildNumber  
macOSProductName  
macOSDarwinVersion  
SystemFirmwareVersion  
T2FirmwareVersion (currently Intel only as a separate thing in system profiler SPHardwareDataType)  
OSLoaderVersion  
HardwareSerialNumber  
HardwareUUID  
ProvisioningUDID  
HardwareModelName  
HardwareModelID  
HardwareModelNumber (Apple Silicon Only)  
ActivationLockStatus  
CPUArchitecture  
CPUName  
CPUSpeed (Intel Only)  
CPUCount (Intel Only)  
CPUCoreCount (Intel Only)  
CPUTotalCoreCount (Apple Silicon Only)  
CPUPerformanceCoreCount (Apple Silicon Only)  
CPUEfficiencyCoreCount (Apple Silicon Only)  
CPUL2CacheSize (Intel Only)  
CPUBrandString  
L3CacheSize (Intel Only)  
HyperThreadingEnabled (Intel Only)  
RAMAmount  
ApplePayPlatformID  
ApplePaySEID  
ApplePaySystemOSSEID (Apple Silicon Only)  
ApplePayHardware  
ApplePayFirmware  
ApplePayJCOPOSVersion  
ApplePayControllerHardwareVersion  
ApplePayControllerFirmwareVersion  
ApplePayControllerMiddlewareVersion  
BluetoothMAC  
BluetoothChipset  
BluetoothDiscoverable  
BluetoothFirmwareVersion  
BluetoothProductID (Apple Silicon Only)  
BluetoothSupportedServices  
BluetoothTransport  
BluetoothVendorID  
ACCurrentPowerSource  
ACSystemSleepTimer  
ACDiskSleepTImer  
ACDisplaySleepTimer  
ACHibernateMode  
ACLowPowerMode  
ACNetworkOverSleep  
ACWakeOnLan  
ACHighPowerMode (Apple Silicon Only)  
ACSleepOnPowerButton (Apple Silicon Only)  
ACDisplaySleepUsesDim (Intel Only)  
ACWakeOnACChange (Intel Only)  
ACWakeOnClamshellOpen (Intel Only)  
ACChargerConnected  
ACChargerCharging  
ACChargerName  
ACChargerSerialNumber  
ACChargerWatts  
ACChargerManf  
ACChargerID  
ACChargerHWVers  
ACChargerFirmwareVers  
ACChargerFamily  
batteryCurrentPowerSource  
batterySystemSleepTimer  
batteryDiskSleepTimer  
batteryDisplaySleepTimer  
batteryReduceBrightness  
batteryHibernateMode  
batteryLowPowerMode  
batteryNetworkOverSleep  
batteryWakeOnLan  
batteryHighPowerMode (Apple Silicon Only)  
batterySleepOnPowerButton (Apple Silicon Only)  
batteryDisplaySleepUsesDim (Intel Only)  
batteryWakeOnACChange (Intel Only)  
batteryWakeOnClamshellOpen (Intel Only)  
batteryWarningLevel  
batteryFullyCharged  
batteryIsCharging  
batteryChargeLevel  
batteryMaxChargeCapacity (Intel Only)  
batteryCycleCount  
batteryHealth  
batteryHealthMaxCapacity (Apple Silicon Only)  
batterySerialNumber  
batteryDeviceName  
batteryFirmwareVersion  
batteryHardwareRevision  
batteryCellRevision  
batteryManufacturer (Intel Only)  
UPSCurrentPowerSource  
UPSSystemSleepTimer  
UPSAutoRestartOnPowerLoss  
UPSDiskSleepTimer  
UPSDisplaySleepTimer  
UPSNetworkOverSleep  
UPSWakeOnLan  
UPSSleepOnPowerButton (Apple Silicon Only)  
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

obviously, this list is expandable.

20 May 2020 update added - Comment-based help (it's a bit odd, but it gives you an idea of what's going on) The ability to get one, some, or all the key/value pairs as a result Set up the hashtable as an ordered hashtable, so the output order for the full result makes a bit more sense in terms of grouping

20 May 2020 update
added - 
  Comment-based help (it's a bit odd, but it gives you an idea of what's going on)
  The ability to get one, some, or all the key/value pairs as a result
  Set up the hashtable as an ordered hashtable, so the output order for the full result makes a bit more sense in terms of grouping
  
27 May 2020 update
IT'S ALIVE! IT WORKS AS A MODULE! 

7 Mar 2022 update
Edits to account for changes to system profiler output. Added Hyperthreading status, provisioningudid, activation lock status, renamed EFI to SystemFirmwareVersion and SMC to OSLoaderVersion

1 Oct 2022 update
Added first attempt at Apple Silicon

20 July 2023 update
Added SIP status

13 July Update
	added many things, apple pay, bluetooth, post test, formatted the output a bit better, it now works correctly for Apple Silicon...so many updates. There's also now a CHANGELOG file.  
  
2 Feb. 2025 update  
	MASSIVE update. Read the CHANGELOG for details  
