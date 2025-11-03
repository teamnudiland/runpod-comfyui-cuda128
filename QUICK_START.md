# 快速开始指南

## 📋 目录

1. [本地测试 Docker 镜像](#本地测试)
2. [发布到 Docker Hub](#发布到-docker-hub)

---

## 🧪 本地测试

### 前置条件

- ✅ Docker Desktop 已安装并运行
- ✅ NVIDIA GPU 和驱动程序（Windows 需要 WSL2）
- ✅ 至少 150 GB 磁盘空间

### 步骤 1: 构建本地镜像

```powershell
# 在项目根目录执行
cd "E:\Program Files\runpod-comfyui-cuda128"

# 构建镜像（首次构建需要 1.5-5 小时）
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
```

> ⏱️ **预计时间**: 
> - 拉取基础镜像: 5-15 分钟
> - 安装节点: 10-30 分钟  
> - 下载模型: 1-4 小时 ⚠️ **最耗时**
> - **总计**: 1.5-5 小时

### 步骤 2: 创建数据目录

```powershell
New-Item -ItemType Directory -Force -Path ".\data\comfyui\output"
New-Item -ItemType Directory -Force -Path ".\data\runpod-volume"
```

### 步骤 3: 启动本地服务

```powershell
docker-compose up
```

这将启动：
- **ComfyUI**: http://localhost:8188
- **Worker API**: http://localhost:8000

### 步骤 4: 测试 API

#### 方法 1: 使用 Swagger UI（最简单）

1. 打开浏览器访问：**http://localhost:8000/docs**
2. 点击 `/runsync` 端点
3. 点击 "Try it out"
4. 粘贴 `test_input copy 4.json` 的内容
5. 点击 "Execute"

#### 方法 2: 使用 Python 脚本

```powershell
# 安装依赖（如果还没有）
pip install requests

# 运行测试脚本
python test_local.py
```

#### 方法 3: 使用 PowerShell

```powershell
$jsonContent = Get-Content "test_input copy 4.json" -Raw -Encoding UTF8
$response = Invoke-RestMethod -Uri "http://localhost:8000/runsync" -Method Post -Body $jsonContent -ContentType "application/json"
$response | ConvertTo-Json -Depth 10
```

### 步骤 5: 验证功能

✅ **测试 URL 图片输入**：
- 确认图片从 URL 下载并转换为 base64

✅ **测试工作流执行**：
- 确认图片生成成功

✅ **检查输出**：
- 响应应包含 `output.images` 数组
- 每张图片有 `filename`, `type`, `data` 字段

### 步骤 6: 停止服务

```powershell
# 按 Ctrl+C 停止
# 或在新终端执行
docker-compose down
```

---

## 🐳 发布到 Docker Hub

### 前置条件

- ✅ Docker Hub 账户（https://hub.docker.com）
- ✅ 已构建的镜像
- ✅ 足够的上传时间（30 分钟 - 2 小时）

### 步骤 1: 登录 Docker Hub

```powershell
docker login
```

输入：
- **Username**: 您的 Docker Hub 用户名
- **Password**: 密码或访问令牌

> 💡 **推荐使用访问令牌**（更安全）:
> 1. 访问 https://hub.docker.com/settings/security
> 2. 创建新的访问令牌
> 3. 使用令牌作为密码

### 步骤 2: 构建生产镜像

```powershell
# 替换 your-username 为您的 Docker Hub 用户名
# 替换 v1.0.0 为版本号
docker build --platform linux/amd64 -t your-username/runpod-comfyui-cuda128:v1.0.0 .

# 同时标记为 latest
docker tag your-username/runpod-comfyui-cuda128:v1.0.0 your-username/runpod-comfyui-cuda128:latest
```

### 步骤 3: 验证镜像

```powershell
# 查看镜像
docker images | Select-String "runpod-comfyui-cuda128"

# 预期大小: 约 70-90 GB
```

### 步骤 4: 推送到 Docker Hub

```powershell
# 推送版本标签
docker push your-username/runpod-comfyui-cuda128:v1.0.0

# 推送 latest 标签
docker push your-username/runpod-comfyui-cuda128:latest
```

> ⏱️ **预计推送时间**: 30 分钟 - 2 小时
> 
> ⚠️ **注意**: 
> - 确保网络连接稳定
> - 如果中断，可以重新运行 push 命令继续

### 步骤 5: 验证推送成功

访问您的 Docker Hub 仓库：
```
https://hub.docker.com/r/your-username/runpod-comfyui-cuda128
```

### 步骤 6: 在 RunPod 中使用

1. **登录 RunPod 控制台**: https://www.runpod.io/console
2. **创建 Serverless Endpoint**
3. **配置镜像**: `your-username/runpod-comfyui-cuda128:latest`
4. **设置容器磁盘**: 80 GB
5. **选择 GPU**: RTX 4090 或更高
6. **部署并测试**

---

## 📝 完整命令清单

### 本地测试流程

```powershell
# 1. 构建镜像
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .

# 2. 创建目录
New-Item -ItemType Directory -Force -Path ".\data\comfyui\output"
New-Item -ItemType Directory -Force -Path ".\data\runpod-volume"

# 3. 启动服务
docker-compose up

# 4. 在另一个终端测试
python test_local.py
# 或访问 http://localhost:8000/docs

# 5. 停止服务
docker-compose down
```

### 发布到 Docker Hub 流程

```powershell
# 1. 登录
docker login

# 2. 构建并标记
docker build --platform linux/amd64 -t your-username/runpod-comfyui-cuda128:v1.0.0 .
docker tag your-username/runpod-comfyui-cuda128:v1.0.0 your-username/runpod-comfyui-cuda128:latest

# 3. 推送
docker push your-username/runpod-comfyui-cuda128:v1.0.0
docker push your-username/runpod-comfyui-cuda128:latest
```

---

## ❓ 常见问题

### Q: 构建失败怎么办？

**A**: Docker 会缓存已完成的步骤，重新运行构建命令会从失败的地方继续：

```powershell
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
```

### Q: 磁盘空间不足？

**A**: 

1. **清理 Docker**:
   ```powershell
   docker system prune -a
   ```

2. **扩展 Docker Desktop 磁盘**:
   - Docker Desktop → Settings → Resources → Advanced
   - 增加 Disk image size（建议 200GB+）

### Q: 推送镜像超时？

**A**: 
- 使用更稳定的网络
- 重新运行 push 命令（支持断点续传）
- 考虑在非高峰时段推送

### Q: 本地测试时如何只测试特定功能？

**A**: 
- 修改 `test_input copy 4.json` 中的工作流
- 或创建简化的测试文件
- 参考 `.runpod/tests.json` 中的测试配置

---

## 🔗 相关文档

- [详细构建指南](docs/build-docker-image.md)
- [本地开发指南](docs/development.md)
- [发布到 RunPod Hub](docs/publish-to-hub.md)
- [部署指南](docs/deployment.md)

---

## ✅ 检查清单

### 本地测试前
- [ ] Docker Desktop 正在运行
- [ ] 至少有 150 GB 可用空间
- [ ] GPU 和驱动程序已安装（如果使用 GPU）

### 发布前
- [ ] 本地测试通过
- [ ] 镜像构建成功
- [ ] Docker Hub 账户已登录
- [ ] 镜像标签正确（包含用户名）
- [ ] 有足够的推送时间

### 推送后
- [ ] 在 Docker Hub 上验证镜像存在
- [ ] 检查镜像大小和标签
- [ ] 准备在 RunPod 上测试

