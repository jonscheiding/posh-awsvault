Describe "Remove-AWSVaultAlias" {
  Import-Module -Force .\posh-awsvault.psd1

  Context "When called to remove a posh-awsvault alias" {
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

  Context "When called to remove an alias that was not created by posh-awsvault" {
    It "Throws an error" {
      { Remove-AWSVaultAlias gc } | Should -Throw
    }
  }

  Context "When called to remove an alias that doesn't exist" {
    It "Throws an error" {
      { Remove-AWSVaultAlias nonexistentalias } | Should -Throw
    }
  }
}
