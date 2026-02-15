function ll {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        $RemainingArgs
    )

    & eza -l --group-directories-first --icons --git --color=always @RemainingArgs
}

function y {
	$tmp = (New-TemporaryFile).FullName
	yazi.exe $args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}