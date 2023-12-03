# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 输入要扫描的目标文件夹路径
param (
    [string]$targetPath
)

# 获取文件夹的最新修改时间
function Get-FolderLatestModifiedTime {
    param (
        [string]$folderPath
    )

    # 获取文件夹下所有文件和子文件夹的修改时间
    $items = Get-ChildItem -Path $folderPath
    $latestModifiedTime = $null
    foreach ($item in $items) {
        if ($latestModifiedTime -eq $null -or $item.LastWriteTime -gt $latestModifiedTime) {
            $latestModifiedTime = $item.LastWriteTime
        }
    }
    return $latestModifiedTime
}

# 设置文件夹的修改时间为指定的修改时间
function Set-FolderModifiedTime {
    param (
        [string]$folderPath,
        [datetime]$modifiedTime
    )
    (Get-Item $folderPath).LastWriteTime = $modifiedTime
}

# 递归扫描目标文件夹及其子文件夹，并设置文件夹的修改时间
function Scan-And-Set-FolderModifiedTime {
    param (
        [string]$targetPath
    )

    # 递归扫描子文件夹并设置修改时间
    $folders = Get-ChildItem -Path $targetPath -Directory
    foreach ($folder in $folders) {
        $folderPath = $folder.FullName
        Scan-And-Set-FolderModifiedTime -targetPath $folderPath
    }

    # 设置当前文件夹的修改时间
    $currentFolderModifiedTime = Get-FolderLatestModifiedTime -folderPath $targetPath
    Set-FolderModifiedTime -folderPath $targetPath -modifiedTime $currentFolderModifiedTime
}

# 执行函数来扫描目标文件夹并设置修改时间
Scan-And-Set-FolderModifiedTime -targetPath $targetPath