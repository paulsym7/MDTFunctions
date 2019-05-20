<#
.Synopsis
   Use the Update-MDTReferenceImageOS function after running the OSDBuilder New-OSBuild function to update the reference image task sequence with the newly updated OSBUild
.DESCRIPTION
   Use the Update-MDTReferenceImageOS function after running the OSDBuilder New-OSBuild function to remove the existing reference image operating system, import the newly updated OSBUild into the MDT reference image deployment share and update the task sequence to use the updated operating system image.
   The -CleanUp switch parameter can be used to remove previous builds from the OSBuilds folder.
.EXAMPLE
   Update-MDTReferenceImageOS -RefDeploymentShare 'MDT-Reference'

   This example removes the existing MDT reference image OS, imports the most recent build from the OSBuilds folder and updates the reference deployment share task sequence to use the updated OS
.EXAMPLE
   Update-MDTReferenceImageOS -RefDeploymentShare 'MDT-Reference' -CleanUp

   This example removes the existing MDT reference image OS, imports the most recent build from the OSBuilds folder, removes previous builds from the OSBuilds folder and updates the reference deloyment share task sequence to use the updates OS
#>

function Update-MDTReferenceImageOS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$RefDeploymentShare,

        [Switch]$CleanUp
    )

    $RefShare = Connect-MDTDeploymentShare -DeploymentShare $RefDeploymentShare
    # Remove OS from MDT
    $CurrentTS = Get-ChildItem -Path "$($RefShare.Path)\Control" -Directory
    $OSBuildFolder = (Get-OSBuilds).FullName
    $LatestBuild = ((Get-Item -Path $OSBuildFolder).Where{$_.PSIsContainer} | sort LastWriteTIme -Descending)[0]
    Write-Verbose "The latest operating system build is in the $LatestBuild folder"
    If($CleanUp){
        Remove-OldOSBuilds -Verbose
    }
    $CurrentOS = Get-OperatingSystemsXML -Path $CurrentTS.Parent.FullName
    Write-Verbose "Removing current operating system - GUID $($CurrentOS.guid)"
    New-PSDrive -Name $RefShare.Name -PSProvider MDTProvider -Root $RefShare.Path | Out-Null
    Remove-Item -Path "$($RefShare.Name):\Operating Systems\$($CurrentOS.Name)" -Force -Verbose
    
    # Import updated OS
    Write-Verbose 'Importing updated operating system build'
    Import-MDTOperatingSystem -Path "$($RefShare.Name):\Operating Systems" -SourcePath (Join-Path $LatestBuild -ChildPath OS) -DestinationFolder "Windows 10 Enterprise x64" -Verbose | Out-Null
    Start-Sleep -Seconds 5
    # Update task sequence to use new OS
    $RefTS = Get-Content (Join-Path $CurrentTS.FullName -ChildPath ts.xml)
    Update-OSGUID -TaskSequence $RefTS -OSGuid $CurrentOS.guid -Verbose
}