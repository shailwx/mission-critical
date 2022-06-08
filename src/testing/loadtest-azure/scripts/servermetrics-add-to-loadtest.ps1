param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

  # Load Test Run Id (optional - not implemented yet)
  [string] $loadTestRunId,

  # Appcomponent Azure ResourceId
  [Parameter(Mandatory = $true)]
  [string] $resourceId,

  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [Parameter(Mandatory = $true)]
  [string] $apiVersion
)

. "$PSScriptRoot/common.ps1"

function validateResourceId($resourceId) {
  $split = $resourceId.split("/")

  if ($split[1] -ne "subscriptions") {
    return $false
  }

  if ($split[3] -ne "resourcegroups") {
    return $false
  }

  if ($split[5] -ne "providers") {
    return $false
  }

  return $true
}

if (!(validateResourceId -resourceId $resourceId)) {
  throw "No valid resourceId provided."
}

function ServerMetricsConfig {
    param
    (
      [string] $resourceName,
      [string] $resourceId,
      [string] $resourceType,
      [string] $loadTestId,
      [string] $loadTestRunId
    )
  
    $result = @"
    {
        "testId": "$loadTestId",
        "metrics": {
            "$resourceId": {
              "displayName": "null",
              "kind": "null",
              "resourceName": "$resourceName",
              "resourceId": "$resourceId",
              "resourceType": "$resourceType"
            }
        }
    }
"@

  return $result
}

# Split Azure ResourceID
$resource = $resourceId.split("/")
$resourceType = $resource[6]+"/"+$resource[7]

$testDataFileName = $loadTestId + ".txt"
ServerMetricsConfig -resourceName $resource[8] `
            -resourceType $resourceType `
            -resourceId $resourceId `
            -loadTestId $loadTestId | Out-File $testDataFileName -Encoding utf8

$urlRoot = "https://" + $apiEndpoint + "/serverMetricsConfig/" + $loadTestId
Write-Verbose "*** Load test service data plane: $urlRoot"