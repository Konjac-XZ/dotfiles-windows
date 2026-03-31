$Flavor = $Catppuccin['Mocha']

if (Get-Command Invoke-FzfTabCompletion -ErrorAction SilentlyContinue) {
  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
}
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -ScriptBlock {
    param($key, $arg)
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($cursor -lt $line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardWord($key, $arg)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
    }
}

Set-PSReadLineKeyHandler -Key UpArrow -Function PreviousHistory
Set-PSReadLineKeyHandler -Key DownArrow -Function NextHistory

$Colors = @{

  ContinuationPrompt     = $Flavor.Teal.Foreground()
  Emphasis               = $Flavor.Red.Foreground()
  Selection              = $Flavor.Surface0.Background()

  InlinePrediction       = $Flavor.Overlay0.Foreground()
  ListPrediction         = $Flavor.Mauve.Foreground()
  ListPredictionSelected = $Flavor.Surface0.Background()

  Command                = $Flavor.Blue.Foreground()
  Comment                = $Flavor.Overlay0.Foreground()
  Default                = $Flavor.Text.Foreground()
  Error                  = $Flavor.Red.Foreground()
  Keyword                = $Flavor.Mauve.Foreground()
  Member                 = $Flavor.Rosewater.Foreground()
  Number                 = $Flavor.Peach.Foreground()
  Operator               = $Flavor.Sky.Foreground()
  Parameter              = $Flavor.Pink.Foreground()
  String                 = $Flavor.Green.Foreground()
  Type                   = $Flavor.Yellow.Foreground()
  Variable               = $Flavor.Lavender.Foreground()
}

$PSReadLineOptions = @{

  Color                = $Colors
  ExtraPromptLineCount = $true
  HistoryNoDuplicates  = $true
  MaximumHistoryCount  = 5000
  BellStyle            = "None"
}

$supportsVT = $false
if ($Host.UI -and ($Host.UI.PSObject.Properties.Name -contains 'SupportsVirtualTerminal')) {
  $supportsVT = [bool]$Host.UI.SupportsVirtualTerminal
}

if ($supportsVT -and -not [Console]::IsOutputRedirected) {
  $PSReadLineOptions['PredictionSource'] = 'HistoryAndPlugin'
  $PSReadLineOptions['PredictionViewStyle'] = 'ListView'
  $PSReadLineOptions['ShowToolTips'] = $true
}

Set-PSReadLineOption @PSReadLineOptions
