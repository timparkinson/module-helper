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
        New-Item -ItemType Directory -Path $build_path -ErrorAction SilentlyContinue |
            Out-Null

        # Eating our own dog food...
        'public', 'private' |
            ForEach-Object {
                $path = Join-Path -Path $PSScriptRoot -ChildPath $_

                Get-ChildItem -Path $path |
                    Where-Object {$_.FullName -notmatch '\.Tests\.ps1'} |
                        ForEach-Object {
                            . $_.FullName
                        }
            }

        Join-PowershellDefinition -Path $PSScriptRoot |
            Out-File -FilePath (Join-Path -Path $build_path -ChildPath "$(Split-Path -Leaf -Path $PSScriptRoot).psm1")

        # PSD
        Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "$(Split-Path -Leaf -Path $PSScriptRoot).psd1") -Destination $build_path
    }

    'Clean' {
        Remove-Item -Path $build_path -Recurse -Force -ErrorAction SilentlyContinue
    }

}