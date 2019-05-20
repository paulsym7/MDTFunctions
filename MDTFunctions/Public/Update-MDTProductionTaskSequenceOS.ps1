<#
.Synopsis
   Use the Update-MDTProductionTaskSequenceOS function to update the production deployment share task sequence with the most recent .wim file in the Captures folder of the reference image deployment share
.DESCRIPTION
   Use the Update-MDTProductionTaskSequenceOS function to import the most recent .wim file in the Captures folder of the reference image deployment share to the production deployment share, and update the task sequence to use the .wim file
.EXAMPLE
   Update-MDTProductionTaskSequenceOS -RefDeploymentShare 'MDT-Reference' -ProdDeploymentShare 'MDT-Production'

   This example updates the MDT-Production deployment share task sequence with the most recent .wim file from the Captures folder of the MDT-Reference deployment share
.EXAMPLE
   Update-MDTProductionTaskSequenceOS -RefDeploymentShare 'MDT-Reference' -ProdDeploymentShare 'MDT-Production' -TaskSequence WIN10-PROD

   This example updates the WIN10-PROD task sequence in the MDT-Production deployment share with the most recent .wim file from the Captures folder of the MDT-Reference deployment share
#>

function Update-MDTProductionTaskSequenceOS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$RefDeploymentShare,

        [Parameter(Mandatory=$true)]
        [String]$ProdDeploymentShare,

        [String]$TaskSequence
    )

    $RefShare = Connect-MDTDeploymentShare -DeploymentShare $RefDeploymentShare -Verbose
    Write-Verbose "Connected to reference deployment share $($RefShare.Name) at $($RefShare.Path)"
    $NewWimFile = (Get-ChildItem (Join-Path $RefShare.Path -ChildPath Captures) | sort CreationTime -Descending)[0]
    Write-Verbose "New wim file to be imported is $($NewWimFile.FullName)"
    $ProdShare = Connect-MDTDeploymentShare -DeploymentShare $ProdDeploymentShare
    New-PSDrive -Name $ProdShare.Name -PSProvider MDTProvider -Root $ProdShare.Path | Out-Null
    Write-Verbose "Connected to reference deployment share $($ProdShare.Name) at $($ProdShare.Path)"
    # Remove existing operating system
    If($TaskSequence){
        $CurrentTS = Get-Item -Path "$($ProdShare.Path)\Control\$TaskSequence"
    }
    Else{
        $CurrentTS = Get-ChildItem -Path "$($ProdShare.Path)\Control" -Directory
    }
    $CurrentOS = Get-OperatingSystemsXML -Path $CurrentTS.Parent.FullName
    Write-Verbose "Existing operating system $($CurrentOS.Name) will be removed"
    Write-Verbose "Current OS guid is $($CurrentOS.guid)"
    Remove-Item -Path "$($ProdShare.Name):\Operating Systems\$($CurrentOS.Name)" -force -verbose
    # Import updated operating system
    Import-MDTOperatingSystem -path "$($ProdShare.Name):\Operating Systems" -SourceFile $NewWimFile.FullName -DestinationFolder $NewWimFile.BaseName -Verbose | Out-Null
    # Update task sequence with updated operating system
    $ProdTS = Get-Content (Join-Path $CurrentTS.FullName -ChildPath ts.xml)
    Update-OSGUID -TaskSequence $ProdTS -OSGuid $CurrentOS.guid -Verbose
}