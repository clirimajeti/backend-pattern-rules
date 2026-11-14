function Get-DiskReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName
    )
    Write-Verbose -Message "Reading disks on $ComputerName"
    Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $ComputerName |
        Where-Object -FilterScript { $_.DriveType -eq 3 } |
        Select-Object -Property DeviceID, Size, FreeSpace
}
