foreach ($file in Get-ChildItem -Path "$PSScriptRoot/src" -Filter *.ps1 -Recurse) {
    . $file.FullName
}
Export-ModuleMember -Function Get-DiskReport, Remove-OldLog, Test-ServiceHealth, Get-ConfigValue
