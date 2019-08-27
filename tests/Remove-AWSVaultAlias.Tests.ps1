Describe "Remove-AWSVaultAlias" {
  Import-Module .\posh-awsvault.psd1

  New-AWSVaultAlias somecommand

  $ModuleName = (Get-Alias somecommand).Module.Name

  Remove-AWSVaultAlias somecommand

  It "Removes the alias" {
    (Get-Alias somecommand -ErrorAction SilentlyContinue) `
      | Should -BeNull
  }

  It "Removes the module" {
    (Get-Module $ModuleName -ErrorAction SilentlyContinue) `
      | Should -BeNull
  }
}
