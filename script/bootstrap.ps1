#
#
#

# Set the root working dir for scanning and whatnot
$winfile_root = Get-Location | Split-Path -Parent

# Find .mklink place-holders
#foreach ($mklink_holder in Get-ChildItem -Filter *.mklink -Recurse -Path $winfile_root) -- Old school way
# Faster PS 4.0 only way
Get-ChildItem -Filter .mklink.in -Recurse -Path $winfile_root | ForEach-Object -process {
  # Grab the mklink file name and path
  $mklink_file = $_.name
  $mklink_path = Split-Path -Parent $_.FullName
    
  # Clone .mklink.in to .mklink.out to record local config
  Out-File -FilePath $mklink_path\.mklink.out

  Import-Csv -Header link,target $_.FullName | ForEach-Object -process {
    # Make sure we have valid paths in here
    do {
      # This path must exist, otherwise what are we trying to link to?
      if (!(Test-Path -Path $_.link)) {
        Write-Error "Link path: $($_.link), does not exist."
        $_.link = Read-Host "YO DAWG"
      }
      # This path may or may not exist.  If it does it will need backed up and removed
      # to make room for our incoming symlink
      if (!(Test-Path -IsValid -Path $_.target)) {
        Write-Error "Target path: $($_.target), does not exist."
        $_.target = Read-Host "YO DAWG"
      }
    # Don't let go until we get something legit or the user rage quits
    } Until ((Test-Path -Path $_.link) -and (Test-Path -IsValid -Path $_.target))

    # Normalize paths relative to wherever the loaded in.mklink file is located
    $_.link = Resolve-Path (Join-Path -Path $mklink_path -ChildPath $_.link)
    #$_.target = Resolve-Path $_.target

    # Should be good to roll now.  If path we're creating the link to already exists back it up
    if (Test-Path -Path $_.target) {
      # If the path exists back it up
      Get-ChildItem `
        -Recurse    `
        -Path $_.target | 
        Write-Zip `
          -Quiet `
          -IncludeEmptyDirectories `
          -EntryPathRoot $(Split-Path -Parent $_.target) `
          -OutputPath $mklink_path\$((Get-Item $_.target).name)$(Get-Date -Format yyyyMMddHHmmss).bak.zip
      # All backed up trash the existing dir
      Remove-Item -Force -Path $_.target
    }

    # Symlink it up!
    New-Symlink -TargetPath $_.link -Path $_.target

    # Looks good, now write an out.mklink for future reference / sanity
    "`"$($_.link)`",`"$($_.target)`"" | Out-File -FilePath $mklink_path\.mklink.out -Append
  }

}
