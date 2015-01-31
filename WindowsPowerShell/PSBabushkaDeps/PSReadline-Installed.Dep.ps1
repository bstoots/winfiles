New-PSBabushkaDep `
	-Name 'PSReadLine-Installed' `
	-Requires 'PsGet-Installed' `
	-Met { Get-Command -Module 'PSReadLine' } `
	-Meet { Install-Module 'PSReadLine' }