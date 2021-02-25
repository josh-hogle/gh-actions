function Invoke-DockerBuild {
	<#
	.SYNOPSIS
		Builds a Docker image.

	.PARAMETER ImageName
		The name of the container image without any tags or registry paths.
	
	.PARAMETER BaseImage
		The image from which to build the given image, if the Dockerfile requires it.

		Note that if this is a private image, you must perform a Docker login first.

	.PARAMETER Version
		The version for the image.

	.PARAMETER BuildContext
		The context (working directory) from which to build the image.

	.PARAMETER Dockerfile
		The path to the Dockerfile to use to build the image.
	
	.PARAMETER ReleaseDate
		The release date for the image, typically in the form dd MMM yyyy (eg: 01 Jan 1970).

		If this is not supplied, the current date is used.
	
	.PARAMETER CommitId
		The ID of the git commit being used to build the image.
	
	.PARAMETER ExtraArgs
		Extra arguments to pass to the docker build command.

	.INPUTS
		Any parameter can be passed from the pipeline in an object with the same property
		defined.

	.OUTPUTS
		[string] Returns the ID of the image that was built if successful or $null on
		error.

	.EXAMPLE
		Invoke-DockerBuild -ImageName alpine -BaseImage alpine:3.12

		Builds a container image named alpine from the default Docker Hub Alpine image.
	#>
	[OutputType([string])]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $ImageName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $BaseImage = $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $Version = $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $BuildContext= $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $Dockerfile = $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $ReleaseDate = $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $CommitId = $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string[]] $ExtraArgs = @()
	)

	Begin { }

	Process {
		if ([string]::IsNullOrEmpty($BuildContext)) {
			$BuildContext = "."
		}
		if ([string]::IsNullOrEmpty($Dockerfile)) {
			$Dockerfile = "./Dockerfile"
		}
		if ([string]::IsNullOrEmpty($ReleaseDate)) {
			$ReleaseDate = $(Get-Date -AsUTC -Format 'dd MMM yyyy')
		}
		if ([string]::IsNullOrEmpty($CommitId)) {
			$tag = [guid]::NewGuid().Guid
		} else {
			$tag = $CommitId
		}

		# build the image
		$argList = @("build",
			"--build-arg", "IMAGE_NAME=`"${ImageName}`"",
			"--build-arg", "BASE_IMAGE=`"${BaseImage}`"",
			"--build-arg", "VERSION=`"${Version}`"",
			"--build-arg", "RELEASE_DATE=`"${ReleaseDate}`"",
			"--build-arg", "CREATED_TIMESTAMP=`"$(Get-Date -AsUTC -Format o)`"",
			"--build-arg", "COMMIT_ID=`"${CommitId}`"",
			"--file", "${Dockerfile}",
			"--tag", "${ImageName}:${tag}")
		$argList += $ExtraArgs + @("${BuildContext}")
		if (-not (Invoke-DockerCommand -ArgList $argList)) {
			Write-ErrorMsg "Build failed for image: ${ImageName}"
			return $null
		}

		# get the image ID
		$result = Invoke-Command -Command "docker" -ArgList @("images", "-q", "${ImageName}:${tag}")
		if ($result.ExitCode -ne 0) {
			Write-ErrorMsg "Failed to retrieve Docker image ID"
			return $null
		}
		$id = $result.StdOut.Trim()
		Write-InfoMsg "Docker build successful for image: ${id}"
		return $id
	}

	End { }
}
