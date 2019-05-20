Function Remove-OldWimFiles {
    [CmdletBinding()]
    param()

    # Delete previous .wim file(s) if more than one is present in the Captures folder
    if($WimFiles.Count -gt 1){
        foreach($Wim in $WimFiles){
            If($Wim -ne $LatestWim){
                Write-Verbose "Remvoing $Wim"
                Remove-Item $Wim -Force
            }
        }
    }
}