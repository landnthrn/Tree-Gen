# Parameters passed via environment variables
$TargetPath = $env:TREE_TARGET_PATH
$OutputFile = $env:TREE_OUTPUT_FILE

function Show-Tree {
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
            $connector = "$([char]0x2514)$([char]0x2500) "
            $nextPrefix = $Prefix + "    "
        } else {
            $connector = "$([char]0x251c)$([char]0x2500) "
            $nextPrefix = $Prefix + "$([char]0x2502)   "
        }

        # Output this item
        $Prefix + $connector + $item.Name

        # Recurse into directories
        if ($item.PSIsContainer) {
            Show-Tree -Path $item.FullName -Prefix $nextPrefix
        }
    }
}

# Generate the tree
$folderName = Split-Path $TargetPath -Leaf
$creationDate = Get-Date -Format "hh:mmtt MM.dd.yyyy"
$treeContent = "Creation Date: $creationDate`nTarget Folder Path : $TargetPath`n`n$folderName`n"
$treeLines = Show-Tree -Path $TargetPath
$treeContent += $treeLines -join "`n"

# Save to file
$treeContent | Out-File -Encoding UTF8 $OutputFile
