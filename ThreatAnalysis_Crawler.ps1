# Vars
$outputDir = $PSScriptRoot
$url_array = @(`
            "https://feeds.feedburner.com/feedburner/Talos",`
            "https://feeds.feedburner.com/Unit42",`
            "https://blog.cloudflare.com/tag/security/rss",`
            "https://feeds.feedburner.com/eset/blog?format=xml",`
            "https://securityintelligence.com/feed/",`
            "http://feeds.trendmicro.com/TrendMicroSimplySecurity",`
            "https://blog.eclecticiq.com/rss.xml",`
            "https://www.intezer.com/blog/feed/",`
            "https://checkmarx.com/feed/",`
            "https://www.datadoghq.com/blog/index.xml"
)

$properties = @("title", "pubDate", "link")
$today = Get-Date
$dateThres = 14
$validIndex = @()
$results = @()
$validResults = @()

# Invoke request
foreach($url in $url_array){
    try{
        $response = Invoke-RestMethod $url
        $results += $response | Select-Object -Property $properties
        echo "[+] 크롤링 완료($url)"
    }
    catch{
        echo "[-] 오류 발생: $_($url)"
    }
}

# Parsing results
foreach($result in $results){
    foreach($property in $properties){
        try{
            if($property -eq "pubDate"){
                if((New-TimeSpan -Start ([datetime]$result.$property) -End $today).Days -lt $dateThres){
                    $validIndex += $results.IndexOf($result)
                }
                $result.$property = ([datetime]$result.$property).ToString('yyyy-MM-dd')
            }
            if($result.$property."#cdata-section"){
                $result.$property = $result.$property."#cdata-section"
            }
        }
        catch{
            echo "[-] 오류 발생: $_"
        }
    }
}

foreach($index in $validIndex){
    $validResults += $results[$index]
}

$validResults = $validResults | Sort-Object -Descending -Property pubDate

echo $validResults
echo `r`n

try{
    $validResults | Export-Csv -Encoding UTF8 -path $outputDir\Result.csv -NoTypeInformation
    echo "[+] 파일 저장됨.($outputDir\Result.csv)"
    $data = Import-Csv -Path $outputDir\Result.csv
    foreach ($item in $data) {
        $item.link = "<a href=$($item.link) target=`"_blank`">$($item.link)</a>"
    }
    $html = $data | ConvertTo-Html -Property title, pubDate, link -Title "ThreatAnalysis Sites" -Head "<link href=`"style.css`" rel=`"stylesheet`">"
    Add-Type -AssemblyName System.Web
    [System.Web.HttpUtility]::HtmlDecode($html) | Set-Content -path $outputDir\ThreatAnalysis-Sites.html
    echo "[+] 파일 저장됨.($outputDir\ThreatAnalysis-Sites.html)"
}
catch{
    echo "[-] 파일 저장 오류.($_)"
}
finally{
    echo "[+] 프로세스 종료.($($MyInvocation.MyCommand.Path))"
}