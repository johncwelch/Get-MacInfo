#hashTable
$myHashTable = @{}
$myOrderedHashTable = [Ordered]@{}
#$myOrderedHashTable = [System.Collections.Specialized.OrderedDictionary]@{}

$myHashTable.GetType()
$myOrderedHashTable.GetType()
Write-Output "`n"

$myHashTable.Add("firstValue","1")
$myHashTable.Add("secondValue","string")
#$myHashTable
#Write-Output "`n"

#$myHashTable.Keys
#$myHashTable.firstValue
#$myHashTable.secondValue
#Write-Output "`n"

$myHashTable["firstValue"]
Write-Output "`n"

$myHashTable = $myHashTable + @{thirdValue="3"}
$myHashTable
Write-Output "`n"

foreach($key in $myHashTable.Keys) {
     "The value of '$Key' is: $($myHashTable[$Key])"
}
#Write-Output "`n"

#$myHashTable.Keys | ForEach-Object {
#     "The value of '$_' is: $($myHashTable[$_])"
#}
#Write-Output "`n"

$myOrderedHashTable.Add("secondValue","string")
$myOrderedHashTable.Add("firstValue","1")
$myOrderedHashTable.Add("thirdValue","3")

$myOrderedHashTable.Keys