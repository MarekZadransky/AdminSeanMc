[CmdletBinding(SupportsShouldProcess=$true)]
Param(
    [Parameter(Mandatory = $false)]
    [string]$Path = 'c:\Temp\TenantMigrationAssessment\',
    [Parameter(Mandatory = $false)]
    [hashtable]$DownloadFiles = @{  'https://raw.githubusercontent.com/MarekZadransky/AdminSeanMc/master/Tenant%20Migration%20Assessment/Prepare-TenantAssessment.ps1' = '1D44A9BD17A1F5D049A618B27B7449501B0215B6ECDD143FD5FD0C82E6AE9FFA';
                                    'https://raw.githubusercontent.com/MarekZadransky/AdminSeanMc/master/Tenant%20Migration%20Assessment/Perform-TenantAssessment.ps1' = '70B1D7F468937C304449641ABFA4E1AF1988A69E6EE7CF15CD2892B0D0268F43';
                                    'https://raw.githubusercontent.com/MarekZadransky/AdminSeanMc/master/Tenant%20Migration%20Assessment/TenantAssessment-Template.xlsx' = '9D992BBF6142EF4095A34FCCA6CACA47E10099528F7977C68E75DBB03FDA5614'},
    [Parameter(Mandatory = $false)]
    [switch]$WriteFileHashes = $false
)
Begin {
    if (-not(Test-Path $Path)) {
        New-Item $Path -ItemType Directory -Force
    }
}
Process {
    if ($WriteFileHashes.IsPresent) {
        Get-ChildItem $Path | Get-FileHash -Algorithm SHA256 | Select-Object @{N='Name';E={$_.Path | Split-Path -Leaf}},Hash
    }else {
        foreach ($Download in $DownloadFiles.GetEnumerator()) {
            $DownloadFile = $false
            $TargetFile = "$($Path)$($Download.Name | Split-Path -Leaf)"
            if (Test-Path $TargetFile) {
                Write-Host "File $TargetFile exist" -ForegroundColor Cyan
                if (((Get-FileHash $TargetFile -Algorithm SHA256).Hash) -eq $Download.Value) {
                    Write-Host "File Hash validated" -ForegroundColor Green 
                }else{
                    Write-Host "File Hash invalid" -ForegroundColor Red
                    $DownloadFile = $true
                }           
            }else{
                $DownloadFile = $true
            }
            if ($DownloadFile) {
                Write-Host "Attemping to download file '$($Download.Name)' into '$TargetFile'"
                Invoke-WebRequest $Download.Name -OutFile $TargetFile
                if (((Get-FileHash $TargetFile -Algorithm SHA256).Hash) -eq $Download.Value) {
                    Write-Host "File Hash validated" -ForegroundColor Green
                    Unblock-File $TargetFile
                }else{
                    Write-Host "File Hash invalid, remove file" -ForegroundColor Red
                    #Remove-Item $TargetFile -Force
                }  
            }
        }
    }
}
