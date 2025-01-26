##test for internal battery
#get ioreg info
$ioregBatteryInfoArray = Invoke-Expression -Command "/usr/sbin/ioreg -brc AppleSmartBattery"
#look for "built-in"
$hasBatteryInfo = $ioregBatteryInfoArray|Where-Object { $_ -match "`"built-in`"" }
#split and get value, will be "yes" if has battery
#use for???
$hasBattery = $hasBatteryInfo.Split("=")[1].Trim()


#get raw json data from system_profiler. This creates an array of strings
$SPPowerTypeRaw = Invoke-Expression -Command "/usr/sbin/system_profiler SPPowerDataType -json"
#convert array to one string
$SPPowerTypeString = $SPPowerTypeRaw|Out-String
#create JSON object from string
$SPPowerTypeData = ConvertFrom-Json -InputObject $SPPowerTypeString

##get various info blocks from json
#battery info
$batteryChargeInfo = $SPPowerTypeData[0].SPPowerDataType[0].sppower_battery_charge_info
$batteryHealthInfo = $SPPowerTypeData[0].SPPowerDataType[0].sppower_battery_health_info
$batteryModelInfo = $SPPowerTypeData[0].SPPowerDataType[0].sppower_battery_model_info

#info about AC power like current power source, sleep timers, etc.
#note that current power source only appears in the entry that is 
#the current power source. Could be useful 
$ACPowerInfo = $SPPowerTypeData[0].SPPowerDataType[1].'AC Power'

#info about Battery Power like current power source, sleep timers, etc.
$BatteryPowerInfo = $SPPowerTypeData[0].SPPowerDataType[1].'Battery Power'
#this is the only value in this block, so we just get it direct
$UPSInstalled = $SPPowerTypeData[0].SPPowerDataType[2].sppower_ups_installed

#Info about the AC charger
$ACChargerInfo = $SPPowerTypeData[0].SPPowerDataType[3]

$batteryWarningLevel = $batteryChargeInfo.sppower_battery_at_warn_level
$batteryFullyCharged = $batteryChargeInfo.sppower_battery_fully_charged
$batteryIsCharging = $batteryChargeInfo.sppower_battery_is_charging
$batteryChargeLevel = $batteryChargeInfo.sppower_battery_state_of_charge

$batteryCycleCount = $batteryHealthInfo.sppower_battery_cycle_count
$batteryHealth = $batteryHealthInfo.sppower_battery_health
$batteryMaxCapacity = $batteryHealthInfo.sppower_battery_health_maximum_capacity

$batterySerialNumber = $batteryModelInfo.sppower_battery_serial_number
$batteryDeviceName = $batteryModelInfo.sppower_battery_device_name
$batteryFirmwareVersion = $batteryModelInfo.sppower_battery_firmware_version
$batteryHardwareRevision = $batteryModelInfo.sppower_battery_hardware_revision
$batteryCellRevision = $batteryModelInfo.sppower_battery_cell_revision

$ACChargerName = $ACChargerInfo.sppower_ac_charger_name #only for apple chargers
$ACChargerSerialNumber = $ACChargerInfo.sppower_ac_charger_serial_number #only for apple chargers
$ACChargerWatts = $ACChargerInfo.sppower_ac_charger_watts
$ACChargerManf = $ACChargerInfo.sppower_ac_charger_manufacturer #only for apple chargers
$ACChargerConnected = $ACChargerInfo.sppower_battery_charger_connected #false when on battery, use as check
$ACChargerCharging = $ACChargerInfo.sppower_battery_is_charging #this and connected are only items when not plugged in
$ACChargerID = $ACChargerInfo.sppower_ac_charger_ID 
$ACChargerHWVers = $ACChargerInfo.sppower_ac_charger_hardware_version #only for apple chargers
$ACChargerFirmwareVers = $ACChargerInfo.sppower_ac_charger_firmware_version #only for apple chargers

