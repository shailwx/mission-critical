param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

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

function AppComponent {
    param
    (
      [string] $resourceName,
      [string] $resourceId,
      [string] $resourceType,
      [string] $loadTestId
    )
  
    $result = @"
    {
        "testId": "$loadTestId",
        "value": {
            "$resourceId": {
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
AppComponent -resourceName $resource[8] `
            -resourceType $resourceType `
            -resourceId $resourceId `
            -loadTestId $loadTestId | Out-File $testDataFileName -Encoding utf8

$urlRoot = "https://" + $apiEndpoint + "/appcomponents/" + $loadTestId
Write-Verbose "*** Load test service data plane: $urlRoot"

# Execute API call - add AppComponents to an existing Load Test
az rest --url $urlRoot `
  --method PATCH `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) "Content-Type=application/merge-patch+json" `
  --url-parameters testId=$loadTestId api-version=$apiVersion `
  --body ('@' + $testDataFileName) `
  $verbose #-o none 

$defaultMetrics = (. $PSScriptRoot/servermetrics-get-defaults.ps1 -apiEndpoint $apiEndpoint -apiVersion $apiVersion -embedded $true).defaultMetrics # retrieve all available metrics
$metrics = $defaultMetrics."$resourceType" # retrieve applicable metrics

# Delete the access token and test data files
Remove-Item $accessTokenFileName
Remove-Item $testDataFileName