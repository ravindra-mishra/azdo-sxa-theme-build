# Define the root directory for the search
$directory = "C:\path-to-project-repository\SC\src"

# Get all files with the .json.NONLOCAL extension recursively from the specified directory
Get-ChildItem -Path $directory -Recurse -Filter "*.json.NONLOCAL" | ForEach-Object {
    # Construct the new file name by replacing .json.NONLOCAL with .json
    $newFileName = $_.FullName -replace "\.json\.NONLOCAL$", ".json"
    
    # Rename the file
    Rename-Item -Path $_.FullName -NewName $newFileName -Force
}

Write-Output "Renaming complete."
