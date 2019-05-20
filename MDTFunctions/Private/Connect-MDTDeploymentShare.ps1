Function Connect-MDTDeploymentShare {
    [CmdletBinding()]
    param(
        [String]$MDTServer = $env:COMPUTERNAME,

        [Parameter(Mandatory=$true)]
        [String]$DeploymentShare
    )

    $MDTInstallDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Deployment 4').Install_Dir + 'Bin'
    Import-Module "$MDTInstallDir\MicrosoftDeploymentToolkit.psd1"
    $DSDrive = (Get-MDTPersistentDrive).Where{$_.Path -like "*$DeploymentShare*"}
    $DSDrive
}
