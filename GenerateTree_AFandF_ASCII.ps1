# Parameters passed via environment variables
$TargetPath = $env:TREE_TARGET_PATH
$OutputFile = $env:TREE_OUTPUT_FILE

function Show-TreeASCII {
    param (
        [string]$Path = ".",
        [string]$Prefix = ""
    )

    # Get items, sort: folders first, then files, both alphabetically (case-insensitive)
    $items = Get-ChildItem -LiteralPath $Path |
             Sort-Object -Property @{Expression="PSIsContainer"; Descending=$true}, @{Expression={ $_.Name.ToLower() }}

    $count = $items.Count

    for ($i = 0; $i -lt $count; $i++) {
        $item = $items[$i]
        $isLast = ($i -eq $count - 1)

        if ($isLast) {
            $connector = "\---"
            $nextPrefix = $Prefix + "    "
        } else {
            $connector = "+---"
            $nextPrefix = $Prefix + "|   "
        }

        # Output this item (ASCII style)
        $Prefix + $connector + " " + $item.Name

        # Recurse into directories
        if ($item.PSIsContainer) {
            Show-TreeASCII -Path $item.FullName -Prefix $nextPrefix
        }
    }
}

# Generate the tree
$folderName = Split-Path $TargetPath -Leaf
$creationDate = Get-Date -Format "hh:mmtt MM.dd.yyyy"
$treeContent = "Creation Date: $creationDate`nTarget Folder Path : $TargetPath`n`n$folderName`n"
$treeLines = Show-TreeASCII -Path $TargetPath
$treeContent += $treeLines -join "`n"

# Save to file
$treeContent | Out-File -Encoding ASCII $OutputFile
