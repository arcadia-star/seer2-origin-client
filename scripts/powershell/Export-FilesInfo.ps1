# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 输入要扫描的目标文件夹路径
param (
	[string]$targetDirectory,
	[string]$outputFilePath
)

function Export-FilesInfo {
    param (
        [string]$targetDirectory,
        [string]$outputFilePath
    )
	
	# 将相对路径转换为绝对路径
    $absolutePath = Convert-Path $targetDirectory

    # 获取指定目录下所有文件
    $files = Get-ChildItem -Path $absolutePath -Recurse -File

    # 准备一个数组来存储文件信息
    $outputData = @()

    # 循环遍历每个文件并输出所需信息
    foreach ($file in $files) {
        # 计算文件的相对路径（使用 / 作为分隔符）并将 \ 替换为 /
        $relativePath = $file.FullName.Replace($absolutePath, '').TrimStart("\").Replace("\", "/")
        
        # 在路径前添加斜杠 /
        $relativePath = "/" + $relativePath

        # 获取文件的修改时间并转换为 UNIX 时间戳（毫秒）
        $lastWriteTime = $file.LastWriteTime.ToUniversalTime()
        $unixTimestamp = [int64]($lastWriteTime - (Get-Date "1970-01-01")).TotalMilliseconds

        # 如果时间戳小于等于0，则设为0
        if ($unixTimestamp -le 0) {
            $unixTimestamp = 0
        }
        
        # 计算文件的 MD5 哈希值并转换为小写
        $md5 = Get-FileHash -Path $file.FullName -Algorithm MD5 | Select-Object -ExpandProperty Hash
        $md5 = $md5.ToLower()

        # 构建文件信息并添加到输出数组中
        $fileInfo = "$relativePath $unixTimestamp $md5"
        $outputData += $fileInfo
    }
	
	# 对数组内容按字母序排序
	$sortedData = $outputData | Sort-Object

    # 将结果保存到文件中
    $sortedData | Out-File -FilePath $outputFilePath -Encoding utf8
}

# 使用函数并传入目标目录路径和输出文件路径
Export-FilesInfo -targetDirectory $targetDirectory -outputFilePath $outputFilePath