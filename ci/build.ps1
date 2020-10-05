#!/usr/bin/env pwsh

$version = $env:BCT_PRODUCT_VERSION 
$build_configuration = $env:BCT_BUILD_CONFIGURATION
$isPublishing = $([System.Convert]::ToBoolean($env:BCT_IS_PUBLISHING))
$isReleaseVersion = $([System.Convert]::ToBoolean($env:BCT_IS_RELEASE_VERSION))
$prereleaseSuffix = $env:BCT_PRERELEASE_SUFFIX


# Mono repository functions
function Get-Products {
	param (
    [string] $productFilePath = "./src/products.json"
	)
			
	$productFileContent = Get-Content -Path $productFilePath
	
	if([string]::IsNullOrEmpty($productFileContent))
	{
		throw "Unable to open products.json - empty string"
	}
	
	$productsObject = $productFileContent | ConvertFrom-Json
	
	return $productsObject;
}

# ProductObject comes from Get-Products
function Pack-Products {
	param (
	[PsObject] $productsObject,
	[string]$nugetOutputPath = "./nupkgs"
	)
	
	$build_configuration = $env:BCT_BUILD_CONFIGURATION
	
	ForEach ($product in $productsObject.Products) {
		if($product.NuGetPack) {
			if($isReleaseVersion) {
				dotnet pack $product.Path --output $nugetOutputPath -p:Version=$product.Version -p:PackageVersion=$product.Version -p:Configuration=$build_configuration
			} else {
				dotnet pack $product.Path --output $nugetOutputPath -p:Version="$product.Version$prereleaseSuffix" -p:PackageVersion="$product.Version$prereleaseSuffix" -p:Configuration=$build_configuration
			}
		}
	}
}

#Instructions:
#Run from root directory



Push-Location ./src
	 if (Test-Path ./nupkgs) {
		 remove-item -path ./nupkgs -recurse
	 }
	dotnet build -p:Configuration=$build_configuration -p:Version=$version
Pop-Location

$products = Get-Products
Pack-Products $products






