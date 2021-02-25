$ErrorActionPreference = "Stop"
Import-Module GitHubActions

# check commit message for text
if (-not [string]::IsNullOrEmpty(${env:INPUT_LOG-MESSAGE})) {
	try {
		$settings = ConvertFrom-Json -InputObject ${env:INPUT_LOG-MESSAGE}
		if (-not $settings -is [array]) {
			$settings = @($settings)
		}
	} catch {
		Write-ErrorMsg -Exception $_.Exception "Failed to parse JSON settings for the message"
		exit 2
	}

	# search for the text
	$lastLogMessage = & git log -1 --pretty="%s %b"
	Write-DebugMsg "Last log message: ${lastLogMessage}"
	foreach ($setting in $settings) {
		$setVariable = $false
		switch ($setting.verb) {
			"contains" {
				if ($lastLogMessage.Contains($setting.text)) { $setVariable = $true }
			}

			"doesnotcontain" {
				if (-not $lastLogMessage.Contains($setting.text)) { $setVariable = $true }
			}

			"startswith" {
				if ($lastLogMessage.StartsWith($setting.text)) { $setVariable = $true }
			}

			"doesnotstartwith" {
				if (-not $lastLogMessage.StartsWith($setting.text)) { $setVariable = $true }
			}

			"endswith" {
				if ($lastLogMessage.EndsWith($setting.text)) { $setVariable = $true }
			}

			"doesnotendwith" {
				if (-not $lastLogMessage.EndsWith($setting.text)) { $setVariable = $true }
			}

			"equals" {
				if ($lastLogMessage -eq $setting.text) { $setVariable = $true }
			}

			"doesnotequal" {
				if (-not $lastLogMessage -eq $setting.text) { $setVariable = $true }
			}
			default {
				Write-ErrorMsg "$($setting.verb): unknown verb for log message condition"
				exit 2
			}
		}
		if ($setVariable) {
			Set-OutputVariable -Name $setting.variable -Value $setting.value
		}
	}
}

# check files for changes
if (-not [string]::IsNullOrEmpty(${env:INPUT_CHANGED-FILES})) {
	try {
		$settings = ConvertFrom-Json -InputObject ${env:INPUT_CHANGED-FILES}
		if (-not $settings -is [array]) {
			$settings = @($settings)
		}
	} catch {
		Write-ErrorMsg -Exception $_.Exception "Failed to parse JSON settings for the message"
		exit 2
	}

	# check each path for changes
	$filesChanged = & git diff --name-only HEAD HEAD~1
	Write-DebugMsg "Files changed since last commit: $($filesChanged -join " ")"
	$stripPath = "$($pwd.Path)/"
	foreach ($setting in $settings) {
		$setVariable = $false

		# build the list of source files we need to check
		$sourceFiles = @()
		foreach ($path in $setting.paths) {
			if (-not (Test-Path($path))) {
				Write-WarnMsg "${path}: skipping non-existent source file path"
				continue
			}
			if ($setting.recurse) {
				$sourceFiles += Get-ChildItem -Path $path -Recurse | ForEach-Object { $_.Fullname -replace $stripPath }
			} else {
				$sourceFiles += Get-ChildItem -Path $path | ForEach-Object { $_.Fullname -replace $stripPath }
			}
		}
		Write-DebugMsg "Comparing changed files with sources: $($sourceFiles -join " ")"

		# do the file lists overlap?
		switch ($setting.verb) {
			"includes" {
				$count = (Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $filesChanged -IncludeEqual `
					-ExcludeDifferent).Count
				if ($count -gt 0) { $setVariable = $true }
			}
			"doesnotinclude" {
				$count = (Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $filesChanged -IncludeEqual `
					-ExcludeDifferent).Count
				if ($count -eq 0) { $setVariable = $true }
			}
			default {
				Write-ErrorMsg "$($setting.verb): unknown verb for changed files condition"
				exit 2
			}
		}
		if ($setVariable) {
			Set-OutputVariable -Name $setting.variable -Value $setting.value
		}
	}
}
exit 0
