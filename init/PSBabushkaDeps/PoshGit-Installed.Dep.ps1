New-PSBabushkaDep `
	-Name 'PoshGit-Installed' `
	-Met { Get-Module -ListAvailable -Name "Posh-Git" } `
  -Meet { Install-Module 'Posh-Git' }
