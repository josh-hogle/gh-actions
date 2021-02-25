$ErrorActionPreference = "Stop"
Import-Module GitHubActions

# set defaults
if ([string]::IsNullOrEmpty("${env:INPUT_RELEASE-TAG}")) {
	if ([string]::IsNullOrEmpty("${env:GITHUB_REF}")) {
		$env:GITHUB_REF = "$(git rev-parse --abbrev-ref HEAD)"
	}
	$parts = $env:GITHUB_REF -split "/"
	${env:INPUT_RELEASE-TAG} = $parts[$parts.Count - 1]
}

# configure parameters
$params = @{}
if (-not [string]::IsNullOrEmpty(${env:INPUT_RELEASE-NAME})) {
	$params["ReleaseName"] = ${env:INPUT_RELEASE-NAME}
}
if (-not [string]::IsNullOrEmpty(${env:INPUT_RELEASE-NOTES})) {
	$params["ReleaseNotes"] = ${env:INPUT_RELEASE-NOTES}
}
if (-not [string]::IsNullOrEmpty($env:INPUT_CHANGELOG)) {
	$params["Changelog"] = $env:INPUT_CHANGELOG
}
if (-not [string]::IsNullOrEmpty(${env:INPUT_COMMIT-ID})) {
	$params["CommitId"] = ${env:INPUT_COMMIT-ID}
}
if (-not [string]::IsNullOrEmpty(${env:INPUT_ASSETS})) {
	$params["Assets"] = ConvertFrom-Json -InputObject $env:INPUT_ASSETS
}
try {
	$excludeChangelog = [System.Convert]::ToBoolean(${env:INPUT_EXCLUDE-CHANGELOG})
	$isDraft = [System.Convert]::ToBoolean(${env:INPUT_IS-DRAFT})
	$isPreRelease = [System.Convert]::ToBoolean(${env:INPUT_IS-PRERELEASE})
	$force = [System.Convert]::ToBoolean($env:INPUT_FORCE)
} catch {
	Write-ErrorMsg -Exception $_.Exception "Failed to convert parameter to a boolean value"
	exit 2
}

# publish the release
$result = Publish-GitHubRelease -RepositoryPath $env:GITHUB_REPOSITORY -GitHubAccessToken ${env:INPUT_ACCESS-TOKEN} `
	-ReleaseTag ${env:INPUT_RELEASE-TAG} -ExcludeChangelog:$excludeChangelog -IsDraft:$isDraft `
	-IsPreRelease:$isPreRelease -Force:$force @params
if ($null -eq $result) {
	exit 2
}

# set variables
Set-OutputVariable -Name "release-id" -Value $result.id
Set-OutputVariable -Name "release-url" -Value $result.release_url
exit 0
