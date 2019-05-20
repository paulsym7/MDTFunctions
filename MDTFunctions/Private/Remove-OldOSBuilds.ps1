function Remove-OldOSBuilds {
    [CmdletBinding()]
    param()

    # Delete previous builds if more than one build in the OSBuilds folder
    if($OSBuildFolder.Count -gt 1){
        foreach($Build in $OSBuildFolder){
            If($Build -ne $LatestBuild){
                Write-Verbose "Remvoing $Build"
                Remove-Item $Build -Recurse -Force
            }
        }
    }
}
