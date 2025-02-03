#!/usr/bin/env pwsh


## To do:
	#app-sso output
	#SPAudioDataType

function getSPJSONData {
	param (
		[Parameter(Mandatory = $true)][string] $SPDataType
	)

	#get raw json data from system_profiler for $SPDataType. This creates an array of strings
	$SPRawResults = Invoke-Expression -Command "/usr/sbin/system_profiler $SPDataType -detailLevel full -json"
	#convert array to one string
	$SPStringResults = $SPRawResults|Out-String
	#create JSON object from string
	$SPJSONResults = ConvertFrom-Json -InputObject $SPStringResults
	#return JSON object to calling command
	return $SPJSONResults
}

function getSPRawData {
	param (
		[Parameter(Mandatory = $true)][string] $SPDataType
	)

	$SPRawResults = Invoke-Expression -Command "/usr/sbin/system_profiler $SPDataType -detailLevel full"
	return $SPRawResults
}

function Get-MacInfo {
	<#
	.SYNOPSIS
	This is a powershell script for macOS that replicates, or tries to, the "Get-ComputerInfo" command for Windows Powershell

	.DESCRIPTION
	It's not a 1:1 replication, some of it wouldn't make any sense on a Mac. Also, it does check to make sure it's running
	on a mac. This pulls information from a variet of sources, including uname, sysctl, AppleScript, sw_ver, system_profiler,
	and some built-in powershell functions. It shoves it all into an ordered hashtable so there's some coherency in the output.
	If you run the script without any parameters, you get all the items in the hashtable. If you provide one key as a parameter,
	you get the information for that key. You can provide a comma-separated list of keys and you'll get that as a result.

	20221001 added code for Apple Silicon

	Note: the keys labled "Intel Only" don't exist for Apple Silicon.

	Current keys are:
	macOSBuildLabEx
	macOSCurrentVersion
	macOSCurrentBuildNumber
	macOSProductName
	macOSDarwinVersion
	SystemFirmwareVersion
	T2FirmwareVersion (Intel only)
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

	.EXAMPLE
	Get-MacInfo by itself gives you all the parameters it can output

	.EXAMPLE
	Get-MacInfo TimeZone gives you the current timezone for the computer

	.EXAMPLE
	Get-MacInfo TimeZone,FileVault status gives you the current timezone and the filevault status for the computer

	.NOTES
	This can be used as a Powershell module or as a standalone script.

	.LINK
	https://github.com/johncwelch/Get-MacInfo
	#>

	#input parameter line, has to be the first executable line in the script
	param ($keys)

	#check to make sure this is running on a mac, if not, print error message and exit
	if (-Not $IsMacOS)
		{
		     Write-Output "This Script only runs on macOS, exiting"
		     Exit-PSSession
		}

	#since the idea of this is to create a version of Get-Computerinfo for the Mac

	#create the main hashtable that will hold all the values. This will allow for easier retreival of data
	#in a more normal powershell way. Hashtables will work well since we're going to have no repeating keys and allows us to use "normal"
	#dot notation to retrieve values.

	$macInfoHash = [ordered]@{}

	#uname section============================

	#get CPU Architecture
	#we have to do this first so we can account for the CPU differences
	$macInfoCPUArch = Invoke-Expression -Command "/usr/bin/uname -m"
	if ($macInfoCPUArch -eq "x86_64") {
		$isAppleSilicon = $false
	} else {
		$isAppleSilicon = $true
	}

	#we're going to try to mirror the results of the windows version of Get-ComputerInfo as much as possible
	#first get the kernel version as maintDarwinVersion. This is initially a string
	$getMainDarwinVersion = Invoke-Expression -Command "/usr/bin/uname -v"

	#now we want to split the string up into an array so we can build just the elemnts we need
	#use space as the separator
	$darwinVersionSeparator = " "

	#set up our string.split options
	$darwinVersionSplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries

	#create our array of strings
	$mainDarwinVersionArray = $getMainDarwinVersion.Split($darwinVersionSeparator,$darwinVersionSplitOptions)

	#get the kernel version info
	$tempString = $mainDarwinVersionArray[3]
	#since that will end with a colon, strip the last character off the temp string
	$mainDarwinKernelVersion = $tempString.Substring(0,$tempString.Length-1)

	#sw_ver section===============================================================

	#now, let's get some basic higher-level info
	$macInfoOSVersion = Invoke-Expression -Command "/usr/bin/sw_vers -productVersion"
	$macInfoOSBuildNumber = Invoke-Expression -Command "/usr/bin/sw_vers -buildVersion"
	$macInfoOSName = Invoke-Expression -Command "/usr/bin/sw_vers -productName"

	#system_profiler section=========================================================

	##now, let's get our system_profiler hardware info

	#use getSPJSONData to get a JSON object for SPHardwareDataType
	$SPHardwareTypeData = getSPJSONData -SPDataType "SPHardwareDataType"
	#set up a var that deals with the first two layers of the return
	$SPHardwareTypeInfo = $SPHardwareTypeData[0].SPHardwareDataType[0]

	#Get the raw data so we can more easily get to the things not in JSON output
	$SPHardwareRaw = getSPRawData -SPDataType "SPHardwareDataType"

	##Apple Silicon Differences
	#Model Number
	#Chip Type: instead of cpu_type:
	#No Processor Speed:
	#No Number of Processors
	#Total Number of Cores: has more info
	#No L2 Cache:
	#No L3 Cache:
	#No HyperThreading Technology:

	##common SPHardwareType sections

	#Get the OS Loader Version
	$macInfoSMCVersion = $SPHardwareTypeInfo.os_loader_version

	#hardware serial number
	$macInfoHardwareSN = $SPHardwareTypeInfo.serial_number

	#hardware UUID
	$macInfoHardwareUUID = $SPHardwareTypeInfo.platform_UUID

	#provisioning UUID
	$macInfoProvisioningUDID = $SPHardwareTypeInfo.provisioning_UDID

	#activation Lock status
	$macInfoActivationLockStatus = $SPHardwareTypeInfo.activation_lock_status

	#model name
	$macInfoModelName = $SPHardwareTypeInfo.machine_name

	#model Identfier
	$macInfoModelID = $SPHardwareTypeInfo.machine_model

	#RAM size
	$macInfoRAMSize = $SPHardwareTypeInfo.physical_memory

	#Apple Silicon Section
	if($isAppleSilicon) {

		#getthe System Firmware Version
		#this is slightly different on Intel
		$macInfoEFIVersion = $SPHardwareTypeInfo.boot_rom_version

		#model number
		$macInfoModelNumber = $SPHardwareTypeInfo.model_number

		#CPU Model
		$macInfoCPUName = $SPHardwareTypeInfo.chip_type

		#get the core count. We're going to split ito perf and efficiency
		#This is a mess to get because it doesn't show in the JSON output, although to be fair
		#unless the JSON data split it up into total, performance, and efficiency in discrete values
		#the only difference would be we'd not have to run system_profiler again to get the grep'd results

		#get the total number of cores string from $SPHardwareDataRaw
		#this is basically greping the array of strings to find the one we want.
		#this allows us to only need one call to system_profiler for all the non-json data we'll need for SPHardwareDataType
		$macInfoCPUCoreCount = $SPHardwareRaw -match "Total Number of Cores"

		#split on the colon, grab the second element of the array Split(":") creates
		#(with all the good data) and trim leading/trailing whitespace with Trim()
		$macInfoCPUCoreCount = $macInfoCPUCoreCount.Split(":")[1].Trim()

		#list total cores
		$macInfoCPUCoreCountTotal = $macInfoCPUCoreCount.Split(" ")[0]

		#get Perf and efficiency cores

		#strip of total core count and leading parens
		$macInfoCPUCoreCountTemp = $macInfoCPUCoreCount.Split(" (")[1]

		#strip trailing parens from temp
		$macInfoCPUCoreCountTemp = $macInfoCPUCoreCountTemp.Substring(0,$macInfoCPUCoreCountTemp.Length-1)

		#get performance cores
		$macInfoCPUPerformanceCoreCount = $macInfoCPUCoreCountTemp.Split(" and ")[0]

		#get efficiency cores
		$macInfoCPUEfficiencyCoreCount = $macInfoCPUCoreCountTemp.Split(" and ")[1]

	} else {
		#we want to start grabbing items. first we grab the EFI version, aka Boot ROM version. We only want the last part, so
		#we split on the colon, grab the second part [1]
          #trim all the whitespace from [1]
		#this is actually now referred to as the System Firmware Version, so we'll rename that one day
		#get via match from $SPHardwareRaw
		$macInfoEFIRaw = $SPHardwareRaw -match "System Firmware Version"

		#split on the parens and grab the first entry [0] to get rid of the ibridge stuff
          #and get ride of any remaining whitespace
		$macInfoEFIVersion = $macInfoEFIRaw.Split("(")[0].Trim()

		#T2 Firmware Version
		#split on leading parens to get the ibridge version(T2) info
		$macInfoT2FirmwareVersion = $macInfoEFIRaw.Split("(")[1]
		#split on the colon to get just the numbers
		$macInfoT2FirmwareVersion = $macInfoT2FirmwareVersion.Split(":")[1].Trim()
          #get rid of the last ) character
		$macInfoT2FirmwareVersion = $macInfoT2FirmwareVersion.Substring(0,$macInfoT2FirmwareVersion.Length-1)

		#CPU Model
		$macInfoCPUName = $SPHardwareTypeInfo.cpu_type

		#CPU Speed
		$macInfoCPUSpeed = $SPHardwareTypeInfo.current_processor_speed

		#CPU Count
		$macInfoCPUCount = $SPHardwareTypeInfo.packages

		#core count
		$macInfoCPUCoreCount = $SPHardwareTypeInfo.number_processors

		#L2 Cache Size
		$macInfoCPUL2CacheSize = $SPHardwareTypeInfo.l2_cache_core

		#L3 Cache size
		$macInfoL3CacheSize = $SPHardwareTypeInfo.l3_cache

		#hyperthreading status
		#not in json, do with grep
		#get full results
		$macInfoHyperThreadingRaw =  $SPHardwareRaw -match "Hyper-Threading Technology"

		#split at the colon, grab the second element in the array that creates with Split(":")
		#and use Trim() to remove leading trailing whitespace
		$macInfoHyperThreadingEnabled = $macInfoHyperThreadingRaw.Split(":")[1].Trim()
	}

	#apple pay info===============================================================================

	#get JSON applepay data from system profiler
	$SPApplePayData = getSPJSONData -SPDataType "SPSecureElementDataType"
	#we don't need to care about raw here, there's no difference between ray and JSON output
	$SPApplePayInfo = $SPApplePayData[0].SPSecureElementDataType[0]


	#shove into an arraylist, remove all the blank lines
	#[System.Collections.ArrayList]$applePayInfoArrayList = $applePayInfoArrayRaw.Split([Environment]::NewLine,$darwinVersionSplitOptions)

	#remove the first two lines that only say "Apple Pay"
	#$applePayInfoArrayList.RemoveRange(0,2)

	#grab the platform ID line, item[0] split it on the :, grab the second element [1]
	#trim all leading/trailing whitespace from element[1]
	$applePayInfoPlatformID = $SPApplePayInfo.se_plt

	#get the SEID the same way
	$applePayInfoSEID = $SPApplePayInfo.se_id

	#Hardware
	$applePayInfoHardware = $SPApplePayInfo.se_hw

	#firmware
	$applePayInfoFirmware = $SPApplePayInfo.se_fw

	#JCOP OS version
	$applePayInfoJCOPOSVersion = $SPApplePayInfo.se_os_version

	##Apple Pay Controller Info
		#hardware version
		$applePayControllerHardwareVersion = $SPApplePayInfo.ctl_hw

		#firmware version
		$applePayControllerFirmwareVersion = $SPApplePayInfo.ctl_fw

		#middleWare version
		$applePayControllerMiddlewareVersion = $SPApplePayInfo.ctl_mw

	#get systemOS SEID, this is the only intel/apple silcon difference
	if($isAppleSilicon) {
		#apple Silicon Only
		#system OS SEID
		$applePayInfoSystemOSSEID = $SPApplePayInfo.se_os_id
	}

	#bluetooth info===============================================================================
	#get the applepay info from system profiler
	#Intel doesn't have the product ID

	$SPBlueToothData = getSPJSONData -SPDataType "SPBluetoothDataType"
	$SPBlueToothInfo = $SPBlueToothData[0].SPBluetoothDataType[0].controller_properties

	$blueToothMAC = $SPBlueToothInfo.controller_address

	#get the BT chipset
	$blueToothChipset = $SPBlueToothInfo.controller_chipset

	#get discoverable status
	#we have to do a bit of parsing here. The actual value is "atrrib_on" or "attrib_off"
	#so we split on the "_", then grab the second item in the array created, the actual thing we
	#care about and Trim() any whitespace that may be there
	$blueToothDiscoverable = $SPBlueToothInfo.controller_discoverable.Split("_")[1].Trim()

	#get firmware version
	$bluetoothFirmwareVersion = $SPBlueToothInfo.controller_firmwareVersion

	#supported services end up
	$bluetoothSupportedServicesRaw = $SPBlueToothInfo.controller_supportedServices

	#get transport
	$blueToothTransport = $SPBlueToothInfo.controller_transport

	#get vendor ID
	$blueToothVendorID = $SPBlueToothInfo.controller_vendorID

	#get state ala discoverable status
	$blueToothState = $SPBlueToothInfo.controller_state.Split("_")[1].Trim()

	#start split between Apple Silicon and Intel

	if($isAppleSilicon) {
		#product ID
		$blueToothProductID = $SPBlueToothInfo.controller_productID
	}

	##for supported services, we only need the inital block in the if statement, all the rest can live outside
	#build an arraylist to contain all the services
	[System.Collections.ArrayList]$bluetoothSupportedServices = @()

	#get the first item
	$bluetoothSupportedServices.Add($bluetoothSupportedServicesRaw.Split("<")[0].Trim())|Out-Null

	#now we get the other half of the string
	$blueToothTemp = $bluetoothSupportedServicesRaw.Split("<")[1].Trim()

	#trim the trailing >
	$blueToothTemp = $blueToothTemp.Substring(0,$blueToothTemp.Length-1)

	#yeet any leading/trailing whitespace
	$blueToothTemp = $blueToothTemp.Trim()

	#create a temp array for the other services
	$blueToothTempArray = $blueToothTemp.Split(" ")

	#add them onto the backend of the arraylist which we can then shove in the hashlist
	foreach($item in $blueToothTempArray){
		$bluetoothSupportedServices.Add($item)|Out-Null
	}

	#Removed the POST test section, it seems to have completely gone away
	#Removed redundancies in the hashtable.

	#SPPowerDataTypeNotes
	#do some checking for AC Charger info
	#Intel has
	##	manufacturer for battery model info
	##	full charge capacity for battery charge info (sppower_battery_max_capacity)
	##	AC Power
	##		Wake on AC Changes
	##		Wake on clamshell open
	##		Display sleep uses Dim
	##	Battery Power
	##		Wake on AC Changes
	##		Wake on clamshell open
	##		Display sleep uses Dim

	#AS has
	##	maximum capacity for battery health info
	##	AC Power
	##		sleep on power button
	##		High Power Mode
	##	Battery Power
	##		sleep on power button
	##		High Power Mode
	##		Reduce Brightness

	#get full output of SPPowerDataType as JSON
	#because of how this works, we'll have to do this as a loop testing section names, AND deal with intel/AS differences
	#oh yey
	$SPPowerTypeData = getSPJSONData -SPDataType "SPPowerDataType"

	#get number of items in the collection, may end up not needing
	#$SPPowerTypeDataCount = $SPPowerTypeData.SPPowerDataType.Count

	#Get list of section names
	$SPPowerTypeNames = $SPPowerTypeData[0].SPPowerDataType._name

	#set up flags to check for battery/UPS
	#every mac always has AC Power, but they don't all have batteries and/or UPS's

	#global flag vars. yes I know, global vars bad, whatevs
	$Global:hasBattery = $false
	$Global:hasUPS = $false

	#we use globals here because scope issues can be tricky and are HARD to manager.
	foreach($entry in $SPPowerTypeNames) {
		#the index is important in doing this, since it may or may not be different. saves some work
		$theIndex = [array]::IndexOf($SPPowerTypeNames,$entry)

		#switch-case to manage this
		switch ($entry) {

			"spbattery_information" {
				#has a battery if this exists, set $hasBattery to true
				$hasBattery = $true
				#get all three battery information items
				#battery Charge Info
				$batteryChargeInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].sppower_battery_charge_info
				$Global:batteryWarningLevel = $batteryChargeInfo.sppower_battery_at_warn_level
				$Global:batteryFullyCharged = $batteryChargeInfo.sppower_battery_fully_charged
				$Global:batteryIsCharging = $batteryChargeInfo.sppower_battery_is_charging
				$Global:batteryChargeLevel = $batteryChargeInfo.sppower_battery_state_of_charge
				#Intel-only value
				if (!($isAppleSilicon)) {
					$Global:batteryMaxChargeCapacity = $batteryChargeInfo.sppower_battery_max_capacity
				}

				#battery health info, same for both arch's
				$batteryHealthInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].sppower_battery_health_info
				$Global:batteryCycleCount = $batteryHealthInfo.sppower_battery_cycle_count
				$Global:batteryHealth = $batteryHealthInfo.sppower_battery_health
				#AS-only value
				if ($isAppleSilicon) {
					$Global:batteryHealthMaxCapacity = $batteryHealthInfo.sppower_battery_health_maximum_capacity
				}

				#battery model info
				$batteryModelInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].sppower_battery_model_info
				$Global:batterySerialNumber = $batteryModelInfo.sppower_battery_serial_number
				$Global:batteryDeviceName = $batteryModelInfo.sppower_battery_device_name
				$Global:batteryFirmwareVersion = $batteryModelInfo.sppower_battery_firmware_version
				$Global:batteryHardwareRevision = $batteryModelInfo.sppower_battery_hardware_revision
				$Global:batteryCellRevision = $batteryModelInfo.sppower_battery_cell_revision
				#Intel-Only
				if (!($isAppleSilicon)) {
					$Global:batteryManufacturer = $batteryModelInfo.sppower_battery_manufacturer
				}
			}

			"sppower_information" {

				#We can always assume AC power exists
				#set up our common stuff
				$ACPowerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].'AC Power'
				$Global:ACDiskSleepTimer = $ACPowerInfo.'Disk Sleep Timer'
				$Global:ACDisplaySleepTimer = $ACPowerInfo.'Display Sleep Timer'
				$Global:ACHibernateMode = $ACPowerInfo.'Hibernate Mode'
				$Global:ACLowPowerMode = $ACPowerInfo.LowPowerMode
				$Global:ACNetworkOverSleep = $ACPowerInfo.PrioritizeNetworkReachabilityOverSleep
				$Global:ACSystemSleepTimer = $ACPowerInfo.'System Sleep Timer'
				$Global:ACWakeOnLAN = $ACPowerInfo.'Wake On LAN'

				#test to see if the machine is plugged in or not. IF it is, set the current power source var
				#we set it to null/empty for when we add to the hashtable
				if(!([string]::IsNullOrEmpty($ACPowerInfo.'Current Power Source'))) {
					$Global:ACCurrentPowerSource = $ACPowerInfo.'Current Power Source'
				} else {
					$Global:ACCurrentPowerSource = "FALSE"
				}

				#apple Silicon section for AC Power
				if ($isAppleSilicon) {
					$Global:ACSleepOnPowerButton = $ACPowerInfo.'Sleep On Power Button'
					$Global:ACHighPowerMode = $ACPowerInfo.HighPowerMode
				} else {
					$Global:ACDisplaySleepDim = $ACPowerInfo.'Display Sleep Uses Dim'
					$Global:ACWakeOnACCHange = $ACPowerInfo.'Wake On AC Change'
					$Global:ACWakeOnClamshellOpen = $ACPowerInfo.'Wake On Clamshell Open'
				}

				#Test for Battery
				$batteryPowerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].'Battery Power'

				#if there's a battery (like built in, not in the room)
				if ($null -ne $batteryPowerInfo) {
					#this is possibly redundant, but since we can't be SURE which will be hit first, this
					#or the preceding battery info, setting it here too is fine.
					$hasBattery = $true

					#test to see if computer is running on battery power
					if(!([string]::IsNullOrEmpty($batteryPowerInfo.'Current Power Source'))) {
						$Global:batteryCurrentPowerSource = $batteryPowerInfo.'Current Power Source'
					} else {
						$Global:batteryCurrentPowerSource = "FALSE"
					}

					#architecture independent stuff
					$Global:batteryDiskSleepTimer = $batteryPowerInfo.'Disk Sleep Timer'
					$Global:batteryDisplaySleepTimer = $batteryPowerInfo.'Display Sleep Timer'
					$Global:batteryHibernateMode = $batteryPowerInfo.'Hibernate Mode'
					$Global:batteryLowPowerMode = $batteryPowerInfo.LowPowerMode
					$Global:batteryNetworkOverSleep = $batteryPowerInfo.PrioritizeNetworkReachabilityOverSleep
					$Global:batteryReduceBrightness = $batteryPowerInfo.ReduceBrightness
					$Global:batterySystemSleepTimer = $batteryPowerInfo.'System Sleep Timer'
					$Global:batteryWakeOnLan = $batteryPowerInfo.'Wake On LAN'

					#Arch-specific stuff
					if ($isAppleSilicon) {
						$Global:batteryHighPowerMode = $batteryPowerInfo.HighPowerMode
						$Global:batterySleepOnPowerButton = $batteryPowerInfo.'Sleep On Power Button'
					} else {
						$Global:batteryDisplaySleepUsesDim = $batteryPowerInfo.'Display Sleep Uses Dim'
						$Global:batteryWakeOnACChange = $batteryPowerInfo.'Wake On AC Change'
						$Global:batteryWakeOnClamshellOpen = $batteryPowerInfo.'Wake On Clamshell Open'
					}
				}

				#test for UPS Power. Yes, I know about hwconfig info, but we don't know if this
				#section will process before or after that, so we test it here, where we need it
				$UPSPowerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].'UPS Power'

				#UPS power exists
				if ($null -ne $UPSPowerInfo) {

					#set has UPS flag to true
					$hasUPS = $true

					if(!([string]::IsNullOrEmpty($UPSPowerInfo.'Current Power Source'))) {
						$Global:UPSCurrentPowerSource = $UPSPowerInfo.'Current Power Source'
					} else {
						$Global:UPSCurrentPowerSource = "FALSE"
					}

					#no idea if there's arch-dependent stuff, so it's all just here
					$Global:UPSAutoRestartOnPwrLoss = $UPSPowerInfo.'Automatic Restart On Power Loss'
					$Global:UPSDiskSleepTimer = $UPSPowerInfo.'Disk Sleep Timer'
					$Global:UPSDisplaySleepTimer = $UPSPowerInfo.'Display Sleep Timer'
					$Global:UPSNetworkOverSleep = $UPSPowerInfo.PrioritizeNetworkReachabilityOverSleep
					#assuming this is apple silcon only here too, since it is everywhere else
					if ($isAppleSilicon) {
						$Global:UPSSleepOnPowerButton = $UPSPowerInfo.'Sleep On Power Button'
					}
					$Global:UPSSystemSleepTimer = $UPSPowerInfo.'System Sleep Timer'
					$Global:UPSWakeOnLan = $UPSPowerInfo.'Wake On LAN'
				}
			}

			"sppower_hwconfig_information" {
				#has one value: is a UPS installed or not
				#it always exists, so we don't need to set it anywhere else
				$Global:UPSInstalled = $SPPowerTypeData[0].SPPowerDataType[$theIndex].sppower_ups_installed

				#set the flag appropriately.
				if ($UPSInstalled -eq "TRUE") {
					$hasUPS = $true
				} else {
					#is this strictly needed? No. Does it avoid potential problems? Yes
					$hasUPS = $false
				}
			}

			"sppower_ac_charger_information" {
				#like assuming there's always an AC Power Type, we assume there's always some kind of
				#AC charger info. This is different in that we don't have a named property after
				#SPPowerDataType[$theIndex]

				#Also note that depending on the charger the computer is plugged into,
				#much of these may be null. We can check when we build the hash. They're all strings
				#so easy enough
				$ACChargerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex]

				#these exist, even when on battery
				$Global:ACChargerConnected = $ACChargerInfo.sppower_battery_charger_connected #false when on battery, use as check
				$Global:ACChargerCharging = $ACChargerInfo.sppower_battery_is_charging #this and connected are only items when not plugged in

				#there doesn't seem to be any architectural difference here, just charger differences
				$Global:ACChargerName = $ACChargerInfo.sppower_ac_charger_name #only for apple chargers
				$Global:ACChargerSerialNumber = $ACChargerInfo.sppower_ac_charger_serial_number #only for apple chargers
				$Global:ACChargerWatts = $ACChargerInfo.sppower_ac_charger_watts
				$Global:ACChargerManf = $ACChargerInfo.sppower_ac_charger_manufacturer #only for apple chargers
				$Global:ACChargerID = $ACChargerInfo.sppower_ac_charger_ID
				$Global:ACChargerHWVers = $ACChargerInfo.sppower_ac_charger_hardware_version #only for apple chargers
				$Global:ACChargerFirmwareVers = $ACChargerInfo.sppower_ac_charger_firmware_version #only for apple chargers
				$Global:ACChargerFamily = $ACChargerInfo.sppower_ac_charger_family #this may be dependent on charger

			}
		}

	}

	#sysctl section===============================================================================
	$macInfoCPUBrand = Invoke-Expression -Command "/usr/sbin/sysctl -n machdep.cpu.brand_string"
	$macInfoVMPageFile = Invoke-Expression -Command "/usr/sbin/sysctl -n vm.swapfileprefix"

	##get application memory in use. This is calculated by ((vm page size) * (vm page internal count - vm page purgeable count)/1073741824)
	##to get the memory used in GB. To get this without needing a ton of lines, we're going to directly inject the vm data into the
	##equation, via invoke-expression to the correct sysctl values. the [Int] parameter coerces that text file returned to an integer value
	##dividing by 1073741824 converts the number to GB.
	$macInfoAppMemoryUsedGB = (([Int](Invoke-Expression -Command "/usr/sbin/sysctl -n vm.pagesize")) * (([Int](Invoke-Expression -Command "/usr/sbin/sysctl -n vm.page_pageable_internal_count")) - ([Int](Invoke-Expression -Command "/usr/sbin/sysctl -n vm.page_purgeable_count"))))/1073741824

	##now, we trim this down to four decimal places (just in case it's less than a GB, we get a useful number that way)
	$macInfoAppMemoryUsedGB = "{0:N4}" -f $macInfoAppMemoryUsedGB

	##next is current swap usage. Again, this is going to come from sysctl, specifically vm.swapusage. That reports in M as a string,
	##so we first grab the data from sysctl and split each entry into its own item in an array by splitting on spaces
	$macInfoVMSwapUsed = (Invoke-Expression -Command "/usr/sbin/sysctl -n vm.swapusage").Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)

	##next, the value we want is the 6th entry in the array. that's a string that ends in "M", so we want to trim that "M" from the
	##end via "TrimEnd("M"), which makes the string able to be coerced into a decimal via [Decimal], then we divide by 1024
	##to convert the data in MB to GB (we're trying to stick with GB in this where possible), and finally, we limit the decimal
	##to four decimal places "{0,N4}" -f at the front end. Again, we use four decimal places in case there's less than a GB of swap used.

	$macInfoVMSwapUsed = "{0:N4}" -f (([Decimal]($macInfoVMSwapUsed[5].TrimEnd("M")))/1024)

	#other section================================================================================

	#get boot device
	$macInfoBootDevice = Invoke-Expression -Command "/usr/sbin/bless --info --getboot"

	#get the current language
	$macInfoEFILanguage = (Get-Culture).DisplayName

	#get DST status
	$macInfoDSTStatus = (Get-Date).IsDaylightSavingTime()

	#get timezone
	$macInfoTimeZone = (Get-TimeZone).Id

	#get UTC offset
	$macInfoUTCOffset = (Get-TimeZone).BaseUTCOffset

	##filevault status
	#changed this to allow for multiline entries that can happen, all we care about for this is if FV is on
	$macInfoFileVaultTemp = Invoke-Expression -Command "/usr/bin/fdesetup status"
	#shove into array because multiline
	$macInfoFileVaultStatusArray = $macInfoFileVaultTemp.Split([Environment]::NewLine,$darwinVersionSplitOptions)
	#get last word of return of first line of array which has on/off
     #and trim trailing period
	$macInfoFileVaultStatus = $macInfoFileVaultStatusArray[0].Split(" ")[-1].TrimEnd(".")

	#DNS host name
	$macInfoDNSHostNameTest = Invoke-Expression -Command "/usr/sbin/scutil --get HostName"
	#we want to test for null or empty so we can have a default value just in case
	if([string]::IsNullOrEmpty($macInfoDNSHostNameTest)) {
		$macInfoDNSHostName = "Hostname: Not Set"
	} else {
		$macInfoDNSHostName = $macInfoDNSHostNameTest
	}

	##local machine name
	$macInfoLocalHostName = Invoke-Expression -Command "/usr/sbin/scutil --get ComputerName"

	#get a list of network services. This takes a few steps. First, get the list and put it into an array
	##this does a lot of things. It runs the networksetup - listallnetworkservices, then splits that output into an array,
	##one entry per line and removes blank lines
	#set it up as an arraylist
	[System.Collections.ArrayList]$macInfoNICList = @()

	#grab the NIC list and shove them into the array list
	$macInfoNICList = (Invoke-Expression -Command "/usr/sbin/networksetup -listallnetworkservices").Split([Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)

	##now we remove the first line, which is unnecessary for our needs
	##and yes, i know this is not technically a nic list, but it will work for our needs
	##and it grabs services that don't have ports that -listallhardwareports would have, like iPhone USB
	$macInfoNICList.RemoveAt(0)


	#using powershell -> bash -> applescript
	#get current user name
	$macInfoShortUserName = Invoke-Expression -Command '/usr/bin/osascript -e "get short user name of (system info)"'

	#get current user UID
	$macInfoUID = Invoke-Expression -Command '/usr/bin/osascript -e "get user ID of (system info)"'

	#get current date and time
	$macInfoCurrentDate = Get-Date

	#get last boot time
	##run who -b, but split on a space since you only get back a single line.
	$macInfoLastBoot = (Invoke-Expression -Command "/usr/bin/who -b").Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
	##remove the first two entries, since those aren't of use here
	$macInfoLastBoot = $macInfoLastBoot[2..($macInfoLastBoot.length - 1)]
	##convert it from an array back to a single line text string with the things we want
	$macInfoLastBoot = $macInfoLastBoot -join ' '

	#get uptime since
	##first, get the raw uptime
	$macInfoUptime = Get-Uptime
	## now pull out days.hours:minutes:seconds
	$macInfoUptime = $macInfoUptime -join " "

	##Get SIP status, split on : to make array
	$csrutilOutput = (Invoke-Expression -Command "/usr/bin/csrutil status").Split(":")
	#remove the leading space in the status
	$csrutilStatus = $csrutilOutput[1].Trim()
	#remove the trailing period
	$csrutilStatus = $csrutilStatus.Substring(0,$csrutilStatus.Length-1)

	##hashtable build, we deal with arch versions inline. It's not harder to read
	##and gets rid of a LOT of duplication.

	##the reason for the ever-increasing spaces in the blank lines is to avoid duplication of "names"
	##which are no-nos for hashtables.

	$macInfoHash.Add("macOSBuildLabEx", $mainDarwinKernelVersion)
	$macInfoHash.Add(" "," ")
	$macInfoHash.Add("macOSCurrentVersion", $macInfoOSVersion)
	$macInfoHash.Add("macOSCurrentBuildNumber", $macInfoOSBuildNumber)
	$macInfoHash.Add("macOSProductName", $macInfoOSName)
	$macInfoHash.Add("  "," ")
	$macInfoHash.Add("macOSDarwinVersion", $mainDarwinKernelVersion)
	$macInfoHash.Add("   "," ")
	$macInfoHash.Add("SystemFirmwareVersion", $macInfoEFIVersion)
	if (!($isAppleSilicon)) {
		$macInfoHash.Add("T2FirmwareVersion", $macInfoT2FirmwareVersion) #intel only
	}
	$macInfoHash.Add("OSLoaderVersion", $macInfoSMCVersion)
	$macInfoHash.Add("HardwareSerialNumber", $macInfoHardwareSN)
	$macInfoHash.Add("HardwareUUID", $macInfoHardwareUUID)
	$macInfoHash.Add("ProvisioningUDID",$macInfoProvisioningUDID)
	$macInfoHash.Add("    "," ")
	$macInfoHash.Add("HardwareModelName", $macInfoModelName)
	$macInfoHash.Add("HardwareModelID", $macInfoModelID)
	if ($isAppleSilicon) {
		$macInfoHash.Add("HardwareModelNumber", $macInfoModelNumber) #apple silicon only
	}
	$macInfoHash.Add("ActivationLockStatus", $macInfoActivationLockStatus)
	$macInfoHash.Add("     "," ")
	$macInfoHash.Add("CPUArchitecture", $macInfoCPUArch)
	$macInfoHash.Add("CPUName" , $macInfoCPUName)
	$macInfoHash.Add("CPUBrandString", $macInfoCPUBrand)
	$macInfoHash.Add("RAMAmount", $macInfoRAMSize)
	if ($isAppleSilicon) {
		$macInfoHash.Add("CPUTotalCoreCount", $macInfoCPUCoreCountTotal) #apple silicon only
		$macInfoHash.Add("CPUPerformanceCoreCount", $macInfoCPUPerformanceCoreCount) #apple silicon only
		$macInfoHash.Add("CPUEfficiencyCoreCount", $macInfoCPUEfficiencyCoreCount) #apple silicon only
	} else {
		$macInfoHash.Add("CPUSpeed", $macInfoCPUSpeed) #Intel Only
		$macInfoHash.Add("CPUCount", $macInfoCPUCount) #Intel Only
		$macInfoHash.Add("CPUCoreCount", $macInfoCPUCoreCount) #Intel Only
		$macInfoHash.Add("CPUL2CacheSize", $macInfoCPUL2CacheSize) #Intel Only
		$macInfoHash.Add("L3CacheSize", $macInfoL3CacheSize) #Intel Only
		$macInfoHash.Add("HyperThreadingEnabled", $macInfoHyperThreadingEnabled) #Intel Only
	}
	$macInfoHash.Add("      "," ")

	$macInfoHash.Add("ApplePayPlatformID", $applePayInfoPlatformID)
	$macInfoHash.Add("ApplePaySEID", $applePayInfoSEID)
	if ($isAppleSilicon) {
		$macInfoHash.Add("ApplePaySystemOSSEID", $applePayInfoSystemOSSEID)#apple silicon only
	}
	$macInfoHash.Add("ApplePayHardware", $applePayInfoHardware)
	$macInfoHash.Add("ApplePayFirmware", $applePayInfoFirmware)
	$macInfoHash.Add("ApplePayJCOPOSVersion", $applePayInfoJCOPOSVersion)
	$macInfoHash.Add("ApplePayControllerHardwareVersion", $applePayControllerHardwareVersion)
	$macInfoHash.Add("ApplePayControllerFirmwareVersion", $applePayControllerFirmwareVersion)
	$macInfoHash.Add("ApplePayControllerMiddlewareVersion", $applePayControllerMiddlewareVersion)
	$macInfoHash.Add("       "," ")

	$macInfoHash.Add("BluetoothMAC",$blueToothMAC)
	$macInfoHash.Add("BluetoothChipset",$blueToothChipset)
	$macInfoHash.Add("BluetoothDiscoverable",$blueToothDiscoverable)
	$macInfoHash.Add("BluetoothState",$blueToothState)
	$macInfoHash.Add("BluetoothFirmwareVersion",$bluetoothFirmwareVersion)
	if ($isAppleSilicon) {
		$macInfoHash.Add("BluetoothProductID", $blueToothProductID) #apple silicon only
	}
	$macInfoHash.Add("BluetoothSupportedServices",$bluetoothSupportedServices)
	$macInfoHash.Add("BluetoothTransport",$blueToothTransport)
	$macInfoHash.Add("BluetoothVendorID",$blueToothVendorID)
	$macInfoHash.Add("        "," ")

	#more common elements. The order matters
	$macInfoHash.Add("AppMemoryUsedGB", $macInfoAppMemoryUsedGB)
	$macInfoHash.Add("VMPageFile", $macInfoVMPageFile)
	$macInfoHash.Add("VMSwapInUseGB", $macInfoVMSwapUsed)
	$macInfoHash.Add("         "," ")
	$macInfoHash.Add("BootDevice", $macInfoBootDevice)
	$macInfoHash.Add("FileVaultStatus", $macInfoFileVaultStatus)
	$macInfoHash.Add("SIPStatus", $csrutilStatus)
	$macInfoHash.Add("          "," ")
	$macInfoHash.Add("EFICurrentLanguage", $macInfoEFILanguage)
	$macInfoHash.Add("DSTStatus", $macInfoDSTStatus)
	$macInfoHash.Add("TimeZone", $macInfoTimeZone)
	$macInfoHash.Add("UTCOffset", $macInfoUTCOffset)
	$macInfoHash.Add("           "," ")
	$macInfoHash.Add("DNSHostName", $macInfoDNSHostName)
	$macInfoHash.Add("LocalHostName", $macInfoLocalHostName)
	$macInfoHash.Add("NetworkServiceList", $macInfoNICList)
	$macInfoHash.Add("            "," ")
	$macInfoHash.Add("CurrentUserName", $macInfoShortUserName)
	$macInfoHash.Add("CurrentUserUID", $macInfoUID)
	$macInfoHash.Add("             "," ")
	$macInfoHash.Add("CurrentDateTime", $macInfoCurrentDate)
	$macInfoHash.Add("LastBootDateTime", $macInfoLastBoot)
	$macInfoHash.Add("Uptime", $macInfoUptime)
	$macInfoHash.Add("              "," ")

	##Power Info
	#AC Power first, that's always there
	$macInfoHash.Add("ACCurrentPowerSource",$ACCurrentPowerSource)
	$macInfoHash.Add("ACSystemSleepTimer",$ACSystemSleepTimer)
	$macInfoHash.Add("ACDiskSleepTImer",$ACDiskSleepTimer)
	$macInfoHash.Add("ACDisplaySleepTimer",$ACDisplaySleepTimer)
	$macInfoHash.Add("ACHibernateMode",$ACHibernateMode)
	$macInfoHash.Add("ACLowPowerMode",$ACLowPowerMode)
	$macInfoHash.Add("ACNetworkOverSleep",$ACNetworkOverSleep)
	$macInfoHash.Add("ACWakeOnLan",$ACWakeOnLAN)
	#apple silicon info
	if ($isAppleSilicon) {
		$macInfoHash.Add("ACHighPowerMode",$ACHighPowerMode)
		$macInfoHash.Add("ACSleepOnPowerButton",$ACSleepOnPowerButton)
	} else {
		#intel info
		$macInfoHash.Add("ACDisplaySleepUsesDim",$ACDisplaySleepDim)
		$macInfoHash.Add("ACWakeOnACChange",$ACWakeOnACCHange)
		$macInfoHash.Add("ACWakeOnClamshellOpen",$ACWakeOnClamshellOpen)
	}
	#add a blank line to make reading easier
	$macInfoHash.Add("               "," ")

	#put in the AC Charger info here, there's some logic to it
	$macInfoHash.Add("ACChargerConnected",$ACChargerConnected)
	$macInfoHash.Add("ACChargerCharging",$ACChargerCharging)
	#the rest of this is variable AF, and there's not a great way to test for it other
	#than if statements or a switch case. Which I'll do if I get complaints
	$macInfoHash.Add("ACChargerName",$ACChargerName)
	$macInfoHash.Add("ACChargerSerialNumber",$ACChargerSerialNumber)
	$macInfoHash.Add("ACChargerWatts",$ACChargerWatts)
	$macInfoHash.Add("ACChargerManf",$ACChargerManf)
	$macInfoHash.Add("ACChargerID",$ACChargerID)
	$macInfoHash.Add("ACChargerHWVers",$ACChargerHWVers)
	$macInfoHash.Add("ACChargerFirmwareVers",$ACChargerFirmwareVers)
	$macInfoHash.Add("ACChargerFamily",$ACChargerFamily)
	$macInfoHash.Add("                "," ")

	#if we have a battery, add that
	if ($hasBattery) {
		$macInfoHash.Add("batteryCurrentPowerSource",$batteryCurrentPowerSource)
		$macInfoHash.Add("batterySystemSleepTimer",$batterySystemSleepTimer)
		$macInfoHash.Add("batteryDiskSleepTimer",$batteryDiskSleepTimer)
		$macInfoHash.Add("batteryDisplaySleepTimer",$batteryDisplaySleepTimer)
		$macInfoHash.Add("batteryReduceBrightness",$batteryReduceBrightness)
		$macInfoHash.Add("batteryHibernateMode",$batteryHibernateMode)
		$macInfoHash.Add("batteryLowPowerMode",$batteryLowPowerMode)
		$macInfoHash.Add("batteryNetworkOverSleep",$batteryNetworkOverSleep)
		$macInfoHash.Add("batteryWakeOnLan",$batteryWakeOnLan)
		#apple silicon info
		if ($isAppleSilicon) {
			$macInfoHash.Add("batteryHighPowerMode",$batteryHighPowerMode)
			$macInfoHash.Add("batterySleepOnPowerButton",$batterySleepOnPowerButton)
		} else {
			#intel info
			$macInfoHash.Add("batteryDisplaySleepUsesDim",$batteryDisplaySleepUsesDim)
			$macInfoHash.Add("batteryWakeOnACChange",$batteryWakeOnACChange)
			$macInfoHash.Add("batteryWakeOnClamshellOpen",$batteryWakeOnClamshellOpen)
		}
		#more white space
		$macInfoHash.Add("                 "," ")

		$macInfoHash.Add("batteryWarningLevel",$batteryWarningLevel)
		$macInfoHash.Add("batteryFullyCharged",$batteryFullyCharged)
		$macInfoHash.Add("batteryIsCharging",$batteryIsCharging)
		$macInfoHash.Add("batteryChargeLevel",$batteryChargeLevel)
		if (!($isAppleSilicon)) {
			$macInfoHash.Add("batteryMaxChargeCapacity",$batteryMaxChargeCapacity) #intel only
		}
		$macInfoHash.Add("                  "," ")

		$macInfoHash.Add("batteryCycleCount",$batteryCycleCount)
		$macInfoHash.Add("batteryHealth",$batteryHealth)
		if ($isAppleSilicon) {
			$macInfoHash.Add("batteryHealthMaxCapacity",$batteryHealthMaxCapacity) #apple silicon only
		}
		$macInfoHash.Add("                   "," ")

		$macInfoHash.Add("batterySerialNumber",$batterySerialNumber)
		$macInfoHash.Add("batteryDeviceName",$batteryDeviceName)
		$macInfoHash.Add("batteryFirmwareVersion",$batteryFirmwareVersion)
		$macInfoHash.Add("batteryHardwareRevision",$batteryHardwareRevision)
		$macInfoHash.Add("batteryCellRevision",$batteryCellRevision)
		if (!($isAppleSilicon)) {
			$macInfoHash.Add("batteryManufacturer",$batteryManufacturer) #intel Only
		}
		$macInfoHash.Add("                    "," ")
	}

	#if we have a UPS, add that
	#note we add the hardware config regardless, this is just for the UPS-specific info
	$macInfoHash.Add("UPSInstalled",$UPSInstalled)
	if ($hasUPS) {
		$macInfoHash.Add("UPSCurrentPowerSource",$UPSCurrentPowerSource)
		$macInfoHash.Add("UPSSystemSleepTimer",$UPSSystemSleepTimer)
		$macInfoHash.Add("UPSAutoRestartOnPowerLoss",$UPSAutoRestartOnPwrLoss)
		$macInfoHash.Add("UPSDiskSleepTimer",$UPSDiskSleepTimer)
		$macInfoHash.Add("UPSDisplaySleepTimer",$UPSDisplaySleepTimer)
		$macInfoHash.Add("UPSNetworkOverSleep",$UPSNetworkOverSleep)
		$macInfoHash.Add("UPSWakeOnLan",$UPSWakeOnLan)
		if ($isAppleSilicon) {
			$macInfoHash.Add("UPSSleepOnPowerButton",$UPSSleepOnPowerButton) #apple silicon only
		}
		$macInfoHash.Add("                     "," ")
	}

	#so we want the hashtable to be filled before we even care about what the person asked for. This is lazy as hell, to be sure, but,
	#it ensures that no matter what the parameter asks for, it will work. Also really, the entire thing takes just over a second to run,
	#even on a ten-year-old macbook pro.

	#so here, we're checking to see if there's no input parameters, which means display the entire hashtable. We're not formatting it,
	#the default is fine.

	#if there are input parameters, we use the -f formatting operator to create two columns labled "Name", and "Value", setting the first one
	#to 30 characters, which gives us some space as our longest key is only about 24 characters in width, and the value column to 100 characters
	#both columns are lef-aligned.

	#I did try to use -format table, but it didn't work out

	if ($null -eq $keys) {
		$macInfoHash
		Exit-PSSession
	}
	else {
		"{0,-30}{1,-100}" -f "Name","Value"
		"{0,-30}{1,-100}" -f "----","-----"
		foreach ($key in $keys) {
		     $theValue = $macInfoHash.$key
		     "{0,-30}{1,-100}" -f $key,$theValue
		}
	}
}

Export-ModuleMember -Function Get-MacInfo



# SIG # Begin signature block
# MIIMgAYJKoZIhvcNAQcCoIIMcTCCDG0CAQMxDTALBglghkgBZQMEAgEwewYKKwYB
# BAGCNwIBBKBtBGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCApPuCjcaHnkEo3
# AM9SfIRXunVyh37ZA/KtDmPDKiZnCKCCCaswggQEMIIC7KADAgECAggYeqmowpYh
# DDANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUg
# SW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAU
# BgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMTIwMjAxMjIxMjE1WhcNMjcwMjAxMjIx
# MjE1WjB5MS0wKwYDVQQDDCREZXZlbG9wZXIgSUQgQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMw
# EQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAIl2TwZbmkHupSMrAqNf13M/wDWwi4QKPwYkf6eVP+tP
# DpOvtA7QyD7lbRizH+iJR7/XCQjk/1aYKRXnlJ25NaMKzbTA4eJg9MrsKXhFaWlg
# a1+KkvyeI+Y6wiKzMU8cuvK2NFlC7rCpAgMYkQS2s3guMx+ARQ1Fb7sOWlt/OufY
# CNcLDjJt+4Y25GyrxBGKcIQmqp9E0fG4xnuUF5tI9wtYFrojxZ8VOX7KXcMyXw/g
# Un9A6r6sCGSVW8kanOWAyh9qRBxsPsSwJh8d7HuvXqBqPUepWBIxPyB2KG0dHLDC
# ThFpJovL1tARgslOD/FWdNDZCEtmeKKrrKfi0kyHWckCAwEAAaOBpjCBozAdBgNV
# HQ4EFgQUVxftos/cfJihEOD8voctLPLjF1QwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
# HSMEGDAWgBQr0GlHlHYJ/vRrjS5ApvdHTX8IXjAuBgNVHR8EJzAlMCOgIaAfhh1o
# dHRwOi8vY3JsLmFwcGxlLmNvbS9yb290LmNybDAOBgNVHQ8BAf8EBAMCAYYwEAYK
# KoZIhvdjZAYCBgQCBQAwDQYJKoZIhvcNAQELBQADggEBAEI5dGuh3MakjzcqjLMd
# CkS8lSx/vFm4rGH7B5CSMrnUvzvBUDlqRHSi7FsfcOWq3UtsHCNxLV/RxZO+7puK
# cGWCnRbjGhAXiS2ozf0MeFhJDCh/M+4Aehu0dqy2tbtP36gbncgZl0oLVmcvwj62
# s8SDOvB3bXTELiNR7pqlA29g9KVIpwbCu1riHx9GRX7kl/UnELcgInJvctrGUHXF
# PSWPXaMA6Z82jEg5j7M76pCALpWaYPR4zvQOClM+ovpP2B6uhJWNMrxWTYnpeBjg
# rJpCunpGG4Siic4U6IjRWIv2rlbELAUqRa8L2UupAg80rIjHYVWJRMkncwfuguVO
# 9XAwggWfMIIEh6ADAgECAggGHmabX9eOKjANBgkqhkiG9w0BAQsFADB5MS0wKwYD
# VQQDDCREZXZlbG9wZXIgSUQgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxJjAkBgNV
# BAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBs
# ZSBJbmMuMQswCQYDVQQGEwJVUzAeFw0yMDA5MTYwMzU4MzBaFw0yNTA5MTcwMzU4
# MzBaMIGNMRowGAYKCZImiZPyLGQBAQwKNzk2NDg4Vkc5NTE4MDYGA1UEAwwvRGV2
# ZWxvcGVyIElEIEluc3RhbGxlcjogSm9obiBXZWxjaCAoNzk2NDg4Vkc5NSkxEzAR
# BgNVBAsMCjc5NjQ4OFZHOTUxEzARBgNVBAoMCkpvaG4gV2VsY2gxCzAJBgNVBAYT
# AlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw0uP+x8FCIpcy4DJ
# xqWRX3Pdtr55nnka0f22c7Ko+IAC//91iQxQLuz8fqbe4b3pEyemzfDB0GSVyhnY
# AYLVYMjVaUamr2j7apX8M3QxIcxrlHAJte1Mo+ntsQic4+syz5HZm87ew4R/52T3
# zzvtsjaKRIfy0VT35E9T4zVhpq3vdJkUCuQrHrXljxXhOEzJrJ9XllDDJ2QmYZc0
# K29YE9pVPFiZxkbf5xmtx1CZhiUulCI0ypnj7dGxLJxRtJhsFChzeSflkOBtn9H/
# RVuBjb0DaRib/mEK7FCbYgEbcIL5QcO3pUlIyghXaQoZsNaViszg7Xzfdh16efby
# y+JLaQIDAQABo4ICFDCCAhAwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBRXF+2i
# z9x8mKEQ4Py+hy0s8uMXVDBABggrBgEFBQcBAQQ0MDIwMAYIKwYBBQUHMAGGJGh0
# dHA6Ly9vY3NwLmFwcGxlLmNvbS9vY3NwMDMtZGV2aWQwNzCCAR0GA1UdIASCARQw
# ggEQMIIBDAYJKoZIhvdjZAUBMIH+MIHDBggrBgEFBQcCAjCBtgyBs1JlbGlhbmNl
# IG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0
# YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBj
# b25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZp
# Y2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMDYGCCsGAQUFBwIBFipodHRwOi8v
# d3d3LmFwcGxlLmNvbS9jZXJ0aWZpY2F0ZWF1dGhvcml0eS8wFwYDVR0lAQH/BA0w
# CwYJKoZIhvdjZAQNMB0GA1UdDgQWBBRdVgk/6FL+2RJDsLeMey31Hn+TBzAOBgNV
# HQ8BAf8EBAMCB4AwHwYKKoZIhvdjZAYBIQQRDA8yMDE5MDIwNjAwMDAwMFowEwYK
# KoZIhvdjZAYBDgEB/wQCBQAwDQYJKoZIhvcNAQELBQADggEBAHdfmGHh7XOchb/f
# reKxq4raNtrvb7DXJaubBNSwCjI9GhmoAJIQvqtAHSSt4CHsffoekPkWRWaJKgbk
# +UTCZLMy712KfWtRcaSNNzOp+5euXkEsrCurBm/Piua+ezeQWt6RzGNM86bOa34W
# 4r6jdYm8ta9ql4So07Z4kz3y5QN7fI20B8kG5JFPeN88pZFLUejGwUpshXFO+gbk
# GrojkwbpFuRAsiEZ1ngeqtObaO8BRKHahciFNpuTXk1I0o0XBZ2JmCUWzx3a6T4u
# fME1heNtNLRptGYMtZXH4tboV39Wf5lgHc4KR85Mbw52srsRU22NE8JWAvgFp/Qz
# qX5rmVIxggIrMIICJwIBATCBhTB5MS0wKwYDVQQDDCREZXZlbG9wZXIgSUQgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRp
# b24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUwII
# Bh5mm1/XjiowCwYJYIZIAWUDBAIBoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZI
# hvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
# ARUwLwYJKoZIhvcNAQkEMSIEIBkmzAzJfBtgP9ydyNX4q3Mm1W6giyf4xwbaLSTk
# je3KMAsGCSqGSIb3DQEBAQSCAQBdiCZ6QUUVqEgHY5EtS8HQ2ufHYGozBjWzSJ4r
# 575rTfLBfYMksvVoHhyL4Re4wERVq4jakwjEwXvQpI08+DL+sqh4KzEzG0J83x9q
# oyEpmz7M5vPaTNV2+tlfGs9SlvQ9oRZTehXfm9rOz+fxiIb4v7SKHvt6K+t1SdGV
# LZ4ctDXtat00Ma8C2hOGi8ortKZcnifRQt72HKz8p0OB1V2jdhIEEhoIgmTAt6YW
# oSj3SNC++HL/U9TfHx15l1YZwr5jXPu4P7P+57p2eXwB15CAkrQaVRD8ETEYF5K9
# m/RbB3e7rl2tZge4DMHC3s6MlUfV+9NnOuvuycNfARBBBjtc
# SIG # End signature block
