[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet(
        'Build',
        'Clean'
    )]
    [string]$Task

)

$build_path = Join-Path $PSScriptRoot -ChildPath 'build'

switch ($Task) {
    'Build' {
        Write-Verbose "Creating $build_path"
        New-Item -ItemType Directory -Path $build_path -ErrorAction SilentlyContinue |
            Out-Null

        # Eating our own dog food...
        Write-Verbose "Loading functions"
        'public', 'private' |
            ForEach-Object {
                $path = Join-Path -Path $PSScriptRoot -ChildPath $_

                Get-ChildItem -Path $path |
                    Where-Object {$_.FullName -notmatch '\.Tests\.ps1'} |
                        ForEach-Object {
                            . $_.FullName
                        }
            }

        Write-Verbose "Creating module file"
        Join-PowershellDefinition -Path $PSScriptRoot |
            Out-File -FilePath (Join-Path -Path $build_path -ChildPath "$(Split-Path -Leaf -Path $PSScriptRoot).psm1")

        Write-Verbose "Creating module manifest"
        Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "$(Split-Path -Leaf -Path $PSScriptRoot).psd1") -Destination $build_path
    }

    'Clean' {
        Write-Verbose "removing $build_path"
        Remove-Item -Path $build_path -Recurse -Force -ErrorAction SilentlyContinue
    }

}