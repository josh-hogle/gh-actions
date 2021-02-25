$ErrorActionPreference = "Stop"
Import-Module GitHubActions

# build the new image
if ([string]::IsNullOrEmpty(${env:INPUT_EXTRA-ARGS})) {
	$extraArgs = @()
} else {
	$extraArgs = "${env:INPUT_EXTRA-ARGS}" -split ","
}
$id = Invoke-DockerBuild `
	-ImageName "${env:INPUT_IMAGE-NAME}" `
	-BaseImage "${env:INPUT_BASE-IMAGE}" `
	-Version "${env:INPUT_VERSION}" `
	-BuildContext "${env:INPUT_BUILD-CONTEXT}" `
	-Dockerfile "${env:INPUT_DOCKERFILE}" `
	-ReleaseDate "${env:INPUT_RELEASE-DATE}" `
	-CommitId $env:GITHUB_SHA `
	-ExtraArgs $extraArgs
if ($null -eq $id) {
	exit 2
}

Set-OutputVariable -Name "image-id" -Value $id
exit 0
