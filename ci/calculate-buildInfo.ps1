#!/usr/bin/env pwsh

param (
    [switch] $isLocalBuild
)

$ErrorActionPreference = 'stop'

# compute path to library from environment variable local build
$toolPath = "./buildtools"

# include build tools library ('source' the file)
# we now have access to all the functions in library
. $toolPath/pwsh/workflow-utils.ps1 -expectMajorVersion:1 -expectMinorVersion:2

# ----------------------------- TOOLS ARE INITIALIZED ----------------------------

Set-EnvironmentFromFolder -directory ./configmap
Set-EnvironmentFromFolder -directory "$HOME/.secrets" -include @('artifact-apikey','artifact-username', 'sonarqube-token', 'sonarqube-project-key')

$eventName = Get-EventName -isLocalBuild:$isLocalBuild
$branchName = Get-BranchName -isLocalBuild:$isLocalBuild
$branchHash = Get-BranchHash
$prefix = Get-PrereleaseVersionPrefix -branchName:$branchName -eventName:$eventName
$buildTime = Get-VersionTimeComponent
$isReleaseVersion = Get-IsReleaseVersion -isLocalBuild:$isLocalBuild -eventName:$eventName -branchName:$branchName

# Product version for ReleaseVersion (master or release branch): <SemVer>
# Otherwise: <SemVer>-<prefix>-<time>-<branchSha>
$Product_Version = $env:BCT_PRODUCT_VERSION_BASE
if (-not $isReleaseVersion) {
    $Product_Version = "$Product_Version-$prefix$buildTime-$branchHash"
}

$PrereleaseSuffix = "-$prefix$buildTime-$branchHash"

$isPublishing = Get-IsPublishing -isReleaseVersion:$isReleaseVersion -branchName:$branchName

#for non-local builds set git configuration author and email
if (! $isLocalBuild) {
   Set-GitConfigAuthor
}

# ---- SAVE ENVIRONMENT VARIABLES ------------------

Set-BuildEnvironmentVariable BCT_EVENT_NAME  $eventName
Set-BuildEnvironmentVariable BCT_BUILDTOOLS_PATH $toolPath
Set-BuildEnvironmentVariable BCT_PRODUCT_VERSION $Product_Version
Set-BuildEnvironmentVariable BCT_BRANCH $branchName
Set-BuildEnvironmentVariable BCT_IS_RELEASE_VERSION $isReleaseVersion
Set-BuildEnvironmentVariable BCT_IS_PUBLISHING $isPublishing
Set-BuildEnvironmentVariable BCT_GIT_SHA $branchHash
#MONO
Set-BuildEnvironmentVariable BCT_PRERELEASE_SUFFIX $PrereleaseSuffix
