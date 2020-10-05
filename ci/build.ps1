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
	
	Write-Host "Packing on $productsObject"
	
	ForEach ($product in $productsObject.Products) {
		$productName = $product.Name
		$productPath = $product.Path
		$productVersion = $product.Version
	
		if($product.NuGetPack) {
			if($isReleaseVersion) {
				Write-Host "Packing product: $productName in $productPath with version $productVersion for configuration: $build_configuration"
				dotnet pack $product.Path --output $nugetOutputPath -p:Version=$product.Version -p:PackageVersion=$product.Version -p:Configuration=$build_configuration --nologo
			} else {
				Write-Host "Packing product: $productName in $productPath with version $productVersion for configuration: $build_configuration"
				dotnet pack $product.Path --output $nugetOutputPath -p:Version="$productVersion$prereleaseSuffix" -p:PackageVersion="$productVersion$prereleaseSuffix" -p:Configuration=$build_configuration --nologo
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
	#dotnet build -p:Configuration=$build_configuration -p:Version=$version
Pop-Location

$products = Get-Products
Pack-Products $products






