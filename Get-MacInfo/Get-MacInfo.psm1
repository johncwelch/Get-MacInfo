#!/usr/bin/env pwsh

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

## To do:
	#app-sso output
	#system_profiler SPSecureElementDataType (apple pay), get
		#firmware
		#JCOP OS
		#controller hardware
		#controller firmware
		#controller middleware
	#SPAudioDataType
		#list the 
function Get-MacInfo {
	#input parameter line, has to be the first executable line in the script
	param ($keys)

	#check to make sure this is running on a mac, if not, print error message and exit
	if (-Not $IsMacOS)
		{
		     write-host "This Script only runs on macOS, exiting"
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

	#now, let's get our system_profiler hardware info
	$macInfoSystemProfilerRaw = Invoke-Expression -Command "/usr/sbin/system_profiler SPHardwareDataType"

	##Apple Silicon Differences
	#Chip: instead of Processor Name:
	#No Processor Speed:
	#No Number of Processors
	#Total Number of Cores: has more info
	#No L2 Cache:
	#No L3 Cache:
	#No HyperThreading Technology:

	#we want to shove this into an array and remove blank lines. Luckily, we have the remove blank lines option from an earlier step,
	#so we can just reuse that. We also want to have the split command just split on a new line. 
	#the [Environment]::NewLine parameter handles splitting on a new line.
	$macInfoSystemProfilerArray = $macInfoSystemProfilerRaw.Split([Environment]::NewLine,$darwinVersionSplitOptions)

	#now we have to get clever. So we're going to put this array into an arraylist so we can arbitrarily remove items we don't need.
	#yes, it's a memory hog, but this is a very tiny array

	[System.Collections.ArrayList]$macInfoSystemProfilerArrayList = $macInfoSystemProfilerArray 

	#now we remove the first two items. Note that RemoveRange parameters read as (startingIndex,numberofItemsToRemove)
	$macInfoSystemProfilerArrayList.RemoveRange(0,2)

	###Here is the first place where we have to account for Apple Silicon vs Intel
     ##.Trim() removes all leading and trailing whitespace in one step

	#Apple Silicon Section
	if($isAppleSilicon) {
		#getthe System Firmware Version
		$macInfoEFIVersion = $macInfoSystemProfilerArrayList[6].Split(":")[1].Trim()

		#Get the OS Loader Version
		$macInfoSMCVersion = $macInfoSystemProfilerArrayList[7].Split(":")[1].Trim()

		#hardware serial number
		$macInfoHardwareSN = $macInfoSystemProfilerArrayList[8].Split(":")[1].Trim()

		#hardware UUID
		$macInfoHardwareUUID = $macInfoSystemProfilerArrayList[9].Split(":")[1].Trim()

		#provisioning UUID
		$macInfoProvisioningUDID = $macInfoSystemProfilerArrayList[10].Split(":")[1].Trim()

		#activation Lock status
		$macInfoActivationLockStatus = $macInfoSystemProfilerArrayList[11].Split(":")[1].Trim()

		#model name
		$macInfoModelName = $macInfoSystemProfilerArrayList[0].Split(":")[1].Trim()

		#model Identfier
		$macInfoModelID = $macInfoSystemProfilerArrayList[1].Split(":")[1].Trim()

		#model number
		$macInfoModelNumber = $macInfoSystemProfilerArrayList[2].Split(":")[1].Trim()

		#CPU Model
		$macInfoCPUName = $macInfoSystemProfilerArrayList[3].Split(":")[1].Trim()

		#core count. We're going to split ito perf and efficiency
		$macInfoCPUCoreCount = $macInfoSystemProfilerArrayList[4].Split(":")[1].Trim()

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
		$macInfoRAMSize = $macInfoSystemProfilerArrayList[5].Split(":")[1].Trim()
	} else {
		#we want to start grabbing items. first we grab the EFI version, aka Boot ROM version. We only want the last part, so
		#we split on the colon, grab the second part [1]
          #trim all the whitespace from [1]
		#this is actually now referred to as the System Firmware Version, so we'll rename that one day
		$macInfoEFIVersion = $macInfoSystemProfilerArrayList[10].Split(":")[1].Trim()

		#split on the parens and grab the first entry [0] to get rid of the ibridge stuff
          #and get ride of any remaining whitespace
		$macInfoEFIVersion = $macInfoEFIVersion.Split("(")[0].Trim()

		#T2 Firmware Version
		$macInfoT2FirmwareVersion = $macInfoSystemProfilerArrayList[10].Split("(")[1]
		$macInfoT2FirmwareVersion = $macInfoT2FirmwareVersion.Split(":")[1].Trim()
		
          #get rid of the last ) character
		$macInfoT2FirmwareVersion = $macInfoT2FirmwareVersion.Substring(0,$macInfoT2FirmwareVersion.Length-1)

		#smc version
		#now the OS Loader version
		$macInfoSMCVersion = $macInfoSystemProfilerArrayList[11].Split(":")[1].Trim()
		
		#hardware serial number
		$macInfoHardwareSN = $macInfoSystemProfilerArrayList[12].Split(":")[1].Trim()
		
		#hardware UUID
		$macInfoHardwareUUID = $macInfoSystemProfilerArrayList[13].Split(":")[1].Trim()
		
		#provisioning UUID
		$macInfoProvisioningUDID = $macInfoSystemProfilerArrayList[14].Split(":")[1].Trim()
		
		#activation Lock status
		$macInfoActivationLockStatus = $macInfoSystemProfilerArrayList[15].Split(":")[1].Trim()
		
		#model name
		$macInfoModelName = $macInfoSystemProfilerArrayList[0].Split(":")[1].Trim()
          
		#model Identfier
		$macInfoModelID = $macInfoSystemProfilerArrayList[1].Split(":")[1].Trim()
		
		#CPU Model
		$macInfoCPUName = $macInfoSystemProfilerArrayList[2].Split(":")[1].Trim()
		
		#CPU Speed
		$macInfoCPUSpeed = $macInfoSystemProfilerArrayList[3].Split(":")[1].Trim()
		
		#CPU Count
		$macInfoCPUCount = $macInfoSystemProfilerArrayList[4].Split(":")[1].Trim()
		
		#core count
		$macInfoCPUCoreCount = $macInfoSystemProfilerArrayList[5].Split(":")[1].Trim()
		
		#L2 Cache Size
		$macInfoCPUL2CacheSize = $macInfoSystemProfilerArrayList[6].Split(":")[1].Trim()
		
		#L3 Cache size
		$macInfoL3CacheSize = $macInfoSystemProfilerArrayList[7].Split(":")[1].Trim()
		
		#hyperthreading status
		$macInfoHyperThreadingEnabled = $macInfoSystemProfilerArrayList[8].Split(":")[1].Trim()
		
		#RAM size
		$macInfoRAMSize = $macInfoSystemProfilerArrayList[9].Split(":")[1].Trim()
	}

	#apple pay info===============================================================================

	#get the applepay info from system profiler
	$applePayInfoArrayRaw = Invoke-Expression -Command "/usr/sbin/system_profiler SPSecureElementDataType"

	#shove into an arraylist, remove all the blank lines 
	[System.Collections.ArrayList]$applePayInfoArrayList = $applePayInfoArrayRaw.Split([Environment]::NewLine,$darwinVersionSplitOptions)

	#remove the first two lines that only say "Apple Pay"
	$applePayInfoArrayList.RemoveRange(0,2)

	#grab the platform ID line, item[0] split it on the :, grab the second element [1]
	#trim all leading/trailing whitespace from element[1]
	$applePayInfoPlatformID = $applePayInfoArrayList[0].Split(":")[1].Trim()

	#get the SEID the same way
	$applePayInfoSEID = $applePayInfoArrayList[1].Split(":")[1].Trim()

	#get systemOS SEID, apple Silicon Only and other Apple Silicon specific changes in this one
	if($isAppleSilicon) {
		#apple Silicon Only
		$applePayInfoSystemOSSEID = $applePayInfoArrayList[2].Split(":")[1].Trim()

		#Hardware
		$applePayInfoHardware = $applePayInfoArrayList[6].Split(":")[1].Trim()

		#firmware
		$applePayInfoFirmware = $applePayInfoArrayList[7].Split(":")[1].Trim()

		#JCOP OS version
		$applePayInfoJCOPOSVersion = $applePayInfoArrayList[8].Split(":")[1].Trim()

		##Apple Pay Controller Info
		#hardware version
		$applePayControllerHardwareVersion = $applePayInfoArrayList[10].Split(":")[1].Trim()

		#firmware version
		$applePayControllerFirmwareVersion = $applePayInfoArrayList[11].Split(":")[1].Trim()

		#middleWare version
		$applePayControllerMiddlewareVersion = $applePayInfoArrayList[12].Split(":")[1].Trim()
	} else {
		#Intel versions
		#Hardware
		$applePayInfoHardware = $applePayInfoArrayList[5].Split(":")[1].Trim()

		#firmware
		$applePayInfoFirmware = $applePayInfoArrayList[6].Split(":")[1].Trim()

		#JCOP OS version
		$applePayInfoJCOPOSVersion = $applePayInfoArrayList[7].Split(":")[1].Trim()

		##Apple Pay Controller Info
		#hardware version
		$applePayControllerHardwareVersion = $applePayInfoArrayList[9].Split(":")[1].Trim()

		#firmware version
		$applePayControllerFirmwareVersion = $applePayInfoArrayList[10].Split(":")[1].Trim()

		#middleWare version
		$applePayControllerMiddlewareVersion = $applePayInfoArrayList[11].Split(":")[1].Trim()
	}	

	#bluetooth info===============================================================================
	#get the applepay info from system profiler
	#Intel doesn't have the product ID
	$blueToothRaw = Invoke-Expression -Command "/usr/sbin/system_profiler SPBluetoothDataType"

	#shove into an arraylist, remove all the blank lines 
	[System.Collections.ArrayList]$blueToothArrayList = $blueToothRaw.Split([Environment]::NewLine,$darwinVersionSplitOptions)

	#remove the first two lines
	$blueToothArrayList.RemoveRange(0,2)

	#since the BluetoothMAC is colon-delimited, we can't just split on colons like usual
	#in this case, we're going to blank the leading spaces, then trim on the middle space
	#blank the leading spaces
	$blueToothMAC = $blueToothArrayList[0].TrimStart()

	#split on the only remaining space, grab the second element, [1] and remove its whitespace
	$blueToothMAC = $blueToothMAC.Split(" ")[1].Trim()

	#get the BT chipset
	$blueToothChipset = $blueToothArrayList[2].Split(":")[1].Trim()

	#get discoverable status
	$blueToothDiscoverable = $blueToothArrayList[3].Split(":")[1].Trim()

	#get firmware version
	$bluetoothFirmwareVersion = $blueToothArrayList[4].Split(":")[1].Trim()

	#start split between Apple Silicon and Intel
	

	if($isAppleSilicon) {
		#product ID
		$blueToothProductID = $blueToothArrayList[5].Split(":")[1].Trim()

		#supported services end up being weird and Apple Silicon has a one-off difference thanks to product ID
		$bluetoothSupportedServicesRaw = $blueToothArrayList[6].Split(":")[1].Trim()

		#get transport
		$blueToothTransport = $blueToothArrayList[7].Split(":")[1].Trim()

		#get vendor ID
		$blueToothVendorID = $blueToothArrayList[8].Split(":")[1].Trim()
	
	} else {
		#supported services end up being weird and Apple Silicon has a one-off difference thanks to product ID
		$bluetoothSupportedServicesRaw = $blueToothArrayList[5].Split(":")[1].Trim()

		#get transport
		$blueToothTransport = $blueToothArrayList[6].Split(":")[1].Trim()

		#get vendor ID
		$blueToothVendorID = $blueToothArrayList[7].Split(":")[1].Trim()
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

	#POST test section============================================================================
	##Intel Only, the datatype returns nothing on Apple Silicon
	if(-not $isAppleSilicon) {
		#get the POST data
		$POSTInfoRaw = Invoke-Expression -Command "/usr/sbin/system_profiler SPDiagnosticsDataType"

		#shove into an array list
		[System.Collections.ArrayList]$POSTInfoArrayList = $POSTInfoRaw.Split([Environment]::NewLine,$darwinVersionSplitOptions)

		#remove the first two lines
		$POSTInfoArrayList.RemoveRange(0,2)

		#trim leading/trailing whitespace from the first entry (date & time)
		$POSTInfoArrayList[0] = $POSTInfoArrayList[0].Trim()

		#split the date & time on space, this gives us 4 entries
		[System.Collections.ArrayList]$POSTInfoRunDateArrayList = $POSTInfoArrayList[0].Split(" ")

		#delete the first two entries
		$POSTInfoRunDateArrayList.RemoveRange(0,2)

		#now build a date & time string with ONLY the date and time
		$POSTInfoLastRunDate = $POSTInfoRunDateArrayList[0] + " " + $POSTInfoRunDateArrayList[1]

		#now get the last run results
		$POSTInfoLastRunResults = $POSTInfoArrayList[1].Split(":")[1].Trim()
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

	##test for apple sillcon here as well
	if($isAppleSilicon) {
		#into the (Apple Silcon) hashtable with you!
		$macInfoHash.Add("macOSBuildLabEx", $mainDarwinKernelVersion)
		$macInfoHash.Add(" "," ")
		$macInfoHash.Add("macOSCurrentVersion", $macInfoOSVersion)
		$macInfoHash.Add("macOSCurrentBuildNumber", $macInfoOSBuildNumber)
		$macInfoHash.Add("macOSProductName", $macInfoOSName)
		$macInfoHash.Add("  "," ")
		$macInfoHash.Add("macOSDarwinVersion", $mainDarwinKernelVersion)
		$macInfoHash.Add("   "," ")
		$macInfoHash.Add("SystemFirmwareVersion", $macInfoEFIVersion)
		$macInfoHash.Add("OSLoaderVersion", $macInfoSMCVersion)
		$macInfoHash.Add("HardwareSerialNumber", $macInfoHardwareSN)
		$macInfoHash.Add("HardwareUUID", $macInfoHardwareUUID)
		$macInfoHash.Add("ProvisioningUDID",$macInfoProvisioningUDID)
		$macInfoHash.Add("    "," ")
		$macInfoHash.Add("HardwareModelName", $macInfoModelName)
		$macInfoHash.Add("HardwareModelID", $macInfoModelID)
		$macInfoHash.Add("HardwareModelNumber", $macInfoModelNumber) #apple silicon only
		$macInfoHash.Add("ActivationLockStatus", $macInfoActivationLockStatus)
		$macInfoHash.Add("     "," ")
		$macInfoHash.Add("CPUArchitecture", $macInfoCPUArch)
		$macInfoHash.Add("CPUName" , $macInfoCPUName)
		$macInfoHash.Add("CPUTotalCoreCount", $macInfoCPUCoreCountTotal) #apple silicon only
		$macInfoHash.Add("CPUPerformanceCoreCount", $macInfoCPUPerformanceCoreCount) #apple silicon only
		$macInfoHash.Add("CPUEfficiencyCoreCount", $macInfoCPUEfficiencyCoreCount) #apple silicon only
		$macInfoHash.Add("CPUBrandString", $macInfoCPUBrand)
		$macInfoHash.Add("RAMAmount", $macInfoRAMSize)
		$macInfoHash.Add("      "," ")
		$macInfoHash.Add("ApplePayPlatformID", $applePayInfoPlatformID)
		$macInfoHash.Add("ApplePaySEID", $applePayInfoSEID)
		$macInfoHash.Add("ApplePaySystemOSSEID", $applePayInfoSystemOSSEID)#apple silicon only
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
		$macInfoHash.Add("BluetoothFirmwareVersion",$bluetoothFirmwareVersion)
		$macInfoHash.Add("BluetoothProductID", $blueToothProductID)
		$macInfoHash.Add("BluetoothSupportedServices",$bluetoothSupportedServices)
		$macInfoHash.Add("BluetoothTransport",$blueToothTransport)
		$macInfoHash.Add("BluetoothVendorID",$blueToothVendorID)
		$macInfoHash.Add("        "," ")
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
	} else {
		#into the (Intel) hashtable with you!
		$macInfoHash.Add("macOSBuildLabEx", $mainDarwinKernelVersion)
		$macInfoHash.Add(" "," ")
		$macInfoHash.Add("macOSCurrentVersion", $macInfoOSVersion)
		$macInfoHash.Add("macOSCurrentBuildNumber", $macInfoOSBuildNumber)
		$macInfoHash.Add("macOSProductName", $macInfoOSName)
		$macInfoHash.Add("  "," ")
		$macInfoHash.Add("macOSDarwinVersion", $mainDarwinKernelVersion)
		$macInfoHash.Add("   "," ")
		$macInfoHash.Add("SystemFirmwareVersion", $macInfoEFIVersion)
		$macInfoHash.Add("T2FirmwareVersion", $macInfoT2FirmwareVersion)
		$macInfoHash.Add("OSLoaderVersion", $macInfoSMCVersion)
		$macInfoHash.Add("HardwareSerialNumber", $macInfoHardwareSN)
		$macInfoHash.Add("HardwareUUID", $macInfoHardwareUUID)
		$macInfoHash.Add("ProvisioningUDID",$macInfoProvisioningUDID)
		$macInfoHash.Add("    "," ")
		$macInfoHash.Add("HardwareModelName", $macInfoModelName)
		$macInfoHash.Add("HardwareModelID", $macInfoModelID)
		$macInfoHash.Add("ActivationLockStatus", $macInfoActivationLockStatus)
		$macInfoHash.Add("     "," ")
		$macInfoHash.Add("CPUArchitecture", $macInfoCPUArch)
		$macInfoHash.Add("CPUName" , $macInfoCPUName)
		$macInfoHash.Add("CPUSpeed", $macInfoCPUSpeed) #Intel Only
		$macInfoHash.Add("CPUCount", $macInfoCPUCount) #Intel Only
		$macInfoHash.Add("CPUCoreCount", $macInfoCPUCoreCount)
		$macInfoHash.Add("CPUL2CacheSize", $macInfoCPUL2CacheSize) #Intel Only
		$macInfoHash.Add("CPUBrandString", $macInfoCPUBrand)
		$macInfoHash.Add("L3CacheSize", $macInfoL3CacheSize) #Intel Only
		$macInfoHash.Add("HyperThreadingEnabled", $macInfoHyperThreadingEnabled) #Intel Only
		$macInfoHash.Add("RAMAmount", $macInfoRAMSize)
		$macInfoHash.Add("      "," ")
		$macInfoHash.Add("ApplePayPlatformID", $applePayInfoPlatformID)
		$macInfoHash.Add("ApplePaySEID", $applePayInfoSEID)
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
		$macInfoHash.Add("BluetoothFirmwareVersion",$bluetoothFirmwareVersion)
		$macInfoHash.Add("BluetoothSupportedServices",$bluetoothSupportedServices)
		$macInfoHash.Add("BluetoothTransport",$blueToothTransport)
		$macInfoHash.Add("BluetoothVendorID",$blueToothVendorID)
		$macInfoHash.Add("        "," ")
		$macInfoHash.Add("POSTLastRunDate",$POSTInfoLastRunDate) #Intel Only
		$macInfoHash.Add("POSTLastRunResults",$POSTInfoLastRunResults) #Intel Only
		$macInfoHash.Add("         "," ")
		$macInfoHash.Add("AppMemoryUsedGB", $macInfoAppMemoryUsedGB)
		$macInfoHash.Add("VMPageFile", $macInfoVMPageFile)
		$macInfoHash.Add("VMSwapInUseGB", $macInfoVMSwapUsed)
		$macInfoHash.Add("          "," ")
		$macInfoHash.Add("BootDevice", $macInfoBootDevice)
		$macInfoHash.Add("FileVaultStatus", $macInfoFileVaultStatus)
		$macInfoHash.Add("SIPStatus", $csrutilStatus)
		$macInfoHash.Add("           "," ")
		$macInfoHash.Add("EFICurrentLanguage", $macInfoEFILanguage)
		$macInfoHash.Add("DSTStatus", $macInfoDSTStatus)
		$macInfoHash.Add("TimeZone", $macInfoTimeZone)
		$macInfoHash.Add("UTCOffset", $macInfoUTCOffset)
		$macInfoHash.Add("            "," ")
		$macInfoHash.Add("DNSHostName", $macInfoDNSHostName)
		$macInfoHash.Add("LocalHostName", $macInfoLocalHostName)
		$macInfoHash.Add("NetworkServiceList", $macInfoNICList)
		$macInfoHash.Add("             "," ")
		$macInfoHash.Add("CurrentUserName", $macInfoShortUserName)
		$macInfoHash.Add("CurrentUserUID", $macInfoUID)
		$macInfoHash.Add("              "," ")
		$macInfoHash.Add("CurrentDateTime", $macInfoCurrentDate)
		$macInfoHash.Add("LastBootDateTime", $macInfoLastBoot)
		$macInfoHash.Add("Uptime", $macInfoUptime)
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