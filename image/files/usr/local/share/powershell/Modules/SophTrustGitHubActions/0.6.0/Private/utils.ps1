function Split-ImageUrl {
	<#
	.SYNOPSIS
		Splits an image URL into protocol, hostname and path

	.PARAMETER ImageUrl
		The URL to split.

	.INPUTS
		None.

	.OUTPUTS
		[PSCustomObject] Returns an object containing proto, hostname and path properties
		on success or $null on failure.
	#>
	[OutputType([PSCustomObject])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $ImageUrl
	)

	($proto, $image) = $ImageUrl -split "://"
	switch ($proto) {
		# Generic Docker registry / Docker Hub
		"docker" {
		  	Write-DebugMsg "Docker registry URL detected"
		  	($hostname, $path) = $image -split "/",2
		  	if ([string]::IsNullOrEmpty($hostname)) {
				$hostname = "index.docker.io"
			}
	  	}

		# GitHub Container Regsitry
		"ghcr" {
		  	Write-DebugMsg "GitHub Container Registry URL detected"
		  	($hostname, $path) = $image -split "/",2
		  	if ([string]::IsNullOrEmpty($hostname)) {
				$hostname = "ghcr.io"
		  	}
		}

	  	# Google Container Registry
	  	"gcr" {
			Write-DebugMsg "Google Container Registry URL detected"
			($hostname, $path) = $image -split "/",2
			if ([string]::IsNullOrEmpty($hostname)) {
				$hostname = "gcr.io"
		  	}
		}

		# Unknown registry type
		default {
		  	Write-ErrorMsg "Unsupported Docker registry protocol: ${proto}"
		  	return $null
		}
	}

	Write-DebugMsg "Split-ImageUrl: Protocol = ${proto}, Hostname = ${hostname}, Path = ${path}"
	return [PSCustomObject]@{
		proto = $proto
		hostname = $hostname
		path = $path
	}
}

Function Invoke-Command {
	<#
	.SYNOPSIS
		Runs an arbitrary command and waits for it to finish.

	.PARAMETER Command
		The command to execute.

	.PARAMETER ArgList
		Any arguments to pass to the command.

	.INPUTS
		None.

	.OUTPUTS
		[System.Object] An object containing the StdOut and StdErr contents as well as the ExitCode from the process.
	#>
	[OutputType([System.Object])]
	param(
		[string] $Command,
		[string[]] $ArgList
	)

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $Command
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $ArgList -join " "
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    return @{
        StdOut = $p.StandardOutput.ReadToEnd()
        StdErr = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode
    }
}
