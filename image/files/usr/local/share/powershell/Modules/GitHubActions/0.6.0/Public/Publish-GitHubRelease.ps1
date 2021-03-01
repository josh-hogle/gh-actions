function Publish-GitHubRelease {
	<#
	.SYNOPSIS
		Creates a new Release for the given GitHub repository.

	.DESCRIPTION
		Uses the GitHub API to create a new Release for a given repository.
	
		Allows you to specify all of the Release properties, such as the Tag, Name and
		whether it's a Draft or Prerelease.

	.PARAMETER RepositoryPath
		The path to the GitHub repository.
	
	.PARAMETER GitHubAccessToken
		The access token to use for authentication with GitHub.

		Access tokens should be in the form of an OAuth or personal access token, typically
		in the form username:personal_access_token.

	.PARAMETER ReleaseTag
		The tag to create with the release, if it does not exist already.

		If the tag exists already, a new release will be generated and any existing release will
		be removed.

	.PARAMETER ReleaseName
		The name to use for the new release, if different from the ReleaseTag.

	.PARAMETER ReleaseNotes
		The text describing the contents of the release.

	.PARAMETER ExcludeChangelog
		If specified, exclude the notes from the matching release tag in the CHANGELOG file.

	.PARAMETER Changelog
		The name of the CHANGELOG file if it is not CHANGELOG.md.

	.PARAMETER Assets
		An array of assets to attach to the release.

		Each asset must be a PSCustomObject containing the Path and MediaType for the asset.
		It may also contain the AssetName and AssetLabel for the asset.

	.PARAMETER CommitId
		Specifies the commit ID that determines where the Git tag is created.
	
		This can be any branch or commit SHA. It is unused if the ReleaseTag already exists.

	.PARAMETER IsDraft
		If specified, create a draft release.

	.PARAMETER IsPreRelease
		If specified, mark the release as being a pre-release.

	.PARAMETER Force
		If specified, overwrite any existing release with the same tag.

	.INPUTS
		Any parameter can be passed from the pipeline in an object with the same property
		defined.

	.OUTPUTS
		[PSCustomObject] A custom object containing the release_url and id of the new
		release on success or $null on failure.
	#>
	[OutputType([PSCustomObject])]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string] $RepositoryPath,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string] $GitHubAccessToken,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
		[ValidateNotNullOrEmpty()]
		[string] $ReleaseTag,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $ReleaseName = $null,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
		[string] $ReleaseNotes = $null,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
		[switch] $ExcludeChangelog = $false,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
		[string] $Changelog = "./CHANGELOG.md",
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[PSCustomObject[]] $Assets = @(),
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 3)]
		[string] $CommitId = $null,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[switch] $IsDraft = $false,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[switch] $Force = $false,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[switch] $IsPreRelease = $false
	)

	Begin { }

	Process	{
		# append the changelog info to the release notes
		if (-not $ExcludeChangelog) {
			if (-not $PSBoundParameters.ContainsKey("ReleaseNotes") -or [string]::IsNullOrEmpty($ReleaseNotes)) {
				$ReleaseNotes = ""
			} else {
				$ReleaseNotes += "`n`n**Changes Since Last Release**`n"
			}
			if (-not (Test-Path $Changelog)) {
				Write-ErrorMsg "No such file or directory: $Changelog"
				return $null
			}

			# parse the changelog
			$contents = Get-Content $Changelog
			$inRelease = $false
			$changes = @()
			$releaseLinePattern = "^## v?(?<version>(?<major>\d+)(\.(?<minor>\d+))?(\.(?<patch>\d+))?(\-" +
				"(?<pre>[0-9A-Za-z\-\.]+))?(\+(?<build>\d+))?) \((?<release_date>(?<day>\d{2}) (?<month>" +
				"Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (?<year>\d{4}))\)$"
			foreach ($line in $contents) {
				# does the line match a formatted release line
				if ($line -match $releaseLinePattern) {

					# did we match the current release?
					if ($ReleaseTag -eq $Matches['version'] -or $ReleaseTag -eq "v$($Matches['version'])") {
						$inRelease = $true
						continue
					} else {
						$inRelease = $false
						continue
					}
				}

				# skip the blank line immediately after the release
				if ([string]::IsNullOrEmpty($line) -and $changes.Count -eq 0) {
					continue
				}

				# add lines to the changelog
				if ($inRelease) {
					$changes += $line
				}
			}
			$ReleaseNotes += $changes -join "`n"
		}

		# check to see if the release tag exists
		$result = Find-GitHubReleaseTag -RepositoryPath $RepositoryPath -ReleaseTag $ReleaseTag `
			-Token $GitHubAccessToken
		if ($null -eq $result) {
			Write-ErrorMsg "One or more errors occurred while publishing the release"
			return $null
		}

		# configure parameters
		$params = @{}
		if ($PSBoundParameters.ContainsKey("ReleaseNotes") -or -not [string]::IsNullOrEmpty($ReleaseNotes)) {
			$params["ReleaseNotes"] = $ReleaseNotes
		}
		if ($PSBoundParameters.ContainsKey("ReleaseName")) {
			$params["ReleaseName"] = $ReleaseName
		}
		if ($PSBoundParameters.ContainsKey("CommitId")) {
			$params["CommitId"] = $CommitId
		}
		if ($PSBoundParameters.ContainsKey("IsDraft")) {
			$params["IsDraft"] = $IsDraft
		}
		if ($PSBoundParameters.ContainsKey("IsPreRelease")) {
			$params["IsPreRelease"] = $IsPreRelease
		}

		# create / update the release
		if ($result.status_code -eq 404) { # tag does not exist, so just create the release
			$release = New-GitHubRelease -RepositoryPath $RepositoryPath -ReleaseTag $ReleaseTag `
				-Token $GitHubAccessToken @params
			if ($null -eq $release) {
				Write-ErrorMsg "One or more errors occurred while publishing the release"
				return $null
			}
		} elseif (-not $Force) { # tag exists - do not overwrite
			Write-ErrorMsg `
				"A release with the same tag exists. Use the -Force parameter to update the existing release."
			return $null
		} else { # tag exists - overwrite
			$release = Update-GitHubRelease -RepositoryPath $RepositoryPath -ReleaseId $result.data.id `
				-ReleaseTag $ReleaseTag -Token $GitHubAccessToken @params
			if ($null -eq $release) {
				Write-ErrorMsg "One or more errors occurred while updating the release"
				return $null
			}
			
			# remove all existing assets and then upload the new ones
			$result = Remove-GitHubReleaseAssets -RepositoryPath $RepositoryPath -ReleaseId $release.id `
				-Token $GitHubAccessToken
			if (-not $result) {
				Write-ErrorMsg "One or more errors occurred while updating the release"
				return $null
			}
		}

		# attach assets
		foreach ($asset in $Assets) {
			$options = @{}
			if (-not [string]::IsNullOrEmpty($asset.MediaType)) {
				$options["MediaType"] = $asset.MediaType
			}
			if (-not [string]::IsNullOrEmpty($asset.AssetName)) {
				$options["AssetName"] = $asset.AssetName
			}
			if (-not [string]::IsNullOrEmpty($asset.AssetLabel)) {
				$options["AssetLabel"] = $asset.AssetLabel
			}
			$result = New-GitHubReleaseAsset -Path $asset.Path -UploadUrl $release.upload_url `
				-RepositoryPath $RepositoryPath -ReleaseId $release.id @options `
				-Token $GitHubAccessToken
			if ($null -eq $result) {
				Write-ErrorMsg "One or more errors occurred while attaching assets to the release"
				return $null
			}
		}
		return [PSCustomObject]@{ id = $release.id; release_url = $release.url }
	}

	End { }
}
