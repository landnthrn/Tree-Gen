@echo off
cd /d "%~dp0"
chcp 65001 >nul
setlocal DisableDelayedExpansion
mode con: cols=135 lines=60
color 0A

:menu
cls
echo ==========================
echo         TREE GEN
echo      by landn.thrn
echo ==========================
echo.
echo OPTIONS:
echo.
echo 1 - Create a Tree
echo 2 - View Saved Tree's
echo.
set /p choice="Enter Command: "

if "%choice%"=="1" goto create_tree
if "%choice%"=="2" goto view_trees
goto menu

:create_tree
REM Clear previous variables
set "style="
set "type="
set "folder_path="

cls
echo ==========================
echo       CREATE A TREE
echo ==========================
echo.
echo M - Back to Menu
echo.
set /p folder_path="Enter the path to the folder: "

REM Check if user wants to go back to menu
if "%folder_path%"=="M" goto menu
if "%folder_path%"=="m" goto menu

if not exist "%folder_path%" (
    echo Error: Folder does not exist.
    echo.
    goto create_tree
)

:tree_style
cls
echo ==========================
echo       CREATE A TREE
echo ==========================
echo.
echo Choose Tree Style:
echo 1 - ASCII Format
echo 2 - Unicode Format
echo.
echo M - Back to Menu
echo.
set /p style_choice="Enter Command: "

if "%style_choice%"=="1" set style=ASCII
if "%style_choice%"=="2" set style=UTF-8
if "%style_choice%"=="M" goto menu
if "%style_choice%"=="m" goto menu
if not defined style goto tree_style

:tree_type
cls
echo ==========================
echo       CREATE A TREE
echo ==========================
echo.
echo Choose Tree Type:
echo 1 - All Folders (AF)
echo 2 - All Files and Folders (AF^&F)
echo.
echo M - Back to Menu
echo.
set /p type_choice="Enter Command: "

if "%type_choice%"=="1" set type=AF
if "%type_choice%"=="2" set type=AFandF
if "%type_choice%"=="M" goto menu
if "%type_choice%"=="m" goto menu
if not defined type goto tree_type

REM Create MyTree's folder if it doesn't exist
if not exist "MyTree's" mkdir "MyTree's"

REM Get folder name for filename
for %%I in ("%folder_path%") do set "folder_name=%%~nxI"

REM Generate output filename with versioning
setlocal EnableDelayedExpansion
set "base_name=MyTree's\tree-%folder_name%-%type%-%style%"
set "output_file=!base_name!.txt"

REM Check if file exists and add version number if needed
if exist "!output_file!" (
    set counter=1
    :check_version
    set "versioned_file=!base_name! (!counter!).txt"
    if exist "!versioned_file!" (
        set /a counter+=1
        goto check_version
    )
    set "output_file=!versioned_file!"
)
endlocal & set "output_file=%output_file%"

REM Set environment variables for PowerShell scripts
set "TREE_TARGET_PATH=%folder_path%"
set "TREE_OUTPUT_FILE=%output_file%"

REM Call the appropriate PowerShell script
if "%style%"=="UTF-8" (
    if "%type%"=="AF" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GenerateTree_AF_Unicode.ps1"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GenerateTree_AFandF_Unicode.ps1"
    )
) else (
    if "%type%"=="AF" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GenerateTree_AF_ASCII.ps1"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GenerateTree_AFandF_ASCII.ps1"
    )
)

REM Check if file was created
if exist "%output_file%" (
    REM Generate header info by echoing directly

    REM Expand terminal for tree viewing with scrolling enabled
    powershell -NoProfile -Command "$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(135, 9999); $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(135, 60)"
    cls
    echo ========================
    echo Tree for %folder_name% folder
    echo ========================
    echo.
    set "TREE_FILE=%output_file%"
    REM Display tree content (skip header lines)
    powershell -NoProfile -Command "$content = Get-Content $env:TREE_FILE -Encoding UTF8; $content[2..($content.Length-1)] -join \"`n\" | Out-Host"
    echo.
    echo ========================
    echo.
    REM Use same format as PowerShell scripts
    for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format 'hh:mmtt MM.dd.yyyy'"') do echo Creation Date: %%i
    echo.
    echo Target Folder Path : %folder_path%
    echo.
    echo Tree Saved to: \MyTree's\tree-%folder_name%-%type%-%style%.txt
    echo.
    echo ========================
    echo.
    echo Press any key to return to main menu...
    pause >nul
) else (
    echo Error: Failed to generate tree.
    pause
)

goto menu

:open_folder
REM Open MyTree's folder in File Explorer
for /f "delims=" %%i in ("%~dp0MyTree's") do start "" "%%~fi"
goto view_trees

:view_trees
cls
echo ==========================
echo        SAVED TREE'S
echo ==========================
echo.
echo Tree's Location:
for /f "delims=" %%i in ("%~dp0MyTree's") do echo %%~fi
echo.

REM Check if MyTree's folder exists
if not exist "MyTree's" (
    echo No saved trees found.
    echo.
    pause
    goto menu
)

setlocal EnableDelayedExpansion

REM Enable scrolling for long tree lists
powershell -NoProfile -Command "$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(135, 9999); $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(135, 60)"

REM List all tree files sorted by creation time
powershell -NoProfile -Command "$files = Get-ChildItem 'MyTree''s\tree-*.txt' | Sort-Object CreationTime; if ($files.Count -eq 0) { Write-Host 'No saved trees found.' } else { $files | ForEach-Object -Begin { $i = 1 } -Process { Write-Host ($i.ToString() + ' - ' + $_.Name); $i++ } }"

REM Check if there are any files
for /f %%c in ('powershell -NoProfile -Command "(Get-ChildItem ''MyTree''''s\tree-*.txt'').Count"') do set file_count=%%c

if !file_count!==0 (
    echo.
    pause
    goto menu
)

echo.
echo O - Open MyTree's Folder
echo M - Back to Menu
echo.
set /p view_choice="Enter command: "

if "%view_choice%"=="O" goto open_folder
if "%view_choice%"=="o" goto open_folder
if "%view_choice%"=="M" goto menu
if "%view_choice%"=="m" goto menu

REM Find the selected file by index (sorted by creation time)
powershell -NoProfile -Command "$files = Get-ChildItem 'MyTree''s\tree-*.txt' | Sort-Object CreationTime; $index = %view_choice% - 1; if ($index -ge 0 -and $index -lt $files.Count) { $files[$index].FullName }" > temp_file.txt 2>nul
set /p selected_file=<temp_file.txt
if exist temp_file.txt del temp_file.txt

if defined selected_file (
    REM Set environment variable for PowerShell
    set "VIEW_FILE=!selected_file!"

    REM Expand terminal for tree viewing with scrolling enabled
    powershell -NoProfile -Command "$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(135, 9999); $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(135, 60)"
    cls
    REM Read header info (creation date and target path)
    for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Content $env:VIEW_FILE -Encoding UTF8 | Select-Object -First 1"') do set creation_date=%%i
    for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Content $env:VIEW_FILE -Encoding UTF8 | Select-Object -Index 1"') do set target_path=%%i

    REM Display tree content (skip header lines)
    powershell -NoProfile -Command "$content = Get-Content $env:VIEW_FILE -Encoding UTF8; $content[2..($content.Length-1)] -join \"`n\" | Out-Host"

    echo.
    echo ========================
    echo.
    for %%f in ("!selected_file!") do echo Viewing: %%~nxf
    echo.
    echo !creation_date!
    echo.
    echo !target_path!
    echo.
    for %%f in ("!selected_file!") do echo Tree Saved to: %%~nxf
    echo.
    echo ========================
    echo.
    echo Press any key to continue...
    pause >nul

    goto view_trees
) else (
    echo Invalid selection.
    echo.
    goto view_trees
)

endlocal
