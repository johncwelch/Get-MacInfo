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


$SPBlueToothData = getSPJSONData -SPDataType "SPBluetoothDataType"
$SPBlueToothInfo = $SPBlueToothData[0].SPBluetoothDataType[0].controller_properties
$bluetoothSupportedServicesRaw = $SPBlueToothInfo.controller_supportedServices
[System.Collections.ArrayList]$bluetoothSupportedServices = @()
$bluetoothSupportedServices.Add($bluetoothSupportedServicesRaw.Split("<")[0].Trim())|Out-Null
$blueToothTemp = $bluetoothSupportedServicesRaw.Split("<")[1].Trim()
$blueToothTemp = $blueToothTemp.Substring(0,$blueToothTemp.Length-1)
$blueToothTemp = $blueToothTemp.Trim()
$blueToothTempArray = $blueToothTemp.Split(" ")

foreach($item in $blueToothTempArray){
	$bluetoothSupportedServices.Add($item)|Out-Null
}

$bluetoothSupportedServices

$SPApplePayData = getSPJSONData -SPDataType "SPSecureElementDataType"
#we don't need to care about raw here, there's no difference between ray and JSON output
$SPApplePayInfo = $SPApplePayData[0].SPSecureElementDataType[0]

$SPHardwareRaw = getSPRawData -SPDataType "SPHardwareDataType"


$macInfoCPUCoreCount = $SPHardwareRaw -match "Total Number of Cores"      
$macInfoCPUCoreCount = $macInfoCPUCoreCount.Split(":")[1].Trim()
$macInfoCPUCoreCountTotal = $macInfoCPUCoreCount.Split(" ")[0]
$macInfoCPUCoreCountTemp = $macInfoCPUCoreCount.Split(" (")[1]
$macInfoCPUCoreCountTemp = $macInfoCPUCoreCountTemp.Substring(0,$macInfoCPUCoreCountTemp.Length-1)             
$macInfoCPUPerformanceCoreCount = $macInfoCPUCoreCountTemp.Split(" and ")[0]
$macInfoCPUEfficiencyCoreCount = $macInfoCPUCoreCountTemp.Split(" and ")[1]

##note that we use flags for if there's a battery and/or UPS
##we'll test at the "Building the hash table" stage. If either is false, then we don't provide
##battery/UPS info

#get full output of SPPowerDataType as JSON
$SPPowerTypeData = getSPJSONData -SPDataType "SPPowerDataType"

#get number of items in the collection
$SPPowerTypeDataCount = $SPPowerTypeData.SPPowerDataType.Count

$SPPowerTypeNames = $SPPowerTypeData[0].SPPowerDataType._name

#we can check for existence with .GetType() try/catch. If error, bad
#or check via _name, if null, not there
#or flag in switch block, probably more reliable

#global flag vars
$Global:hasBattery = $false
$Global:hasUPS = $false

#we use globals here because scope issues can be tricky and are HARD to manager.
foreach($entry in $SPPowerTypeNames) {
	$theIndex = [array]::IndexOf($SPPowerTypeNames,$entry)
	switch ($entry) {
		"spbattery_information" {
			#has a battery if this exists, set $hasBattery to true
			$hasBattery = $true
			#get all three battery information items
			$batteryChargeInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].sppower_battery_charge_info
			$Global:batteryWarningLevel = $batteryChargeInfo.sppower_battery_at_warn_level
			$Global:batteryFullyCharged = $batteryChargeInfo.sppower_battery_fully_charged
			$Global:batteryIsCharging = $batteryChargeInfo.sppower_battery_is_charging
			$Global:batteryChargeLevel = $batteryChargeInfo.sppower_battery_state_of_charge
			#if (!($isAppleSilicon)) {
				$Global:batteryMaxCapacity = $batteryChargeInfo.sppower_battery_max_capacity
			#}

			$batteryHealthInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].sppower_battery_health_info
			$Global:batteryCycleCount = $batteryHealthInfo.sppower_battery_cycle_count
			$Global:batteryHealth = $batteryHealthInfo.sppower_battery_health
			$Global:batteryMaxCapacity = $batteryHealthInfo.sppower_battery_health_maximum_capacity

			$batteryModelInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].sppower_battery_model_info
			$Global:batterySerialNumber = $batteryModelInfo.sppower_battery_serial_number
			$Global:batteryDeviceName = $batteryModelInfo.sppower_battery_device_name
			$Global:batteryFirmwareVersion = $batteryModelInfo.sppower_battery_firmware_version
			$Global:batteryHardwareRevision = $batteryModelInfo.sppower_battery_hardware_revision
			$Global:batteryCellRevision = $batteryModelInfo.sppower_battery_cell_revision
			#if (!($isAppleSilicon)) {
				$Global:batteryManufacturer = $batteryModelInfo.sppower_battery_manufacturer
			#}
		}

		"sppower_information" {
			#we can assume there's ALWAYS an AC power type
			$ACPowerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].'AC Power'
			#test to see if computer is plugged in/on AC power
			if(!([string]::IsNullOrEmpty($ACPowerInfo.'Current Power Source'))) {
				$Global:ACCurrentPowerSource = $ACPowerInfo.'Current Power Source'
			}
			$Global:ACDisplaySleepTimer = $ACPowerInfo.'Display Sleep Timer'
			$Global:ACHibernateMode = $ACPowerInfo.'Hibernate Mode'
			$Global:ACNetworkOverSleep = $ACPowerInfo.PrioritizeNetworkReachabilityOverSleep
			$Global:ACSleepOnPowerButton = $ACPowerInfo.'Sleep On Power Button'
			$Global:ACSleepTimer = $ACPowerInfo.'System Sleep Timer'
			$Global:ACWakeOnLAN = $ACPowerInfo.'Wake On LAN'

			#Test for battery
			$batteryPowerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].'Battery Power'
			#if there's no battery power, $batteryPowerInfo will be null
			if ($null -ne $batteryPowerInfo) {
				#this is possibly redundant, but since we can't be SURE which will be hit first, this
				#or the preceding battery info, setting it here too is fine.
				$Global:hasBattery = $true
				#test to see if computer is running on battery power
				if(!([string]::IsNullOrEmpty($batteryPowerInfo.'Current Power Source'))) {
					$Global:ACCurrentPowerSource = $ACPowerInfo.'Current Power Source'
				}
				$Global:batteryDisplaySleepTimer = $batteryPowerInfo.'Display Sleep Timer'
				$Global:batteryHibernateMode = $batteryPowerInfo.'Hibernate Mode'
				$Global:batteryNetworkOverSleep = $batteryPowerInfo.PrioritizeNetworkReachabilityOverSleep
				$Global:batterySleepOnPowerButton = $batteryPowerInfo.'Sleep On Power Button'
				$Global:batterySleepTimer = $batteryPowerInfo.'System Sleep Timer'
				$Global:batteryWakeOnLan = $batteryPowerInfo.'Wake On LAN'
			}

			#Test for UPS
			$UPSPowerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex].'UPS Power'
			#if $UPSPowerInfo is not null, we have a UPS
			if ($null -ne $UPSPowerInfo) {
				#check for UPS current power source (Not sure if this ever happens)
				if(!([string]::IsNullOrEmpty($UPSPowerInfo.'Current Power Source'))) {
					$Global:UPSCurrentPowerSource = $UPSPowerInfo.'Current Power Source'
				}

				$Global:UPSDisplaySleepTimer = $UPSPowerInfo.'Display Sleep Timer'
				$Global:UPSHibernateMode = "No hibernate mode info for UPS"
				$Global:UPSNetworkOverSleep = $UPSPowerInfo.PrioritizeNetworkReachabilityOverSleep
				$Global:UPSSleepOnPowerButton = $UPSPowerInfo.'Sleep On Power Button'
				$Global:UPSSleepTimer = $UPSPowerInfo.'System Sleep Timer'
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
			#much of these may be null
			$ACChargerInfo = $SPPowerTypeData[0].SPPowerDataType[$theIndex]
			#Test to see if battery power is even connected
			if ($ACChargerInfo.sppower_battery_charger_connected -eq "FALSE") {
				#not plugged in 
				$Global:ACChargerConnected = $ACChargerInfo.sppower_battery_charger_connected #false when on battery, use as check
				$Global:ACChargerCharging = $ACChargerInfo.sppower_battery_is_charging #this and connected are only items when not plugged in
				#these are all blank when not plugged in
				$Global:ACChargerName = ""
				$Global:ACChargerSerialNumber = ""
				$Global:ACChargerWatts = ""
				$Global:ACChargerManf = ""
				$Global:ACChargerID = ""
				$Global:ACChargerHWVers = ""
				$Global:ACChargerFirmwareVers = ""
			} else {
				$Global:ACChargerName = $ACChargerInfo.sppower_ac_charger_name #only for apple chargers
				$Global:ACChargerSerialNumber = $ACChargerInfo.sppower_ac_charger_serial_number #only for apple chargers
				$Global:ACChargerWatts = $ACChargerInfo.sppower_ac_charger_watts
				$Global:ACChargerManf = $ACChargerInfo.sppower_ac_charger_manufacturer #only for apple chargers
				$Global:ACChargerConnected = $ACChargerInfo.sppower_battery_charger_connected #false when on battery, use as check
				$Global:ACChargerCharging = $ACChargerInfo.sppower_battery_is_charging #this and connected are only items when not plugged in
				$Global:ACChargerID = $ACChargerInfo.sppower_ac_charger_ID 
				$Global:ACChargerHWVers = $ACChargerInfo.sppower_ac_charger_hardware_version #only for apple chargers
				$Global:ACChargerFirmwareVers = $ACChargerInfo.sppower_ac_charger_firmware_version #only for apple chargers
			}
		}
	}
}

#hardware info testing
$SPHardwareTypeData = getSPJSONData -SPDataType "SPHardwareDataType"
$SPHardwareTypeInfo = $SPHardwareTypeData[0].SPHardwareDataType[0]

$macInfoEFIVersion = $SPHardwareTypeInfo.boot_rom_version

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

#model number
$macInfoModelNumber = $SPHardwareTypeInfo.model_number

#CPU Model
$macInfoCPUName = $SPHardwareTypeInfo.chip_type

#core count. We're going to split ito perf and efficiency
#This is a mess to get because it doesn't show in the JSON output

#get total number of cores the fast way via grep
$macInfoCPUCoreCount = Invoke-Expression "/usr/sbin/system_profiler SPHardwareDataType -detailLevel full|grep `"Total Number of Cores`""

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

#RAM size
$macInfoRAMSize = $SPHardwareTypeInfo.physical_memory

