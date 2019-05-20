Function Get-OperatingSystemsXML {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$Path
    )

    $OSxml = Join-Path -Path $Path -ChildPath OperatingSystems.xml
    $OS = New-Object -TypeName xml
    $OS.Load($OSxml)
    $OS.oss.os
}