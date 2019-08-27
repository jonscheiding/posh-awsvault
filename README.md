# posh-awsvault

[![Build Status](https://img.shields.io/travis/jonscheiding/posh-awsp.svg)](https://travis-ci.org/jonscheiding/posh-vault)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/posh-awsvault.svg)](https://www.powershellgallery.com/packages/posh-vault)

## Table of Contents

## Overview

**posh-awsvault** is a PowerShell module that makes it easy to create aws-vault aliases for commands.

This tool is useful if you:

- are using [aws-vault](https://github.com/99designs/aws-vault) to manage your AWS credentials; and
- have multiple profiles which you use the `AWS_PROFILE` environment variable to manage.

It allows you to create aliases which wrap existing commands in an `aws-vault exec` call that uses your current `AWS_PROFILE` variable value.

### Background

I created this tool specifically to deal with Terraform and MFA in AWS.  Terraform does not support interactively prompting for MFA codes, and aws-vault was a simple way to externally deal with that problem.  But I got tired of typing `aws-vault exec $Env:AWS_PROFILE terraform` all the time.

Because this tool creates aliases and functions dynamically, it does some manipulation of dynamic modules.  Each alias resides in its own dynamic module.

## Installation

posh-awsvault is available in the [PowerShell Gallery](https://www.powershellgallery.com/packages/posh-awsvault), and can be installed with the following command:

```powershell
Install-Module posh-awsvault
```

Before using this module, you will need to install [aws-vault](https://github.com/99designs/aws-vault).

You might also consider installing my other module, [posh-awsp](https://github.com/jonscheiding/posh-awsp), if you want an easier way to interact with multiple profiles.

## Quick Start

To use aws-vault to execute a command using your current profile:

```powershell
awsv terraform
```

To create a new alias that consistently does this:

```powershell
New-AWSVaultAlias terraform
```

## Usage

The following commands are provided by posh-awsvault.

### `New-AWSVaultAlias`

Creates a new alias which calls the provided command via `aws-vault exec`.

By default, the alias is named the same as the command:

```powershell
PS> $Env:AWS_PROFILE="development"
PS> New-AWSVaultAlias terraform
PS> terraform
Invoking aws-vault for terraform with profile development.
Usage: terraform [-version] [-help] <command> [args]

The available commands for execution are listed below.
...
```

You can also name the alias differently from the command:

```powershell
PS> New-AWSVaultAlias tf terraform
PS> tf
Invoking aws-vault for terraform with profile development.
Usage: terraform [-version] [-help] <command> [args]

The available commands for execution are listed below.
...
```

### `Remove-AWSVaultAlias`

This deletes an alias which was created by `New-AWSVaultAlias`.

```powershell
PS> Remove-AWSVaultAlias tf
PS> tf
tf : The term 'tf' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ tf
+ ~~
    + CategoryInfo          : ObjectNotFound: (tf:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

### `Invoke-AWSVault`

Calls aws-vault using your currently selected profile.  Can be useful for one-off commands that you don't want to create an alias for.

Aliased as `awsv` for convenient access.

```powershell
PS> Invoke-AWSVault terraform
Invoking aws-vault for terraform with profile development.
Usage: terraform [-version] [-help] <command> [args]

The available commands for execution are listed below.
...
```
