Import-Module posh-git
Import-Module PSReadLine
Import-Module CompletionPredictor
Import-Module Catppuccin

if (Get-Command fzf -ErrorAction SilentlyContinue) {
	Import-Module PSFzf -ErrorAction SilentlyContinue
}
