
$macInfoShortUserName = /usr/bin/whoami

#build warranty folder path for current user
#we are absolutely not going to check other users
$warrantyFolderPath = "/Users/$macInfoShortUserName/Library/Application Support/com.apple.NewDeviceOutreach"
$hardwareModelName = "MacBook Pro"
$warrantyHashTable = [ordered]@{}

#does the path even exist, if not, exit
if (Test-Path -Path $warrantyFolderPath) {
	#if it exists, get a count of files
	$fileCount = (Get-ChildItem -Path $warrantyFolderPath -File).Count
	#if there's at least one file, proceed
	if ($fileCount -gt 0) {
		#get an array of file names with the newest file first
		$fileNameArray = ls -t $warrantyFolderPath
		#okay, so here's the thing: you may have multiple warranty files for your stuff. I have two for my airpods
		#and one each for my MBPs. So we have to make a choice. We're going to go with the newest file
		#that matches the model of the mac we're running this on. If I come up with a better/more reliable/less fragile
		#method, we'll use that.

		#iterate through the files
		foreach ($warrantyFile in $fileNameArray) {
			#get the index, we'll need that
			$theIndex = [array]::IndexOf($fileNameArray,$warrantyFile)

			#use plutil to create a json version of the plist file in /tmp with the name "warranty$theIndex.json"
			/usr/bin/plutil -convert json "$warrantyFolderPath/$warrantyFile" -r -o "/tmp/warranty$theIndex.json"

			#get the contents of that file, this is an array
			$warrantyFileRaw = Get-Content -Path "/tmp/warranty$theIndex.json"

			#convert to a string
			$warrantyFileString = $warrantyFileRaw|Out-String

			#use this to convert to an ordered hashtable that really isn't JSON, but works really well for our needs
			$warrantyInfo = ConvertFrom-Json -InputObject $warrantyFileString -AsHashtable

			#is the deviceDesc the same as the hardware model we're running the command on. If it is, cool,
			#we pull data. If not, we go to the next one. Hopefully ONE of these matches
			if ($warrantyInfo.deviceInfo.deviceDesc -eq $hardwareModelName) {
				#now lets get the info and put it into something that is useful. Like another ordered hashtable!
				$warrantyHashTable.Add("hasCoverage",$warrantyInfo.covered)
				$warrantyHashTable.Add("AppleCareOfferEligible",$warrantyInfo.acOfferEligible)
				$warrantyHashTable.Add("AppleCareSubscription",$warrantyInfo.isAcSubscription)
				$warrantyHashTable.Add("coverageLabel",$warrantyInfo.coverageLocalizedLabel)
				$warrantyHashTable.Add("shortCoverageDesc",$warrantyInfo.coverageLocalizedDesc)
				$warrantyHashTable.Add("longCoverageDesc",$warrantyInfo.coverageLocalizedDescLong)
				$warrantyHashTable.Add("coverageExpirationLabel",$warrantyInfo.coverageLocalizedExpirationLabel)

				#check for coverage end date
				#this is in epoch time and an int64, but we don't care
				$coverageEndDate = $warrantyInfo.coverageEndDate
				if ($null -ne $coverageEndDate) {
					#there's SOMETHING there, let's get a human readable date
					#PowerShell can do this, but the number's not the same as the unix version,
					#and I think for our needs the "truth" would be the unix version

					#and now it's a string!
					$coverageEndDate = date -jf %s $coverageEndDate "+%F"
					$warrantyHashTable.Add("coverageEndDate",$coverageEndDate)
				}
			}
			break 
		}
	} else {
		write-output "no warranty files found"
	}
} else {
	write-output "no warranty info folder"
}
$warrantyHashTable