Describe "The posh-awsvault module" {
  Context "When imported and used to create an alias" {
    $TestState = @{}

    Import-Module -Force .\posh-awsvault.psd1

    New-AWSVaultAlias somecommand

    It "Creates a dynamic module for that alias" {
      $TestState["Module"] = (Get-Module posh-awsvault-somecommand)
      $TestState["Module"] | Should -Not -BeNullOrEmpty
    }

    It "Exports the alias and the associated function" {
      $TestState["Module"].ExportedAliases.Keys | Should -Contain "somecommand"
    }

    Remove-Module posh-awsvault

    It "Removes the dynamic module when itself is removed" {
      (Get-Module posh-awsvault-somecommand `
        -ErrorAction SilentlyContinue `
      ) | Should -BeNullOrEmpty
    }
  }
}
