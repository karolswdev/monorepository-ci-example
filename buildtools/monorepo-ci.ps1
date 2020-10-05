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
			dotnet pack $product.Path --output $nugetOutputPath -p:Version=$version -p:PackageVersion=$version -p:Configuration=$build_configuration
		}
	}
}