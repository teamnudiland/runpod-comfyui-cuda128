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
# worker-comfyui

> [ComfyUI](https://github.com/comfyanonymous/ComfyUI) as a serverless API on [RunPod](https://www.runpod.io/)

<p align="center">
  <img src="assets/worker_sitting_in_comfy_chair.jpg" title="Worker sitting in comfy chair" />
</p>

[![Runpod](https://api.runpod.io/badge/ultimatech-cn/runpod-comfyui-cuda128)](https://console.runpod.io/hub/ultimatech-cn/runpod-comfyui-cuda128)

---

This project allows you to run ComfyUI workflows as a serverless API endpoint on the RunPod platform. Submit workflows via API calls and receive generated images as base64 strings or S3 URLs.

## Table of Contents

- [Quickstart](#quickstart)
- [Available Docker Images](#available-docker-images)
- [API Specification](#api-specification)
- [Usage](#usage)
- [Getting the Workflow JSON](#getting-the-workflow-json)
- [Further Documentation](#further-documentation)

---

## Quickstart

1.  🐳 Choose one of the [available Docker images](#available-docker-images) for your serverless endpoint (e.g., `runpod/worker-comfyui:<version>-sd3`).
2.  📄 Follow the [Deployment Guide](docs/deployment.md) to set up your RunPod template and endpoint.
3.  ⚙️ Optionally configure the worker (e.g., for S3 upload) using environment variables - see the full [Configuration Guide](docs/configuration.md).
4.  🧪 Pick an example workflow from [`test_resources/workflows/`](./test_resources/workflows/) or [get your own](#getting-the-workflow-json).
5.  🚀 Follow the [Usage](#usage) steps below to interact with your deployed endpoint.

## Available Docker Images

These images are available on Docker Hub under `runpod/worker-comfyui`:

- **`runpod/worker-comfyui:<version>-base`**: Clean ComfyUI install with no models.
- **`runpod/worker-comfyui:<version>-flux1-schnell`**: Includes checkpoint, text encoders, and VAE for [FLUX.1 schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell).
- **`runpod/worker-comfyui:<version>-flux1-dev`**: Includes checkpoint, text encoders, and VAE for [FLUX.1 dev](https://huggingface.co/black-forest-labs/FLUX.1-dev).
- **`runpod/worker-comfyui:<version>-sdxl`**: Includes checkpoint and VAEs for [Stable Diffusion XL](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0).
- **`runpod/worker-comfyui:<version>-sd3`**: Includes checkpoint for [Stable Diffusion 3 medium](https://huggingface.co/stabilityai/stable-diffusion-3-medium).

Replace `<version>` with the current release tag, check the [releases page](https://github.com/runpod-workers/worker-comfyui/releases) for the latest version.

## API Specification

The worker exposes standard RunPod serverless endpoints (`/run`, `/runsync`, `/health`). By default, images are returned as base64 strings. You can configure the worker to upload images to an S3 bucket instead by setting specific environment variables (see [Configuration Guide](docs/configuration.md)).

Use the `/runsync` endpoint for synchronous requests that wait for the job to complete and return the result directly. Use the `/run` endpoint for asynchronous requests that return immediately with a job ID; you'll need to poll the `/status` endpoint separately to get the result.

### Input

```json
{
  "input": {
    "workflow": {
      "6": {
        "inputs": {
          "text": "a ball on the table",
          "clip": ["30", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": {
          "title": "CLIP Text Encode (Positive Prompt)"
        }
      }
    },
    "images": [
      {
        "name": "input_image_1.png",
        "image": "data:image/png;base64,iVBOR..."
      }
    ]
  }
}
```

The following tables describe the fields within the `input` object:

| Field Path                | Type   | Required | Description                                                                                                                                |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `input`                   | Object | Yes      | Top-level object containing request data.                                                                                                  |
| `input.workflow`          | Object | Yes      | The ComfyUI workflow exported in the [required format](#getting-the-workflow-json).                                                        |
| `input.images`            | Array  | No       | Optional array of input images. Each image is uploaded to ComfyUI's `input` directory and can be referenced by its `name` in the workflow. |
| `input.comfy_org_api_key` | String | No       | Optional per-request Comfy.org API key for API Nodes. Overrides the `COMFY_ORG_API_KEY` environment variable if both are set.              |

#### `input.images` Object

Each object within the `input.images` array must contain:

| Field Name | Type   | Required | Description                                                                                                                       |
| ---------- | ------ | -------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `name`     | String | Yes      | Filename used to reference the image in the workflow (e.g., via a "Load Image" node). Must be unique within the array.            |
| `image`    | String | Yes      | Base64 encoded string of the image. A data URI prefix (e.g., `data:image/png;base64,`) is optional and will be handled correctly. |

> [!NOTE]
>
> **Size Limits:** RunPod endpoints have request size limits (e.g., 10MB for `/run`, 20MB for `/runsync`). Large base64 input images can exceed these limits. See [RunPod Docs](https://docs.runpod.io/docs/serverless-endpoint-urls).

### Output

> [!WARNING]
>
> **Breaking Change in Output Format (5.0.0+)**
>
> Versions `< 5.0.0` returned the primary image data (S3 URL or base64 string) directly within an `output.message` field.
> Starting with `5.0.0`, the output format has changed significantly, see below

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

| Field Path      | Type             | Required | Description                                                                                                 |
| --------------- | ---------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `output`        | Object           | Yes      | Top-level object containing the results of the job execution.                                               |
| `output.images` | Array of Objects | No       | Present if the workflow generated images. Contains a list of objects, each representing one output image.   |
| `output.errors` | Array of Strings | No       | Present if non-fatal errors or warnings occurred during processing (e.g., S3 upload failure, missing data). |

#### `output.images`

Each object in the `output.images` array has the following structure:

| Field Name | Type   | Description                                                                                     |
| ---------- | ------ | ----------------------------------------------------------------------------------------------- |
| `filename` | String | The original filename assigned by ComfyUI during generation.                                    |
| `type`     | String | Indicates the format of the data. Either `"base64"` or `"s3_url"` (if S3 upload is configured). |
| `data`     | String | Contains either the base64 encoded image string or the S3 URL for the uploaded image file.      |

> [!NOTE]
> The `output.images` field provides a list of all generated images (excluding temporary ones).
>
> - If S3 upload is **not** configured (default), `type` will be `"base64"` and `data` will contain the base64 encoded image string.
> - If S3 upload **is** configured, `type` will be `"s3_url"` and `data` will contain the S3 URL. See the [Configuration Guide](docs/configuration.md#example-s3-response) for an S3 example response.
> - Clients interacting with the API need to handle this list-based structure under `output.images`.

## Usage

To interact with your deployed RunPod endpoint:

1.  **Get API Key:** Generate a key in RunPod [User Settings](https://www.runpod.io/console/serverless/user/settings) (`API Keys` section).
2.  **Get Endpoint ID:** Find your endpoint ID on the [Serverless Endpoints](https://www.runpod.io/console/serverless/user/endpoints) page or on the `Overview` page of your endpoint.

### Generate Image (Sync Example)

Send a workflow to the `/runsync` endpoint (waits for completion). Replace `<api_key>` and `<endpoint_id>`. The `-d` value should contain the [JSON input described above](#input).

```bash
curl -X POST \
  -H "Authorization: Bearer <api_key>" \
  -H "Content-Type: application/json" \
  -d '{"input":{"workflow":{... your workflow JSON ...}}}' \
  https://api.runpod.ai/v2/<endpoint_id>/runsync
```

You can also use the `/run` endpoint for asynchronous jobs and then poll the `/status` to see when the job is done. Or you [add a `webhook` into your request](https://docs.runpod.io/serverless/endpoints/send-requests#webhook-notifications) to be notified when the job is done.

Refer to [`test_input.json`](./test_input.json) for a complete input example.

## Getting the Workflow JSON

To get the correct `workflow` JSON for the API:

1.  Open ComfyUI in your browser.
2.  In the top navigation, select `Workflow > Export (API)`
3.  A `workflow.json` file will be downloaded. Use the content of this file as the value for the `input.workflow` field in your API requests.

## Further Documentation

- **[Deployment Guide](docs/deployment.md):** Detailed steps for deploying on RunPod.
- **[Configuration Guide](docs/configuration.md):** Full list of environment variables (including S3 setup).
- **[Customization Guide](docs/customization.md):** Adding custom models and nodes (Network Volumes, Docker builds).
- **[Development Guide](docs/development.md):** Setting up a local environment for development & testing
- **[CI/CD Guide](docs/ci-cd.md):** Information about the automated Docker build and publish workflows.
- **[Acknowledgments](docs/acknowledgments.md):** Credits and thanks
