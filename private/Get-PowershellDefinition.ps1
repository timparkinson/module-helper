function Get-PowershellDefinition {
    <#
        .SYNOPSIS
            Gets a set of powershell definitions.
        .DESCRIPTION
            Gets a set of powershell defintions.
        .PARAMETER Path
            The path to the directory holding the definitions.
        .PARAMETER Exclude
            The pattern(s) to exclude. Defaults to '*.Tests.ps1'
        .PARAMETER Include
            The pattern(s) to Include. Defaults to '*.ps1'.
        .PARAMETER UsingPattern
            The pattern of 'using' statements to remove from the definition. This should never be changed.
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'UsingPattern',
        Justification = 'False positive.')]

    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true
        )]
        [string[]] $Path,
        [Parameter()]
        [string[]] $Exclude = @(
            '\.Tests.ps1$'
        ),
        [Parameter()]
        [string[]] $Include = @(
            '\.ps1$'
        ),
        [Parameter()]
        [string]$UsingPattern = '^using .*',
        [Parameter()]
        [switch]$Recurse
    )

    begin {
        $definitions =  [System.Collections.Generic.List[string]]::new()
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
                                $definition = Get-Content -Path $_.FullName |
                                    ForEach-Object {
                                        $_ -replace $UsingPattern, ''
                                    }
                                $definitions.Add(($definition -join "`n"))
                            }
                        }
                }
            }
    }

    end {
        $definitions
    }
}