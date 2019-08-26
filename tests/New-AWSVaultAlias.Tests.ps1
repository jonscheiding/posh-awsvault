Describe "New-AWSVaultAlias" {
  Import-Module .\posh-awsvault.psm1

  Context "Calling New-AWSVaultAlias" {
    $TestState = @{
      "Alias" = $null
      "Function" = $null
    }

    New-AWSVaultAlias somecommand

    It "Creates an alias" {
      $TestState["Alias"] = Get-Alias somecommand
      $TestState["Alias"] | Should -Not -BeNull
      Write-Debug ($TestState["Alias"] | Out-String)
    }

    It "Points to a function" {
      $TestState["Function"] = Get-Item Function:\$($TestState["Alias"].Definition)
      $TestState["Function"] | Should -Not -BeNull
      Write-Debug ($TestState["Function"] | Out-String)
    }

    Mock Invoke-AWSVault -ModuleName $TestState["Alias"].Module { 
      Write-Debug "Invoke-AWSVault $($args[0]) $($args[1])"
    } 

    It "Calls Invoke-AWSVault" {
      &($TestState["Function"].Name) someargument

      Assert-MockCalled Invoke-AWSVault -ModuleName $TestState["Function"].Module -ParameterFilter {
        $args[0] -eq "somecommand"
        $true
      }
    }

    Remove-Module $TestState["Function"].Module -ErrorAction SilentlyContinue
  }

  Remove-Module posh-awsvault
}