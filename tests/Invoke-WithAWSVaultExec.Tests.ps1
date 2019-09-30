$DebugPreference = "Continue"

Describe "Invoke-WithAWSVaultExec" {
  Import-Module -Force .\posh-awsvault.psd1

  $global:TEST_VARS = @{
    AWS_PROFILE = "someprofile"
  }

  Mock Get-Item -ModuleName posh-awsvault -ParameterFilter { $Path -eq "Env:\AWS_PROFILE" } { @{ Value = $global:TEST_VARS.AWS_PROFILE } }
  Mock Set-Item -ModuleName posh-awsvault -ParameterFilter { $Path -like "Env:\AWS_PROFILE" } { $global:TEST_VARS.AWS_PROFILE = $Value }
  Mock Remove-Item -ModuleName posh-awsvault -ParameterFilter { $Path -eq "Env:\AWS_PROFILE" } { $global:TEST_VARS.AWS_PROFILE = $null }

  Mock Get-Command -ModuleName posh-awsvault { $Name }
  
  Context 'When Invoke-External is successful' {
    Mock Invoke-External -ModuleName posh-awsvault { 
      $global:TEST_VARS.AWS_PROFILE_WHEN_CALLED = $global:TEST_VARS.AWS_PROFILE
      Write-Debug "Invoke-External -Command $Command -Arguments $Arguments" 
    }

    Invoke-WithAWSVaultExec somecommand someargument1 someargument2
    
    It "Passes the correct arguments to Invoke-External" {
      Assert-MockCalled Invoke-External -ModuleName posh-awsvault `
        -ParameterFilter { 
          $Command -eq "aws-vault" -and `
          (Compare-Object $Arguments @("exec", "--", "someprofile", "somecommand", "someargument1", "someargument2")).Length -eq 0
        }
    }

    It "Unsets and resets AWS_PROFILE environment variable" {
      # Due to https://github.com/99designs/aws-vault/issues/410
      $global:TEST_VARS.AWS_PROFILE_WHEN_CALLED | Should -BeNullOrEmpty
      $global:TEST_VARS.AWS_PROFILE | Should -Be "someprofile"
    }
  }

  Context 'When Invoke-External throws' {
    Mock Invoke-External -ModuleName posh-awsvault { 
      $global:TEST_VARS.AWS_PROFILE_WHEN_CALLED = $global:TEST_VARS.AWS_PROFILE
      throw "This is an error."
    }

    It "Bubbles up the exception" {
      { Invoke-WithAWSVaultExec somecommand someargument } | Should -Throw
    }

    It "Still resets the AWS_PROFILE environment variable" {
      $global:TEST_VARS.AWS_PROFILE | Should -Be "someprofile"
    }
  }

  Remove-Module posh-awsvault
}
