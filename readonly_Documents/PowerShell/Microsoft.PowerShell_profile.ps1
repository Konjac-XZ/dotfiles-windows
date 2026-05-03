$profileRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$profileScripts = Join-Path $profileRoot "Scripts\Profile"

function Test-InteractiveSession {
  if (-not [Environment]::UserInteractive) {
    return $false
  }

  try {
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
      return $false
    }
  } catch {
    return $false
  }

  return $null -ne $Host.UI -and $null -ne $Host.UI.RawUI
}

if (-not (Test-InteractiveSession)) {
  return
}

$startupScripts = @(
  "10-modules.ps1"
  "20-prompt.ps1"
  "30-theme.ps1"
  "40-aliases.ps1"
  "50-env.ps1"
  "80-psreadline.ps1"
  "81-fzf.ps1"
  "82-zoxide.ps1"
  "83-ssh.ps1"
)

foreach ($script in $startupScripts) {
  $scriptPath = Join-Path $profileScripts $script
  if (Test-Path $scriptPath) {
    . $scriptPath
  }
}
