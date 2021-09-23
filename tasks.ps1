[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(
        'Build',
        'Clean', 
        'Publish'
        
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

    'Publish' {
        if (-not $env:GITHUB_TOKEN) {
            Write-Error -ErrorAction Stop -Message "No GITHUB_TOKEN set"
        }

        $owner, $repository = $env:GITHUB_REPOSITORY -split '/'

        $credential = New-Object -TypeName pscredential -ArgumentList $owner, ($env:GITHUB_TOKEN | ConvertTo-SecureString -AsPlainText -Force)

        $source = "https://nuget.pkg.github.com/$owner/index.json"
        $source_name = 'GitHub'
        Write-Verbose "Registering repository $source_name at $source"
        Register-PSRepository -Name $source_name -SourceLocation $source -PublishLocation $source -Credential $credential
    
        Write-Verbose "Publishing $build_path to $source_name"
        Write-Verbose ((ls $build_path | select FullName) -join ',' )
        Publish-Module -Path $build_path -Credential $credential -Repository $source_name -NuGetApiKey 'n/a' -ErrorAction Stop
    }

}