
$originalWd = pwd

# TODO - Force PSBabushka to scan WindowsPowerShell directory regardless of start directory
# For now just cd there
cd (Split-Path -Parent $PROFILE)

# PSBabushka - Config management
if (Get-Module -ListAvailable | Where-Object {$_.name -eq "PSBabushka"}) {
  Import-Module PSBabushka
}
else {
  # The version of PSBabushka in PsGet isn't current.  Get from git for now
  git clone "git@github.com:PSBabushka/PSBabushka.git" "$PSScriptRoot\Modules\PSBabushka"
  Import-Module PSBabushka
}

# Make sure PsGet is installed
Invoke-PSBabushka 'PsGet-Installed' *>$null

# Make sure PSReadLine is installed
Invoke-PSBabushka 'PSReadLine-Installed' *>$null
# TODO - Move these into their own directories or something ...
Invoke-PSBabushka 'PSReadline-Config-TabComplete' *>$null

# Make sure PoshGit is installed
Invoke-PSBabushka 'PoshGit-Installed' *>$null

# posh-git - Git goodies, prompt etc
# TODO - Figure out a way to do this with PSBabushka
if (Get-Module posh-git) {
  # Set up a simple prompt, adding the git prompt parts inside git repos
  # D:\Users\bstoots\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1
  function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE
    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
    Write-Host($pwd.ProviderPath) -nonewline
    Write-VcsStatus
    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
  }
  Enable-GitColors
}

cd $originalWd