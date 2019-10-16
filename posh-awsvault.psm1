function New-AWSVaultAlias {
  <#
    .SYNOPSIS
      Creates an aws-vault alias.

    .DESCRIPTION
      When called with a command name, creates an alias that does the equivalent of
      aws-vault exec $Env:AWS_PROFILE command.

    .PARAMETER AliasName
      The name of the alias.

    .PARAMETER CommandName
      The command to execute.  If omitted, it will be assumed to be the same as
      AliasName.

    .LINK
      https://www.github.com/jonscheiding/posh-awsvault
  #>

  param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string] $AliasName,
    [Parameter(Position = 1)]
    [string] $CommandName
  )

  $ModuleName = "posh-awsvault-$AliasName"
  if([string]::IsNullOrEmpty($CommandName)) {
    $CommandName = $AliasName
  }

  $Module = New-Module -Name $ModuleName -ArgumentList @($AliasName, $CommandName) {
    param(
      [Parameter(Position = 0)] $AliasName,
      [Parameter(Position = 1)] $CommandName
    )

    $FunctionName = "Invoke-AWSVault_$AliasName"

    $FunctionScriptBlock = {
      Invoke-WithAWSVaultExec $CommandName @args
    }
  
    Set-Item -Path function:\$FunctionName -Value $FunctionScriptBlock
    Set-Alias -Name $AliasName -Value $FunctionName

    Export-ModuleMember -Alias $AliasName -Function $FunctionName
  }
  
  $Module | Import-Module -Force -Global
}

function Remove-AWSVaultAlias {
  <#
    .SYNOPSIS
      Removes an aws-vault alias that was created by New-AWSVaultAlias.

    .PARAMETER AliasName
      The name of the alias to remove.

    .LINK
      https://www.github.com/jonscheiding/posh-awsvault
  #>

  param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string] $AliasName
  )

  $ErrorActionPreference = "stop"

  $Alias = Get-Alias $AliasName
  $Module = $Alias.Module

  if($null -eq $Module -or !$Module.Name.StartsWith("posh-awsvault-")) {
    Write-Error "The alias '$Alias' is not a posh-awsvault alias."
  }

  Remove-Item "Alias:\$($Alias.Name)"
  Remove-Module $Alias.Module.Name
}

function Invoke-AWSVault {
  <#
    .SYNOPSIS
      Wraps aws-vault with a workaround for https://github.com/99designs/aws-vault/issues/410.

    .LINK
      https://www.github.com/jonscheiding/posh-awsvault
  #>

  param(
    [Parameter(ValueFromRemainingArguments = $true)] $CommandArguments
  )

  $AWSProfile = (Get-Item Env:\AWS_PROFILE -ErrorAction SilentlyContinue)
  $WasAWSProfileSet = $true

  if($null -eq $AWSProfile) {
    $AWSProfile = "default"
    $WasAWSProfileSet = $false
  } else {
    $AWSProfile = $AWSProfile.Value
  }

  $AWSVault = Get-Command -CommandType Application aws-vault;

  try {
    #
    # AWS_PROFILE needs to be unset while calling aws-vault
    # See https://github.com/99designs/aws-vault/issues/410
    #
    Remove-Item Env:\AWS_PROFILE -ErrorAction SilentlyContinue
    Invoke-External $AWSVault @CommandArguments
  } finally {
    if($WasAWSProfileSet) {
      Set-Item Env:\AWS_PROFILE $AWSProfile
    }
  }
}

function Invoke-WithAWSVaultExec {
  <#
    .SYNOPSIS
      Provides a convenient wrapper for aws-vault exec.

    .DESCRIPTION
      Calling this with a command is basically equivalent to calling 
      aws-vault exec $Env:AWS_PROFILE command.
      
      But, see https://github.com/99designs/aws-vault/issues/410 for caveats.

    .PARAMETER CommandName
      The command to execute.
    
    .PARAMETER CommandArguments
      The arguments to pass to the command specified by CommandName.

    .LINK
      https://www.github.com/jonscheiding/posh-awsvault
  #>

  param(
    [Parameter(Mandatory = $true)] $CommandName,
    [Parameter(ValueFromRemainingArguments = $true)] $CommandArguments
  )

  $AWSProfile = Get-AWSProfile -OrDefault

  Write-Host -ForegroundColor Cyan `
    "Invoking aws-vault for $CommandName with profile $AWSProfile."

  Write-Debug "$CommandName ($CommandArguments)"

  $Command = Get-Command -CommandType Application $CommandName | Select-Object -First 1

  Invoke-AWSVault exec $AWSProfile `-- $Command @CommandArguments
}

function Invoke-External {
  param(
    [Parameter(Mandatory = $true)] [string] $Command,
    [Parameter(ValueFromRemainingArguments = $true)] $Arguments
  )

  & $Command @Arguments
}

function Get-AWSProfile {
  param(
    [switch] $OrDefault
  )

  $Item = (Get-Item Env:\AWS_PROFILE -ErrorAction SilentlyContinue);
  
  if($null -eq $Item) {
    if($OrDefault) { return "default" }
    return $null;
  }

  return $Item.Value
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { 
  Get-Module `
    | Where-Object { $_.Name.StartsWith("posh-awsvault-") } `
    | Remove-Module
}

New-Alias awsv Invoke-WithAWSVaultExec
New-Alias aws-vault Invoke-AWSVault
