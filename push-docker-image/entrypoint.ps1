$ErrorActionPreference = "Stop"
Import-Module GitHubActions

# authenticate against destination URL for push
$success = Invoke-DockerLogin `
	-ImageUrl "${env:INPUT_PUSH-TO}" `
	-Username "${env:INPUT_USERNAME}" `
	-Password "${env:INPUT_PASSWORD}"
if (-not $success) {
	exit 2
}

# cache the existing image (to hopefully improve build time)
$tags = "${env:INPUT_TAGS}" -split "," | ForEach-Object { $_.Trim() }
$success = Invoke-DockerPush `
	-Image "${env:INPUT_IMAGE}" `
	-DestinationUrl "${env:INPUT_PUSH-TO}" `
	-Tags $tags
if (-not $success) {
	exit 3
}
exit 0
