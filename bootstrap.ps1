<#
.Synopsis
   Like dotfiles but for Windows!
.Link
  https://github.com/bstoots/winfiles
.Description
  Configures Windows machines for development by setting up registry keys, creating symlinks,
  installing Powershell modules, and more.
.Example
   .\bootstrap.ps1
#>

param (
  [switch]$Force = $false,
  [switch]$Verbose = $false
)

$statusSuccess  = "+"
$statusFailure  = "-"
$statusForced   = "!"
$statusNoChange = "@"

Set-Variable sectionRegistry -option Constant -value "registry"
Set-Variable sectionSymlink -option Constant -value "symlink"
Set-Variable sectionPsModule -option Constant -value "psmodule"
Set-Variable sectionPath -option Constant -value "path"

$maxBackups = 10

# 
# Functions
# 

# 
# 
# 
Function formatLine([string]$status, [string]$label, [string]$key, $old, $new) {
  Write-Host "$($status) [$($label)] $($key)"
  if ($Verbose) {
    if ($old) { Write-Host -Foreground "Red" "$($old)" } else { Write-Host -Foreground "Yellow" "<?>" }
    if ($new) { Write-Host -Foreground "Green" "$($new)" } else { Write-Host -Foreground "Yellow" "<null>" }
  }
}

# 
# 
# 
Function Test-PathIsSymlink([string]$path) {
  return [bool]((Get-Item $path -Force -ea 0).Attributes -band [IO.FileAttributes]::ReparsePoint)
}

# 
# Main
# 

# Bootstrap necessary packages

# Get NuGet so we can use Powershell Gallery to grab additional modules $$$$$$$
if (!(Get-PackageProvider -ListAvailable -Name "NuGet" -ErrorAction SilentlyContinue)) {
  Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
if (!(Get-Module -ListAvailable -Name "Pscx")) {
  Install-Module -Name Pscx -Force -Scope CurrentUser -ErrorAction Stop
}
if (!(Get-Module -ListAvailable -Name "PSConfig")) {
  Install-Module -Name PSConfig -Force -Scope CurrentUser -ErrorAction Stop
}
if (!(Get-Module -ListAvailable -Name "Carbon")) {
  Install-Module -Name Carbon -Force -Scope CurrentUser -ErrorAction Stop
}

# Initialize configs
Clear-ConfigurationSource
Add-FileConfigurationSource -Path ".\config.json" -Format "Json"

# Check and install registry keys
$registry = Get-ConfigurationItem -Key $sectionRegistry
if ($registry -ne $null) {
  # A single object gets squashed, re-expand it to an array
  $registry = @($registry)
  foreach ($reg in $registry) {
    $oldVal = $null
    if (Test-RegistryKeyValue -Path $reg.path -Name $reg.key) {
      # Key value exists but does not match incoming.  Should we overwrite?
      if ((Get-RegistryKeyValue -Path $reg.path -Name $reg.key) -ne $reg.val) {
        $oldVal = Get-RegistryKeyValue -Path $reg.path -Name $reg.key
        if ($Force) {
          Set-RegistryKeyValue -Path $reg.path -Name $reg.key -String $reg.val
          formatLine $statusForced $sectionRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
        } else {
          formatLine $statusFailure $sectionRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
        }
      }
      # Else key is already set to incoming value, no need to set again
      else {
        formatLine $statusNoChange $sectionRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
      }
    }
    # Key does not exist, create and set it
    else {
      Set-RegistryKeyValue -Path $reg.path -Name $reg.key -String $reg.val
      formatLine $statusSuccess $sectionRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
    }
  }
}

# Configure symlinks
$symlink = Get-ConfigurationItem -Key $sectionSymlink
if ($symlink -ne $null) {
  # A single object gets squashed, re-expand it to an array
  $symlink = @($symlink)
  foreach ($sym in $symlink) {
    $oldVal = $null
    $expandedTarget = $ExecutionContext.InvokeCommand.ExpandString($sym.target)
    $expandedLink = $ExecutionContext.InvokeCommand.ExpandString($sym.link)
    # Make sure TargetPath is set otherwise there's no point in continuing
    if (!(Test-Path -Path $expandedTarget)) {
      formatLine $statusFailure $sectionSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedTarget
      continue
    }
    
    # If $expandedLink is already a symlink lets just assume it's one of ours
    if (Test-PathIsSymlink $expandedLink) {
      formatLine $statusNoChange $sectionSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
      continue
    }

    # See if there's anything living at our link path
    if (Test-Path -Path $expandedLink) {
      #  If we're going to attempt to force it make a backup just in case
      if ($Force) {
        # If we are forcing it we'll keep a few backups, just in case
        for ($i = 0; $i -le $maxBackups; $i++) {
          if (!(Test-Path -Path ("$($expandedLink).winfiles.$($i)") )) {
            Move-Item -Force -Path $expandedLink -Destination ("$($expandedLink).winfiles.$($i)")
            break
          }
        }
        #  Make sure the file is no longer present then link it up
        if (!(Test-Path -Path $expandedLink)) {
          New-Symlink -TargetPath $expandedTarget -LiteralPath $expandedLink | Out-Null
          formatLine $statusForced $sectionSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
        } else {
          Write-Error "Too many backups spoil the broth"
          formatLine $statusFailure $sectionSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
        }
      }
      # Without -Force just report failure
      else {
        formatLine $statusFailure $sectionSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedTarget
      }
    }
    # Nothing at link path, go ahead and link it up
    else {
      New-Symlink -TargetPath $expandedTarget -LiteralPath $expandedLink | Out-Null
      formatLine $statusSuccess $sectionSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
    }
  }
}

# Install additional Powershell modules
$psmodule = Get-ConfigurationItem -Key $sectionPsModule
if ($psmodule -ne $null) {
  # A single object gets squashed, re-expand it to an array
  $psmodule = @($psmodule)
  foreach ($module in $psmodule) {
    # See if this module is already installed
    $oldMod = Get-Module -ListAvailable -Name $module.name -ErrorAction SilentlyContinue
    if ($oldMod) {
      $oldModVersion = [string]$oldMod.version
      # For now just continue if the module is already installed, later we could do something
      # more interesting in here like version checking + upgrade
      formatLine $statusNoChange $sectionPsModule $module.name $oldModVersion $newModVersion
      continue
    }
    Try {
      $newMod = Install-Module -Name $module.name -Scope CurrentUser
      if ($newMod) {
        $newModVersion = [string]$newMod.version
      }
      formatLine $statusSuccess $sectionPsModule $module.name $oldModVersion $newModVersion
    } Catch {
      formatLine $statusFailure $sectionPsModule $module.name $oldModVersion $newModVersion
    }
  }
}

# Install additional Powershell modules
$paths = Get-ConfigurationItem -Key $sectionPath
if ($paths -ne $null) {
  # A single object gets squashed, re-expand it to an array
  $paths = @($paths)
  foreach ($path in $paths) {
    # Snag existing path
    $oldPath = [environment]::GetEnvironmentVariable("Path", "User")
    $escapedPath = [Regex]::Escape($ExecutionContext.InvokeCommand.ExpandString($path.value))
    if ($oldPath -notmatch ";??$escapedPath;") {
      if ($oldPath -ne "" -and $oldPath -ne $null -and $oldPath -match ";$") {
        $newPath = "$($oldPath);"
      } else {
        $newPath = $oldPath
      }
      $newPath += "$($path.value);"
      Set-EnvironmentVariable -Name 'Path' -Value $newPath -ForUser
      formatLine $statusSuccess $sectionPath $path.value $oldPath $newPath
    }
    # Otherwise the path value already exists
    else {
      formatLine $statusNoChange $sectionPath $path.value $oldPath $newPath
    }
  }
}
