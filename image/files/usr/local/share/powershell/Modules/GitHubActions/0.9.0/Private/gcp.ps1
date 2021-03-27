
function Invoke-GcrLoginCommand {
	<#
	.SYNOPSIS
		Handles actually running the 'gcloud auth' commands.

	.PARAMETER Hostname
		The GCP registry hostname to log into.

	.PARAMETER EncodedKey
		The base64-encoded service account JSON key.

	.INPUTS
		None.

	.OUTPUTS
		[bool] Returns $true on success or $false on failure.
	#>
	[OutputType([bool])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Hostname,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $EncodedKey
	)

	try {
		# decode the key
		$keyFile = "${home}/.docker-secret-${pid}"
		[System.Convert]::FromBase64String($EncodedKey) | Out-File "${keyFile}"

		# activate the service account
		$argList = @("auth", "activate-service-account", "--quiet", "--key-file", $keyFile)
		$process = Start-Process -FilePath "gcloud" -ArgumentList $argList -Wait -NoNewWindow -PassThru
		if ($process.ExitCode -ne 0) {
			Write-ErrorMsg "Authentication failed: failed to activate service account"
			return $false
		}

		# configure Docker login
		$argList = @("auth", "configure-docker", "--quiet", $Hostname)
		$rc = Start-Process -FilePath "gcloud" -ArgumentList $argList -Wait -NoNewWindow -PassThru
		if ($rc.ExitCode -ne 0) {
			Write-ErrorMsg "Authentication failed"
			return $false
		}
	} catch {
		Write-ErrorMsg -Exception $_.Exception "'gcloud auth' command failed"
		return $false
	} finally {
		Remove-Item -ErrorAction "SilentlyContinue" -Force $keyFile
	}
	Write-InfoMsg "Authentication succeeded"
	return $true
}
