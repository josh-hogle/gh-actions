$ErrorActionPreference = "Stop"
Import-Module GitHubActions

# authenticate against the image URL for pull
$success = Invoke-DockerLogin `
	-ImageUrl "${env:INPUT_IMAGE}" `
	-Username "${env:INPUT_USERNAME}" `
	-Password "${env:INPUT_PASSWORD}"
if (-not $success) {
	exit 2
}

# cache the existing image (to hopefully improve build time)
$success = Invoke-DockerPull -ImageUrl "${env:INPUT_IMAGE}"
exit 0
