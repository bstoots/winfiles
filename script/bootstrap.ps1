#
#
#

# Define CLI args
param (
  # $mode - Which mode to run the bootstrap script in.  Options are:
  #   * report
  #   * link
  #   * backup
  [string]$mode = "report"
)

# Define consts
Set-Variable MKLINK_DEF -option Constant -value ".mklink.def"
Set-Variable WINFILE_ROOT -option Constant -value (Join-Path -Path $PSCommandPath -ChildPath ..\.. -Resolve)

<# 
  Search given directory recursively for .mklink.def files
#>
Function Get-MklinkDefDir($dir) {
  Get-ChildItem -Filter $MKLINK_DEF -Recurse -Path $dir -File
}

<# 
#>
Function Get-MklinkDefCsvRow($csv) {
  Import-Csv -Header link,target $csv
}

<# 
#>
Function Expand-Path ([string]$path, [string]$working_dir = ".") {
  # If path is relative expand it relative to the working directory
  if ($path.StartsWith(".")) {
    # If working_dir is relative expand it
    if ($working_dir.StartsWith(".")) {
      $working_dir = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($working_dir).toString())
    }
    else {
      $working_dir = [System.Environment]::ExpandEnvironmentVariables($working_dir).toString()
    }
    # 
    $expanded_path = [System.IO.Path]::GetFullPath(
      (Join-Path (
        Join-Path ($working_dir) .) ([System.Environment]::ExpandEnvironmentVariables($path).toString())
      )
    )
  }
  # If path is not relative just expand the env vars
  else {
    $expanded_path = [System.Environment]::ExpandEnvironmentVariables($path).toString()
  }
  # Return expanded path
  $expanded_path
}

<# 
#>
Function Backup-Path ([string]$path, [string]$archive) {
  if (!(Test-Path -Path $archive)) {
    $null | Write-Zip -Quiet -OutputPath $archive
  }
 Get-ChildItem -Recurse $path | Write-Zip -Quiet -IncludeEmptyDirectories -EntryPathRoot $(Split-Path -Parent $path) -OutputPath $archive
}

<#
#>
function Is-Symlink([string]$path) {
  $file = Get-Item $path -Force -ea 0
  [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

<# 
  Main
#>
Get-MklinkDefDir $WINFILE_ROOT | ForEach-Object -process {
  $working_dir = $_.Directory
  # Might be worthwhile to move this to its own backup dir or something.  we'll see.
  $archive = "$working_dir\$(Split-Path -Leaf $working_dir)$(Get-Date -Format yyyyMMddHHmmss).mklink.bak.zip"
  Get-MklinkDefCsvRow $_.FullName | ForEach-Object -process {
    $link = Expand-Path $_.link $working_dir 
    $target = Expand-Path $_.target $working_dir 
    # Sanity check link path before we start
    if (!(Test-Path -Path $link)) {
      Write-Error "Link path doesn't exist! $link.  Check your $MKLINK_DEF"
      exit 1
    }
    # Sanity check target path as well, if it's already symlink don't try to remove it
    if (Test-Path -Path $target) {
      # If this file/path exists we'll need to back it up
      if (Is-Symlink $target) {
        Remove-ReparsePoint -Confirm:$false -Path $target
      }
      else {
        Backup-Path $target $archive
        Remove-Item -Force -Recurse -Confirm:$false -Path $target
      }
    }
    # Symlink it up!
    New-Symlink -TargetPath $link -Path $target
  }
}
return $true
