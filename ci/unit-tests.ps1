#!/usr/bin/env pwsh

#Instructions:
# - ./ci/unit-tests.ps1

$version = $env:BCT_PRODUCT_VERSION 
$build_configuration = $env:BCT_BUILD_CONFIGURATION

$exitStatusArray = New-Object System.Collections.ArrayList

# Run unit and component tests
ForEach ($folder in (Get-ChildItem -Path src -Include *.*.UnitTests, *.*.ComponentTests  -Exclude bin, obj -recurse))
{
	$fullFolder = $folder.FullName
	$basename = $folder.BaseName
	Write-Host $basename

	dotnet test $fullFolder --logger:"xunit;LogFilePath=../TestResults/$basename.$version.testresults.xml" -c $build_configuration /p:AltCover=true --no-build --test-adapter-path:.
	$exitStatusArray.Add($?)
	
	Move-Item $folder/coverage.xml ./src/TestResults/$basename.$version.coverage.xml -ErrorAction Ignore
}

# Throw Error if one or more test/s fail
if ($exitStatusArray.Contains($false))
{
	throw "Test Run Failed!"
}