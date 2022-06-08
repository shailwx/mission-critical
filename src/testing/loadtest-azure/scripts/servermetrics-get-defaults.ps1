param
(
  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [Parameter(Mandatory = $true)]
  [string] $apiVersion,

  [string] $embedded = $false # when true do not delete $accessTokenFile

)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://" + $apiEndpoint + "/serverMetricsConfig/default"
Write-Verbose "*** Load test service data plane: $urlRoot"

$url = $urlRoot + "?api-version=" + $apiVersion

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

$result = Invoke-RestMethod -Uri $url `
  -Method GET `
  -Authentication Bearer `
  -Token $accessTokenSecure

return $result

# Delete the access token and test data files
if (!$embedded) {
    Remove-Item $accessTokenFileName
}