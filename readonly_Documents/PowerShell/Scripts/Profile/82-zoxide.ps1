$env:_ZO_ECHO = "1"

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	Invoke-Expression (& { (zoxide init powershell --hook prompt | Out-String) })
}
