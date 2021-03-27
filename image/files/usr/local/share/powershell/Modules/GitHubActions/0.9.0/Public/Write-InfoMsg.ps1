function Write-InfoMsg {
	<#
	.SYNOPSIS
		Writes an informational message to the console.

	.PARAMETER Message
		The message text to write to the console.

	.INPUTS
		None.

	.OUTPUTS
		None.
	#>
	[OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Message
	)

	Write-Host -ForegroundColor "Cyan" "|INFO| ${Message}"
}
