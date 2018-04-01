<#
.Synopsis
   Like dotfiles but for Windows!
.Link
  https://github.com/bstoots/winfiles
.Description
  Configures Windows machines for development by setting up registry keys, creating symlinks,
  installing Powershell modules, and more.
.Example
   .\bin\winfiles.ps1
#>

# 
# Constants
# 

Set-Variable WINFILES_ROOT -Option ReadOnly -Value (Split-Path -Path $PSScriptRoot -Parent)
Set-Variable WINFILES_BACKUPS -Option ReadOnly -Value "$WINFILES_ROOT\backups"
Set-Variable WINFILES_BIN     -Option ReadOnly -Value "$WINFILES_ROOT\bin"
Set-Variable WINFILES_CACHES  -Option ReadOnly -Value "$WINFILES_ROOT\caches"
Set-Variable WINFILES_CONF    -Option ReadOnly -Value "$WINFILES_ROOT\conf"
Set-Variable WINFILES_COPY    -Option ReadOnly -Value "$WINFILES_ROOT\copy"
Set-Variable WINFILES_LINK    -Option ReadOnly -Value "$WINFILES_ROOT\link"
Set-Variable WINFILES_SOURCE  -Option ReadOnly -Value "$WINFILES_ROOT\source"
Set-Variable WINFILES_TEST    -Option ReadOnly -Value "$WINFILES_ROOT\test"
Set-Variable WINFILES_VENDOR  -Option ReadOnly -Value "$WINFILES_ROOT\vendor"

# 
# Functions
# 

Function walk {
  param(
    [string] $basePath,
    [scriptblock] $block
  )
  Get-ChildItem -Recurse $basePath | Foreach-Object {
    $srcPath = $_.FullName
    $dstPath = $_.FullName.Replace($basePath, "").TrimStart("\")
    $pathType = $null
  
    if (Test-Path -Path "$srcPath" -PathType Container) {
      $pathType = "Container"
    }
    elseif (Test-Path -Path "$srcPath" -PathType Leaf) {
      $pathType = "Leaf"
    }
    else {
      # @TODO - Catch this, just in case
    }
    # Call the script block and pass src, dest, and type
    $block.invoke($srcPath, $dstPath, $pathType)
  }
}

# Walk over files to be copied
walk $WINFILES_COPY {
  param(
    [string] $srcPath,
    [string] $dstPath,
    [string] $pathType
  )
  # Continue on to next iteration if destination object exists
  if (Test-Path -Path "$dstPath" -PathType "$pathType") {
    if ($pathType -eq "Container") {
      return
    }
    elseif ($pathType -eq "Leaf") {
      # New-Item -ItemType File -Path "$WINFILES_BACKUPS\$dstPath" -Force | Out-Null
      # Copy-Item -Path "$srcPath" -Destination "$WINFILES_BACKUPS\$dstPath" -Force
      Write-Output Exists
      return
    }
    else {
      # @TODO - Catch this, just in case
      return
    }
  }
  # Create the thing
  if ($pathType -eq "Container") {
    New-Item -ItemType Directory -Path "$dstPath" | Out-Null
  }
  elseif ($pathType -eq "Leaf") {
    Copy-Item -Path "$srcPath" -Destination "$dstPath"
  }
  else {
    # @TODO - Catch this, just in case
  }
}

# Walk over files to be linked
walk $WINFILES_LINK {
  param(
    [string] $srcPath,
    [string] $dstPath,
    [string] $pathType
  )
  # Continue on to next iteration if destination object exists
  if (Test-Path -Path "$dstPath" -PathType "$pathType") {
    if ($pathType -eq "Container") {
      return
    }
    elseif ($pathType -eq "Leaf") {
      # New-Item -ItemType File -Path "$WINFILES_BACKUPS\$dstPath" -Force | Out-Null
      # Copy-Item -Path "$srcPath" -Destination "$WINFILES_BACKUPS\$dstPath" -Force
      Write-Output Exists
      return
    }
    else {
      # @TODO - Catch this, just in case
      return
    }
  }
  # Create the thing
  if ($pathType -eq "Container") {
    New-Item -ItemType Directory -Path "$dstPath" | Out-Null
  }
  elseif ($pathType -eq "Leaf") {
    New-Item -Value "$srcPath" -ItemType SymbolicLink -Path "$dstPath" | Out-Null
  }
  else {
    # @TODO - Catch this, just in case
  }
}

