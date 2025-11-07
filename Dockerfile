# start from a clean base image (replace <version> with the desired [release](https://github.com/runpod-workers/worker-comfyui/releases))
FROM runpod/worker-comfyui:5.5.0-base-cuda12.8.1

# Set environment variables for better maintainability
ENV COMFYUI_PATH=/comfyui
ENV DEBIAN_FRONTEND=noninteractive

# Copy custom handler.py to override the base image's handler
# This allows you to use your enhanced handler with URL image support and path normalization
COPY handler.py /handler.py

# Ensure required tools are installed (wget, git, unzip should already be in base image, but verify)
# Note: build-essential, g++, and python3-dev are needed to compile insightface (Cython/C++ extensions)
# python3-dev provides Python.h header files needed for compiling Python extensions
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        unzip \
        ffmpeg \
        curl \
        ca-certificates \
        build-essential \
        g++ \
        python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create all necessary model directories upfront
RUN mkdir -p \
    $COMFYUI_PATH/models/checkpoints/SDXL \
    $COMFYUI_PATH/models/checkpoints/Wan2.2 \
    $COMFYUI_PATH/models/clip_vision/wan \
    $COMFYUI_PATH/models/pulid \
    $COMFYUI_PATH/models/insightface/models \
    $COMFYUI_PATH/models/reswapper \
    $COMFYUI_PATH/models/hyperswap \
    $COMFYUI_PATH/models/facerestore_models \
    $COMFYUI_PATH/models/upscale_models \
    $COMFYUI_PATH/models/loras/SDXL \
    $COMFYUI_PATH/models/loras/Wan2.2

# Install all custom nodes in a single RUN block (optimizes Docker layers)
# Each node installs its requirements.txt if it exists
# Note: Using python3 instead of /venv/bin/python as the base image may not have /venv
# Remove existing directories before cloning to avoid "already exists" errors
# Configure git to avoid credential prompts and handle network issues
RUN git config --global --add safe.directory '*' && \
    git config --global credential.helper '' && \
    git config --global url."https://github.com/".insteadOf git@github.com: && \
    git config --global http.sslVerify true && \
    git config --global http.postBuffer 524288000 && \
    cd $COMFYUI_PATH/custom_nodes && \
    # Install ComfyUI-ReActor (ReActor Face Swap)
    rm -rf ComfyUI-ReActor && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git ComfyUI-ReActor && \
    (cd ComfyUI-ReActor && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    # Disable NSFW detection in ReActor by modifying reactor_sfw.py to always return False
    (python3 -c "import re; f=open('$COMFYUI_PATH/custom_nodes/ComfyUI-ReActor/scripts/reactor_sfw.py','r',encoding='utf-8'); c=f.read(); f.close(); c=re.sub(r'def nsfw_image\([^)]+\):.*?(?=\n\ndef |\nclass |\Z)', 'def nsfw_image(img_data, model_path: str):\n    return False', c, flags=re.DOTALL); f=open('$COMFYUI_PATH/custom_nodes/ComfyUI-ReActor/scripts/reactor_sfw.py','w',encoding='utf-8'); f.write(c); f.close()" 2>/dev/null || true) && \
    \
    # Install rgthree-comfy
    rm -rf rgthree-comfy && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git rgthree-comfy && \
    (cd rgthree-comfy && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Manager
    rm -rf ComfyUI-Manager && \
    git clone --depth 1 https://github.com/Comfy-Org/ComfyUI-Manager.git ComfyUI-Manager && \
    (cd ComfyUI-Manager && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install was-node-suite-comfyui
    rm -rf was-node-suite-comfyui && \
    git clone --depth 1 https://github.com/WASasquatch/was-node-suite-comfyui.git was-node-suite-comfyui && \
    (cd was-node-suite-comfyui && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Crystools
    rm -rf ComfyUI-Crystools && \
    (git clone --depth 1 https://github.com/crystian/ComfyUI-Crystools.git ComfyUI-Crystools || \
     (sleep 2 && git clone --depth 1 https://github.com/crystian/ComfyUI-Crystools.git ComfyUI-Crystools)) && \
    (cd ComfyUI-Crystools && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    # Fix SyntaxWarning: invalid escape sequence in ComfyUI-Crystools (fix \/ to / in all Python files)
    (find $COMFYUI_PATH/custom_nodes/ComfyUI-Crystools -name "*.py" -type f -exec sed -i 's|\\/|/|g' {} \; 2>/dev/null || true) && \
    \
    # Install ComfyUI-KJNodes
    rm -rf comfyui-kjnodes && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git comfyui-kjnodes && \
    (cd comfyui-kjnodes && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-VideoHelperSuite
    rm -rf comfyui-videohelpersuite && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    (cd comfyui-videohelpersuite && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install PuLID_ComfyUI
    rm -rf PuLID_ComfyUI && \
    git clone --depth 1 https://github.com/cubiq/PuLID_ComfyUI.git PuLID_ComfyUI && \
    (cd PuLID_ComfyUI && \
     ([ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
     python3 -m pip install --no-cache-dir facexlib || true) && \
    \
    # Install comfyui-mixlab-nodes
    rm -rf comfyui-mixlab-nodes && \
    git clone --depth 1 https://github.com/MixLabPro/comfyui-mixlab-nodes.git comfyui-mixlab-nodes && \
    (cd comfyui-mixlab-nodes && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Frame-Interpolation
    rm -rf ComfyUI-Frame-Interpolation && \
    git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git ComfyUI-Frame-Interpolation && \
    (cd ComfyUI-Frame-Interpolation && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Easy-Use
    rm -rf ComfyUI-Easy-Use && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git ComfyUI-Easy-Use && \
    (cd ComfyUI-Easy-Use && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    cd $COMFYUI_PATH

# Download InsightFace AntelopeV2 models (antelopev2.zip)
# According to PuLID_ComfyUI README: models should be placed in ComfyUI/models/insightface/models/antelopev2
# Using antelopev2.zip directly from Hugging Face instead of buffalo_l.zip to avoid renaming
RUN wget -q -O /tmp/antelopev2.zip "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" && \
    test -f /tmp/antelopev2.zip || (echo "Error: Failed to download antelopev2.zip" && exit 1) && \
    unzip -q /tmp/antelopev2.zip -d $COMFYUI_PATH/models/insightface/models/ && \
    rm /tmp/antelopev2.zip

# Download all models in optimized batches (grouped by type to optimize layer caching)
# Checkpoint models
RUN wget -q  -O $COMFYUI_PATH/models/checkpoints/SDXL/ultraRealisticByStable_v20FP16.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/ultraRealisticByStable_v20FP16.safetensors"

# WAN2.2 Checkpoint model (commented out - uncomment if needed)
 RUN wget -q  -O $COMFYUI_PATH/models/checkpoints/Wan2.2/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors \
     "https://huggingface.co/Phr00t/WAN2.2-14B-Rapid-AllInOne/resolve/main/v10/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors"

# Download all additional models in a single RUN command to reduce image layers
RUN wget -q -O $COMFYUI_PATH/models/clip_vision/wan/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/pulid/ip-adapter_pulid_sdxl_fp16.safetensors \
    "https://huggingface.co/huchenlei/ipadapter_pulid/resolve/main/ip-adapter_pulid_sdxl_fp16.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/insightface/inswapper_128.onnx \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx" && \
    wget -q -O $COMFYUI_PATH/models/reswapper/reswapper_128.onnx \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/reswapper_128.onnx" && \
    wget -q -O $COMFYUI_PATH/models/hyperswap/hyperswap_1a_256.onnx \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1a_256.onnx" && \
    wget -q -O $COMFYUI_PATH/models/hyperswap/hyperswap_1b_256.onnx \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1b_256.onnx" && \
    wget -q -O $COMFYUI_PATH/models/hyperswap/hyperswap_1c_256.onnx \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1c_256.onnx" && \
    wget -q -O $COMFYUI_PATH/models/upscale_models/RealESRGAN_x2.pth \
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x2.pth" && \
    wget -q -O $COMFYUI_PATH/models/facerestore_models/GFPGANv1.4.pth \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GFPGANv1.4.pth" && \
    wget -q -O $COMFYUI_PATH/models/facerestore_models/GPEN-BFR-512.onnx \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GPEN-BFR-512.onnx" && \
    wget -q -O $COMFYUI_PATH/models/loras/SDXL/subtle-analsex-xl3.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/subtle-analsex-xl3.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/SDXL/LCMV2-PONYplus-PAseer.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/LCMV2-PONYplus-PAseer.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/DR34MJOB_I2V_14b_HighNoise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/DR34MJOB_I2V_14b_HighNoise.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/DR34MJOB_I2V_14b_LowNoise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/DR34MJOB_I2V_14b_LowNoise.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/W22_NSFW_Posing_Nude_i2v_HN_v1.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/W22_NSFW_Posing_Nude_i2v_HN_v1.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/W22_NSFW_Posing_Nude_i2v_LN_v1.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/W22_NSFW_Posing_Nude_i2v_LN_v1.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/huge-titfuck-high.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/huge-titfuck-high.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/huge-titfuck-low.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/huge-titfuck-low.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/mql_massage_tits_wan22_i2v_v1_high_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/mql_massage_tits_wan22_i2v_v1_high_noise.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/mql_massage_tits_wan22_i2v_v1_low_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/mql_massage_tits_wan22_i2v_v1_low_noise.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/nsfw_wan_14b_spooning_leg_lifted_sex_position.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/nsfw_wan_14b_spooning_leg_lifted_sex_position.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/pworship_high_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/pworship_high_noise.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/pworship_low_noise.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/pworship_low_noise.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/spanking_for_wan_v1_e128.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/spanking_for_wan_v1_e128.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/sockjob_wan_v1.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/sockjob_wan_v1.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/wan-thiccum-v3.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan-thiccum-v3.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/wan2.2-i2v-high-oral-insertion-v1.0.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan2.2-i2v-high-oral-insertion-v1.0.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/wan2.2-i2v-low-oral-insertion-v1.0.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan2.2-i2v-low-oral-insertion-v1.0.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/wan22-jellyhips-i2v-13epoc-high-k3nk.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan22-jellyhips-i2v-13epoc-high-k3nk.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/wan22-jellyhips-i2v-23epoc-low-k3nk.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan22-jellyhips-i2v-23epoc-low-k3nk.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/wan_shoejob_footjob_14B_v10_e15.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan_shoejob_footjob_14B_v10_e15.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/zurimix-high-i2v.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/zurimix-high-i2v.safetensors" && \
    wget -q -O $COMFYUI_PATH/models/loras/Wan2.2/zurimix-low-i2v.safetensors \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/zurimix-low-i2v.safetensors"

# Pre-download BLIP models to avoid runtime download failures
# BLIP models are used by was-node-suite-comfyui for image captioning and VQA
# According to was-node-suite-comfyui, it uses /comfyui/models/blip as cache_dir
# We download models using transformers library which will place them correctly
RUN mkdir -p $COMFYUI_PATH/models/blip && \
    python3 -c "from transformers import BlipProcessor, BlipForConditionalGeneration, BlipForQuestionAnswering; \
    import os; \
    blip_cache = '/comfyui/models/blip'; \
    os.environ['HF_HUB_CACHE'] = blip_cache; \
    print('Downloading BLIP image captioning model...'); \
    BlipProcessor.from_pretrained('Salesforce/blip-image-captioning-base', cache_dir=blip_cache); \
    BlipForConditionalGeneration.from_pretrained('Salesforce/blip-image-captioning-base', cache_dir=blip_cache); \
    print('Downloading BLIP VQA model...'); \
    BlipProcessor.from_pretrained('Salesforce/blip-vqa-base', cache_dir=blip_cache); \
    BlipForQuestionAnswering.from_pretrained('Salesforce/blip-vqa-base', cache_dir=blip_cache); \
    print('BLIP models downloaded successfully')"

# Clean up build tools and caches to reduce image size
# Remove build tools after all Python packages are installed (they're only needed for compilation)
# Note: We keep all models and custom nodes, only removing unnecessary build dependencies
RUN apt-get update && \
    apt-get remove -y build-essential g++ python3-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Clean Python cache
    find /usr/local/lib/python3* -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true && \
    find /usr/local/lib/python3* -name "*.pyc" -delete 2>/dev/null || true && \
    find /usr/local/lib/python3* -name "*.pyo" -delete 2>/dev/null || true && \
    # Clean pip cache (if any)
    rm -rf /root/.cache/pip/* 2>/dev/null || true && \
    # Clean temporary files
    rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
