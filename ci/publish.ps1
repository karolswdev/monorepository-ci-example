#!/usr/bin/env pwsh

#Instructions:
#Run from root folder

$version = $env:BCT_PRODUCT_VERSION 
$isReleaseVersion = $([System.Convert]::ToBoolean($env:BCT_IS_RELEASE_VERSION))
$isPublishing = $([System.Convert]::ToBoolean($env:BCT_IS_PUBLISHING))

if ($isPublishing) {
	Write-Output "Publishing Bct.Common.Auditing.Client"
	Push-Location ./src/nupkgs
		# dotnet nuget push Bct.Common.Auditing.Client.$version.nupkg
		nuget push Bct.Common.Auditing.Client.$version.nupkg -Source Artifactory
	Pop-Location
}

# If Release Version - tag the branch
if ($isReleaseVersion)
{
	git tag -a $version $env:BCT_GIT_SHA -m "Release $version"
	git push origin $version
}
