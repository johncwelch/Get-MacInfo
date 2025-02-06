#get user name of person running the script
$macInfoShortUserName = /usr/bin/whoami

#build warranty folder path for current user
#we are absolutely not going to check other users
$warrantyFolderPath = "/Users/$macInfoShortUserName/Library/Application Support/com.apple.NewDeviceOutreach"

#this is hardcoded to save some lines, but there's ways to not do this
$hardwareModelName = "MacBook Pro"

#list of hashtable names
$theNamesArrayList = New-Object System.Collections.ArrayList

#does the path even exist, if not, exit
if (Test-Path -Path $warrantyFolderPath) {
	#if it exists, get a count of files
	$fileCount = (Get-ChildItem -Path $warrantyFolderPath -File).Count
	#if there's at least one file, proceed
	if ($fileCount -gt 0) {
		#get an array of file names with the newest file first
		$fileNameArray = /bin/ls -t $warrantyFolderPath
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

				#this is the only way to build multiple hashtables, one for each item that matches

				#create the hashtable name
				$theName = "warrantyHashTable$theIndex"
				
				#add to our arrayList. The out-null supresses the listing of the arraylist index number
				#in the output. It's just annoying is all
				$theNamesArrayList.Add($theName)|Out-Null
				
				#create a global hashtable
				Set-Variable -Name $theName -Scope Global

				#use get-variable so we can actually manipulate this since we can't directly
				$theHashTable = Get-Variable -Name $theName

				#make it an actual hashtable by manipulating the value
				$theHashTable.Value = [ordered]@{}

				#now we can add to the hashtable

				#now lets get the info and put it into something that is useful. Like another ordered hashtable!
				$theHashTable.Value.Add("HardwareModelName",$hardwareModelName)
				$theHashTable.Value.Add("hasCoverage",$warrantyInfo.covered)
				$theHashTable.Value.Add("AppleCareOfferEligible",$warrantyInfo.acOfferEligible)
				$theHashTable.Value.Add("AppleCareSubscription",$warrantyInfo.isAcSubscription)
				$theHashTable.Value.Add("coverageLabel",$warrantyInfo.coverageLocalizedLabel)
				$theHashTable.Value.Add("shortCoverageDesc",$warrantyInfo.coverageLocalizedDesc)
				$theHashTable.Value.Add("longCoverageDesc",$warrantyInfo.coverageLocalizedDescLong)
				$theHashTable.Value.Add("coverageExpirationLabel",$warrantyInfo.coverageLocalizedExpirationLabel)

				#check for coverage end date
				#this is in epoch time and an int64, but we don't care
				$coverageEndDate = $warrantyInfo.coverageEndDate
				if ($null -ne $coverageEndDate) {
					#there's SOMETHING there, let's get a human readable date
					#PowerShell can do this, but the number's not the same as the unix version,
					#and I think for our needs the "truth" would be the unix version. Actually, that's
					#wrong, the date in the warranty info for the System Preferences UI matches the
					#PowerShell version, so we're going to use that

					#Convert Unix Epoch time to "human" date and time the powershell way
					$coverageEndDate = (New-Object DateTime 1970,1,1,0,0,0).AddSeconds($coverageEndDate)
					#Get just the date from the DateTime object and format it sanely, i.e. 09 Mar 2025
					$coverageEndDate = $coverageEndDate.ToString("dd MMM yyyy")
					#add to the hashtable
					$theHashTable.Value.Add("coverageEndDate",$coverageEndDate)
				}
				#this will only get the first item that matches the hardware the script is running on
				#hopefully that's what works, there's no good way to have this
				#$theHashTable.Value 
			}
		}
	} else {
		write-output "no warranty files found"
	}
} else {
	write-output "no warranty info folder"
}


#now we iterate through the various hashtables and show their values
foreach ($warrantyHashName in $theNamesArrayList) { 
	$theWarrantyHashTable = Get-Variable -Name $warrantyHashName 
	$theTableName = $theWarrantyHashTable.Name
	Write-Output "Table Name: $theTableName"
	Write-Output $theWarrantyHashTable.Value
	Write-Output " "
}