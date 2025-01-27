function getSPJSONData {
	param (
		[Parameter(Mandatory = $true)][string] $SPDataType
	)
	
	#get raw json data from system_profiler for $SPDataType. This creates an array of strings
	$SPRawResults = Invoke-Expression -Command "/usr/sbin/system_profiler $SPDataType -json"
	#convert array to one string
	$SPStringResults = $SPRawResults|Out-String
	#create JSON object from string
	$SPJSONResults = ConvertFrom-Json -InputObject $SPStringResults
	#return JSON object to calling command
	return $SPJSONResults
}

##test for internal battery
#get ioreg info
#$ioregBatteryInfoArray = Invoke-Expression -Command "/usr/sbin/ioreg -brc AppleSmartBattery"
#look for "built-in"
#$hasBatteryInfo = $ioregBatteryInfoArray|Where-Object { $_ -match "`"built-in`"" }
#split and get value, will be "yes" if has battery
#use for???
#$hasBattery = $hasBatteryInfo.Split("=")[1].Trim()

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

