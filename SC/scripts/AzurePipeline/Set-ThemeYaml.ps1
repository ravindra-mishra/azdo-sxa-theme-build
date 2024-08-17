[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $SourceFile,
    [Parameter(Mandatory = $true)]
    [string] $DestFile
)
$ErrorActionPreference = 'Stop'

if ([System.IO.File]::Exists($SourceFile) -eq $false)
{
    throw "Source File $SourceFile does not exist"
}

if([System.IO.File]::Exists($DestFile) -eq $false)
{
    throw "Destination File $DestFile does not exist"
} 

Write-Host "Moving file contents from $SourceFile into $DestFile" 

$sourceBytes = [System.IO.File]::ReadAllBytes($SourceFile)
$blob = [System.Convert]::ToBase64String($sourceBytes)
$size = $sourceBytes.Length
$date = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')

$destText = [System.IO.File]::ReadAllText($DestFile)
$blobId = [System.Guid]::NewGuid().ToString().ToLower()
$sb = [System.Text.StringBuilder]::new()

if ($destText -match "ID: ""40e50ed9-ba07-4702-992e-a912738d32dc""") {
    $datePattern = '- ID: "([a-fA-F0-9-]{36})"\s+Hint: __Updated\s+Value: ([\w\-]+)'
    $blobPattern = '- ID: "([a-fA-F0-9-]{36})"\s+Hint: Blob\s+BlobID: "([a-fA-F0-9-]{36})"\s+Value: ([A-Za-z0-9+/=]+)'
    $sizePattern = '- ID: "([a-fA-F0-9-]{36})"\s+Hint: Size\s+Value: ([\w\-]+)'

    $sbBlob = [System.Text.StringBuilder]::new()
    $sbBlob.AppendLine("- ID: ""40e50ed9-ba07-4702-992e-a912738d32dc""");
    $sbBlob.AppendLine("  Hint: Blob");
    $sbBlob.AppendLine("  BlobID: ""${blobId}""");
    $sbBlob.Append("  Value: ${blob}");

    $sbSize = [System.Text.StringBuilder]::new()
    $sbSize.AppendLine("- ID: ""6954b7c7-2487-423f-8600-436cb3b6dc0e""");
    $sbSize.AppendLine("  Hint: Size");
    $sbSize.Append("  Value: ${size}");

    $sbDate = [System.Text.StringBuilder]::new()
    $sbDate.AppendLine("- ID: ""d9cf14b1-fa16-4ba6-9288-e8a174d4d522""");
    $sbDate.AppendLine("      Hint: __Updated");
    $sbDate.Append("      Value: ${date}");
 
    
    $outText = $destText;
    $outText = $outText -replace $blobPattern, $sbBlob.ToString();
    $outText = $outText -replace $sizePattern, $sbSize.ToString();
    $outText = $outText -replace $datePattern, $sbDate.ToString();
     
} else {
    $createdDatePattern = '- ID: "([a-fA-F0-9-]{36})"\s+Hint: __Created\s+Value: ([\w\-]+)'

    $sb = [System.Text.StringBuilder]::new()
    $sb.AppendLine("SharedFields:");
    $sb.AppendLine("- ID: ""40e50ed9-ba07-4702-992e-a912738d32dc""");
    $sb.AppendLine("  Hint: Blob");
    $sb.AppendLine("  BlobID: ""${blobId}""");
    $sb.AppendLine("  Value: ${blob}");
    $sb.AppendLine("- ID: ""6954b7c7-2487-423f-8600-436cb3b6dc0e""");
    $sb.AppendLine("  Hint: Size");
    $sb.Append("  Value: ${size}");

    $sbCreatedDate = [System.Text.StringBuilder]::new()
    $sbCreatedDate.AppendLine("- ID: ""25bed78c-4957-4165-998a-ca1b52f67497""");
    $sbCreatedDate.AppendLine("      Hint: __Created");
    $sbCreatedDate.AppendLine("      Value: ${date}");
    $sbCreatedDate.AppendLine("    - ID: ""badd9cf9-53e0-4d0c-bcc0-2d784c282f6a""");
    $sbCreatedDate.AppendLine("      Hint: __Updated by");
    $sbCreatedDate.AppendLine("      Value: |");
    $sbCreatedDate.AppendLine("        sitecore\admin");
    $sbCreatedDate.AppendLine("    - ID: ""d9cf14b1-fa16-4ba6-9288-e8a174d4d522""");
    $sbCreatedDate.AppendLine("      Hint: __Updated");
    $sbCreatedDate.Append("      Value: ${date}");


    $outText = $destText;

    $outText = $outText.Replace("SharedFields:",$sb.ToString());
    $outText = $outText -replace $createdDatePattern, $sbCreatedDate.ToString();
    [System.IO.File]::WriteAllText($DestFile, $outText);
}

$BOM = [System.Text.Encoding]::UTF8.GetPreamble()
[System.IO.File]::WriteAllBytes($DestFile, $BOM + [System.Text.Encoding]::UTF8.GetBytes($outText))

Write-Host $outText