function Test-ServiceHealth {
    param(
        [string[]] $Name
    )
    foreach ($service in Get-Service $Name) {
        if ($service.Status -ne 'Running') {
            Write-Host "$($service.Name) is $($service.Status)"
        }
    }
}
