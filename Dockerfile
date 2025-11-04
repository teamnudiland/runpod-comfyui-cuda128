# start from a clean base image (replace <version> with the desired [release](https://github.com/runpod-workers/worker-comfyui/releases))
FROM runpod/worker-comfyui:5.5.0-base-cuda12.8.1

# Set environment variables for better maintainability
ENV COMFYUI_PATH=/comfyui
ENV DEBIAN_FRONTEND=noninteractive

# Copy custom handler.py to override the base image's handler
# This allows you to use your enhanced handler with URL image support and path normalization
COPY handler.py /handler.py

# Ensure required tools are installed (wget, git, unzip should already be in base image, but verify)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        unzip \
        ffmpeg \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create all necessary model directories upfront
RUN mkdir -p \
    $COMFYUI_PATH/models/checkpoints/SDXL \
    $COMFYUI_PATH/models/checkpoints/Wan2.2 \
    $COMFYUI_PATH/models/clip_vision/wan \
    $COMFYUI_PATH/models/pulid \
    $COMFYUI_PATH/models/insightface \
    $COMFYUI_PATH/models/reswapper \
    $COMFYUI_PATH/models/hyperswap \
    $COMFYUI_PATH/models/facerestore_models \
    $COMFYUI_PATH/models/upscale_models \
    $COMFYUI_PATH/models/loras/SDXL \
    $COMFYUI_PATH/models/loras/Wan2.2 \
    $COMFYUI_PATH/models/insightface/models/antelopev2

# Install all custom nodes in a single RUN block (optimizes Docker layers)
# Each node installs its requirements.txt if it exists
# Note: Using python3 instead of /venv/bin/python as the base image may not have /venv
RUN cd $COMFYUI_PATH/custom_nodes && \
    # Install ComfyUI-ReActor (ReActor Face Swap)
    git clone https://github.com/Gourieff/ComfyUI-ReActor.git ComfyUI-ReActor && \
    (cd ComfyUI-ReActor && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install rgthree-comfy
    git clone https://github.com/rgthree/rgthree-comfy.git rgthree-comfy && \
    (cd rgthree-comfy && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Manager
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git ComfyUI-Manager && \
    (cd ComfyUI-Manager && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install was-node-suite-comfyui
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git was-node-suite-comfyui && \
    (cd was-node-suite-comfyui && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Crystools
    git clone https://github.com/cubiq/ComfyUI-Crystools.git ComfyUI-Crystools && \
    (cd ComfyUI-Crystools && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-KJNodes
    git clone https://github.com/kijai/ComfyUI-KJNodes.git comfyui-kjnodes && \
    (cd comfyui-kjnodes && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-VideoHelperSuite
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    (cd comfyui-videohelpersuite && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install PuLID_ComfyUI
    git clone https://github.com/cubiq/PuLID_ComfyUI.git PuLID_ComfyUI && \
    (cd PuLID_ComfyUI && \
     ([ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
     python3 -m pip install --no-cache-dir facexlib || true) && \
    \
    cd $COMFYUI_PATH

# Download InsightFace AntelopeV2 models (buffalo_l.zip) - special handling with unzip
RUN wget -q -O /tmp/buffalo_l.zip "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/buffalo_l.zip" && \
    unzip -q /tmp/buffalo_l.zip -d $COMFYUI_PATH/models/insightface/models/ && \
    rm /tmp/buffalo_l.zip

# Download all models in optimized batches (grouped by type to optimize layer caching)
# Checkpoint models
RUN wget -q --show-progress -O $COMFYUI_PATH/models/checkpoints/SDXL/ultraRealisticByStable_v20FP16.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/ultraRealisticByStable_v20FP16.safetensors"

# WAN2.2 Checkpoint model (commented out - uncomment if needed)
# RUN wget -q --show-progress -O $COMFYUI_PATH/models/checkpoints/Wan2.2/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors \
#     "https://huggingface.co/Phr00t/WAN2.2-14B-Rapid-AllInOne/resolve/main/v10/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors"

# Clip vision models
RUN wget -q --show-progress -O $COMFYUI_PATH/models/clip_vision/wan/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# PuLID models
RUN wget -q --show-progress -O $COMFYUI_PATH/models/pulid/ip-adapter_pulid_sdxl_fp16.safetensors \
    "https://huggingface.co/huchenlei/ipadapter_pulid/resolve/main/ip-adapter_pulid_sdxl_fp16.safetensors"

# InsightFace models
RUN wget -q --show-progress -O $COMFYUI_PATH/models/insightface/inswapper_128.onnx \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx"

# Reswapper models
RUN wget -q --show-progress -O $COMFYUI_PATH/models/reswapper/reswapper_128.onnx \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/reswapper_128.onnx"

# Hyperswap models (batch download)
RUN wget -q --show-progress -O $COMFYUI_PATH/models/hyperswap/hyperswap_1a_256.onnx \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1a_256.onnx" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/hyperswap/hyperswap_1b_256.onnx \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1b_256.onnx" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/hyperswap/hyperswap_1c_256.onnx \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1c_256.onnx"

# Upscale models
RUN wget -q --show-progress -O $COMFYUI_PATH/models/upscale_models/RealESRGAN_x2.pth \
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x2.pth"

# Face restore models (batch download)
RUN wget -q --show-progress -O $COMFYUI_PATH/models/facerestore_models/GFPGANv1.4.pth \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GFPGANv1.4.pth" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/facerestore_models/GPEN-BFR-512.onnx \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GPEN-BFR-512.onnx"

# SDXL LoRA models (batch download)
RUN wget -q --show-progress -O $COMFYUI_PATH/models/loras/SDXL/subtle-analsex-xl3.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/subtle-analsex-xl3.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/SDXL/LCMV2-PONYplus-PAseer.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/LCMV2-PONYplus-PAseer.safetensors"

# Wan2.2 LoRA models (batch download - all in one RUN for better caching)
RUN wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/DR34MJOB_I2V_14b_HighNoise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/DR34MJOB_I2V_14b_HighNoise.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/DR34MJOB_I2V_14b_LowNoise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/DR34MJOB_I2V_14b_LowNoise.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/W22_NSFW_Posing_Nude_i2v_HN_v1.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/W22_NSFW_Posing_Nude_i2v_HN_v1.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/W22_NSFW_Posing_Nude_i2v_LN_v1.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/W22_NSFW_Posing_Nude_i2v_LN_v1.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/huge-titfuck-high.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/huge-titfuck-high.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/huge-titfuck-low.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/huge-titfuck-low.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/mql_massage_tits_wan22_i2v_v1_high_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/mql_massage_tits_wan22_i2v_v1_high_noise.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/mql_massage_tits_wan22_i2v_v1_low_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/mql_massage_tits_wan22_i2v_v1_low_noise.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/nsfw_wan_14b_spooning_leg_lifted_sex_position.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/nsfw_wan_14b_spooning_leg_lifted_sex_position.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/pworship_high_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/pworship_high_noise.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/pworship_low_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/pworship_low_noise.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/spanking_for_wan_v1_e128.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/spanking_for_wan_v1_e128.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/sockjob_wan_v1.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/sockjob_wan_v1.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/wan-thiccum-v3.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan-thiccum-v3.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/wan2.2-i2v-high-oral-insertion-v1.0.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan2.2-i2v-high-oral-insertion-v1.0.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/wan2.2-i2v-low-oral-insertion-v1.0.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan2.2-i2v-low-oral-insertion-v1.0.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/wan22-jellyhips-i2v-13epoc-high-k3nk.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan22-jellyhips-i2v-13epoc-high-k3nk.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/wan22-jellyhips-i2v-23epoc-low-k3nk.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan22-jellyhips-i2v-23epoc-low-k3nk.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/wan_shoejob_footjob_14B_v10_e15.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan_shoejob_footjob_14B_v10_e15.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/zurimix-high-i2v.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/zurimix-high-i2v.safetensors" && \
    wget -q --show-progress -O $COMFYUI_PATH/models/loras/Wan2.2/zurimix-low-i2v.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/zurimix-low-i2v.safetensors"
