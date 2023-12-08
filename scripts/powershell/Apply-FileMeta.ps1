# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# .\scripts\powershell\Apply-FileMeta.ps1 -filePath .\meta\file-meta.data -targetPathPrefix .\seer2.61.com

# 输入要扫描的目标文件夹路径
param (
	[string]$filePath,
	[string]$targetPathPrefix
)

function Get-FileMeta {
    param(
        [string]$filePath
    )

	# 读取文件内容
	$fileContent = Get-Content -Path $filePath -Raw -Encoding UTF8

	# 分割文本并处理每一行
	$urls = $fileContent -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
		# 拆分每一行并处理
		$parts = $_ -split " "
		$path = $parts[0..($parts.Count - 3)] -join " "
		$modifiedTime = [UInt64]::Parse($parts[$parts.Count - 2])
		$md5 = $parts[$parts.Count - 1].Trim()

		# 输出 $modifiedTime 小于等于 0 的数据并打印整行内容
		if ($modifiedTime -le 0) {
			Write-Host "Modified Time is less than or equal to 0: $_"
		}
		
		# 构建一个包含所需信息的对象
		[PSCustomObject]@{
			Path = $path
			ModifiedTime = $modifiedTime
			MD5 = $md5
		}
	}

	# 输出结果
	$urls
}

function Set-FileMeta {
    param(
		[string]$targetPathPrefix,
        [string]$filePath,
        [UInt64]$modifiedTime,
		[string]$expectedMD5
    )
	
	$fullPath = $targetPathPrefix + $filePath
	$modifiedDateTime = (Get-Date -Date "1970-01-01T00:00:00Z").AddMilliseconds($modifiedTime)
	
	#Write-Host "$filePath $modifiedDateTime"

    # 修改文件的创建时间和修改时间
    $file = Get-Item -Path $fullPath
    $file.CreationTime = $modifiedDateTime
    $file.LastWriteTime = $modifiedDateTime
	
	# 计算文件的MD5并检查是否与期望的MD5一致
	$currentMD5 = Get-FileHash -Path $fullPath -Algorithm MD5 | Select-Object -ExpandProperty Hash

	if ($currentMD5 -ne $expectedMD5) {
		Write-Host "MD5 mismatch for file: $filePath, expected: $expectedMD5, current: $currentMD5"
	}
}

function Apply-FileMeta {
    param(
        [string]$filePath,
        [string]$targetPathPrefix
    )

    # 获取文件信息
    $fileMeta = Get-FileMeta -filePath $filePath

    # 循环处理文件信息并修改文件时间
    foreach ($file in $fileMeta) {
        Set-FileMeta -targetPathPrefix $targetPathPrefix -filePath $file.Path -modifiedTime $file.ModifiedTime -expectedMD5 $file.md5
    }
}

Apply-FileMeta -filePath $filePath -targetPathPrefix $targetPathPrefix