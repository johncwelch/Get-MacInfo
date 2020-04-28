#!/usr/bin/env pwsh

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

$macInfoHash = @{}

#uname section============================

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

#lets get the kernel build info and shove it into the hashtable
$tempString = $mainDarwinVersionArray[10]
$macInfoHash.Add("macOSBuildLabEx", $tempString)

#get the kernel version info
$tempString = $mainDarwinVersionArray[3]
#since that will end with a colon, strip the last character off the temp string
$mainDarwinKernelVersion = $tempString.Substring(0,$tempString.Length-1)


#get CPU Architecture
$macInfoCPUArch = Invoke-Expression -Command "/usr/bin/uname -m"

#sw_ver section===============================================================


#now, let's get some basic higher-level info
$macInfoOSVersion = Invoke-Expression -Command "/usr/bin/sw_vers -productVersion"
$macInfoOSBuildNumber = Invoke-Expression -Command "/usr/bin/sw_vers -buildVersion"
$macInfoOSName = Invoke-Expression -Command "/usr/bin/sw_vers -productName"

#shove them into the hashTable
$macInfoHash.Add("macOSCurrentVersion", $macInfoOSVersion)
$macInfoHash.Add("macOSCurrentBuildNumber", $macInfoOSBuildNumber)
$macInfoHash.Add("macOSProductName", $macInfoOSName)

#system_profiler section=========================================================

#now, let's get our system_profiler info
$macInfoSystemProfilerRaw = Invoke-Expression -Command "/usr/sbin/system_profiler SPHardwareDataType"

#we want to shove this into an array and remove blank lines. Luckily, we have the remove blank lines option from an earlier step,
#so we can just reuse that. We also want to have the split command just split on a new line. 
#the [Environment]::NewLine parameter handles splitting on a new line.
$macInfoSystemProfilerArray = $macInfoSystemProfilerRaw.Split([Environment]::NewLine,$darwinVersionSplitOptions)

#now we have to get clever. So we're going to put this array into an arraylist so we can arbitrarily remove items we don't need.
#yes, it's a memory hog, but this is a very tiny array

[System.Collections.ArrayList]$macInfoSystemProfilerArrayList = $macInfoSystemProfilerArray 

#now we remove the first two items. Note that RemoveRange parameters read as (startingIndex,numberofItemsToRemove)
$macInfoSystemProfilerArrayList.RemoveRange(0,2)

#we want to start grabbing items. first we grab the EFI version, aka Boot ROM version. We only want the last part, so
#we split on the colon, and grab the second part [1]
$macInfoEFIVersion = $macInfoSystemProfilerArrayList[9].Split(":")[1]

#now we trim the leading space. If we don't put anything in the parens, it just yoinks the first character
$macInfoEFIVersion = $macInfoEFIVersion.TrimStart()

#smc version
$macInfoSMCVersion = $macInfoSystemProfilerArrayList[10].Split(":")[1]
$macInfoSMCVersion = $macInfoSMCVersion.TrimStart()

#hardware serial number
$macInfoHardwareSN = $macInfoSystemProfilerArrayList[11].Split(":")[1]
$macInfoHardwareSN = $macInfoHardwareSN.TrimStart()

#hardware UUID
$macInfoHardwareUUID = $macInfoSystemProfilerArrayList[12].Split(":")[1]
$macInfoHardwareUUID = $macInfoHardwareUUID.TrimStart()

#model name
$macInfoModelName = $macInfoSystemProfilerArrayList[0].Split(":")[1]
$macInfoModelName = $macInfoModelName.TrimStart()

#model Identfier
$macInfoModelID = $macInfoSystemProfilerArrayList[1].Split(":")[1]
$macInfoModelID = $macInfoModelID.TrimStart()

#CPU Model
$macInfoCPUName = $macInfoSystemProfilerArrayList[2].Split(":")[1]
$macInfoCPUName = $macInfoCPUName.TrimStart()

#CPU Speed
$macInfoCPUSpeed = $macInfoSystemProfilerArrayList[3].Split(":")[1]
$macInfoCPUSpeed = $macInfoCPUSpeed.TrimStart()

# CPU Count
$macInfoCPUCount = $macInfoSystemProfilerArrayList[4].Split(":")[1]
$macInfoCPUCount = $macInfoCPUCount.TrimStart()

#core count
$macInfoCPUCoreCount = $macInfoSystemProfilerArrayList[5].Split(":")[1]
$macInfoCPUCoreCount = $macInfoCPUCoreCount.TrimStart()

#L2 Cache Size
$macInfoCPUL2CacheSize = $macInfoSystemProfilerArrayList[6].Split(":")[1]
$macInfoCPUL2CacheSize = $macInfoCPUL2CacheSize.TrimStart()

#L3 Cache size
$macInfoL3CacheSize = $macInfoSystemProfilerArrayList[7].Split(":")[1]
$macInfoL3CacheSize = $macInfoL3CacheSize.TrimStart()

$macInfoRAMSize = $macInfoSystemProfilerArrayList[8].Split(":")[1]
$macInfoRAMSize = $macInfoRAMSize.TrimStart()

#sysctl section===============================================================================
$macInfoCPUBrand = Invoke-Expression -Command "/usr/sbin/sysctl -n machdep.cpu.brand_string"

#other section================================================================================
$macInfoBootDevice = Invoke-Expression -Command "/usr/sbin/bless --info --getboot"

#get the current language
$macInfoEFILanguage = (Get-Culture).DisplayName


#into the hashtable with you!
$macInfoHash.Add("macOSDarwinVersion", $mainDarwinKernelVersion)
$macInfoHash.Add("CPUArchitecture", $macInfoCPUArch)

$macInfoHash.Add("EFIVersion", $macInfoEFIVersion)
$macInfoHash.Add("SMCVersion", $macInfoSMCVersion)
$macInfoHash.Add("HardwareSerialNumber", $macInfoHardwareSN)
$macInfoHash.Add("HardwareUUID", $macInfoHardwareUUID)
$macInfoHash.Add("EFICurrentLanguage", $macInfoEFILanguage)
$macInfoHash.Add("HardwareModelName", $macInfoModelName)
$macInfoHash.Add("HardwareModelID", $macInfoModelID)
$macInfoHash.Add("CPUName" , $macInfoCPUName)
$macInfoHash.Add("CPUSpeed", $macInfoCPUSpeed)
$macInfoHash.Add("CPUCount", $macInfoCPUCount)
$macInfoHash.Add("CPUCoreCount", $macInfoCPUCoreCount)
$macInfoHash.Add("CPUL2CacheSize", $macInfoCPUL2CacheSize)
$macInfoHash.Add("L3CacheSize", $macInfoL3CacheSize)
$macInfoHash.Add("RAMAmount", $macInfoRAMSize)

$macInfoHash.Add("CPUBrandString", $macInfoCPUBrand)
$macInfoHash.Add("BootDevice", $macInfoBootDevice)


$macInfoHash