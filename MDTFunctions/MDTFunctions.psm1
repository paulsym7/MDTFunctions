# Dot source public and private function scripts
$modulePublicPath  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$modulePrivatePath = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

foreach ($Function in @($modulePublicPath + $modulePrivatePath)) {
    Try {. $Function.FullName}
    Catch {Write-Error -Message "Failed to import function $($Function.FullName): $_"}
}

Export-ModuleMember -Function $modulePublicPath.BaseName