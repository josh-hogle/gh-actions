function Write-ErrorMsg {
	<#
	.SYNOPSIS
		Writes an error message to the console.

	.PARAMETER Message
		The message text to write to the console.

	.PARAMETER Exception
		Optional exception information to add to the message.

	.INPUTS
		None.

	.OUTPUTS
		None.
	#>
	[OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Message,
		[Parameter(Mandatory = $false)]
		[Exception] $Exception = $null
	)

	Write-Host -ForegroundColor "Red" "|ERROR| ${Message}"
	if ($null -ne $Exception) {
		Write-Host -ForegroundColor "Red" $Exception | Format-List -Force
	}
}
