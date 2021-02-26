<#
.SYNOPSIS
	Script to build the Docker image required by the various GH actions in this repo.

.PARAMETER PullUrl
	The URL to pull a cached version of the image from in order to improve build time.

.PARAMETER Username
	The username to use to authenticate with the registry for pulls and pushes.

.PARAMETER Password
	The password to use for the given username.

.PARAMETER GitHubAccessToken
	Token for authenticating with GitHub API.

.PARAMETER ImageName
	The base name of the image without any registry paths or tags.

.PARAMETER Version
	The version of the image being built.

.PARAMETER DestUrl
	The URL of the registry to push the tagged images to.

.PARAMETER Tags
	The tags to use for the image.

.INPUTS
	None.

.OUTPUTS
	None.
#>
[OutputType([void])]
param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $PullUrl,
	[Parameter(Mandatory = $false)]
	[string] $Username = $null,
	[Parameter(Mandatory = $false)]
	[string] $Password = $null,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $GitHubAccessToken = $null,
	[Parameter(Mandatory = $true, Position = 2)]
	[string] $ImageName,
	[Parameter(Mandatory = $false)]
	[string] $Version = $null,
	[Parameter(Mandatory = $true, Position = 2)]
	[string] $DestUrl,
	[Parameter(Mandatory = $false)]
	[string[]] $Tags = @("latest")
)

Import-Module "${PSScriptRoot}/../../image/files/usr/local/share/powershell/Modules/GitHubActions"

# authenticate against source and destination URLs for pull/push
$success = Invoke-DockerLogin -ImageUrl $PullUrl -Username $Username -Password $Password
if (-not $success) {
	exit 1
}
$success = Invoke-DockerLogin -ImageUrl $DestUrl -Username $Username -Password $Password
if (-not $success) {
	exit 1
}

# cache the existing image (to hopefully improve build time)
$success = Invoke-DockerPull -ImageUrl $PullUrl

# build the new image
$id = Invoke-DockerBuild `
	-ImageName $ImageName `
	-Version $Version `
	-CommitId $env:GITHUB_SHA `
	-BuildContext "${PSScriptRoot}/../../image" `
	-Dockerfile "${PSScriptRoot}/../../image/Dockerfile"
if ($null -eq $id) {
	exit 2
}

# push the image
$success = Invoke-DockerPush -Image $id -DestinationUrl $DestUrl -Tags $Tags
if (-not $success) {
	exit 3
}

# publish a release
$result = Publish-GitHubRelease -RepositoryPath $env:GITHUB_REPOSITORY -GitHubAccessToken $GitHubAccessToken `
	-ReleaseTag "v${Version}" -ReleaseName "Release ${Version}" -Changelog "${PSScriptRoot}/../../CHANGELOG.md" -Force
if ($null -eq $result) {
	exit 4
}
exit 0
