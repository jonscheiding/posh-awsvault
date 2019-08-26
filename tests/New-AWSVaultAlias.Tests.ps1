Import-Module -Force .\posh-awsvault.psm1

$DebugPreference = "Continue"

Describe "New-AWSVaultAlias" {
  Context "When called to create an alias" {
    $TestState = @{
      "Alias" = $null
      "Function" = $null
    }

    New-AWSVaultAlias somecommand

    It "Is created" {
      { $TestState["Alias"] = Get-Alias somecommand } | Should -Not -Throw
    }

    Import-Module -Force -ModuleInfo $TestState["Alias"].Module

    It "Points to a function" {
      { $TestState["Function"] = Get-Item Function:\$($TestState["Alias"].Definition) } | Should -Not -Throw      
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
}