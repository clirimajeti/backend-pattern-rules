BeforeAll {
    . "$PSScriptRoot/../src/Public/Get-DiskReport.ps1"
}
Describe 'Get-DiskReport' {
    It 'needs a computer name' {
        (Get-Command -Name Get-DiskReport).Parameters['ComputerName'].Attributes.Mandatory | Should -Contain $true
    }
}
