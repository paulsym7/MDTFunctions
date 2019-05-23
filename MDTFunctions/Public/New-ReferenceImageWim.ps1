<#
.Synopsis
   Use the New-ReferenceImageWim function to generate a .wim file in the Captures folder of the MDT reference image deployment share
.DESCRIPTION
   The New-ReferenceImageWim function will mount the boot ISO into a virtual machine, start the machine and execute the reference image task sequence, capturing a .wim file in the Captures folder of the MDT reference image deployment share. If the -VMName parameter is used it is assumed that the virtual machine has a base snapshot with no OS installed.
   The -CleanUp switch is used to remove any existing .wim files in the Captures folder
.EXAMPLE
   New-ReferenceImageWim -VMName Win10

   This example will use the Win10 virtual machine to launch the reference image task sequence
.EXAMPLE
   New-ReferenceImageWim -VMServer HyperV-01 -CleanUp

   This example will create a temporary virtual machine on host HyperV-01 to capture the reference image task sequence on and all .wim files in the Captures folder will be removed, apart from the most recent one.
#>

function New-ReferenceImageWim {
    [CmdletBinding()]
    param(
        [String]$VMServer = $env:COMPUTERNAME,

        [String]$VMName,

        [Switch]$CleanUp
    )

    $RefShare = Connect-MDTDeploymentShare -DeploymentShare 'Reference'
    try{
        $VM = Get-VM -Name $VMName -ComputerName $VMServer -ErrorAction Stop
        # Stop VM if it is running
        If($VM.State -ne 'Off'){
            Stop-VM -Name $VM.Name -ComputerName $VMServer -Force -Verbose
        }
        # Revert to snapshot
        If(Get-VMSnapshot -VMName $VM.Name -ComputerName $VMServer){
            Write-Verbose "Reverting $($VM.Name) back to snapshot $($VM.ParentSnapshotName)"
            Get-VMSnapshot -VMName $VM.Name -ComputerName $VMServer | Restore-VMSnapshot -Confirm:$false
        }
    }
    catch{
        Write-Verbose "No virtual machine was specified, need to create a virtual machine to run capture task sequence on"
        $CreateVM= $true
        Configure-VM -VMName ReferenceImage -Prepare -Verbose
        $VM = Get-VM -Name ReferenceImage -ComputerName $VMServer
    }
    # Insert boot iso
    $ISOFile = (Get-ChildItem -Path (Join-Path $RefShare.Path -ChildPath Boot\*) -Include *.iso).FullName
    Write-Verbose "Mounting $ISOFile and starting $($VM.Name)"
    Set-VMDvdDrive -VMName $VM.Name -ComputerName $VMServer -Path $ISOFile
    Start-VM -VMName $VM.Name -ComputerName $VMServer
    # Wait until .wim file is generated
    do{
        Write-Progress -Activity 'Generating reference image on virtual machine' -PercentComplete -1
        Start-Sleep -Seconds 20
    }
    until((Get-VM -Name $VM.Name -ComputerName $VMServer).State -eq 'Off')
    If($CreateVM){
        Write-Verbose 'A temporary virtual machine was created for image capture, this will now be removed'
        Configure-VM -VMName ReferenceImage -CleanUp -Verbose
    }
    $WimFiles = Get-ChildItem -Path (Join-Path $RefShare.Path -ChildPath Captures\*) -Include *.wim
    $LatestWim = ($WimFiles | sort LastWriteTime -Descending)[0]
    If($CleanUp){
        Write-Verbose '-CleanUp switch was selected, old .wim files will now be removed'
        Write-Verbose "The most recent .wim file is $($LatestWim.FullName)"
        foreach($WimFile in $WimFiles){
            If($WimFile -ne $LatestWim){
                Remove-Item $WimFile -Force
                Write-Verbose "$WimFile has been removed"
            }
        }
    }
    Write-Verbose "New wim file created at $WimFile"
}