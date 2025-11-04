# Docker Hub 自动构建配置指南

Docker Hub 的自动构建功能可以直接连接 GitHub 仓库，在代码推送时自动构建 Docker 镜像。相比 GitHub Actions，Docker Hub 的构建环境通常有更大的磁盘空间，更适合构建大型镜像。

## 前置条件

- Docker Hub 账号（如：`robinl9527`）
- GitHub 仓库已公开（或 Docker Hub 已授权访问私有仓库）

## 步骤 1：在 Docker Hub 创建仓库

1. 登录 [Docker Hub](https://hub.docker.com/)
2. 点击右上角的 **"Create Repository"** 按钮
3. 填写仓库信息：
   - **Repository Name**: `comfyui-cuda128`
   - **Visibility**: 选择 `Public` 或 `Private`（根据你的需求）
   - **Description**（可选）: 描述你的镜像
4. **不要**勾选 "Build from source code"（我们将在下一步手动配置）
5. 点击 **"Create"** 创建仓库

## 步骤 2：连接 GitHub 仓库

1. 在 Docker Hub 中，进入你的仓库页面：`https://hub.docker.com/r/robinl9527/comfyui-cuda128`
2. 点击 **"Builds"** 标签页
3. 点击 **"Link GitHub Account"** 或 **"Configure Automated Builds"**
4. 如果还没有连接 GitHub：
   - 点击 **"Authorize and Select"** 或 **"Connect GitHub"**
   - 授权 Docker Hub 访问你的 GitHub 账号
   - 选择要连接的 GitHub 组织或账号（如：`ultimatech-cn`）
5. 选择要连接的仓库：`ultimatech-cn/runpod-comfyui-cuda128`

## 步骤 3：配置构建规则

在 Docker Hub 的构建配置页面，你需要设置以下构建规则：

### 规则 1：主分支构建（latest 标签）

1. 点击 **"Create Automated Build"** 或 **"Add Build Rule"**
2. 配置：
   - **Source Type**: `Branch`
   - **Source**: `main`（或你的主分支名）
   - **Docker Tag**: `latest`
   - **Dockerfile Location**: `Dockerfile`（默认）
   - **Build Context**: `/`（默认）
3. 点击 **"Create"** 或 **"Save"**

### 规则 2：版本标签构建（可选）

如果你想为 Git tags 创建版本标签：

1. 再次点击 **"Add Build Rule"**
2. 配置：
   - **Source Type**: `Tag`
   - **Source**: `v*`（匹配所有以 `v` 开头的标签，如 `v1.0.0`）
   - **Docker Tag**: `{sourceref}`（使用标签名作为 Docker tag）
   - **Dockerfile Location**: `Dockerfile`
   - **Build Context**: `/`
3. 点击 **"Create"** 或 **"Save"**

### 规则 3：每次提交构建（可选，不推荐）

如果你想要每次提交都构建（会产生很多构建）：

1. 再次点击 **"Add Build Rule"**
2. 配置：
   - **Source Type**: `Branch`
   - **Source**: `main`
   - **Docker Tag**: `{sourceref}`（使用 commit SHA 作为 tag）
   - **Dockerfile Location**: `Dockerfile`
   - **Build Context**: `/`
3. 点击 **"Create"** 或 **"Save"**

## 步骤 4：触发构建

配置完成后，你可以通过以下方式触发构建：

### 方式 1：自动触发（推荐）

- **推送代码到主分支**：当你推送代码到 `main` 分支时，Docker Hub 会自动检测并开始构建
- **创建 Git Tag**：如果你配置了版本标签规则，创建新 tag 时会自动构建

```bash
# 创建并推送版本标签示例
git tag v1.0.0
git push origin v1.0.0
```

### 方式 2：手动触发

1. 在 Docker Hub 仓库的 **"Builds"** 标签页
2. 找到对应的构建规则
3. 点击规则右侧的 **"Trigger"** 按钮
4. 选择要构建的分支或标签
5. 点击 **"Trigger Build"**

## 步骤 5：查看构建状态

1. 在 Docker Hub 仓库的 **"Builds"** 标签页
2. 你可以看到所有构建历史：
   - **绿色**：构建成功
   - **红色**：构建失败
   - **黄色**：构建中
   - **灰色**：已取消或等待中
3. 点击构建记录可以查看详细日志

## 构建优化建议

### 1. 使用 `.dockerignore` 文件

确保 `.dockerignore` 文件已正确配置，排除不必要的文件以加快构建速度：

```dockerignore
.DS_Store
venv
.env
data
models
simulated_uploaded
__pycache__
.specstory/
logs*.txt
*.log
```

### 2. 构建缓存

Docker Hub 会自动缓存构建层，如果 Dockerfile 的层顺序合理，构建会更快。

### 3. 构建时间

- 首次构建可能需要 **1-3 小时**（取决于镜像大小和网络速度）
- 后续构建如果只是小改动，通常需要 **30 分钟到 1 小时**

## 常见问题

### Q: 构建失败怎么办？

A: 查看构建日志：
1. 在 Docker Hub 的构建页面点击失败的构建记录
2. 查看详细日志，找出失败原因
3. 修复问题后重新推送代码或手动触发构建

### Q: 如何清理旧的构建？

A: Docker Hub 会自动清理旧的构建记录，但镜像会保留在仓库中。你可以在仓库的 **"Tags"** 标签页手动删除不需要的标签。

### Q: 构建速度慢怎么办？

A: 
- 检查 `.dockerignore` 是否排除了不必要的文件
- 优化 Dockerfile 的层顺序，将变化少的层放在前面
- 考虑使用多阶段构建（如果适用）

### Q: 如何设置构建触发器？

A: 在构建规则中，你可以设置：
- **Autobuild**: 自动构建（推送代码时自动触发）
- **Active**: 构建规则是否启用

### Q: 私有仓库如何配置？

A: 
1. 确保 Docker Hub 已授权访问你的 GitHub 私有仓库
2. 在连接仓库时选择私有仓库
3. Docker Hub 的自动构建支持私有仓库

## 验证构建成功

构建成功后，你可以通过以下方式验证：

```bash
# 拉取镜像
docker pull robinl9527/comfyui-cuda128:latest

# 查看镜像信息
docker images robinl9527/comfyui-cuda128:latest
```

## 下一步

配置完成后，你可以：
1. 在 RunPod 中使用 Docker Hub 镜像：`robinl9527/comfyui-cuda128:latest`
2. 更新 `.runpod/hub.json` 中的镜像配置（如果需要）
3. 删除或禁用 GitHub Actions 工作流（如果不再需要）

---

**注意**：Docker Hub 的免费账号有构建时间限制（每月 200 分钟），如果你的镜像很大，可能需要考虑升级到付费计划。

