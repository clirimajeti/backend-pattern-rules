function Remove-OldLog {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $Path,
        [int] $Days = 30
    )
    $limit = (Get-Date).AddDays(-$Days)
    gci -Path $Path -Filter *.log | ? { $_.LastWriteTime -lt $limit } | ForEach-Object -Process {
        if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
            Remove-Item -LiteralPath $_.FullName
        }
    }
}
