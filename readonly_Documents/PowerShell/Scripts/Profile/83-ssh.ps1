function Resolve-SshConfigPath {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,

		[Parameter(Mandatory = $true)]
		[string]$BaseDirectory
	)

	$expanded = [Environment]::ExpandEnvironmentVariables($Path)
	if ($expanded.StartsWith('~/') -or $expanded.StartsWith('~\')) {
		$expanded = Join-Path $HOME $expanded.Substring(2)
	}

	if ([System.IO.Path]::IsPathRooted($expanded)) {
		return $expanded
	}

	return Join-Path $BaseDirectory $expanded
}

$script:SshCompletionLogPath = Join-Path $HOME '.ssh\completion-debug.log'

function Write-SshCompletionLog {
	param(
		[string]$Message
	)

	if ($env:SSH_COMPLETION_DEBUG -ne '1') {
		return
	}

	$timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
	$line = "[$timestamp] $Message"
	Add-Content -LiteralPath $script:SshCompletionLogPath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Get-SshConfigHostList {
	param(
		[string]$ConfigPath = (Join-Path $HOME '.ssh\config')
	)

	$visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
	$hosts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

	function Parse-SshConfigFile {
		param(
			[Parameter(Mandatory = $true)]
			[string]$Path
		)

		$resolvedPath = $Path
		if (-not [System.IO.Path]::IsPathRooted($resolvedPath)) {
			$resolvedPath = Resolve-Path -LiteralPath $resolvedPath -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Path
		}

		if ([string]::IsNullOrWhiteSpace($resolvedPath) -or -not (Test-Path -LiteralPath $resolvedPath)) {
			return
		}

		if (-not $visited.Add($resolvedPath)) {
			return
		}

		$currentDirectory = Split-Path -Parent $resolvedPath
		$lines = Get-Content -LiteralPath $resolvedPath -ErrorAction SilentlyContinue

		foreach ($line in $lines) {
			$trimmed = $line.Trim()
			if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
				continue
			}

			if ($trimmed -match '^(?i)Host\s+(.+)$') {
				foreach ($token in ($matches[1] -split '\s+')) {
					if (
						-not [string]::IsNullOrWhiteSpace($token) -and
						-not $token.Contains('*') -and
						-not $token.Contains('?') -and
						-not $token.StartsWith('!')
					) {
						[void]$hosts.Add($token)
					}
				}

				continue
			}

			if ($trimmed -match '^(?i)Include\s+(.+)$') {
				foreach ($includeToken in ($matches[1] -split '\s+')) {
					if ([string]::IsNullOrWhiteSpace($includeToken)) {
						continue
					}

					$includePath = Resolve-SshConfigPath -Path $includeToken -BaseDirectory $currentDirectory
					$matchingFiles = Get-ChildItem -Path $includePath -File -ErrorAction SilentlyContinue
					foreach ($file in $matchingFiles) {
						Parse-SshConfigFile -Path $file.FullName
					}
				}
			}
		}
	}

	Parse-SshConfigFile -Path $ConfigPath
	return @($hosts) | Sort-Object
}

$script:SshHostsCache = $null
$script:SshHostsCachePath = $null
$script:SshHostsCacheTime = $null

function Get-CachedSshHostList {
	$configPath = Join-Path $HOME '.ssh\config'

	if (-not (Test-Path -LiteralPath $configPath)) {
		Write-SshCompletionLog "config not found at $configPath"
		return @()
	}

	$configInfo = Get-Item -LiteralPath $configPath -ErrorAction SilentlyContinue
	if (-not $configInfo) {
		return @()
	}

	if (
		$script:SshHostsCache -and
		$script:SshHostsCachePath -eq $configPath -and
		$script:SshHostsCacheTime -eq $configInfo.LastWriteTimeUtc
	) {
		Write-SshCompletionLog "cache hit for $configPath ($($script:SshHostsCache.Count) hosts)"
		return $script:SshHostsCache
	}

	$script:SshHostsCache = Get-SshConfigHostList -ConfigPath $configPath
	$script:SshHostsCachePath = $configPath
	$script:SshHostsCacheTime = $configInfo.LastWriteTimeUtc
	Write-SshCompletionLog "cache refreshed from $configPath ($($script:SshHostsCache.Count) hosts)"
	return $script:SshHostsCache
}

Register-ArgumentCompleter -Native -CommandName ssh -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	Write-SshCompletionLog "completer invoked: word='$wordToComplete' cursor=$cursorPosition line='$($commandAst.Extent.Text)'"

	if ($wordToComplete -like '-*') {
		return
	}

	$hosts = Get-CachedSshHostList
	if (-not $hosts -or $hosts.Count -eq 0) {
		Write-SshCompletionLog 'no hosts returned by parser'
		return
	}

	$userPrefix = $null
	$hostQuery = $wordToComplete
	if ($wordToComplete -match '^(?<user>[^@]+)@(?<host>.*)$') {
		$userPrefix = $matches['user']
		$hostQuery = $matches['host']
	}

	$displayHosts = if ($userPrefix) {
		$hosts | ForEach-Object { "$userPrefix@$_" }
	} else {
		$hosts
	}

	$selected = $null
	if (Get-Command fzf -ErrorAction SilentlyContinue) {
		Write-SshCompletionLog "opening fzf with query '$hostQuery' and $($displayHosts.Count) candidates"
		$selected = $displayHosts |
			fzf --query "$hostQuery" --prompt 'ssh> ' --select-1 --exit-0 --height 40%
	}

	if ([string]::IsNullOrWhiteSpace($selected)) {
		Write-SshCompletionLog 'fzf returned no selection, using prefix fallback'
		$displayHosts |
			Where-Object { $_ -like "$wordToComplete*" } |
			ForEach-Object {
				[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
			}
		return
	}

	Write-SshCompletionLog "selected host '$selected'"
	[System.Management.Automation.CompletionResult]::new($selected, $selected, 'ParameterValue', $selected)
}

if (Get-Command Invoke-FzfTabCompletion -ErrorAction SilentlyContinue) {
	Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
		param($key, $arg)

		$line = $null
		$cursor = $null
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
		$lineToCursor = if ($line -and $cursor -ge 0) { $line.Substring(0, $cursor) } else { '' }

		if ($lineToCursor -match '^\s*ssh(?:\.exe)?(?:\s+.*)?$') {
			Write-SshCompletionLog "Tab routed to PSReadLine completion for line '$lineToCursor'"
			[Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext($key, $arg)
			return
		}

		Write-SshCompletionLog "Tab routed to Invoke-FzfTabCompletion for line '$lineToCursor'"
		Invoke-FzfTabCompletion
	}
}
