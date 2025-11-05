# ComfyUI Endpoint 使用指南

## 目录

1. [项目介绍](#项目介绍)
2. [前置要求](#前置要求)
3. [在 RunPod 上部署 Endpoint](#在-runpod-上部署-endpoint)
4. [API 使用说明](#api-使用说明)
5. [请求与响应格式](#请求与响应格式)
6. [完整示例](#完整示例)
7. [常见问题与故障排除](#常见问题与故障排除)
8. [附录](#附录)

---

## 项目介绍

本项目将 [ComfyUI](https://github.com/comfyanonymous/ComfyUI) 封装为可部署在 RunPod 上的 Serverless Endpoint，提供标准化的 REST API 接口。通过本服务，您可以：

- ✅ 使用 ComfyUI 的强大工作流功能生成图像和视频
- ✅ 通过 HTTP API 调用，无需本地部署
- ✅ 支持图片 URL 和 Base64 输入
- ✅ 自动处理视频输出（MP4、WebM 等）
- ✅ 支持 S3 存储或 Base64 返回

### 内置功能

- **模型支持**: SDXL、Wan2.2、PuLID、ReActor 等
- **自定义节点**: 集成常用自定义节点和 LoRA
- **路径标准化**: 自动处理 Windows/Unix 路径差异
- **错误处理**: 完善的错误处理和重连机制

---

## 前置要求

在开始之前，请确保您具备以下条件：

### 必需项

- ✅ **RunPod 账户**: 注册并登录 [RunPod](https://www.runpod.io/)
- ✅ **Docker Hub 镜像**: 已构建并推送的 Docker 镜像（或使用公共镜像）
- ✅ **API 调用工具**: Postman、curl、Python requests 等
- ✅ **ComfyUI 工作流**: 从 ComfyUI 导出的工作流 JSON 文件

### 推荐项

- ✅ **ComfyUI 本地环境**: 用于测试和导出工作流
- ✅ **S3 存储账户**: 用于存储生成的图片/视频（可选）
- ✅ **Python 环境**: 用于编写测试脚本

---

## 在 RunPod 上部署 Endpoint

本节将详细介绍如何在 RunPod 上创建和配置 Serverless Endpoint。

### 步骤 1: 登录 RunPod 控制台

1. 访问 [RunPod 控制台](https://www.runpod.io/console)
2. 使用您的账户登录

**截图位置 1**: 插入 RunPod 控制台首页截图

---

### 步骤 2: 创建 Serverless Template（可选但推荐）

创建 Template 可以方便地重复使用配置。

1. 在左侧导航栏，点击 **"Serverless"** → **"Templates"**
2. 点击 **"New Template"** 按钮

**截图位置 2**: 插入 Templates 页面和 "New Template" 按钮截图

3. 在创建 Template 对话框中，填写以下信息：

   - **Template Name**: `comfyui-cuda128` （或您喜欢的名称）
   - **Template Type**: 选择 **"Serverless"**
   - **Container Image**: 输入您的 Docker 镜像名称
     - 示例: `robinl9527/comfyui-cuda128:latest`
   - **Container Registry Credentials**: 
     - 如果镜像为公开的，选择 **"Default"**
     - 如果镜像为私有的，需要配置 Registry 凭证
   - **Container Disk**: `200` GB（根据您的镜像大小调整）
   - **Environment Variables**（可选）:
     - `COMFY_ORG_API_KEY`: Comfy.org API 密钥（如果使用 API Nodes）
     - `BUCKET_ENDPOINT_URL`: S3 存储端点 URL
     - `BUCKET_ACCESS_KEY_ID`: S3 访问密钥 ID
     - `BUCKET_SECRET_ACCESS_KEY`: S3 密钥
     - 其他高级配置（见 [配置文档](configuration.md)）

**截图位置 3**: 插入 Template 创建对话框的完整截图，标注关键字段

4. 点击 **"Save Template"** 保存

**截图位置 4**: 插入保存成功后的 Templates 列表页面截图

---

### 步骤 3: 创建 Serverless Endpoint

1. 在左侧导航栏，点击 **"Serverless"** → **"Endpoints"**
2. 点击 **"New Endpoint"** 按钮

**截图位置 5**: 插入 Endpoints 页面和 "New Endpoint" 按钮截图

3. 在创建 Endpoint 对话框中，配置以下信息：

   **基本信息**:
   - **Endpoint Name**: `comfyui-endpoint` （或您喜欢的名称）

   **Worker 配置**:
   - **GPU Type**: 选择 **"RTX 4090"** 或 **"A100"**（推荐 24GB+ VRAM）
   - **Active Workers**: `0` （初始可以设为 0，按需自动扩展）
   - **Max Workers**: `3` （根据您的预算和需求设置）
   - **GPUs/Worker**: `1`
   - **Idle Timeout**: `5` 分钟（Worker 空闲多久后关闭）

   **Template 选择**:
   - **Select Template**: 选择步骤 2 中创建的 Template
     - 或直接填写 **Container Image**（如果未创建 Template）

   **高级配置**（可选）:
   - **Flash Boot**: 启用（推荐，加快启动速度）
   - **Network Volume**: 如果使用网络卷存储模型，在此选择

**截图位置 6**: 插入 Endpoint 创建对话框的完整截图，标注关键配置项

4. 点击 **"Deploy"** 按钮创建 Endpoint

**截图位置 7**: 插入部署过程中的进度提示截图

---

### 步骤 4: 获取 Endpoint ID 和 API 地址

部署完成后，您需要获取 Endpoint 的信息：

1. 在 Endpoints 列表中，点击您刚创建的 Endpoint

**截图位置 8**: 插入 Endpoints 列表页面，标注新创建的 Endpoint

2. 在 Endpoint 详情页面，您会看到：
   - **Endpoint ID**: 类似 `abc123def456` 的字符串
   - **API Base URL**: 类似 `https://api.runpod.io/v2/abc123def456`

**截图位置 9**: 插入 Endpoint 详情页面截图，标注 Endpoint ID 和 API Base URL

3. 记录这些信息，后续 API 调用需要使用

---

### 步骤 5: 验证 Endpoint 状态

在开始调用 API 之前，确保 Endpoint 处于可用状态：

1. 在 Endpoint 详情页面，查看 **"Workers"** 状态
2. 首次调用时，Worker 会自动启动（可能需要 1-3 分钟）
3. 等待 Worker 状态变为 **"Running"**

**截图位置 10**: 插入 Worker 状态页面截图，标注 "Running" 状态

---

## API 使用说明

RunPod Serverless API 提供两种调用方式：

### 方式 1: 同步调用（推荐用于测试）

**端点**: `POST /runsync`

- 发送请求后，等待任务完成并直接返回结果
- 适用于快速测试和简单场景
- 超时时间由 RunPod 控制（通常为 5-10 分钟）

### 方式 2: 异步调用（推荐用于生产环境）

**端点**: `POST /run`

- 发送请求后立即返回 `jobId`
- 需要轮询 `/status/{jobId}` 获取结果
- 适用于长时间运行的任务
- 更好的容错性和可扩展性

---

## 请求与响应格式

### 请求格式

#### 完整请求结构

```json
{
  "input": {
    "workflow": {
      "3": {
        "inputs": {
          "seed": 814583843642114,
          "steps": 8,
          "cfg": 1.1,
          "sampler_name": "lcm",
          "scheduler": "exponential",
          "denoise": 1,
          "model": ["4", 0],
          "positive": ["22", 0],
          "negative": ["23", 0],
          "latent_image": ["46", 0]
        },
        "class_type": "KSampler"
      },
      "4": {
        "inputs": {
          "ckpt_name": "SDXL/ultraRealisticByStable_v20FP16.safetensors"
        },
        "class_type": "CheckpointLoaderSimple"
      },
      "8": {
        "inputs": {
          "samples": ["3", 0],
          "vae": ["4", 2]
        },
        "class_type": "VAEDecode"
      },
      "12": {
        "inputs": {
          "image": "test_img.jpg"
        },
        "class_type": "LoadImage"
      },
      "22": {
        "inputs": {
          "text": "a beautiful woman, high quality, detailed",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "23": {
        "inputs": {
          "text": "lowres, low quality, worst quality, artifacts",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "46": {
        "inputs": {
          "dimensions": " 832 x 1216  (portrait)",
          "clip_scale": 1,
          "batch_size": 1
        },
        "class_type": "SDXL Empty Latent Image (rgthree)"
      },
      "112": {
        "inputs": {
          "filename_prefix": "ComfyUI",
          "images": ["8", 0]
        },
        "class_type": "SaveImage"
      }
    },
    "images": [
      {
        "name": "test_img.jpg",
        "image": "https://example.com/your_image.jpg"
      }
    ],
    "comfy_org_api_key": "your-api-key-here"
  }
}
```

#### 请求字段说明

| 字段路径 | 类型 | 必填 | 说明 |
|---------|------|------|------|
| `input` | Object | 是 | 顶层输入对象 |
| `input.workflow` | Object | 是 | ComfyUI 工作流 JSON（从 ComfyUI 导出） |
| `input.images` | Array | 否 | 输入图片数组 |
| `input.comfy_org_api_key` | String | 否 | Comfy.org API 密钥（用于 API Nodes） |

#### `input.images` 数组项说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `name` | String | 是 | 文件名，在工作流中通过 `LoadImage` 节点引用 |
| `image` | String | 是 | 图片数据，支持以下格式：<br>1. HTTP(S) URL: `"https://example.com/image.jpg"`<br>2. Base64: `"data:image/jpeg;base64,/9j/4AAQ..."`<br>3. 纯 Base64: `"/9j/4AAQ..."` |

---

### 响应格式

#### 成功响应（同步调用）

```json
{
  "id": "sync-abc123def456",
  "status": "COMPLETED",
  "output": {
    "images": [
      {
        "filename": "ComfyUI_00001_.png",
        "type": "base64",
        "data": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg..."
      }
    ],
    "errors": []
  },
  "delayTime": 123,
  "executionTime": 4567
}
```

#### 成功响应（异步调用 - 初始）

```json
{
  "id": "async-abc123def456",
  "status": "IN_PROGRESS"
}
```

#### 成功响应（异步调用 - 完成）

```json
{
  "id": "async-abc123def456",
  "status": "COMPLETED",
  "output": {
    "images": [
      {
        "filename": "ComfyUI_00001_.png",
        "type": "s3_url",
        "data": "https://s3.amazonaws.com/bucket/path/to/ComfyUI_00001_.png"
      }
    ],
    "errors": []
  },
  "delayTime": 123,
  "executionTime": 4567
}
```

#### 错误响应

```json
{
  "error": "Failed to upload one or more input images",
  "details": [
    "Failed to download image from URL: https://invalid-url.com/image.jpg"
  ]
}
```

#### 响应字段说明

| 字段路径 | 类型 | 说明 |
|---------|------|------|
| `id` | String | 任务 ID |
| `status` | String | 任务状态：<br>- `IN_PROGRESS`: 进行中<br>- `COMPLETED`: 已完成<br>- `FAILED`: 失败 |
| `output.images` | Array | 生成的图片/视频数组 |
| `output.images[].filename` | String | 文件名 |
| `output.images[].type` | String | 数据类型：<br>- `base64`: Base64 编码<br>- `s3_url`: S3 存储 URL |
| `output.images[].data` | String | 数据内容（Base64 字符串或 S3 URL） |
| `output.errors` | Array | 错误信息数组（如果有） |
| `delayTime` | Number | 延迟时间（毫秒） |
| `executionTime` | Number | 执行时间（毫秒） |

---

## 完整示例

### 示例 1: 使用 Python 调用同步 API

以下是一个完整的 Python 示例，展示如何调用同步 API：

```python
import requests
import json
import base64

# 配置
ENDPOINT_ID = "your-endpoint-id-here"
API_KEY = "your-runpod-api-key-here"
API_URL = f"https://api.runpod.io/v2/{ENDPOINT_ID}/runsync"

# 准备请求数据
request_data = {
    "input": {
        "workflow": {
            # ... 您的工作流 JSON ...
        },
        "images": [
            {
                "name": "input.jpg",
                "image": "https://example.com/input.jpg"
            }
        ]
    }
}

# 发送请求
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {API_KEY}"
}

response = requests.post(
    API_URL,
    json=request_data,
    headers=headers,
    timeout=600  # 10 分钟超时
)

# 处理响应
if response.status_code == 200:
    result = response.json()
    
    if result.get("status") == "COMPLETED":
        images = result.get("output", {}).get("images", [])
        
        for i, img in enumerate(images):
            filename = img.get("filename")
            img_type = img.get("type")
            data = img.get("data")
            
            if img_type == "base64":
                # 提取 Base64 数据（去除 data URI 前缀）
                if "," in data:
                    base64_data = data.split(",")[1]
                else:
                    base64_data = data
                
                # 解码并保存
                image_bytes = base64.b64decode(base64_data)
                with open(f"output_{i}_{filename}", "wb") as f:
                    f.write(image_bytes)
                print(f"✅ 已保存: output_{i}_{filename}")
            
            elif img_type == "s3_url":
                print(f"✅ S3 URL: {data}")
    else:
        print(f"❌ 任务状态: {result.get('status')}")
        print(f"错误: {result.get('error', 'Unknown error')}")
else:
    print(f"❌ 请求失败: {response.status_code}")
    print(f"响应: {response.text}")
```

**截图位置 11**: 插入运行 Python 脚本的终端输出截图

---

### 示例 2: 使用 curl 调用同步 API

使用 curl 命令调用 API 的示例：

```bash
curl -X POST "https://api.runpod.io/v2/YOUR_ENDPOINT_ID/runsync" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "input": {
      "workflow": {
        "3": {
          "inputs": {
            "seed": 814583843642114,
            "steps": 8,
            "cfg": 1.1,
            "sampler_name": "lcm",
            "scheduler": "exponential",
            "denoise": 1,
            "model": ["4", 0],
            "positive": ["22", 0],
            "negative": ["23", 0],
            "latent_image": ["46", 0]
          },
          "class_type": "KSampler"
        }
      },
      "images": [
        {
          "name": "test_img.jpg",
          "image": "https://example.com/image.jpg"
        }
      ]
    }
  }'
```

**截图位置 12**: 插入 curl 命令执行结果截图

---

### 示例 3: 使用 Postman 调用 API

使用 Postman 工具调用 API 的步骤：

1. **创建新请求**:
   - 方法: `POST`
   - URL: `https://api.runpod.io/v2/YOUR_ENDPOINT_ID/runsync`

2. **配置 Headers**:
   - `Content-Type`: `application/json`
   - `Authorization`: `Bearer YOUR_API_KEY`

3. **配置 Body**:
   - 选择 `raw` 和 `JSON`
   - 粘贴您的请求 JSON

4. **发送请求**

**截图位置 13**: 插入 Postman 界面截图，标注各个配置区域

---

### 示例 4: 异步调用（轮询结果）

以下示例展示如何使用异步 API 并轮询结果：

```python
import requests
import time

ENDPOINT_ID = "your-endpoint-id-here"
API_KEY = "your-runpod-api-key-here"
API_BASE = f"https://api.runpod.io/v2/{ENDPOINT_ID}"

# 步骤 1: 提交任务
run_response = requests.post(
    f"{API_BASE}/run",
    json={"input": {...}},  # 您的输入数据
    headers={"Authorization": f"Bearer {API_KEY}"}
)

job_id = run_response.json()["id"]
print(f"✅ 任务已提交: {job_id}")

# 步骤 2: 轮询状态
max_wait_time = 600  # 最大等待 10 分钟
poll_interval = 5    # 每 5 秒轮询一次
elapsed_time = 0

while elapsed_time < max_wait_time:
    status_response = requests.get(
        f"{API_BASE}/status/{job_id}",
        headers={"Authorization": f"Bearer {API_KEY}"}
    )
    
    status_data = status_response.json()
    status = status_data.get("status")
    
    print(f"⏳ 状态: {status} (已等待 {elapsed_time} 秒)")
    
    if status == "COMPLETED":
        print("✅ 任务完成!")
        print(f"结果: {status_data.get('output')}")
        break
    elif status == "FAILED":
        print(f"❌ 任务失败: {status_data.get('error')}")
        break
    
    time.sleep(poll_interval)
    elapsed_time += poll_interval
else:
    print("❌ 超时: 任务未在指定时间内完成")
```

---

### 示例 5: 处理视频输出

以下示例展示如何处理视频格式的输出：

```python
import requests
import base64

# ... 发送请求（同上） ...

result = response.json()
images = result.get("output", {}).get("images", [])

for img in images:
    filename = img.get("filename")
    
    # 检查是否是视频文件
    if filename.lower().endswith(('.mp4', '.webm', '.mov')):
        print(f"📹 检测到视频输出: {filename}")
        
        data = img.get("data")
        if img.get("type") == "base64":
            # 提取 Base64 数据
            if "," in data:
                base64_data = data.split(",")[1]
            else:
                base64_data = data
            
            # 解码并保存视频
            video_bytes = base64.b64decode(base64_data)
            with open(filename, "wb") as f:
                f.write(video_bytes)
            print(f"✅ 视频已保存: {filename}")
```

---

## 常见问题与故障排除

### Q1: 如何从 ComfyUI 导出工作流？

**回答**:

1. 在 ComfyUI 中打开您的工作流
2. 点击顶部菜单 **"Workflow"** → **"Export (API)"**
3. 保存 JSON 文件
4. 将 JSON 内容作为 `input.workflow` 的值

**截图位置 14**: 插入 ComfyUI 导出工作流菜单截图

---

### Q2: Worker 启动失败怎么办？

**可能原因**:
- 镜像拉取失败
- 容器磁盘空间不足
- GPU 资源不足

**解决方法**:
1. 检查 Endpoint 日志（在 RunPod 控制台查看）
2. 确认镜像名称和标签正确
3. 增加 Container Disk 大小
4. 尝试使用不同的 GPU 类型

**截图位置 15**: 插入 Worker 错误日志截图示例

---

### Q3: 图片上传失败怎么办？

**可能原因**:
- URL 无法访问
- Base64 格式错误
- 图片文件过大

**解决方法**:
1. 确认 URL 可公开访问（不使用需要认证的 URL）
2. 检查 Base64 格式是否正确
3. 压缩图片大小（建议 < 10MB）
4. 查看响应中的 `errors` 字段获取详细错误信息

---

### Q4: 如何配置 S3 存储？

**回答**: 在创建 Template 或 Endpoint 时，设置以下环境变量：

- `BUCKET_ENDPOINT_URL`: `https://your-bucket.s3.region.amazonaws.com`
- `BUCKET_ACCESS_KEY_ID`: 您的 AWS Access Key ID
- `BUCKET_SECRET_ACCESS_KEY`: 您的 AWS Secret Access Key

配置后，输出将自动上传到 S3，并返回 S3 URL 而不是 Base64。

**截图位置 16**: 插入 Template 环境变量配置截图

---

### Q5: 如何查看 Worker 日志？

**回答**:

1. 在 Endpoint 详情页面，点击 **"Workers"** 标签
2. 点击 Worker ID
3. 查看 **"Logs"** 标签页

**截图位置 17**: 插入 Worker 日志页面截图

---

### Q6: 任务超时怎么办？

**可能原因**:
- 工作流执行时间过长
- 模型加载时间过长
- 网络问题

**解决方法**:
1. 使用异步调用（`/run`）代替同步调用（`/runsync`）
2. 优化工作流，减少不必要的步骤
3. 使用更快的 GPU（如 A100）
4. 检查网络连接稳定性

---

### Q7: 如何获取 RunPod API Key？

**回答**:

1. 登录 RunPod 控制台
2. 点击右上角头像 → **"Settings"**
3. 在左侧菜单选择 **"API Keys"**
4. 点击 **"Create API Key"**
5. 复制并保存 API Key（只显示一次）

**截图位置 18**: 插入 API Keys 设置页面截图

---

## 附录

### A. 获取 Endpoint ID 的完整 URL

RunPod API 的完整 URL 格式为：

```
https://api.runpod.io/v2/{ENDPOINT_ID}/{ACTION}
```

其中：
- `{ENDPOINT_ID}`: 您的 Endpoint ID（在 Endpoint 详情页面查看）
- `{ACTION}`: 操作类型
  - `runsync`: 同步调用
  - `run`: 异步调用
  - `status/{jobId}`: 查询状态

---

### B. 工作流路径标准化

如果您的 ComfyUI 工作流包含 Windows 风格路径（如 `SDXL\\model.safetensors`），本服务会自动转换为 Unix 风格（`SDXL/model.safetensors`），无需手动修改。

---

### C. 支持的视频格式

输出视频支持以下格式：
- `.mp4` (推荐)
- `.webm`
- `.mov`
- `.avi`
- `.mkv`

---

### D. 常用环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `COMFY_ORG_API_KEY` | Comfy.org API 密钥 | - |
| `BUCKET_ENDPOINT_URL` | S3 存储端点 | - |
| `BUCKET_ACCESS_KEY_ID` | S3 访问密钥 ID | - |
| `BUCKET_SECRET_ACCESS_KEY` | S3 密钥 | - |
| `COMFY_LOG_LEVEL` | ComfyUI 日志级别 | `DEBUG` |
| `WEBSOCKET_RECONNECT_ATTEMPTS` | WebSocket 重连次数 | `5` |
| `WEBSOCKET_RECONNECT_DELAY_S` | WebSocket 重连延迟（秒） | `3` |

---

### E. 相关链接

- [RunPod 官方文档](https://docs.runpod.io/)
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [项目 GitHub 仓库](https://github.com/your-repo/runpod-comfyui-cuda128)
- [Docker Hub 镜像](https://hub.docker.com/r/robinl9527/comfyui-cuda128)

---

### F. 联系与支持

如有问题或建议，请通过以下方式联系：

- GitHub Issues: [提交 Issue](https://github.com/your-repo/runpod-comfyui-cuda128/issues)
- Email: your-email@example.com

---

## 文档版本

- **版本**: 1.0.0
- **最后更新**: 2025-01-XX
- **作者**: Your Name

---

**祝您使用愉快！** 🎉

