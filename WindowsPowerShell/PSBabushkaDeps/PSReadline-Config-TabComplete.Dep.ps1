New-PSBabushkaDep `
	-Name 'PSReadline-Config-TabComplete' `
	-Requires 'PSReadLine-Installed' `
	-Met { foreach ($line in (Get-PSReadlineKeyHandler -Bound)) { if ( ($line | Out-String) -imatch "tab\s+complete" ) { $true; break; } } } `
	-Meet { Set-PSReadlineKeyHandler -Key Tab -Function Complete }