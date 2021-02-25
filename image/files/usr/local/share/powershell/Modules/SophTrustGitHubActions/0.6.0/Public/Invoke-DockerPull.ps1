function Invoke-DockerPull {
	<#
	.SYNOPSIS
		Attempts to pull a Docker image from the given URL.

	.PARAMETER ImageUrl
		The URL to the image on the docker registry.
		
		The URL must include a protocol which indicates the type of registry being accessed.
		The following protocols are supported:
		- docker:// --> Docker Hub or any generic Docker registry (Default: index.docker.io)
		- ghcr://   --> GitHub Container Registry (Default: ghcr.io)
		- gcr://    --> Google Container Registry (Default: gcr.io)

		The remainder of the URL should typically be the hostname followed by the image path
		and name and an optional tag. If you wish to use the default hostname for the protocol
		as indicated above, just add a / followed by the image path and name.
	
	.PARAMETER FailIfNotFound
		If the image is not found, emit an error and return $false rather than emitting a
		warning and returning $true.

	.INPUTS
		Any parameter can be passed from the pipeline in an object with the same property
		defined.

	.OUTPUTS
		[bool] Returns $true if the image was pulled successfully or $false on error.

	.EXAMPLE
		Invoke-DockerPull -ImageUrl docker:///alpine:latest

		Pulls the 'alpine:latest' image from Docker Hub.

	.EXAMPLE
		Invoke-DockerPull -ImageUrl ghcr:///josh-hogle/alpine-docker:latest

		Pulls the alpine-docker:latest image from GitHub Container Registry.

	.EXAMPLE
		Invoke-DockerPull -ImageUrl gcr://us.gcr.io/josh-hogle/alpine:latest

		Pulls the josh-hogle/alpine:latest image from the US Google Container Registry.
	#>
	[OutputType([int])]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $ImageUrl,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[switch] $FailIfNotFound = $false
	)

	Begin { }

	Process {
		$image = Split-ImageUrl "${ImageUrl}"
		if ($null -eq $image) {
			Write-ErrorMsg "Pull failed: Image URL is not valid"
			return $false
		}
		$imagePath = "$($image.hostname)/$($image.path)"

		# check to see if the image exists
		$env:DOCKER_CLI_EXPERIMENTAL = "enabled"
		Write-InfoMsg "Checking for image: ${imagePath}"
		if (-not (Invoke-DockerCommand -ArgList @("manifest", "inspect", "${imagePath}"))) {
			if ($FailIfNotFound) {
				Write-ErrorMsg "Image not found: ${imagePath}"
				return $false
			}
			Write-WarnMsg "Image not found: ${imagePath}"
			return $true
		}

		# pull the image
		Write-InfoMsg "Pulling image: ${imagePath}"
		if (-not (Invoke-DockerCommand -ArgList @("pull", "${imagePath}"))) {
			Write-ErrorMsg "Failed to pull image"
			return $false
		}
		Write-InfoMsg "Pulled image succesfully."
		return $true
	}

	End { }
}
