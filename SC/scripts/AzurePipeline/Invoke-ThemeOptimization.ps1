param (
    [Parameter(Mandatory = $true)][string] $BuildSourcesDirectory = "C:\Projects\Sitecore\"
)
function SetThemeYml{
    param(
    [Parameter(Mandatory = $true)][string]$themeFolder,
    [Parameter(Mandatory = $true)][string]$ymlFolder,
    [Parameter(Mandatory = $true)][string]$sourceFile,
    [Parameter(Mandatory = $true)][string]$destFile
)   
    & "$BuildSourcesDirectory\SC\scripts\AzurePipeline\Set-ThemeYaml.ps1" -SourceFile "$themeFolder\$sourceFile" -DestFile "$ymlFolder\$destFile"
}

$themes = @(
    [PSCustomObject]@{ Name = 'Common Theme'; ThemePath = '\SC\themes\Common\Common'; YmlPath = '\SC\src\Project\Common\serialization\OptimizedThemes\Common' },
    [PSCustomObject]@{ Name = 'Site1 Theme'; ThemePath = '\SC\themes\Site1'; YmlPath = '\SC\src\Project\Site1\serialization\OptimizedThemes\Site1' },
    [PSCustomObject]@{ Name = 'Site2 Theme'; ThemePath = '\SC\themes\Site2'; YmlPath = '\SC\src\Project\Site2\serialization\OptimizedThemes\Site2' }
)

# Only need to install the global SXA CLI once.
npm config set @sxa:registry=https://sitecore.myget.org/F/sc-npm-packages/npm/
npm install -g @sxa/CLI 

$nodeModulesFolder = ""

foreach($theme in $themes){
    $ymlProjectPath = $BuildSourcesDirectory + $theme.YmlPath
    $projectPath = $BuildSourcesDirectory + $theme.ThemePath
    $themeName = $theme.Name

    Write-Host "`r`nStarting Optimization for: $projectPath"

    [string]$ThemeFolder=Get-ChildItem -Filter "gulpfile.js" -Path "$projectPath" | Select-Object -ExpandProperty DirectoryName -Unique
    if ($null -eq $ThemeFolder -Or $ThemeFolder -eq ""){
        Write-Warning "SXA 10 Theme not found for directory: $projectPath"
        Write-Warning "Exited Optimization for: $projectPath"
        continue
    }   

    #[System.Collections.ArrayList]$ymlFolders = Get-ChildItem -Filter "pre-optimized-min.yml" -Path "$ymlProjectPath" -Recurse | Select-Object -ExpandProperty DirectoryName -Unique
    [System.Collections.ArrayList]$ymlFolders = Get-ChildItem -Path "$ymlProjectPath" -Recurse -Include "pre-optimized-min.yml", "pre-optimized-min-css.yml", "pre-optimized-min-js.yml" | Select-Object -ExpandProperty DirectoryName -Unique

    if ($null -eq $ymlFolders -Or $ymlFolders.Count -eq 0){
        Write-Warning "Destination YML files not found for directory: $projectPath"
        Write-Warning "Exited Optimization for: $projectPath"
        continue
    }

    Set-Location $ThemeFolder

    if ($nodeModulesFolder -eq "") {

        npm install
        $nodeModulesFolder = $projectPath + "\node_modules"

    } else {
        
        Write-Output "nodeModulesFolder: $nodeModulesFolder"
        
        try {
            if (Test-Path -Path "./node_modules") {
                Remove-Item -Recurse -Force "./node_modules"
            }

            New-Item -ItemType SymbolicLink -Path ".\node_modules" -Target $nodeModulesFolder 
            Write-Output "Symbolic link created successfully."
        } catch {
            Write-Error "Failed to create symbolic link: $_"
            npm install
        }

    }

    sxa build All --debug

    $scriptFolder = $ymlFolders | Where-Object {$_.ToUpper().Contains("SCRIPTS")  }

    if($null -ne $scriptFolder -and $scriptFolder -ne ""){
        
        Write-Host "scriptFolder: $scriptFolder"
        
        try {
            SetThemeYml -themeFolder $ThemeFolder -sourceFile 'scripts\pre-optimized-min.js' -ymlFolder $scriptFolder -destFile "pre-optimized-min.yml"
        }
        catch {
            Write-Warning "Script (js) Optimization Failed"
            Write-Warning $_.Exception.Message
        }    

        try {
            SetThemeYml -themeFolder $ThemeFolder -sourceFile 'scripts\pre-optimized-min-js.map' -ymlFolder $scriptFolder -destFile "pre-optimized-min-js.yml"
        }
        catch {
            Write-Warning "Script (map) Optimization Failed"
            Write-Warning $_.Exception.Message
        }
    }

    $stylesFolder = $ymlFolders | Where-Object {$_.ToUpper().Contains("STYLES")  }

    if($null -ne $stylesFolder -and $stylesFolder -ne ""){
        
        Write-Host "stylesFolder: $stylesFolder"

        try {
            SetThemeYml -themeFolder $ThemeFolder -sourceFile 'styles\pre-optimized-min.css' -ymlFolder $stylesFolder -destFile "pre-optimized-min.yml"
        }
        catch {
            Write-Warning "Style(css) Optimization Failed"
            Write-Warning $_.Exception.Message
        }   

        try {
            SetThemeYml -themeFolder $ThemeFolder -sourceFile 'styles\pre-optimized-min-css.map' -ymlFolder $stylesFolder -destFile "pre-optimized-min-css.yml"
        }
        catch {
            Write-Warning "Style(map) Optimization Failed"
            Write-Warning $_.Exception.Message
        }   
    }
    Write-Host "`r`nFinished Optimization for: $projectPath"
}

& "$BuildSourcesDirectory\SC\scripts\AzurePipeline\Enable-ThemeOptmizationConfiguationFiles.ps1"

Set-Location  ${PSScriptRoot}