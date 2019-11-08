[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$path = "C:\Users\nathan.mitchell\Documents\http\"
$totalURL = Get-content -Path $path'http.txt' | Measure-Object –Line
$count = 0

Set-Content -Path $path'result.csv' -Value 'Domain,HTTP Code,Description,Protocol Version,Server,Redirect Location'

foreach($url in [System.IO.File]::ReadLines($path+'http.txt')) {

    try {

        $request = Invoke-WebRequest $url -MaximumRedirection 0 -ErrorAction Ignore -TimeoutSec 1

        $result = $url + ',' + $request.StatusCode + ',' + $request.StatusDescription + ',' + $request.BaseResponse.ProtocolVersion.Major + '.' + $request.BaseResponse.ProtocolVersion.Minor + ',' + $request.BaseResponse.Server + ',' +$request.Headers.Location

    } catch {

        if ((($_ -split '\n')[0]).Contains("401") -or (($_ -split '\n')[0]).Contains("Unauthorized")) {

            $result = $url + ',401,' + ($_ -split '\n')[0]

        } elseif ((($_ -split '\n')[0]).Contains("Forbidden") -or (($_ -split '\n')[0]).Contains("You do not have permission")) {
          # -or (($_ -split '\n')[1]).Contains("403")
            $result = $url + ',403,' + ($_ -split '\n')[0]

        } elseif ((($_ -split '\n')[0]).Contains("404") -or (($_ -split '\n')[0]).Contains("Not Found") -or (($_ -split '\n')[0]).Contains("not found") -or (($_ -split '\n')[0]).Contains("could be found") -or (($_ -split '\n')[0]).Contains("The resource you are looking for has been removed")) {

            $result = $url + ',404,' + ($_ -split '\n')[4]

        } elseif (($_ -split '\n')[0] -eq "Unable to connect to the remote server") {
        
            $result = $url + ',408,' + ($_ -split '\n')[0]

        } elseif ((($_ -split '\n')[0]).Contains("Server Error")) {
        
            $result = $url + ',500,' + ($_ -split '\n')[0] 

        } elseif ((($_ -split '\n')[0]).Contains("Service Unavailable")) {
        
            $result = $url + ',503,' + ($_ -split '\n')[0] 

        } else {

            $result = $url + ',else,' + ($_ -split '\n')[0]

        }
             #try { $curl = curl kentuckyp20.ky.gov -MaximumRedirection 0 -ErrorAction Ignore } catch { ($_ ) }
    }

    Add-Content -Path $path'result.csv' -Value $result

    $count++
    $count 
    $result

}