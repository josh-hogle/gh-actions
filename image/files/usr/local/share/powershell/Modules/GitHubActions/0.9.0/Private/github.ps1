function Invoke-GitHubApiRequest {
	<#
	.SYNOPSIS
		Invokes a GitHub REST API request.

	.PARAMETER Uri
		The URI for the API to call, including any path parameters.

	.PARAMETER Method
		The HTTP method to use when invoking the request.

	.PARAMETER Body
		Body to send with the request

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.PARAMETER ContentType
		The type of content being uploaded.

	.INPUTS
		None.

	.OUTPUTS
		[PSCustomObject] The response from the API call. On success the status_code property
		will be set to 200 and data will contain the actual response from the API. Any other
		code indicates an error. Check the exception and details properties for more
		information.
	#>
	[OutputType([PSCustomObject])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Uri,
		[Parameter(Mandatory = $false)]
		[string] $Method = "GET",
		[Parameter(Mandatory = $false)]
		[string] $Body = $null,
		[Parameter(Mandatory = $false)]
		[string] $Token = $null,
		[Parameter(Mandatory = $false)]
		[string] $ContentType = "application/json"
	)

	# add headers to the request
	$request = @{
		ContentType = $ContentType
		Uri = "https://api.github.com${Uri}"
		Method = $Method
		Headers = @{
			Accept = "application/vnd.github.v3+json"
		}

	}
	if (-not [string]::IsNullOrEmpty($Token)) {
		$request["Headers"]["Authorization"] = "token ${Token}"
	}
	if (-not [string]::IsNullOrEmpty($Body)) {
		$request["Body"] = $Body
	}

	# make the request
	try	{
		Write-DebugMsg "Invoking $($request.Method) web request for URL: $($request.Uri)"
		$response = [PSCustomObject](Invoke-RestMethod @request)
	} catch	{
		if ($null -eq $_.Exception.Response) {
			return [PSCustomObject]@{
				status_code = 500
				exception = $_.Exception
				details = $_.Exception.Message
			}
		} else {
			# get the error body
			if ($PSVersionTable.PSVersion.Major -lt 6) {
				$reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
				$reader.BaseStream.Position = 0
				$reader.DiscardBufferedData()
				$body = $reader.ReadToEnd()
			} else {
				$body = $_.ErrorDetails.Message
			}

			# write the message
			$statusCode = $_.Exception.Response.StatusCode
			return [PSCustomObject]@{
				status_code = $statusCode
				exception = $_.Exception
				details = ConvertFrom-Json -InputObject $body
			}
		}
	}
	return [PSCustomObject]@{
		status_code = 200
		data = $response
	}
}

function Find-GitHubReleaseTag {
	<#
	.SYNOPSIS
		Finds an existing GitHub release with the given tag for a repository.

	.PARAMETER RepositoryPath
		The path of the GitHub repository to check.

	.PARAMETER ReleaseTag
		The release tag to search for.

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.INPUTS
		None.

	.OUTPUTS
		[PSCustomObject] The details on the release with status_code set to 200 and data
		containing the release details on success or a status_code of 404 if the release
		tag was not found. If an error occurred, $null is returned.
	#>
	[OutputType([PSCustomObject])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string] $ReleaseTag,
		[Parameter(Mandatory = $false)]
		[string] $Token = $null
	)

	Write-InfoMsg "Finding release with tag: ${RepositoryPath} --> ${ReleaseTag}"
	$uri = "/repos/${RepositoryPath}/releases/tags/${ReleaseTag}"
	$response = Invoke-GitHubApiRequest -Uri $uri -Token $Token
	if ($response.status_code -ne 200) {
		if ($response.status_code -eq 404) {
			Write-DebugMsg "Release tag was not found"
			return [PSCustomObject]@{ status_code = 404 }
		}
		Write-ApiExceptionMsg $response
		return $null
	}
	return $response
}

function New-GitHubRelease {
	<#
	.SYNOPSIS
		Creates a new GitHub Release.

	.PARAMETER RepositoryPath
		The path to the GitHub repository.
	
	.PARAMETER ReleaseTag
		The tag to create with the release, if it does not exist already.

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.PARAMETER ReleaseName
		The name to use for the new release, if different from the ReleaseTag.

	.PARAMETER ReleaseNotes
		The text describing the contents of the release.

	.PARAMETER CommitId
		Specifies the commit ID that determines where the Git tag is created.
	
		This can be any branch or commit SHA. It is unused if the ReleaseTag already exists.

	.PARAMETER IsDraft
		If specified, create a draft release.

	.PARAMETER IsPreRelease
		If specified, mark the release as being a pre-release.

	.INPUTS
		None.
	
	.OUTPUTS
		[PSCustomObject] The new release details on success or $null on failure.
	#>
	[OutputType([PSCustomObject])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $ReleaseTag,
		[Parameter(Mandatory = $false)]
		[string] $Token = $null,
		[Parameter(Mandatory = $false)]
		[string] $ReleaseName = $null,
		[Parameter(Mandatory=$false)]
		[string] $ReleaseNotes = $null,
		[Parameter(Mandatory = $false)]
		[string] $CommitId = $null,
		[Parameter(Mandatory = $false)]
		[switch] $IsDraft = $false,
		[Parameter(Mandatory = $false)]
		[switch] $IsPreRelease = $false	
	)

	# construct the request
	$releaseData = @{ 
		tag_name   = $ReleaseTag
	}
	if ($PSBoundParameters.ContainsKey("IsDraft")) {
		$releaseData["draft"] = [bool] $IsDraft
	}
	if ($PSBoundParameters.ContainsKey("IsPreRelease")) {
		$releaseData["prerelease"] = [bool] $IsPreRelease
	}
	if ($PSBoundParameters.ContainsKey("ReleaseName") -and -not [string]::IsNullOrEmpty($ReleaseName)) {
		$releaseData["name"] = $ReleaseName
	}
	if ($PSBoundParameters.ContainsKey("ReleaseNotes") -and -not [string]::IsNullOrEmpty($ReleaseNotes)) {
		$releaseData["body"] = $ReleaseNotes
	}
	if ($PSBoundParameters.ContainsKey("CommitId") -and -not [string]::IsNullOrEmpty($CommitId)) {
		$releaseData["target_commitish"] = $CommitId
	}

	# execute the request
	Write-InfoMsg "Creating release: ${RepositoryPath} --> ${ReleaseName} (${ReleaseTag})"
	$uri = "/repos/${RepositoryPath}/releases"
	$body = ConvertTo-Json $releaseData -Compress
	$response = Invoke-GitHubApiRequest -Uri $uri -Method "POST" -Body $body -Token $Token
	if ($response.status_code -ne 200) {
		Write-ApiExceptionMsg $response
		return $null
	}
	return $response.data
}

function Update-GitHubRelease {
	<#
	.SYNOPSIS
		Updates an existing GitHub Release.

	.PARAMETER RepositoryPath
		The path to the GitHub repository.
	
	.PARAMETER ReleaseId
		The ID of the release to update.

	.PARAMETER ReleaseTag
		The tag to create with the release, if it does not exist already.

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.PARAMETER ReleaseName
		The name to use for the new release, if different from the ReleaseTag.

	.PARAMETER ReleaseNotes
		The text describing the contents of the release.

	.PARAMETER CommitId
		Specifies the commit ID that determines where the Git tag is created.
	
		This can be any branch or commit SHA. It is unused if the ReleaseTag already exists.

	.PARAMETER IsDraft
		If specified, create a draft release.

	.PARAMETER IsPreRelease
		If specified, mark the release as being a pre-release.

	.INPUTS
		None.
	
	.OUTPUTS
		[PSCustomObject] The updated release details on success or $null on failure.
	#>
	[OutputType([PSCustomObject])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $ReleaseId,
		[Parameter(Mandatory = $true, Position = 2)]
		[string] $ReleaseTag,
		[Parameter(Mandatory = $false)]
		[string] $Token = $null,
		[Parameter(Mandatory = $false)]
		[string] $ReleaseName = $null,
		[Parameter(Mandatory=$false)]
		[string] $ReleaseNotes = $null,
		[Parameter(Mandatory = $false)]
		[string] $CommitId = $null,
		[Parameter(Mandatory = $false)]
		[switch] $IsDraft = $false,
		[Parameter(Mandatory = $false)]
		[switch] $IsPreRelease = $false	
	)

	# construct the request
	$releaseData = @{ }
	if ($PSBoundParameters.ContainsKey("IsDraft")) {
		$releaseData["draft"] = [bool] $IsDraft
	}
	if ($PSBoundParameters.ContainsKey("IsPreRelease")) {
		$releaseData["prerelease"] = [bool] $IsPreRelease
	}
	if ($PSBoundParameters.ContainsKey("ReleaseTag") -and -not [string]::IsNullOrEmpty($ReleaseTag)) {
		$releaseData["tag_name"] = $ReleaseTag
	}
	if ($PSBoundParameters.ContainsKey("ReleaseName") -and -not [string]::IsNullOrEmpty($ReleaseName)) {
		$releaseData["name"] = $ReleaseName
	}
	if ($PSBoundParameters.ContainsKey("ReleaseNotes") -and -not [string]::IsNullOrEmpty($ReleaseNotes)) {
		$releaseData["body"] = $ReleaseNotes
	}
	if ($PSBoundParameters.ContainsKey("CommitId") -and -not [string]::IsNullOrEmpty($CommitId)) {
		$releaseData["target_commitish"] = $CommitId
	}

	# execute the request
	Write-InfoMsg "Updating release: ${RepositoryPath} / ${ReleaseId} --> ${ReleaseName} (${ReleaseTag})"
	$uri = "/repos/${RepositoryPath}/releases/${ReleaseId}"
	$body = ConvertTo-Json $releaseData -Compress
	$response = Invoke-GitHubApiRequest -Uri $uri -Method "PATCH" -Body $body -Token $Token
	if ($response.status_code -ne 200) {
		Write-ApiExceptionMsg $response
		return $null
	}
	return $response.data
}

function Find-GitHubReleaseAsset {
	<#
	.SYNOPSIS
		Finds an existing GitHub release asset with the given file name for a repository.

	.PARAMETER RepositoryPath
		The path of the GitHub repository to check.

	.PARAMETER ReleaseId
		The release ID to search for assets for.

	.PARAMETER AssetName
		The name of the asset to search for.

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.INPUTS
		None.

	.OUTPUTS
		[PSCustomObject] The details on the asset with status_code set to 200 and data
		containing the release details on success or a status_code of 404 if the release
		asset was not found. If an error occurred, $null is returned.
	#>
	[OutputType([PSCustomObject])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string] $ReleaseId,
		[Parameter(Mandatory = $true, Position = 2)]
		[ValidateNotNullOrEmpty()]
		[string] $AssetName,
		[Parameter(Mandatory = $false)]
		[string] $Token = $null
	)

	Write-InfoMsg "Finding asset for release: ${AssetName} --> ${ReposoitoryPath}/${ReleaseId}"
	$uri = "/repos/${RepositoryPath}/releases/${ReleaseId}/assets"
	$response = Invoke-GitHubApiRequest -Uri $uri -Token $Token
	if ($response.status_code -ne 200) {
		if ($response.status_code -eq 404) {
			Write-DebugMsg "Release tag was not found"
			return [PSCustomObject]@{ status_code = 404 }
		}
		Write-ApiExceptionMsg $response
		return $null
	}
	foreach ($asset in $response.data) {
		if ($asset.name -eq $AssetName) {
			return $asset
		}
	}
	return [PSCustomObject]@{ status_code = 404 }
}

function New-GitHubReleaseAsset {
	<#
	.SYNOPSIS
		Uploads a new asset file and attaches to a GitHub Release.

	.PARAMETER Path
		The path to the asset to upload.

	.PARAMETER UploadUrl
		The URL for uploading assets to the release.

	.PARAMETER RepositoryPath
		The path to the GitHub repository.
	
	.PARAMETER ReleaseId
		The ID of the release to attach the asset to.

	.PARAMETER MediaType
		The MIME type of the file being uploaded.

	.PARAMETER AssetName
		The name of the file that the asset will be saved as within GitHub.

	.PARAMETER AssetLabel
		The display name for the asset in the release.

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.INPUTS
		None.

	.OUTPUTS
		[PSCustomObject] The uploaded asset details on success or $null on failure.
	#>
	[OutputType([PSCustomObject])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Path,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $UploadUrl,
		[Parameter(Mandatory = $true, Position = 2)]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, Position = 4)]
		[string] $ReleaseId,
		[Parameter(Mandatory = $false)]
		[string] $MediaType = "application/octet-stream",
		[Parameter(Mandatory = $false)]
		[string] $AssetName = $null,
		[Parameter(Mandatory = $false)]
		[string] $AssetLabel = $null,
		[Parameter(Mandatory = $false)]
		[string] $Token
	)

	try {
		# make sure asset exists
		if (-not (Test-Path($Path))) {
			Write-ErrorMsg "Asset file not found: ${Path}"
			return $null
		}

		# construct the upload URL
		$UploadUrl = $UploadUrl.Substring(0, $UploadUrl.IndexOf("{"))
		$queryParams = @()
		if (-not $PSBoundParameters.ContainsKey("AssetName") -or [string]::IsNullOrEmpty($AssetName)) {
			$AssetName = Split-Path -Leaf $Path
		}
		$queryParams += "name=" + [uri]::EscapeDataString($AssetName)
		if ($PSBoundParameters.ContainsKey("AssetLabel") -and -not [string]::IsNullOrEmpty($AssetLabel)) {
			$queryParams += "label=" + [uri]::EscapeDataString($AssetLabel)
		} else {
			$queryParams += "label=" + [uri]::EscapeDataString($AssetName)
		}
		if ($queryParams.Count -gt 0) {
			$UploadUrl += "?" + ($queryParams -join "&")
		}
		Write-DebugMsg "Asset upload URL: ${UploadUrl}"

		# configure the request
		$headers = @{
			Accept = "application/vnd.github.v3+json"
		}
		if ($PSBoundParameters.ContainsKey("Token") -and -not [string]::IsNullOrEmpty($Token)) {
			$headers["Authorization"] = "token ${Token}"
		}

		# perform the upload
		Write-InfoMsg "Uploading asset: ${Path} --> ${RepositoryPath} (Release ID: ${ReleaseId})"
		$response = Invoke-WebRequest -Uri $UploadUrl -ContentType $MediaType -Headers $headers `
			-Method Post -InFile $Path
	} catch {
		Write-ErrorMsg -Exception $_.Exception "Failed to upload asset"
		return $null
	}
	return ConvertFrom-Json -InputObject $response.Content
}

function Remove-GitHubReleaseAsset {
	<#
	.SYNOPSIS
		Removes an existing GitHub release asset with the given file name for a repository.

	.PARAMETER RepositoryPath
		The path of the GitHub repository to check.

	.PARAMETER ReleaseId
		The release ID to search for assets for.

	.PARAMETER AssetName
		The name of the asset to remove.

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.INPUTS
		None.

	.OUTPUTS
		[bool] $true if the asset was removed or did not exist or $false if an error
		occurred.
	#>
	[OutputType([bool])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string] $ReleaseId,
		[Parameter(Mandatory = $true, Position = 2)]
		[ValidateNotNullOrEmpty()]
		[string] $AssetName,
		[Parameter(Mandatory = $false)]
		[string] $Token = $null
	)

	# find the asset
	$result = Find-GitHubReleaseAsset -RepositoryPath $RepositoryPath -ReleaseId $ReleaseId -AssetName $AssetName `
		-Token $Token
	if ($null -eq $result) {
		return $false
	}
	if ($result.status_code -eq 404) {
		return $true # asset does not exist
	}

	# remove the asset
	Write-InfoMsg "Removing asset for release: ${AssetName} --> ${ReposoitoryPath}/${ReleaseId}"
	$uri = "/repos/${RepositoryPath}/releases/${ReleaseId}/assets/$($result.data.id)"
	$response = Invoke-GitHubApiRequest -Uri $uri -Method "DELETE" -Token $Token
	if ($response.status_code -ne 200) {
		Write-ApiExceptionMsg $response
		return $false
	}
	return $true
}

function Remove-GitHubReleaseAssets {
	<#
	.SYNOPSIS
		Removes all assets attached to a GitHub release.

	.PARAMETER RepositoryPath
		The path to the GitHub repository.
	
	.PARAMETER ReleaseId
		The ID of the release to remove the assets from.

	.PARAMETER Token
		An access token for authenticating the request, if necessary.

	.INPUTS
		None.

	.OUTPUTS
		[bool] $true if the assets were all removed or $false if an error occurred.
	#>
	[OutputType([bool])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $ReleaseId,
		[Parameter(Mandatory = $false)]
		[string] $Token = $null
	)

	# get a list of all of the assets
	Write-InfoMsg "Finding release assets: ${RepositoryPath} / ${ReleaseId}"
	$uri = "/repos/${RepositoryPath}/releases/${ReleaseId}/assets"
	$response = Invoke-GitHubApiRequest -Uri $uri -Method "GET" -Token $Token
	if ($response.status_code -ne 200) {
		Write-ApiExceptionMsg $response
		return $false
	}

	# remove each asset
	foreach ($asset in $response.data) {
		Write-InfoMsg "Removing asset: $($asset.name)"
		$uri = "/repos/${RepositoryPath}/releases/assets/$($asset.id)"
		$response = Invoke-GitHubApiRequest -Uri $uri -Method "DELETE" -Token $Token
		if ($response.status_code -ne 200) {
			Write-ApiExceptionMsg $response
			return $false
		}
	}
	return $true
}
