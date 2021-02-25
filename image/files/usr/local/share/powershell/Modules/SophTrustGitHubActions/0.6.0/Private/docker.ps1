function Invoke-DockerLoginCommand {
	<#
	.SYNOPSIS
		Handles actually running the 'docker login' command.

	.PARAMETER Hostname
		The Docker hostname to log into.

	.PARAMETER Username
		The user to authenticate to the registry as.

	.PARAMETER Password
		The password for the user to authenticate as.
	
	.INPUTS
		None.

	.OUTPUTS
		[bool] Returns $true on success or $false on failure.
	#>
	[OutputType([bool])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Hostname,
		[Parameter(Mandatory = $false)]
		[string] $Username = $null,
		[Parameter(Mandatory = $false)]
		[string] $Password = $null
	)

	# construct the argument list
	$inputFile = $null
	$argList = @("login")
	if (-not [string]::IsNullOrEmpty($Username)) {
		$argList += @("-u", $Username)
	}
	if (-not [string]::IsNullOrEmpty($Password)) {
		$inputFile = "${home}/.docker-secret-${pid}"
		$Password | Out-File $inputFile
		$argList += @("--password-stdin")
	}
	$argList += @($Hostname)

	# attempt the login
	try {
		$process = Start-Process -FilePath "docker" -ArgumentList $ArgList -Wait -NoNewWindow -PassThru `
			-RedirectStandardInput $inputFile
		if ($process.ExitCode -ne 0) {
			Write-ErrorMsg "Authentication failed"
			return $false
		}
	} catch {
		Write-ErrorMsg -Exception $_.Exception "'docker login' command failed"
		return $false
	} finally {
		if ($null -ne $inputFile) {
			Remove-Item -ErrorAction "SilentlyContinue" -Force $inputFile
		}
	}
	Write-InfoMsg "Authentication succeeded"
	return $true
}

function Invoke-DockerCommand {
	<#
	.SYNOPSIS
		Handles actually running an arbitrary 'docker' command.

	.PARAMETER ArgList
		The arguments to pass to the 'docker' command.

	.INPUTS
		None.

	.OUTPUTS
		[System.Object] Returns $true on success or $false on failure.
	#>
	[OutputType([bool])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string[]] $ArgList
	)

	try {
		$process = Start-Process -FilePath "docker" -ArgumentList $ArgList -Wait -NoNewWindow -PassThru
		if ($process.ExitCode -ne 0) {
			return $false
		}
	} catch {
		Write-ErrorMsg -Exception $_.Exception "An error occurred running the 'docker' command"
		return $false
	}
	return $true
}
