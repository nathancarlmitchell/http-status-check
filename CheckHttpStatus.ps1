[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$path = 'C:\Users\nathan.mitchell\Documents\Spider\'
$file = 'http.txt'
$resultfile = 'http.result.csv'
$count = 0
$timeout = 1

$urls = Get-Content -path $path$file
$urlCount = $urls.Count

if (![System.IO.File]::Exists($path + $resultfile)) {
	New-Item -Path $path -Name $resultfile
} else {
    Clear-Content -Path $path$resultfile
}

foreach($url in [System.IO.File]::ReadLines($path+$file)) {
    try {
        $request = Invoke-WebRequest $url -ErrorAction Ignore -TimeoutSec $timeout -UseBasicParsing #-MaximumRedirection 0
        $result = $url + ',' + $request.StatusCode + ',' + $request.StatusDescription + ',' + $request.BaseResponse.ProtocolVersion.Major + `
            '.' + $request.BaseResponse.ProtocolVersion.Minor + ',' + $request.BaseResponse.Server + ',' +$request.BaseResponse.ResponseUri.AbsoluteURI + ',' + $request.BaseResponse.ResponseUri.Host
    } catch {
        if ((($_ -split '\n')[0]).Contains("Bad Request")) {
            $http = 400
            $e = ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("401") -or (($_ -split '\n')[0]).Contains("Unauthorized")) {
            $http = 401
            $e = ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("Forbidden") -or (($_ -split '\n')[0]).Contains("You do not have permission")) {
            $http = 403
            $e = ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("404") -or (($_ -split '\n')[0]).Contains("Not Found") -or (($_ -split '\n')[0]).Contains("not found") `
            -or (($_ -split '\n')[0]).Contains("could be found") -or (($_ -split '\n')[0]).Contains("The resource you are looking for has been removed")) {
            $http = 404
            $e = ($_ -split '\n')[4]
        } elseif ((($_ -split '\n')[0]).Contains("Unable to connect to the remote server") -or (($_ -split '\n')[0]).Contains("The operation has timed out.")) {       
            $http = 408
            $e = ($_ -split '\n')[0]
        } elseif ((($_ -split '\n')[0]).Contains("Server Error")) {        
            $http = 500
            $e = ($_ -split '\n')[0] 
        } elseif ((($_ -split '\n')[0]).Contains("Service Unavailable")) {        
            $http = 503
            $e = ($_ -split '\n')[0] 
        } else {
            $http = ''
            $e = ($_ -split '\n')[0]
        }
        $result = $url + ',' + $http + ',' + $e
    }
    Add-Content -Path $path$resultfile -Value $result

	$progress = ($count / $urlCount) * 100
	$progress = "{0:n2}" -f $progress
	Write-Progress -Activity "Search in Progress: $url" -Status "Complete: $progress%" -PercentComplete $progress

    $count++
    $result
}

$content = Get-Content -Path $path$resultfile | Sort-Object | Get-Unique
Clear-Content -Path $path$resultfile
Set-Content -Path $path$resultfile -Value 'Domain,HTTP Code,Description,Protocol Version,Server,Redirect URI,Redirect Domain'
foreach ($c in $content) {
    Add-Content -Path $path$resultfile -Value $c
}