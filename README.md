# worker-comfyui

> 把 [ComfyUI](https://github.com/comfyanonymous/ComfyUI) 封装为可本地测试、可在 RunPod/容器环境部署的服务化 API。

<p align="center">
  <img src="assets/worker_sitting_in_comfy_chair.jpg" title="Worker sitting in comfy chair" />
</p>

[![Runpod](https://api.runpod.io/badge/ultimatech-cn/runpod-comfyui-cuda128)](https://console.runpod.io/hub/ultimatech-cn/runpod-comfyui-cuda128)

---

本项目基于官方 `runpod/worker-comfyui` 打造，内置常用自定义节点与模型，新增以下能力：

- 输入图片支持 HTTP(S) URL 与 Base64（URL 将自动下载并转为 Base64）
- 自动标准化工作流中 Windows 风格路径（`\\` → `/`）
- 提供 Docker 本地一键启动与 Swagger 测试界面
- 提供发布到 Docker Hub 与 RunPod Hub 的文档与脚本

## Table of Contents

- [Quickstart](#quickstart)
- [Local Development & Testing](#local-development--testing)
- [API Specification](#api-specification)
- [Usage](#usage)
- [Getting the Workflow JSON](#getting-the-workflow-json)
- [Publish to Docker Hub](#publish-to-docker-hub)
- [Further Documentation](#further-documentation)

---

## Quickstart

最快开始请参考快速指南：

- [QUICK_START.md](./QUICK_START.md)

核心步骤（Windows 示例）：

1. 构建镜像（首构耗时 1.5-5 小时，主要下载模型）
   ```powershell
   cd "E:\\Program Files\\runpod-comfyui-cuda128"
   docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
   ```
2. 启动本地环境
   ```powershell
   docker-compose up
   ```
   - Worker API: http://localhost:8000 （Swagger: http://localhost:8000/docs）
   - ComfyUI: http://localhost:8188
3. 发送示例请求（使用 `test_input copy 4.json`）
   ```powershell
   python test_local.py
   ```

## Local Development & Testing

详细说明请见 [docs/development.md](docs/development.md) 与 [docs/local-testing-and-publish.md](docs/local-testing-and-publish.md)。

本仓库已内置：

- `docker-compose.yml`（本地一键启动，已映射 8000/8188 端口）
- `test_input copy 4.json`（包含 URL 图片输入与完整工作流）
- `test_local.py`（本地 runsync 测试脚本）

## API Specification

提供标准 RunPod Serverless 风格端点（本地同样可用）：`/run`、`/runsync`、`/health`。

- 默认返回 Base64 图片；若配置了 S3，会返回 S3 URL（见 [Configuration Guide](docs/configuration.md)）。
- `/runsync`：同步等待结果；`/run`：异步返回 jobId，再轮询 `/status`。

### Input

```json
{
  "input": {
    "workflow": { ... 工作流 JSON ... },
    "images": [
      {
        "name": "test_img.jpg",
        "image": "https://example.com/your_image.jpg"
      }
    ]
  }
}
```

The following tables describe the fields within the `input` object:

| Field Path                | Type   | Required | Description                                                                                                                                |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `input`                   | Object | Yes      | Top-level object containing request data.                                                                                                  |
| `input.workflow`          | Object | Yes      | The ComfyUI workflow exported in the required format.                                                                                      |
| `input.images`            | Array  | No       | Optional array of input images. Each image is uploaded to ComfyUI's `input` directory and can be referenced by its `name` in the workflow. |
| `input.comfy_org_api_key` | String | No       | Optional per-request Comfy.org API key for API Nodes. Overrides the `COMFY_ORG_API_KEY` environment variable if both are set.              |

#### `input.images` Object

Each object within the `input.images` array must contain:

| Field Name | Type   | Required | Description                                                                                                                         |
| ---------- | ------ | -------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `name`     | String | Yes      | Filename used to reference the image in the workflow (e.g., via a "Load Image" node). Must be unique within the array.             |
| `image`    | String | Yes      | 支持 Base64（可含 `data:image/...;base64,` 前缀）或 HTTP(S) URL。若为 URL，将在服务端自动下载并转为 Base64 再注入工作流。 |

### Output

```json
{
  "id": "sync-uuid-string",
  "status": "COMPLETED",
  "output": {
    "images": [
      {
        "filename": "ComfyUI_00001_.png",
        "type": "base64",
        "data": "iVBORw0KGgoAAAANSUhEUg..."
      }
    ]
  },
  "delayTime": 123,
  "executionTime": 4567
}
```

> `output.images` 为生成图片列表；如未配置 S3，`type` 为 `base64`，`data` 为 Base64 字符串；配置 S3 后 `type` 为 `s3_url`，`data` 为 URL。

## Usage

与部署后的 RunPod 端点交互方式一致：

1. **同步**：POST 到 `/runsync`，等待返回。
2. **异步**：POST 到 `/run` 获取 `jobId`，轮询 `/status`。

本地直接访问（默认端口）：

- API 文档（Swagger）：http://localhost:8000/docs
- 同步端点：`POST http://localhost:8000/runsync`

## Getting the Workflow JSON

导出工作流 JSON 用于 API：

1. 打开 ComfyUI
2. 顶部导航选择 `Workflow > Export (API)`
3. 将下载的 JSON 作为 `input.workflow` 的值

> 提示：如果你的工作流中包含 Windows 风格路径（如 `SDXL\\xxx.safetensors`），本服务会自动转换为 Unix 风格（`SDXL/xxx.safetensors`）。

## Publish to Docker Hub

发布/推送镜像到 Docker Hub 的完整说明见：

- [docs/local-testing-and-publish.md](docs/local-testing-and-publish.md)

核心命令（示例）：

```powershell
docker build --platform linux/amd64 -t your-username/runpod-comfyui-cuda128:v1.0.0 .
docker tag your-username/runpod-comfyui-cuda128:v1.0.0 your-username/runpod-comfyui-cuda128:latest
docker login
docker push your-username/runpod-comfyui-cuda128:v1.0.0
docker push your-username/runpod-comfyui-cuda128:latest
```

## Further Documentation

- **[QUICK_START.md](QUICK_START.md)** — 快速开始：本地测试与发布
- **[Development Guide](docs/development.md)** — 本地开发与单元测试
- **[Configuration Guide](docs/configuration.md)** — 环境变量与 S3 配置
- **[Customization Guide](docs/customization.md)** — 自定义节点与模型（含网络卷方案）
- **[Deployment Guide](docs/deployment.md)** — 在 RunPod 上部署端点
- **[CI/CD Guide](docs/ci-cd.md)** — 自动化构建与发布
- **[Acknowledgments](docs/acknowledgments.md)** — 致谢

---

如果你只想快速开始本地测试与发布，请直接查看：

- [QUICK_START.md](./QUICK_START.md)
- [docs/local-testing-and-publish.md](docs/local-testing-and-publish.md)
