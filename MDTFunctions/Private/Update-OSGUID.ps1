Function Update-OSGUID {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $TaskSequence,

        [Parameter(Mandatory=$true)]
        [String]$OSGuid
    )

    #Wait for operatingsystems.xml to be updated after the new operating system is imported
    Start-Sleep -Seconds 5
    # Update task sequence to use new OS
    $NewOSGUID = Get-OperatingSystemsXML -Path $CurrentTS.Parent.FullName
    $UpdatedOSGUID = $NewOSGUID.guid
    Write-Verbose "Updating the $($CurrentTS.Name) task sequence"
    $TaskSequence.Replace($OSGuid,$UpdatedOSGUID) | Out-File -FilePath (Join-Path $CurrentTS.FullName -ChildPath ts.xml) -Force
    Write-Verbose "References to $OSGuid have been replaced with $UpdatedOSGUID"
}