#xmlstuff
$filePath = "/Users/jwelch/testxml.xml"
[xml]$theXMLFile = Get-Content $filePath

<# $theXMLFile.books.book.author
Write-Output "`n"
$theXMLFile.books.book[1].author #> #>

$theNodes = $theXMLFile.SelectNodes("//book")
$theNodes.GetType()
$theNodes[0]

$theNodes[0].title = "Some other book"

$theNodes[0].title 
$theXMLFile.Save($filePath)