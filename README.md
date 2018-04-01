# THIS README IS OUT OF DATE!  UPDATED VERSION IN THE WORKS.

# winfiles

Like dotfiles, but for Windows!

## What / Why?

Dotfile repos are a popular way to maintain environment settings on *nix systems but until recently Windows lacked the tools to manage this effectively.  This project is my attempt at managing Windows environments and application settings in a similar fashion.

## Requirements

* Windows 10
* Windows Management Framework 5.0
* Git

Note: All Powershell prompts are assumed to have Administrator priviledges.

This may work on other Windows versions but I have not been able to test it at this point.

## Install

1. Clone this repository somewhere on your machine.  A good place would be %USERPROFILE%\\.winfiles (~/.winfiles)

  ```bash
  # Using Git Bash
  git clone git@github.com:bstoots/winfiles.git ~/.winfiles
  ```

2. Setup your local configuration in ```config.json```, see Configuration section below

3. Set-ExecutionPolicy.  Open a Powershell prompt and set your [ExecutionPolicy](https://technet.microsoft.com/en-us/library/hh847748.aspx)

  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
  ```

## Usage

As with most Powershell modules you can use the `Get-Help` commandlet to get usage info.

```powershell
PS C:\Users\bstoo\.winfiles> Get-Help .\bootstrap.ps1

NAME
    C:\Users\bstoo\.winfiles\bootstrap.ps1

SYNOPSIS
    Like dotfiles but for Windows!


SYNTAX
    C:\Users\bstoo\.winfiles\bootstrap.ps1 [-Force] [-Verbose] [<CommonParameters>]


DESCRIPTION
    Configures Windows machines for development by setting up registry keys, creating symlinks,
    installing Powershell modules, and more.


RELATED LINKS
    https://github.com/bstoots/winfiles
```

* ```-Force``` - Will force the overwriting of existing values if any are found.  Different configuration sections handle this in different ways.  For instance ```symlink``` will move the old file to a temporary file in the same location whereas ```registry``` will simply overwrite the value printing the old and new value for user reference if the ```-Verbose``` flag is set.
* ```-Verbose``` - Shows additional debugging information.  Most useful for seeing what exactly has changed due to actions taken by the bootstrap script.

## Statuses

Various statuses are output indicating whether a given configuration object was applied successfully or not.
* ```+``` - Success, configuration was applied successfully.
* ```-``` - Failure, configuration was NOT applied.
* ```!``` - Forced, configuration was applied under duress.  You may want to check that everything applied correctly.
* ```@``` - No Change, configuration was already in the expected state, no changes were required

## Configuration

The configuration file is JSON-formatted.  It allows for the following configuration options.

### registry

Allows for adding or updating registry keys.  Currently only supports String keys.

* type - Registry key type.  Currently only supports String.
* path - Path to the registry key.
* key  - Actual key to be set.  Will be created if it is not found.
* val  - Value to set this registry key to.

```json
"registry": [
  {
    "type": "String",
    "path": "HKCU:\\Software\\Microsoft\\Command Processor",
    "key" : "AutoRun",
    "val" : "%USERPROFILE%\\.cmdrc.bat"
  }
]
```

### symlink

Creates symlinks.  If a file already exists at the target location is will be moved to ```$filename.winfiles.$n``` where ```$filename``` is the original filename and ```$n``` is an incremental value starting at zero.  

Path references may be either relative or absolute.

Powershell variables will be expanded.  If you need to escape values use the backtick character.  e.g. ````$env:USERPROFILE```

* target - An existing file you would like to create a symlink to
* link   - Target path of the symlink to be created

```json
"symlink": [
  {
    "target" : ".\\.cmdrc.bat",
    "link": "$env:USERPROFILE\\.cmdrc.bat"
  }
]
```

### psmodule

Installs Powershell modules from [Powershell Gallery](https://www.powershellgallery.com/).  Currently will not remove or upgrade existing modules.

* name - Powershell module name

```json
"psmodule": [
  {"name": "posh-git"}
]
```
