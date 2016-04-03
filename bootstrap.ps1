#
#
#

param (
  [switch]$Force = $false,
  [switch]$Verbose = $false
)

$statusSuccess  = "+"
$statusFailure  = "-"
$statusForced   = "!"
$statusNoChange = "@"

$labelRegistry = "registry"
$labelSymlink  = "symlink"

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
  Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
}
if (!(Get-Module -ListAvailable -Name "Pscx")) {
  Install-Module -Name Pscx -Force -ErrorAction Stop
}
if (!(Get-Module -ListAvailable -Name "PSConfig")) {
  Install-Module -Name PSConfig -Force -ErrorAction Stop
}
if (!(Get-Module -ListAvailable -Name "Carbon")) {
  Install-Module -Name Carbon -Force -ErrorAction Stop
}

# Initialize configs
Clear-ConfigurationSource
Add-FileConfigurationSource -Path ".\config.json" -Format "Json"

# Check and install registry keys
$registry = Get-ConfigurationItem -Key "registry"
if ($registry -ne $null) {
  # A single object gets squashed, re-expand it to an array
  if (!$registry.getType().IsArray) {
    $registry = @($registry)
  }
  foreach ($reg in $registry) {
    $oldVal = $null
    if (Test-RegistryKeyValue -Path $reg.path -Name $reg.key) {
      # Key value exists but does not match incoming.  Should we overwrite?
      if ((Get-RegistryKeyValue -Path $reg.path -Name $reg.key) -ne $reg.val) {
        $oldVal = Get-RegistryKeyValue -Path $reg.path -Name $reg.key
        if ($Force) {
          Set-RegistryKeyValue -Path $reg.path -Name $reg.key -String $reg.val
          formatLine $statusForced $labelRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
        } else {
          formatLine $statusFailure $labelRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
        }
      }
      # Else key is already set to incoming value, no need to set again
      else {
        formatLine $statusNoChange $labelRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
      }
    }
    # Key does not exist, create and set it
    else {
      Set-RegistryKeyValue -Path $reg.path -Name $reg.key -String $reg.val
      formatLine $statusSuccess $labelRegistry ("$($reg.path)\$($reg.key)") $oldVal $reg.val
    }
  }
}

# Configure symlinks
$symlink = Get-ConfigurationItem -Key "symlink"
if ($symlink -ne $null) {
  # A single object gets squashed, re-expand it to an array
  if (!$symlink.getType().IsArray) {
    $symlink = @($symlink)
  }
  foreach ($sym in $symlink) {
    $oldVal = $null
    $expandedTarget = $ExecutionContext.InvokeCommand.ExpandString($sym.target)
    $expandedLink = $ExecutionContext.InvokeCommand.ExpandString($sym.link)
    # Make sure TargetPath is set otherwise there's no point in continuing
    if (!(Test-Path -Path $expandedTarget)) {
      formatLine $statusFailure $labelSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedTarget
      continue
    }
    
    # If $expandedLink is already a symlink lets just assume it's one of ours
    if (Test-PathIsSymlink $expandedLink) {
      formatLine $statusNoChange $labelSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
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
          formatLine $statusForced $labelSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
        } else {
          Write-Error "Too many backups spoil the broth"
          formatLine $statusFailure $labelSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
        }
      }
      # Without -Force just report failure
      else {
        formatLine $statusFailure $labelSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedTarget
      }
    }
    # Nothing at link path, go ahead and link it up
    else {
      New-Symlink -TargetPath $expandedTarget -LiteralPath $expandedLink | Out-Null
      formatLine $statusSuccess $labelSymlink ("$($sym.link) -> $($sym.target)") $oldVal $expandedLink
    }
  }
}

