New-PSBabushkaDep `
	-Name 'PoshGit-Installed' `
	-Requires 'PsGet-Installed' `
	-Met { Get-Command -Module 'Posh-Git' } `
	-Meet { Install-Module 'Posh-Git' }