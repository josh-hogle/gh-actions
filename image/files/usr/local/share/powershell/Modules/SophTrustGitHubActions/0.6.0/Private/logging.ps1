function Write-ApiExceptionMsg {
	<#
	.SYNOPSIS
		Converts the given API exception to an error message that is logged.

	.PARAMETER Exception
		The API exception to log.

	.INPUTS
		None.

	.OUTPUTS
		None.
	#>
	[OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[PSCustomObject] $Exception
	)

	$message = "API request returned HTTP code $($Exception.status_code.value__) ($($Exception.status_code)):"
	if ($null -ne $Exception.details.message) {
		$message += "`n" +
			"   message: $($Exception.details.message)`n" +
			"   documentation_url: $($Exception.details.documentation_url)`n"
		foreach ($err in $Exception.details.errors) {
			$message += "   error: Resource=$($err.resource) Code=$($err.code) Field=$($err.field)"
		}
		Write-ErrorMsg $message
	} else {
		Write-ErrorMsg -Exception $Exception.exception $message
	}
}
