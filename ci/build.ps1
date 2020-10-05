#!/usr/bin/env pwsh

#Instructions:
#Run from root directory

$version = $env:BCT_PRODUCT_VERSION 
$build_configuration = $env:BCT_BUILD_CONFIGURATION

Push-Location ./src
	 if (Test-Path ./nupkgs) {
		 remove-item -path ./nupkgs -recurse
	 }
	dotnet msbuild -t:Restore,Build -p:Configuration=$build_configuration -p:Version=$version
Pop-Location

$products = Get-Products
Pack-Products $products



# Mono repository functions
function Get-Products {
	param (
    [string] $productFilePath = "./configmap/products.json"
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
	[Param(Mandatory=$true)]
	$productsObject,
	[Param]
	[string]$nugetOutputPath = "./nupkgs"
	)
	
	$build_configuration = $env:BCT_BUILD_CONFIGURATION
	
	ForEach ($product in $productsObject.Products) {
		if($product.NuGetPack) {
			dotnet pack $product.Path --output $nugetOutputPath -p:Version=$product.Version -p:PackageVersion=$product.Version -p:Configuration=$build_configuration
		}
	}
}



