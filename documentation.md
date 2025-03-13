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
iBridgeBootUUID  
iBridgeFWVersion  
iBridgeModelName  
iBridgeExtraBootPolicies  
iBridgeBootArgsFiltering  
iBridgeKernelCTRR  
iBridgeDEPMDM  
iBridgeUserApprMDM  
iBridgeAllAllKexts  
iBridgeSIPStatus  
iBridgeSSVStatus  
iBridgeSecureBootLvl  
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