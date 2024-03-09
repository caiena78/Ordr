Add-Type -AssemblyName System.Web

function Encode-URL {
    param(
        [string]$baseUrl,
        [string[]]$queryParams
    )

    $encodedQueryParams = @()
    foreach ($param in $queryParams) {
        $paramParts = $param -split '='
        $encodedKey = [System.Web.HttpUtility]::UrlEncode($paramParts[0])
        $encodedValue = [System.Web.HttpUtility]::UrlEncode($paramParts[1])
        $encodedQueryParams += "$encodedKey=$encodedValue"
    }
    
    $encodedUrl = $baseUrl + '?' + ($encodedQueryParams -join '&')
    return $encodedUrl
}

function Query-API {
    param(
        [string]$encodedUrl,
        [string]$username,
        [string]$password
    )

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

    try {
        $response = Invoke-RestMethod -Uri $encodedUrl -Headers @{
            Authorization = "Basic $base64AuthInfo"
        } -Method Get -ContentType "application/json"
        
        return $response
    } catch {
        Write-Host "Error occurred: $_" -ForegroundColor Red
    }
}


function Prompt-UserInput {
    param(
        [string]$prompt
    )

    Write-Host $prompt -NoNewline
    return Read-Host
}


function Check-EnvironmentVariables {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Variables
    )

    foreach ($var in $Variables) {
        if (-not (Test-Path "env:$var")) {
            # throw "Environment variable '$var' does not exist."
            # Exit 1
            Write-Host " "
            Write-Host " "
            Write-Host  "Environment variable '$var' does not exist."
            Write-Host " "
            Write-Host " "
            Exit 1
        }
    }
    
}


function Combine-Url {
    param (
        [Parameter(Mandatory=$true)]
        [string]$BaseUrl,
        [Parameter(Mandatory=$true)]
        [string]$ApiLocation
    )

    # Trim any trailing slashes from the base URL and API location
    $BaseUrl = $BaseUrl.TrimEnd('/')
    $ApiLocation = $ApiLocation.TrimStart('/')
    $CombinedUrl = "{0}/{1}" -f $BaseUrl, $ApiLocation
    return $CombinedUrl
}

Check-EnvironmentVariables -Variables "ORDR_URL","ORDR_USER", "ORDR_PASSWORD", "ORDR_TENANTGUID"

#Enviroment Variables
$baseUrl=$env:ORDR_URL
$tenantGuid=$env:ORDR_TENANTGUID
$username = $env:ORDR_USER
$password = $env:ORDR_PASSWORD

$url = Combine-Url -BaseUrl $baseUrl -ApiLocation "Devices"

$queryParams = @()
$ip = Prompt-UserInput -prompt "Enter IP address: "
$queryParams += "ip=$ip"



$queryParams += "tenantGuid=$tenantGuid"
$encodedUrl = Encode-URL -baseUrl $url -queryParams $queryParams
$jsonResult = Query-API -encodedUrl $encodedUrl -username $username -password $password

Write-Host " "
Write-Host " "
$jsonResult | ConvertTo-Json -Depth 5
