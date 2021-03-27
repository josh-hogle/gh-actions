function Invoke-DockerLogin {
	<#
  	.SYNOPSIS
		Performs authentication against a Docker registry based on the given image URL.

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
  
  	.PARAMETER Username
		An optional username to provide if the registry requires authentication credentials.

		Google Container Registry URLs may always omit this parameter as it is not used.

  	.PARAMETER Password
		An optional password to provide if the registry requires authentication credentials.

		When specifying a Google Container Registry URL, this should be the base64-encoded
		form of the service account's JSON-formatted key.

  	.INPUTS
		Any parameter can be passed from the pipeline in an object with the same property
		defined.

  	.OUTPUTS
		[bool] Returns $true if the login was a success or was not required or $false if
		it was not successful.

  	.EXAMPLE
		Invoke-DockerLogin -ImageUrl docker:///alpine:latest -Username josh -Password test

		Authenticates to index.docker.io (Docker Hub) using the given credentials.

  	.EXAMPLE
		Invoke-DockerLogin -ImageUrl ghcr:///josh-hogle/alpine-docker:latest -Username ${{ github.actor }} -Password ${{ secrets.GHCR_TOKEN }}

		Authenticates to ghcr.io (GitHub Container Registry) using GitHub Action Workflow variables.
  
  	.EXAMPLE
		Invoke-DockerLogin -ImageUrl gcr://us.gcr.io/josh-hogle/alpine:latest -Password SOMEBASE64DATA

		Authenticates to the US Google Container Registry using the given service account key data.
  	#>
  	[OutputType([bool])]
  	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $ImageUrl,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $Username = $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $Password = $null
  	)

  	Begin {	}

  	Process {
		$image = Split-ImageUrl "${ImageUrl}"
		if ($null -eq $image) {
			Write-ErrorMsg "Login failed: Image URL is not valid"
			return $false
		}
		switch ($image.proto) {
	  		# Generic Docker registry / Docker Hub
	  		"docker" {
				if ([string]::IsNullOrEmpty($Username) -or [string]::IsNullOrEmpty($Password)) {
					Write-InfoMsg "No Docker credentials were provided - skipping authentication"
					return $true
				} else {
					Write-InfoMsg "Logging into Docker registry: $($image.hostname)"
					return Invoke-DockerLoginCommand -Hostname "$($image.hostname)" -Username "${Username}" `
						-Password "${Password}"
					
				}
			}
	
	  		# GitHub Container Regsitry
	  		"ghcr" {
				if ([string]::IsNullOrEmpty($Username) -or [string]::IsNullOrEmpty($Password)) {
					Write-InfoMsg "No Docker credentials were provided - skipping authentication"
					return $true
				} else {
		  			Write-InfoMsg "Logging into GitHub registry: $($image.hostname)"
					return Invoke-DockerLoginCommand -Hostname "$($image.hostname)" -Username "${Username}" `
					  	-Password "${Password}"
				}
	  		}

			# Google Container Registry
			"gcr" {
				if ([string]::IsNullOrEmpty($Password)) {
					Write-InfoMsg "No Docker credentials were provided - skipping authentication"
					return $true
				} else {
					Write-InfoMsg "Logging into Google Container registry: $($image.hostname)"
					return Invoke-GcrLoginCommand -Hostname "$($image.hostname)" -EncodedKey "${Password}"
				}
			}
		}
		Write-ErrorMsg "An unexpected error occurred"
		return $false
  	}

	End { }
}
