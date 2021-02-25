function Invoke-DockerPush {
	<#
	.SYNOPSIS
		Attempts to push a Docker image to a registry.

	.PARAMETER Image
		The ID or name of the image to push to the registry.

	.PARAMETER DestinationUrl
		The URL of the image use to do the push without any tags appended.
		
		The URL must include a protocol which indicates the type of registry being accessed.
		The following protocols are supported:
		- docker:// --> Docker Hub or any generic Docker registry (Default: index.docker.io)
		- ghcr://   --> GitHub Container Registry (Default: ghcr.io)
		- gcr://    --> Google Container Registry (Default: gcr.io)

		The remainder of the URL should typically be the hostname followed by the image path.
		If you wish to use the default hostname for the protocol as indicated above, just add
		a / followed by the image path and name.

		You must authenticate to this URL before pushing the image.
	
	.PARAMETER Tags
		A list of tags to push with the image to the destination registry.

	.INPUTS
		Any parameter can be passed from the pipeline in an object with the same property
		defined.

	.OUTPUTS
		[bool] Returns $true if the image and all tags were pushed successfully or $false if
		there was an error.

	.EXAMPLE
		Invoke-DockerPush -Image alpine:local -DestinationUrl docker:///josh/alpine -Tags latest

		Pushes the local alpine:local image to josh's account in Docker Hub as alpine with only
		a latest tag.
	#>
	[OutputType([int])]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $Image,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string] $DestinationUrl,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 2)]
		[string[]] $Tags = $null
	)

	Begin {	}

	Process {
		$dest = Split-ImageUrl "${DestinationUrl}"
		if ($null -eq $dest) {
			Write-ErrorMsg "Push failed: Destination URL is not valid"
			return $false
		}
		$destPath = "$($dest.hostname)/$($dest.path)"

		if ($null -eq $Tags -or $Tags.Count -eq 0) {
			$Tags = @("latest")
		}
		foreach ($tag in $tags) {
			Write-InfoMsg "Tag and push image: ${Image} --> ${destPath}:${tag}"
			if (-not (Invoke-DockerCommand -ArgList @("tag", "${Image}", "${destPath}:${tag}"))) {
				Write-ErrorMsg "Failed to tag image: ${Image}"
				return $false
			}
			if (-not (Invoke-DockerCommand -ArgList @("push", "${destPath}:${tag}"))) {
				Write-ErrorMsg "Failed to push image: ${destPath}:${tag}"
				return $false
			}
		}
		return $true
	}

	End { }
}
