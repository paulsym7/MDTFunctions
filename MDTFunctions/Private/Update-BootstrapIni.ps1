Function Update-BootstrapIni {
    [CmdletBinding()]
    param(
        #[String]$BootStrapIniPath,

        #[String]$DeploymentShare
    )

    BEGIN{
        Write-Verbose  "Backuping up the bootstrap.ini file to $($RefShare.Path)\Backup\Bootstrap.ini"
        Copy-Item -Path (Join-Path $RefShare.Path -ChildPath Control\Bootstrap.ini) -Destination (Join-Path -Path $RefShare.Path -ChildPath Backup\Bootstrap.ini)
    }

    PROCESS{
        $Bootstrap = Get-Content (Join-Path $RefShare.Path -ChildPath Control\Bootstrap.ini)
        Write-Verbose 'Configuring network settings:'
        Write-Verbose "`tSetting IP address to $VMIPAddress"
        Write-Verbose "`tSetting subnet mask to $SubnetMask"
        $NetworkSettings =@"

OSDAdapter0EnableDHCP=FALSE
OSDAdapterCount=1
OSDAdapter0IPAddressList=$VMIPAddress
OSDAdapter0SubnetMask=$SubnetMask
"@ | Out-File -FilePath (Join-Path $RefShare.Path -ChildPath Control\Bootstrap.ini) -Encoding ascii -Append
    }

    END{
        Write-Verbose "The Bootstrap.ini file has been updated. Boot media will now be regenerated in $($RefShare.Name):"
        New-PSDrive -Name $RefShare.Name -PSProvider MDTProvider -Root $RefShare.Path | Out-Null
        Update-MDTDeploymentShare -Path "$($RefShare.Name):" -Force
        Write-Verbose 'Boot media has been updated, the original Bootstrap.ini file will now be restored to the Control folder'
        Copy-Item -Path (Join-Path $RefShare.Path -ChildPath Backup\Bootstrap.ini) -Destination (Join-Path -Path $RefShare.Path -ChildPath Control\Bootstrap.ini) -Force
        Remove-Item -Path (Join-Path $RefShare.Path -ChildPath Backup\Bootstrap.ini) -Force
    }
}