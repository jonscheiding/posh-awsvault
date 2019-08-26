function New-AWSVaultAlias {
  param(
    [Parameter(Mandatory = $true)]
    [string] $CommandName
  )

  $ModuleName = "posh-awsvault-$CommandName"

  $Module = New-Module -Name $ModuleName -ArgumentList $CommandName {
    param(
      [Parameter(Position = 0)] $CommandName
    )

    $FunctionName = "Invoke-AWSVault_$CommandName"

    $FunctionScriptBlock = {
      Invoke-AWSVault (Get-Command $CommandName) $args
    }
  
    Set-Item -Path function:\$FunctionName -Value $FunctionScriptBlock
    Set-Alias -Name $CommandName -Value $FunctionName

    Export-ModuleMember -Alias $CommandName -Function $FunctionName
  }
  
  $Module | Import-Module -Force -Global
}

function Invoke-AWSVault {
  $AWSProfile = (Get-Item Env:\AWS_PROFILE).Value
  $Command = $args[0]

  Write-Host -ForegroundColor Cyan `
    "Invoking aws-vault for $Command with profile $AWSProfile."

  try {
    #
    # AWS_PROFILE needs to be unset while calling aws-vault
    # See https://github.com/99designs/aws-vault/issues/410
    #
    Remove-Item Env:\AWS_PROFILE
    Invoke-External aws-vault exec $AWSProfile -- @args
  } finally {
    Set-Item Env:\AWS_PROFILE $AWSProfile
  }
}

function Invoke-External {
  param(
    [Parameter(Mandatory = $true)] [string] $Command,
    [Parameter(ValueFromRemainingArguments = $true)] $Arguments
  )

  & $Command $Arguments
}
