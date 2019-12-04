[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$path = "C:\Users\Owner\Downloads\Spider-master\Spider-master\"
$file = 'sub.ky.txt'
$resultfile = 'http.result.csv'
$count = 0
$timeout = 1

if (![System.IO.File]::Exists($path + $resultfile)) {
	New-Item -Path $path -Name $resultfile
}

foreach($url in [System.IO.File]::ReadLines($path+$file)) {
    try {
        $request = Invoke-WebRequest $url -MaximumRedirection 0 -ErrorAction Ignore -TimeoutSec $timeout -UseBasicParsing
        $result = $url + ',' + $request.StatusCode + ',' + $request.StatusDescription + ',' + $request.BaseResponse.ProtocolVersion.Major + '.' + $request.BaseResponse.ProtocolVersion.Minor + ',' + $request.BaseResponse.Server + ',' +$request.Headers.Location
    } catch {
        if ((($_ -split '\n')[0]).Contains("Bad Request")) {
            $result = $url + ',400,' + ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("401") -or (($_ -split '\n')[0]).Contains("Unauthorized")) {
            $result = $url + ',401,' + ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("Forbidden") -or (($_ -split '\n')[0]).Contains("You do not have permission")) {
            $result = $url + ',403,' + ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("404") -or (($_ -split '\n')[0]).Contains("Not Found") -or (($_ -split '\n')[0]).Contains("not found") -or (($_ -split '\n')[0]).Contains("could be found") -or (($_ -split '\n')[0]).Contains("The resource you are looking for has been removed")) {
            $result = $url + ',404,' + ($_ -split '\n')[4]
        } elseif ((($_ -split '\n')[0]).Contains("Unable to connect to the remote server") -or (($_ -split '\n')[0]).Contains("The operation has timed out.")) {       
            $result = $url + ',408,' + ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("Server Error")) {        
            $result = $url + ',500,' + ($_ -split '\n')[0] 
        } elseif ((($_ -split '\n')[0]).Contains("Service Unavailable")) {        
            $result = $url + ',503,' + ($_ -split '\n')[0] 
        } else {
            $result = $url + ',,' + ($_ -split '\n')[0]
        }
    }
    Add-Content -Path $path$resultfile -Value $result
    $count++
    $count 
    $result
}

$content = Get-Content -Path $path$resultfile | Sort-Object | Get-Unique
Clear-Content -Path $path$resultfile
Set-Content -Path $path$resultfile -Value 'Domain,HTTP Code,Description,Protocol Version,Server,Redirect Location'
foreach ($c in $content) {
    Add-Content -Path $path$resultfile -Value $c
}