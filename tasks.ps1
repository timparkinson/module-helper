[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(
        'Build',
        'Clean', 
        'Publish',
        'Package'
        
    )]
    [string]$Task
)

$build_path = Join-Path $PSScriptRoot -ChildPath 'build'
$package_path = Join-Path $PSScriptRoot -ChildPath 'package'

$owner, $repository = $env:GITHUB_REPOSITORY -split '/'

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

        Write-Verbose "removing $package_path"
        Remove-Item -Path $package_path -Recurse -Force -ErrorAction SilentlyContinue

        $repository_path = Join-Path -Path $PSScriptRoot -ChildPath $repository
        Write-Verbose "removing $repository_path"
        Remove-Item -Path $repository_path -Recurse -Force -ErrorAction SilentlyContinue

    }

    'Package' {
        # Create a nupkg file, then unzip it and inject the RepositoryUrl required by Github packages
        Write-Verbose "Creating $package_path"
        New-Item -Path $package_path -ItemType Directory -ErrorAction SilentlyContinue |
            Out-Null

        Write-Verbose "Registering PackageBuild repository at $package_path"
        Register-PSRepository -Name PackageBuild -SourceLocation $package_path

        Write-Verbose "Renaming $build_path to $repository"
        Rename-Item -Path $build_path -NewName $repository -ErrorAction Stop
        $module_path = Join-Path -Path (Split-Path -Path $build_path -Parent) -ChildPath $repository

        Write-Verbose "Locally publish $module_path to PackageBuild repository"
        Publish-Module -Path $module_path -Repository PackageBuild -ErrorAction Stop

        $nupkg = Get-Item -Path (Join-Path -Path $package_path -ChildPath "$repository*.nupkg")
        
        Write-Verbose "Expanding $($nupkg.FullName)"
        Expand-Archive -Path $nupkg.FullName -DestinationPath (Join-Path -Path $package_path -ChildPath 'unpacked')

        Write-Verbose "Adding https://github.com/$owner/$repository to nuspec"
        $nuspec = Get-ChildItem -Path (Join-Path -Path $package_path -ChildPath "unpacked/*.nuspec")
        $xml = [xml](Get-Content -Path $nuspec.FullName)
        $element = $xml.CreateElement('repository')
        $element.SetAttribute('url', "https://github.com/$owner/$repository")
        $element.SetAttribute('type', 'git')
        $xml.package.metadata.AppendChild($element) |
            Out-Null
        $xml.Save($nuspec.FullName)

        Write-Verbose "Re-compressing nupkg"
        Compress-Archive -Path (Join-Path -Path $package_path -ChildPath 'unpacked/*') -DestinationPath $nupkg.FullName -Update

        Write-Verbose "removing expanded files"
        Remove-Item -Path (Join-Path -Path $package_path -ChildPath 'unpacked') -Recurse -ErrorAction SilentlyContinue
    }

    'Publish' {
        if (-not $env:GITHUB_TOKEN) {
            Write-Error -ErrorAction Stop -Message "No GITHUB_TOKEN set"
        }
        $nuget_repository = "https://nuget.pkg.github.com/$owner/index.json"
        $nupkg = Get-Item -Path (Join-Path -Path $package_path -ChildPath "$repository*.nupkg")

        $result = dotnet nuget push $nupkg --source $nuget_repository --api-key $env:GITHUB_TOKEN 

        if ($result[-1] -notmatch 'Your package was pushed\.') {
            Write-Error -ErrorAction Stop -Message "Pushing failed"
        }

    }

}