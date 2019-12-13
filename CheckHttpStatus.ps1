[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$path = $PSScriptRoot + '\'
$file = 'http.txt'
$resultfile = 'http.result.csv'
$count = 0
$timeout = 7

if (![System.IO.File]::Exists($path + $resultfile)) {
    New-Item -Path $path -Name $resultfile
}
else {
    Clear-Content -Path $path$resultfile
}

$urls = (Get-Content -path $path$file).ToLower().Replace('www.','') | Sort-Object | Get-Unique
$urlCount = $urls.Count

foreach ($url in $urls) {
    try {
        $request = Invoke-WebRequest $url -ErrorAction Ignore -TimeoutSec $timeout -UseBasicParsing #-MaximumRedirection 0
        $result = $url + ',' + $request.StatusCode + ',' + $request.StatusDescription + ',' + $request.BaseResponse.ProtocolVersion.Major + `
            '.' + $request.BaseResponse.ProtocolVersion.Minor + ',' + $request.BaseResponse.Server + ',' + $request.BaseResponse.ResponseUri.AbsoluteURI + ',' + $request.BaseResponse.ResponseUri.Host
    }
    catch {
        
        $e = ($_ -split '\n')[0]

        if ((($_ -split '\n')[0]).Contains("Bad Request")) {
            $http = 400
        }
        elseif ((($_ -split '\n')[0]).Contains("401") -or (($_ -split '\n')[0]).Contains("Unauthorized")) {
            $http = 401
        }
        elseif ((($_ -split '\n')[0]).Contains("Forbidden") -or (($_ -split '\n')[0]).Contains("You do not have permission")) {
            $http = 403
        }
        elseif ((($_ -split '\n')[0]).Contains("404") -or (($_ -split '\n')[0]).Contains("Not Found") -or (($_ -split '\n')[0]).Contains("not found") `
                -or (($_ -split '\n')[0]).Contains("could be found") -or (($_ -split '\n')[0]).Contains("The resource you are looking for has been removed")) {
            $http = 404
            $e = ($_ -split '\n')[4]
        }
        elseif ((($_ -split '\n')[0]).Contains("Unable to connect to the remote server") -or (($_ -split '\n')[0]).Contains("The operation has timed out.")) {       
            $http = 408
        }
        elseif ((($_ -split '\n')[0]).Contains("Server Error")) {        
            $http = 500
        }
        elseif ((($_ -split '\n')[0]).Contains("Service Unavailable")) {        
            $http = 503
        }
        else {
            $http = ''
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