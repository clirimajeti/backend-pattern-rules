function Get-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Key
    )
    $config = Get-Content -Path "$PSScriptRoot/../../config.json" -Raw | ConvertFrom-Json
    $config.$Key
}
