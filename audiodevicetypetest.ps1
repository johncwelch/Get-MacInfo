$audioDataTypeRaw = system_profiler SPAudioDataType -detailLevel full -json
$audioDataTypeString = $audioDataTypeRaw|Out-String
$audioDataTypeJson = ConvertFrom-Json -InputObject $audioDataTypeString

#array of PS Custom Objects
$audioDeviceObjectList = $audioDataTypeJson[0].SPAudioDataType[0]._items

#create a pscustomobjectlist
#$audioDeviceHashList = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
$audioDeviceNameList = [System.Collections.Generic.List[string]]::new()

#create empty ordered dictionary
#$tempDict = [ordered]@{}

foreach ($object in $audioDeviceObjectList) {
	$audioDeviceNameList.Add($object[0]._name)
}

$theAudioDevices = @{AudioDeviceList = $audioDeviceNameList}
$theAudioDevices

#go through the object array, this gets every property for an audio device, we don't need that
<# foreach ($object in $audioDeviceObjectList) {
	
	#go through the individual object and dump it into a hashtable
	foreach ($device in $object.psobject.Properties.Name) {
		$tempDict[$device] = $object.$device
	}
	#$audioDeviceHashList.Add("Device Name",$tempDict._name)

	$audioDeviceHashList.Add($tempDict)
	
} #>

#list of hashtables, one per audio device

#$audioDeviceHashList
#$finalDict = [ordered]@{}
#$finalDict.Add("audiodevicelist",$audioDeviceHashList)
#$finalDict

#iterate through a pscustom object and pull an ordered dictionary from it
#foreach ($item in $audioDeviceObjectList[0].psobject.Properties.Name) {
#	$tempDict[$item] = $audioDeviceObjectList[0].$item
#}



#get json for SPAudioDataType
#$audioJson[0].SPAudioDataType[0]._items gives the full list of audio devices the mac knows about
#$audioJson[0].SPAudioDataType[0]._items.length is count of items
#$theAudioDevices = $audioJson[0].SPAudioDataType[0]._items is an array of psobjets where each object is an audio device
#create an ordered hashtable to hold data $myAudioHash = [ordered]@{}
#it's an array of pscustomobjets
#foreach ($device in $theAudioDevices ) {
#
#}