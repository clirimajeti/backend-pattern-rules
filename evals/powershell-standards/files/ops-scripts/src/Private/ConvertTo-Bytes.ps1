function ConvertTo-Bytes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [double] $Gigabytes
    )
    [math]::Round($Gigabytes * 1GB)
}
