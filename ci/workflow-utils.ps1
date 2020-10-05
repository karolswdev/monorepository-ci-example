
# Library for Local/GitHub build scripting

# Major/Minor version of this script
# Using semver. Major version MUST MATCH EXACTLY if specified. Minor/Patch versions should be at least the
# expected version if specified.

# Expected versions can be unspecified, but if a expected version is specified the expected versions
# above must also be specified. For example if expectMinorVersion is specified, expectMajorVersion
# must also be specified, but expectPatchVersion does not need to be specified.

param (
    [Parameter(Mandatory=$false)]
    [int] $expectMajorVersion,
    [Parameter(Mandatory=$false)]
    [int] $expectMinorVersion,
    [switch] $continueOnError
)


[int] $CI_MajorVersion = 1
[int] $CI_MinorVersion = 2
[int] $CI_PatchVersion = 0


if ($continueOnError) {
    $ErrorActionPreference = 'continue'
} else {
    $ErrorActionPreference = 'stop'
}

if (0 -ne $expectMajorVersion)
{
    if ($expectMajorVersion -ne $CI_MajorVersion)
    {
        Write-Error "Error: Major version of workflow-utils is wrong: $CI_MajorVersion"
    }
    if (0 -ne $expectMinorVersion)
    {
        if ($expectMinorVersion -gt $CI_MinorVersion)
        {
            Write-Error "Error: Minor version of checked-out workflow-utils ($CI_MinorVersion) is less than requested ($expectMinorVersion)"
        }
     }
}

#--------------------------------------------- Functions only below -------------------------------

# Lets try to keep function order alphabetical and try to follow PS naming conventions.

# Returns the branch hash
function Get-BranchHash
{
    $branchHash = git rev-parse --short HEAD

    return $branchHash;

}

# gets the branch name
function Get-BranchName
{
    param (
        [Parameter(Mandatory=$true)]
        [boolean] $isLocalBuild
    )

    if ($isLocalBuild) {
        $branch = git rev-parse --abbrev-ref HEAD
    }else {
        $branch = $env:GITHUB_REF
    }
    Write-Host "Branch Name: $branchName"
    return $branch    
}

# gets whether this is a release version
function Get-IsReleaseVersion
{
    param (
        [Parameter(Mandatory=$true)]
        [boolean] $isLocalBuild,
        [Parameter(Mandatory=$true)]
        [string] $eventName,
        [Parameter(Mandatory=$true)]
        [string] $branchName
    )

    $isReleaseVersion = $false;
    if ((-not $isLocalBuild) -and ($eventName -eq "push") -and (($branchName -like "*master") -or ($branchName -like "*release"))) {
        $isReleaseVersion = $true;
    }
    return $isReleaseVersion
}

# get event name - returns LOCAL for local builds, or the github event
function Get-EventName
{
    param (
        [Parameter(Mandatory=$true)]
        [boolean] $isLocalBuild
    )

    $eventName = $env:GITHUB_EVENT_NAME
    if ($isLocalBuild)
    {
        $eventName = "LOCAL"
    }
    return $eventName
}

# gets IsPublishing, indicating whether artifacts should be published
function Get-IsPublishing
{
    param (
        [Parameter(Mandatory=$true)]
        [boolean] $isReleaseVersion,
        [Parameter(Mandatory=$true)]
        [string] $branchName
        )

    $isPublishing = $isReleaseVersion -or ($branchName -like "*develop")

    return $isPublishing

}

# gets the prefix of a prerelease version
function Get-PrereleaseVersionPrefix
{
    param (
        [Parameter(Mandatory=$true)]
        [string] $branchName,
        [Parameter(Mandatory=$true)]
        [string] $eventName
    )

    $prefix="";
    if ($eventName -like "pull*") {
        $prefix = "prq-"
    }elseif ($null -ne $branchName) {
       if ($branchName -like "*develop*") {
          $prefix = "dev-";
       } else {
          $prefix = "fea-";
       }
    }
    return $prefix
}

# Computes a number that increments by one each second used for version naming
function Get-VersionTimeComponent{
    [System.DateTime]$nowx = [System.DateTime]::Now
    [System.DateTime]$then = [System.DateTime]::Parse("2018-1-1")
    [System.TimeSpan]$diff = $nowx - $then
    $sec = [System.Math]::Floor($diff.TotalSeconds)
    $build = $sec.ToString("000000000")
    return $build
}


# Saves name/value pair into environment for both local single script and GitHub workflow YAML
function Set-BuildEnvironmentVariable
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $name,
        [Parameter(Mandatory=$true)]
        [string[]]
        $value
    )
    echo "::set-env name=$name::$value"
    Set-Item "env:$name" $value
}

# Converts files in the specified directory into build environment variables. The variable name is
# based on the file name, and the value is the contents of the file.

# The optional include parameter is a string array of the file names to ONLY include as build environment 
# variables. If not specified all files are taken from the specified directory.

# File names are converted to all UPPERCASE, - (dash) is converted to underscore (_), and BCT_ is prepended
# to the beginning of the resulting environment variable name.

# File content is expected to be all on a single line, and cr/lf are removed and white space at ends 
# is trimmed. This removes the problem of hidden spaces at the end.
function Set-EnvironmentFromFolder
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $directory,
        [Parameter(Mandatory=$false)]
        [string[]]
        $include
    )
    if (Test-Path $directory -ne $null) {
        Get-ChildItem $directory | Where-Object { ($null -eq $include) -or $include.Contains($_.Name) } |
        Foreach-Object {
            $content = (Get-Content $_.FullName -Raw).Replace('\n',' ').Replace('\r', ' ').Trim()
            $name = "BCT_" + [System.Io.Path]::GetFileName($_.FullName).ToUpper().Replace('-','_')
            Set-BuildEnvironmentVariable $name $content
        }
    }
}

# set git config author and email address
# to the provided one - if author and email is passed
# or to the author and email of the last commit
function Set-GitConfigAuthor
{
   param(
        [Parameter(Mandatory=$false)]
        [string]
        $commitAuthor,
        [Parameter(Mandatory=$false)]
        [string[]]
        $commitEmail
    )
    if ([string]::IsNullOrEmpty($commitAuthor)) {
        $commitAuthor = git log -1 --pretty=format:"%an"
        $commitEmail = git log -1 --pretty=format:"%ae"
   }

   git config user.name $commitAuthor
   git config user.email $commitEmail
}