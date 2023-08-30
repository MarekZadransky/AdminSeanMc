[CmdletBinding(SupportsShouldProcess=$true)]
Param(
    [Parameter(Mandatory = $false)]
    [string]$Path = 'c:\Temp\TenantMigrationAssessment\',
    [Parameter(Mandatory = $false)]
    [hashtable]$DownloadFiles = @{  'https://github.com/MarekZadransky/AdminSeanMc/blob/master/Tenant%20Migration%20Assessment/Prepare-TenantAssessment.ps1' = 'C5A74092829E17333405625A2BA6592663F97F0533819303B1CC07D2B223161E';
                                    'https://github.com/MarekZadransky/AdminSeanMc/blob/master/Tenant%20Migration%20Assessment/Perform-TenantAssessment.ps1' = 'C197FB26286C5C4479B4460D9E5F3575E52A2CF37F79F6560E47ED229A3A7FE7';
                                    'https://github.com/MarekZadransky/AdminSeanMc/blob/master/Tenant%20Migration%20Assessment/TenantAssessment-Template.xlsx' = 'AE520178ED4FD54FBA79F9010C480C066388F46E22DBDE1B508B260DB0B1EB79'},
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
                    Remove-Item $TargetFile -Force
                }  
            }
        }
    }
}
