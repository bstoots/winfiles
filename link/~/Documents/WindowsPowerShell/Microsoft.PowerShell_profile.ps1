
# PSReadline Configuration
###############################################################################
# Bash-style completions
Set-PSReadlineKeyHandler -Key 'Tab' -Function 'Complete'
# Ctrl-d to Exit ... finally!
Set-PSReadlineKeyHandler -Chord 'Ctrl+d' -Function 'DeleteCharOrExit'
###############################################################################

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
