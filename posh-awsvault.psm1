function New-AWSVaultAlias {
  param(
    [Parameter(Mandatory = $true)]
    [string] $CommandName
  )

  $FunctionName = "aws-vault-$CommandName"

  $FunctionScriptBlock = {
    Invoke-AWSVault (Get-Command $CommandName) $args
  }.GetNewClosure()

  Set-Item -Path function:global:$FunctionName -Value $FunctionScriptBlock
  New-Alias -Name $CommandName -Value $FunctionName -Scope Global
}

function Invoke-AWSVault {
  $AWSProfile = $Env:AWS_PROFILE
  $Command = $args[0]

  Write-Host -ForegroundColor Cyan `
    "Invoking aws-vault for $Command with profile $AWSProfile."

  try {
    #
    # AWS_PROFILE needs to be unset while calling aws-vault
    # See https://github.com/99designs/aws-vault/issues/410
    #
    $Env:AWS_PROFILE = $null
    aws-vault exec $AWSProfile -- @args
  } finally {
      $Env:AWS_PROFILE = $AWSProfile
  }
}
