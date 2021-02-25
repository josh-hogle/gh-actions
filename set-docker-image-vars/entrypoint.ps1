$ErrorActionPreference = "Stop"
Import-Module GitHubActions

# configure image-name and base-image
Set-OutputVariable -Name "image-name" -Value ${env:INPUT_IMAGE-NAME}
Set-OutputVariable -Name "base-image" -Value ${env:INPUT_BASE-IMAGE}

# configure version
if ([string]::IsNullOrEmpty("${env:GITHUB_REF}")) {
	$env:GITHUB_REF = "$(git rev-parse --abbrev-ref HEAD)"
}
if ([string]::IsNullOrEmpty("${env:INPUT_VERSION}")) {
	$parts = $env:GITHUB_REF -split "/"
	$env:INPUT_VERSION = $parts[$parts.Count - 1]
}
Set-OutputVariable -Name "version" -Value $env:INPUT_VERSION

# configure release-date
if ([string]::IsNullOrEmpty("${env:INPUT_RELEASE-DATE}")) {
	${env:INPUT_RELEASE-DATE} = "$(Get-Date -Format "dd MMM yyyy")"
}
Set-OutputVariable -Name "release-date" -Value ${env:INPUT_RELEASE-DATE}

# configure commit-id
if ([string]::IsNullOrEmpty("${env:GITHUB_SHA}")) {
	$gitSha1 = "$(git rev-parse HEAD)"
} else {
	$gitSha1 = $env:GITHUB_SHA
}
$commitId = $gitSha1.SubString(0, 8)
Set-OutputVariable -Name "commit-id" -Value $commitId

# configure tags
$tags = @()
if ("${INPUT_SKIP-COMMIT-TAG}" -ne "true") {
	$tags += "sha-${gitSha1}"
}
if ("${INPUT_SKIP-VERSION-TAG}" -ne "true") {
	$tags += "${env:INPUT_VERSION}"
}
if (-not [string]::IsNullOrEmpty("${env:INPUT_EXTRA-TAGS}")) {
	$tags += "${env:INPUT_EXTRA-TAGS}" -split "," | ForEach-Object { $_.Trim() }
}
Set-OutputVariable -Name "tags" -Value $($tags -join ",")
