function Set-OutputVariable {
	<#
	.SYNOPSIS
		Sets an output variable.

	.PARAMETER Name
		The name of the variable to set.

	.PARAMETER Value
		The value of the variable.

	.INPUTS
		Any parameter can be passed from the pipeline in an object with the same property
		defined.

	.OUTPUTS
		None.
	#>
	[OutputType([void])]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
		[string] $Name,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
		[string] $Value
	)

	Write-InfoMsg "Setting output variable: ${Name}=${Value}"
	# There is a bug in nektos/act where variables don't always get set the first time so we need to output it twice
	Write-Output "::set-output name=${Name}::${Value}"
	Write-Output "::set-output name=${Name}::${Value}"
}
