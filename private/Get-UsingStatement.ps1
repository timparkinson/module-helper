function Get-UsingStatement {
    <#
        .SYNOPSIS
            Gets the 'using' statements from a set of powershell files.
        .DESCRIPTION
            Gets the 'using' statements from a set of powershell files.
        .PARAMETER Path
            The path of the directories to scan for files with using statements.
        .PARAMETER Exclude
            The pattern(s) to exclude. Defaults to '\.Tests\.ps1$'
        .PARAMETER Include
            The pattern(s) to include. Defaults to '\.ps1$'
        .PARAMETER Recurse
            Whether to recurse down a path.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[string]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Recurse',
        Justification = 'False positive.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Include',
        Justification = 'False positive.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Exclude',
        Justification = 'False positive.')]

    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true
        )]
        [string[]] $Path,
        [Parameter()]
        [string[]] $Exclude = @('\.Tests\.ps1$'),
        [Parameter()]
        [string[]] $Include = @('\.ps1$'),
        [Parameter()]
        [switch]$Recurse
    )

    begin {
        $using_list = [System.Collections.Generic.List[string]]::new()
    }

    process {
        $Path |
            ForEach-Object {
                if (Test-Path -Path $_ -PathType Container) {
                    Get-ChildItem -Path $_ -Recurse:$Recurse |
                        ForEach-Object {
                            $process = $false
                            foreach ($pattern in $Include) {
                                if ($_.FullName -match $pattern) {
                                    $process = $true
                                }
                            }
                            foreach ($pattern in $Exclude) {
                                if ($_.FullName -match $pattern) {
                                    $process = $false
                                }
                            }

                            if ($process) {
                                Get-Content -Path $_.FullName |
                                    ForEach-Object {
                                        if ($_ -match '^using ') {
                                            if (-not $using_list.NotContains($_)) {
                                                $using_list.Add($_)
                                            }
                                        }
                                    }
                            }
                        }
                }
            }
    }

    end {
        $using_list
    }
}