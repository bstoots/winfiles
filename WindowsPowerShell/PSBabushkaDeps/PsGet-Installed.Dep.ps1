New-PSBabushkaDep `
  -Name 'PsGet-Installed' `
  -Met { Get-Command -Module 'PsGet' } `
  -Meet { (new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex }