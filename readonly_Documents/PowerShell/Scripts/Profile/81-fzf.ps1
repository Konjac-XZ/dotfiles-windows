$Flavor = $Catppuccin['Mocha']

$env:FZF_DEFAULT_OPTS = @"
--color=hl:$($Flavor.Red),fg:$($Flavor.Text),header:$($Flavor.Red)
--color=info:$($Flavor.Mauve),pointer:$($Flavor.Rosewater),marker:$($Flavor.Rosewater)
--color=fg+:$($Flavor.Text),prompt:$($Flavor.Mauve),hl+:$($Flavor.Red)
--color=border:$($Flavor.Surface2)
--layout=reverse
--cycle
--scroll-off=5
--border
--preview-window=right,60%,border-left
--bind ctrl-u:preview-half-page-up
--bind ctrl-d:preview-half-page-down
--bind ctrl-f:preview-page-down
--bind ctrl-b:preview-page-up
--bind ctrl-g:preview-top
--bind ctrl-h:preview-bottom
--bind alt-w:toggle-preview-wrap
--bind ctrl-e:toggle-preview
"@

function Set-LocationFuzzyEverything {
    param([string]$Directory)

    if ([string]::IsNullOrWhiteSpace($Directory)) {
        $Directory = $PWD.ProviderPath
    }

    $es  = (Get-Command es.exe  -ErrorAction SilentlyContinue)?.Source
    $fzf = (Get-Command fzf.exe -ErrorAction Stop).Source

    if (-not $es) {
        throw "es.exe not found. Install Everything's CLI (ES) or add it to PATH."
    }

    # fzf: --no-sort avoids extra sorting work on huge lists ([Arch Manual Pages](https://man.archlinux.org/man/fzf.1.en?utm_source=chatgpt.com))
    $cmdLine = "`"$es`" -path `"$Directory`" /ad | `"$fzf`" "
    $result = & $env:ComSpec /S /C $cmdLine 2>$null | Select-Object -First 1

    if ($result) { Set-Location -LiteralPath $result }
}

if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
    Set-PsFzfOption -PSReadlineChordProvider "Ctrl+t" -PSReadlineChordReverseHistory "Ctrl+r" -GitKeyBindings -TabExpansion -EnableAliasFuzzyGitStatus -EnableAliasFuzzyEdit -EnableAliasFuzzyFasd -EnableAliasFuzzyKillProcess -EnableAliasFuzzyScoop
}

if (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Chord "Alt+c" -BriefDescription "Fuzzy CD (Everything)" -Description "Select directory with Everything + fzf and Set-Location" -ScriptBlock {
        param($key, $arg)
        Set-LocationFuzzyEverything
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}
