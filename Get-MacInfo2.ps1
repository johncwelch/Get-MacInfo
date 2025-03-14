#!/usr/bin/env pwsh

<#
.SYNOPSIS
This is a powershell script for macOS that replicates, or tries to, the "Get-ComputerInfo" command for Windows Powershell

.DESCRIPTION
It's not a 1:1 replication, some of it wouldn't make any sense on a Mac. Also, it does check to make sure it's running
on a mac. This pulls information from a variet of sources, including uname, sysctl, AppleScript, sw_ver, system_profiler,
and some built-in powershell functions. It shoves it all into an ordered hashtable so there's some coherency in the output.
If you run the script without any parameters, you get all the items in the hashtable. If you provide one key as a parameter, 
you get the informatio for that key. You can provide a comma-separated list of keys and you'll get that as a result.

Current keys are:
macOSBuildLabEx
macOSCurrentVersion
macOSCurrentBuildNumber
macOSProductName
macOSDarwinVersion
EFIVersion
SMCVersion
HardwareSerialNumber
HardwareUUID
HardwareModelName
HardwareModelID
CPUArchitecture
CPUName
CPUSpeed
CPUCount
CPUCoreCount
CPUL2CacheSize
CPUBrandString
L3CacheSize
RAMAmount
AppMemoryUsedGB
VMPageFile
VMSwapInUseGB
BootDevice
FileVaultStatus
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
./Get-MacInfo.ps1

.NOTES
This will eventually be a module for folks using Powershell on the mac. It's a really useful language and should be of great use
to scripters. 

.LINK
https://github.com/johncwelch/Get-MacInfo
#>
#function Get-MacInfo {
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

     #lets get the kernel build info
     $tempString = $mainDarwinVersionArray[10]


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

     #filevault status
     $macInfoFileVaultStatus = Invoke-Expression -Command "/usr/bin/fdesetup status"
     ##get last word of return
     $macInfoFileVaultStatus = $macInfoFileVaultStatus.Split(" ")[-1]
     ##trim trailing period
     $macInfoFileVaultStatus = $macInfoFileVaultStatus.TrimEnd(".")

     #DNS host name
     $macInfoDNSHostName = Invoke-Expression -Command "/usr/sbin/scutil --get HostName"

     #local machine name
     $macInfoLocalHostName = Invoke-Expression -Command "/usr/sbin/scutil --get ComputerName"

     #get a list of network services. This takes a few steps. First, get the list and put it into an array
     ##this does a lot of things. It runs the networksetup - listallnetworkservices, then splits that output into an array,
     ##one entry per line and removes blank lines
     $macInfoNICList = (Invoke-Expression -Command "/usr/sbin/networksetup -listallnetworkservices").Split([Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)

     ##now we remove the first line, which is unnecessary for our needs
     ##and yes, i know this is not technically a nic list, but it will work for our needs
     ##and it grabs services that don't have ports that -listallhardwareports would have, like iPhone USB
     $macInfoNICList = $macInfoNICList[1..($macInfoNICList.length - 1)]

     ##now, mung the array into a single string with a comma-space separating each entry
     $macInfoNICList = $macInfoNICList -join ', ';

     #using powershell -> bash -> applescript
     #get current user name
     $macInfoShortUserName = Invoke-Expression -Command '/usr/bin/osascript -e "get short user name of (system info)"'

     #get current user UID
     $macInfoUID = Invoke-Expression -Command '/usr/bin/osascript -e "get user ID of (system info)"'

     #get current date and time
     $macInfoCurrentDate = Get-Date

     #get last boot time
     ##run who -b, but splite on a space since you only get back a single line.
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


     #into the hashtable with you!
     $macInfoHash.Add("macOSBuildLabEx", $mainDarwinKernelVersion)

     $macInfoHash.Add("macOSCurrentVersion", $macInfoOSVersion)
     $macInfoHash.Add("macOSCurrentBuildNumber", $macInfoOSBuildNumber)
     $macInfoHash.Add("macOSProductName", $macInfoOSName)

     $macInfoHash.Add("macOSDarwinVersion", $mainDarwinKernelVersion)


     $macInfoHash.Add("EFIVersion", $macInfoEFIVersion)
     $macInfoHash.Add("SMCVersion", $macInfoSMCVersion)
     $macInfoHash.Add("HardwareSerialNumber", $macInfoHardwareSN)
     $macInfoHash.Add("HardwareUUID", $macInfoHardwareUUID)

     $macInfoHash.Add("HardwareModelName", $macInfoModelName)
     $macInfoHash.Add("HardwareModelID", $macInfoModelID)

     $macInfoHash.Add("CPUArchitecture", $macInfoCPUArch)
     $macInfoHash.Add("CPUName" , $macInfoCPUName)
     $macInfoHash.Add("CPUSpeed", $macInfoCPUSpeed)
     $macInfoHash.Add("CPUCount", $macInfoCPUCount)
     $macInfoHash.Add("CPUCoreCount", $macInfoCPUCoreCount)
     $macInfoHash.Add("CPUL2CacheSize", $macInfoCPUL2CacheSize)
     $macInfoHash.Add("CPUBrandString", $macInfoCPUBrand)
     $macInfoHash.Add("L3CacheSize", $macInfoL3CacheSize)
     $macInfoHash.Add("RAMAmount", $macInfoRAMSize)


     $macInfoHash.Add("AppMemoryUsedGB", $macInfoAppMemoryUsedGB)
     $macInfoHash.Add("VMPageFile", $macInfoVMPageFile)
     $macInfoHash.Add("VMSwapInUseGB", $macInfoVMSwapUsed)

     $macInfoHash.Add("BootDevice", $macInfoBootDevice)
     $macInfoHash.Add("FileVaultStatus", $macInfoFileVaultStatus)

     $macInfoHash.Add("EFICurrentLanguage", $macInfoEFILanguage)
     $macInfoHash.Add("DSTStatus", $macInfoDSTStatus)
     $macInfoHash.Add("TimeZone", $macInfoTimeZone)
     $macInfoHash.Add("UTCOffset", $macInfoUTCOffset)

     $macInfoHash.Add("DNSHostName", $macInfoDNSHostName)
     $macInfoHash.Add("LocalHostName", $macInfoLocalHostName)
     $macInfoHash.Add("NetworkServiceList", $macInfoNICList)

     $macInfoHash.Add("CurrentUserName", $macInfoShortUserName)
     $macInfoHash.Add("CurrentUserUID", $macInfoUID)

     $macInfoHash.Add("CurrentDateTime", $macInfoCurrentDate)
     $macInfoHash.Add("LastBootDateTime", $macInfoLastBoot)
     $macInfoHash.Add("Uptime", $macInfoUptime)

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
#}

#Export-ModuleMember -Function Get-MacInfo