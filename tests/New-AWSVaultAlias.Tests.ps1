Describe "New-AWSVaultAlias" {
  Import-Module -Force .\posh-awsvault.psd1

  $TestCases = @{
    "When called with only an alias name" = @( "somecommand" )
    "When called with an alias name and a command name" = @( "somealias", "somecommand" )
  }

  foreach($Case in $TestCases.Keys) {
    Context $Case {
      $TestState = @{
        "Alias" = $null
        "Function" = $null
      }

      $TestCaseArguments = $TestCases[$Case]

      $TestAliasName = $TestCaseArguments[0]
      $TestCommandName = $TestAliasName
      
      if($TestCaseArguments.Count -gt 1) {
        $TestCommandName = $TestCaseArguments[1]
      }

      New-AWSVaultAlias @TestCaseArguments

      It "Creates an alias named $TestAliasName" {
        $TestState["Alias"] = Get-Alias $TestAliasName
        $TestState["Alias"] | Should -Not -BeNull
        Write-Debug ($TestState["Alias"] | Out-String)
      }

      It "Points to a function" {
        $TestState["Function"] = Get-Item Function:\$($TestState["Alias"].Definition)
        $TestState["Function"] | Should -Not -BeNull
        Write-Debug ($TestState["Function"] | Out-String)
      }

      Mock Invoke-WithAWSVaultExec -ModuleName $TestState["Function"].Module { 
        Write-Debug "Invoke-WithAWSVaultExec $($args[0]) $($args[1])"
      } 

      It "Calls Invoke-WithAWSVaultExec for command $TestCommandName" {
        &($TestState["Function"].Name)

        Assert-MockCalled Invoke-WithAWSVaultExec -ModuleName $TestState["Function"].Module -ParameterFilter {
          $CommandName -eq $TestCommandName
        }
      }

      Remove-Module $TestState["Function"].Module -ErrorAction SilentlyContinue
    }
  }
  
  Remove-Module posh-awsvault
}