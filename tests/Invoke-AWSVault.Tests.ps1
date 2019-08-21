Import-Module -Force .\posh-awsvault.psm1

$ENV_AWS_PROFILE = "someprofile"

Mock Get-Item -ModuleName posh-awsvault -ParameterFilter { $Path -eq "Env:\AWS_PROFILE" } { @{ Value = $ENV_AWS_PROFILE } }.GetNewClosure()
Mock Set-Item -ModuleName posh-awsvault -ParameterFilter { $Path -like "Env:\AWS_PROFILE" } { $ENV_AWS_PROFILE = $Value }.GetNewClosure()
Mock Remove-Item -ModuleName posh-awsvault -ParameterFilter { $Path -eq "Env:\AWS_PROFILE" } { $ENV_AWS_PROFILE = $null }.GetNewClosure()

Describe "Invoke-AWSVault" {
  It "Calls aws-vault exec for the command" {
    Mock Invoke-External { Write-Debug "Invoke-External: $Command $Arguments" } `
    -ModuleName posh-awsvault `
    -Verifiable `
    -ParameterFilter { 
      "aws-vault" -eq $Command -and
      "exec someprofile somecommand someargument" -eq $Arguments
    }

    Invoke-AWSVault somecommand someargument

    Assert-VerifiableMock
  }
}
