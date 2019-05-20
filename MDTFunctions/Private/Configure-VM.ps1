Function Configure-VM {
    <#
        .SYNOPSIS
            Create or remove virtual machine used to create reference image.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$VMName,

        [switch]$Prepare,

        [switch]$CleanUp
    )

    BEGIN{
        Write-Verbose "VMName is $VMName"
        $Switch = 'MDTBuild'
        $Path = "$env:TEMP\RefImage"
        $VHDPath = "$env:TEMP\RefImage\OS.vhdx"
        $script:MACAddress = (Get-VMHost).MacAddressMaximum.Insert(2,':').Insert(5,':').Insert(8,':').Insert(11,':').Insert(14,':')
    }

    PROCESS{
        If($Prepare){
            Write-Verbose 'Creating virtual machine to capture image on'
            # Create virtual switch
            If(-not(Get-VMSwitch -Name $Switch -ComputerName $VMServer -ErrorAction SilentlyContinue)){
                $VMSwitch = New-VMSwitch -Name $Switch -SwitchType Internal -ComputerName $VMServer
                Write-Verbose "New Internal switch called $Switch created"
            }

            $MemoryStartupBytes = 2GB
            $BootDevice = 'CD'
            $Generation = '1'
            $VHD = New-VHD -Path $VHDPath -ComputerName $VMServer -SizeBytes 127GB -Dynamic
            Write-Verbose "New virtual hard disk created at $($VHD.Path)"
            $VHDPath = $VHD.Path
            New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -BootDevice $BootDevice -VHDPath $VHDPath -Path $Path -Generation $Generation -Switch $Switch -ComputerName $VMServer | Out-Null
            Set-VMMemory -VMName $VMName -ComputerName $VMServer -DynamicMemoryEnabled $false
            Write-Verbose 'New virtual machine created'
            Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapter -StaticMacAddress $MACAddress
            Write-Verbose "Static MAC address of $MACAddress set on network adapter"
            # Generate static IP address info for VM
            $NetworkAdapterName = Get-NetAdapter | where {$_.Name -like "*$Switch*"}
            do{
                Start-Sleep -Milliseconds 50                
            }
            until (($NetworkAdapterName | Get-NetIPAddress).IPv4Address)
            $MDTServerIP = ($NetworkAdapterName | Get-NetIPAddress).IPv4Address | Out-String
            Write-Verbose "IP address $MDTServerIP has been assigned to the MDT Server"
            $Octets = $MDTServerIP.Split('.')
            $LastOctet = [int]$Octets[3] + '1'
            If($LastOctet -eq '256'){
                $LastOctet = 250
            }
            $VMIPAddress = "$($Octets[0]).$($Octets[1]).$($Octets[2]).$LastOctet"
            $SubnetMask = '255.255.0.0'
            Write-Verbose "IP address $VMIPAddress has been assigned to the virtual machine"
            Update-BootStrapIni -Verbose
        }
    
        If($CleanUp){
            Remove-VM -Name $VMName -ComputerName $VMServer -Force
            Write-Verbose 'Virtual machine has been deleted'
            Remove-Item -Path $Path -Recurse -Force
            Write-Verbose 'Virtual hard disk has been deleted'
            Remove-VMSwitch -Name $Switch -ComputerName $VMServer -Force
            Write-Verbose "Internal switch $Switch has been deleted"
            Write-Verbose 'Virtual machine cleanup complete'
        }    
    }

    END {}
}