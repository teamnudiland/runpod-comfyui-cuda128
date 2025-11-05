# Docker 镜像构建和推送到 Docker Hub 脚本
# 适用于 Windows PowerShell

param(
    [string]$Version = "latest",
    [string]$DockerHubUsername = "robinl9527",
    [string]$ImageName = "comfyui-cuda128",
    [switch]$SkipBuild = $false,
    [switch]$SkipPush = $false
)

$ErrorActionPreference = "Stop"

# 配置
$FullImageName = "${DockerHubUsername}/${ImageName}"
$ImageTag = "${FullImageName}:${Version}"
$LatestTag = "${FullImageName}:latest"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Docker 镜像构建和推送脚本" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "镜像名称: $ImageTag" -ForegroundColor Yellow
Write-Host "Docker Hub: $DockerHubUsername" -ForegroundColor Yellow
Write-Host ""

# 检查 Docker 是否运行
Write-Host "[1/6] 检查 Docker 状态..." -ForegroundColor Green
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker 已安装: $dockerVersion" -ForegroundColor Green
    
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Docker 未运行，请启动 Docker Desktop" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker 正在运行" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker 未安装或未运行" -ForegroundColor Red
    exit 1
}

# 检查磁盘空间
Write-Host ""
Write-Host "[2/6] 检查磁盘空间..." -ForegroundColor Green
$disk = Get-PSDrive C
$freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)
Write-Host "可用磁盘空间: ${freeSpaceGB} GB" -ForegroundColor Yellow

if ($freeSpaceGB -lt 150) {
    Write-Host "⚠ 警告: 可用磁盘空间少于 150GB，构建可能失败" -ForegroundColor Yellow
    $response = Read-Host "是否继续? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        exit 0
    }
} else {
    Write-Host "✓ 磁盘空间充足" -ForegroundColor Green
}

# 构建镜像
if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "[3/6] 开始构建 Docker 镜像..." -ForegroundColor Green
    Write-Host "这可能需要 1.5-5 小时，请耐心等待..." -ForegroundColor Yellow
    Write-Host "构建命令: docker build --platform linux/amd64 -t $ImageTag ." -ForegroundColor Cyan
    Write-Host ""
    
    $buildStartTime = Get-Date
    docker build --platform linux/amd64 -t $ImageTag .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 构建失败" -ForegroundColor Red
        exit 1
    }
    
    $buildEndTime = Get-Date
    $buildDuration = $buildEndTime - $buildStartTime
    Write-Host ""
    Write-Host "✓ 构建完成！耗时: $($buildDuration.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    
    # 同时标记为 latest
    if ($Version -ne "latest") {
        Write-Host ""
        Write-Host "[3.5/6] 标记为 latest..." -ForegroundColor Green
        docker tag $ImageTag $LatestTag
        Write-Host "✓ 已标记为 latest" -ForegroundColor Green
    }
    
    # 显示镜像信息
    Write-Host ""
    Write-Host "镜像信息:" -ForegroundColor Cyan
    docker images $FullImageName --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
} else {
    Write-Host ""
    Write-Host "[3/6] 跳过构建步骤" -ForegroundColor Yellow
}

# 登录 Docker Hub
if (-not $SkipPush) {
    Write-Host ""
    Write-Host "[4/6] 登录 Docker Hub..." -ForegroundColor Green
    docker login
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 登录失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ 登录成功" -ForegroundColor Green
}

# 推送镜像
if (-not $SkipPush) {
    Write-Host ""
    Write-Host "[5/6] 推送镜像到 Docker Hub..." -ForegroundColor Green
    Write-Host "这可能需要 30 分钟 - 2 小时，取决于网络速度..." -ForegroundColor Yellow
    Write-Host "推送命令: docker push $ImageTag" -ForegroundColor Cyan
    Write-Host ""
    
    $pushStartTime = Get-Date
    
    # 推送版本标签
    Write-Host "推送 $ImageTag..." -ForegroundColor Yellow
    docker push $ImageTag
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 推送失败" -ForegroundColor Red
        Write-Host "提示: Docker 支持断点续传，可以重新运行此脚本继续推送" -ForegroundColor Yellow
        exit 1
    }
    
    # 如果版本不是 latest，也推送 latest
    if ($Version -ne "latest") {
        Write-Host ""
        Write-Host "推送 $LatestTag..." -ForegroundColor Yellow
        docker push $LatestTag
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠ latest 标签推送失败，但版本标签已成功推送" -ForegroundColor Yellow
        }
    }
    
    $pushEndTime = Get-Date
    $pushDuration = $pushEndTime - $pushStartTime
    Write-Host ""
    Write-Host "✓ 推送完成！耗时: $($pushDuration.ToString('hh\:mm\:ss'))" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[5/6] 跳过推送步骤" -ForegroundColor Yellow
}

# 完成
Write-Host ""
Write-Host "[6/6] 完成！" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "镜像已成功推送 to Docker Hub:" -ForegroundColor Green
Write-Host "  - $ImageTag" -ForegroundColor Cyan
if ($Version -ne "latest") {
    Write-Host "  - $LatestTag" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "查看镜像: https://hub.docker.com/r/${FullImageName}" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

