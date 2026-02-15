Import-Module posh-git
Import-Module PSReadLine
Import-Module CompletionPredictor
Import-Module Catppuccin
Import-Module PSEverything
if (Get-Command fzf -ErrorAction SilentlyContinue) {
	Import-Module PSFzf -ErrorAction SilentlyContinue
}
