#!/bin/pwsh

#____________________________________________________
#|                                                  |
#|               Upload Artifact                    |
#|                                                  |
#| This script allows you to upload any kind of     |
#| artifact into Artifactory using an API key       |
#|__________________________________________________|
#| Parameter          | Description                 |
#|--------------------|-----------------------------|
#| artifactPath       | The file path to upload     |
#|--------------------|-----------------------------|
#| artifactName       | The final name for the arti-|
#|                    | -fact in Artifactory        |
#|--------------------|-----------------------------|
#| artifactRepository | The repository on Artifacto-|
#|                    | -ry for this to live in     |
#|____________________|_____________________________|

# e.g. /upload-artifact.ps1 ../test-results.zip 2020-02-03-SHA1-CoCo-TestResults.zip test-results c0dsd5pxVtCsoJkXo8trOkNcwvBBoc
# will upload the test-results.zip into the test-results storage on TBCT's Artifactory under the file name of '2020-02-03-SHA1-CoCo-TestResults.zip'.


[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $artifactPath,
    [Parameter(Mandatory=$true)]
    [string]
    $artifactName,
    [Parameter(Mandatory=$true)]
    [string]
    $artifactRepository
)

$curl="curl"

if ($IsWindows)
{
	$curl="curl.exe"
}

# The correct cURL header contains the apiKey
$artAPI = "X-JFrog-Art-Api:" + $env:BCT_ARTIFACT_APIKEY

Write-Host "Checking sums on $artifactPath"

# Calculate checksums
$hashSHA1=(Get-FileHash -Path $artifactPath -Algorithm SHA1).Hash
$checksumSHA1="X-Checksum-Sha1:" + $hashSHA1

$hashMD5=(Get-FileHash -Path $artifactPath -Algorithm MD5).Hash
$checksumMD5="X-Checksum-MD5:" + $hashMD5

$hashSHA256=(Get-FileHash -Path $artifactPath -Algorithm SHA256).Hash
$checksumSHA256="X-Checksum-Sha256:" + $hashSHA256

# Artifactory URL together with the artifact repository
$artifactoryUrl = $env:BCT_ARTIFACT_BASE_URL + $artifactRepository + "/" + $artifactName

# Execute the curl request to upload 
& $curl -H $artAPI -H $checksumSHA1 -H $checksumMD5 -H $checksumSHA256 -T $artifactPath $artifactoryUrl