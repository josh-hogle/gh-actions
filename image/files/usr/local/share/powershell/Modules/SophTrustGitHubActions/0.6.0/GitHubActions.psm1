<#
.SYNOPSIS
	HysolateWorkspace PowerShell root module.

.INPUTS
	None.

.OUTPUTS
	None.
#>

# get public and private function definition files
$Public  = @( Get-ChildItem -Path "${PSScriptRoot}\Public\*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "${PSScriptRoot}\Private\*.ps1" -ErrorAction SilentlyContinue )

# dot source the files
foreach ($import in @($Public + $Private))
{
	try
	{
		Write-Verbose "Importing $($import.FullName)"
		. $import.FullName
	}
	catch
	{
		Write-Error -Message "Failed to import function $($import.FullName): $_"
	}
}

# export public module members
Export-ModuleMember -Function $Public.Basename
