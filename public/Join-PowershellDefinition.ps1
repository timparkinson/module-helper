function Join-PowershellDefinition {
    <#
        .SYNOPSIS
            Creates a the contents of scriptblock from a set of module files.
        .DESCRIPTION
            Creates a the contents of scriptblock from a set of module files. Moves 'using' statements to the start of the scriptblock.
            The output from this function may be sent to a file or turned into a scriptblock.
        .PARAMETER Path
            The directory containing the powershell module code.
        .NOTES
            Assumes that the enums, classes, private and public directories exist.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Recurse',
        Justification = 'False positive.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Include',
        Justification = 'False positive.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Exclude',
        Justification = 'False positive.')]

    param(
        [Parameter(
        )]
        [string]$Path,
        [Parameter()]
        [switch]$Recurse
    )

    begin {}

    process {
        $using_statements = Get-UsingStatement -Path $Path -Recurse

        $enum_path = Join-Path -Path $Path -ChildPath 'enums'
        $enums = Get-PowershellDefinition -Path $enum_path -Recurse:$Recurse

        $class_path = Join-Path -Path $Path -ChildPath 'classes'
        $classes = Get-PowershellDefinition -Path $class_path -Recurse:$Recurse

        $private_path = Join-Path -Path $Path -ChildPath 'private'
        $private_functions = Get-PowershellDefinition -Path $private_path -Recurse:$Recurse

        $public_path = Join-Path -Path $Path -ChildPath 'public'
        $public_functions = Get-PowershellDefinition -Path $public_path -Recurse:$Recurse
        $public_function_names = $public_functions |
            ForEach-Object {
                if ($_ -match 'function\W+(?<function_name>[\w\-]+)') {
                    $matches.function_name
                }
            }

        $script_text = @"
#region using
$($using_statements -join "`n")
#endregion

#region enums
$($enums -join "`n")
#endregion

#region classes
$($classes -join "`n")
#endregion

#region private functions
$($private_functions -join "`n")
#endregion

#region public functions
$($public_functions -join "`n")
#endregion

# Export public functions
Export-ModuleMember -Function @('$($public_function_names -join "','")')
"@


    }

    end {
        $script_text
    }
}