# start from a clean base image (replace <version> with the desired [release](https://github.com/runpod-workers/worker-comfyui/releases))
FROM runpod/worker-comfyui:5.5.0-base-cuda12.8.1

# install custom nodes using comfy-cli
RUN comfy-node-install pulid_comfyui comfyui-reactor rgthree-comfy comfyui-manager was-node-suite-comfyui ComfyUI-Crystools comfyui-kjnodes comfyui-videohelpersuite

# download all models using comfy-cli (merged into single RUN for better layer caching)

# RUN comfy model download --url https://huggingface.co/Phr00t/WAN2.2-14B-Rapid-AllInOne/resolve/main/v10/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors --relative-path models/checkpoints/Wan2.2 --filename wan2.2-i2v-rapid-aio-v10-nsfw.safetensors

RUN comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/ultraRealisticByStable_v20FP16.safetensors --relative-path models/checkpoints/SDXL --filename ultraRealisticByStable_v20FP16.safetensors

RUN comfy model download --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors --relative-path models/clip_vision/wan --filename clip_vision_h.safetensors && \
    comfy model download --url https://huggingface.co/huchenlei/ipadapter_pulid/resolve/main/ip-adapter_pulid_sdxl_fp16.safetensors --relative-path models/pulid --filename ip-adapter_pulid_sdxl_fp16.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx --relative-path models/insightface --filename inswapper_128.onnx && \
    comfy model download --url https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/reswapper_128.onnx --relative-path models/reswapper --filename reswapper_128.onnx && \
    comfy model download --url https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1a_256.onnx --relative-path models/hyperswap --filename hyperswap_1a_256.onnx && \
    comfy model download --url https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1b_256.onnx --relative-path models/hyperswap --filename hyperswap_1b_256.onnx && \
    comfy model download --url https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1c_256.onnx --relative-path models/hyperswap --filename hyperswap_1c_256.onnx && \
    comfy model download --url https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GFPGANv1.4.pth --relative-path models/facerestore_models --filename GFPGANv1.4.pth && \
    comfy model download --url https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GPEN-BFR-512.onnx --relative-path models/facerestore_models --filename GPEN-BFR-512.onnx && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/subtle-analsex-xl3.safetensors --relative-path models/loras/SDXL --filename subtle-analsex-xl3.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/LCMV2-PONYplus-PAseer.safetensors --relative-path models/loras/SDXL --filename LCMV2-PONYplus-PAseer.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/DR34MJOB_I2V_14b_HighNoise.safetensors --relative-path models/loras/Wan2.2 --filename DR34MJOB_I2V_14b_HighNoise.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/DR34MJOB_I2V_14b_LowNoise.safetensors --relative-path models/loras/Wan2.2 --filename DR34MJOB_I2V_14b_LowNoise.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/W22_NSFW_Posing_Nude_i2v_HN_v1.safetensors --relative-path models/loras/Wan2.2 --filename W22_NSFW_Posing_Nude_i2v_HN_v1.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/W22_NSFW_Posing_Nude_i2v_LN_v1.safetensors --relative-path models/loras/Wan2.2 --filename W22_NSFW_Posing_Nude_i2v_LN_v1.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/huge-titfuck-high.safetensors --relative-path models/loras/Wan2.2 --filename huge-titfuck-high.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/huge-titfuck-low.safetensors --relative-path models/loras/Wan2.2 --filename huge-titfuck-low.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/mql_massage_tits_wan22_i2v_v1_high_noise.safetensors --relative-path models/loras/Wan2.2 --filename mql_massage_tits_wan22_i2v_v1_high_noise.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/mql_massage_tits_wan22_i2v_v1_low_noise.safetensors --relative-path models/loras/Wan2.2 --filename mql_massage_tits_wan22_i2v_v1_low_noise.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/nsfw_wan_14b_spooning_leg_lifted_sex_position.safetensors --relative-path models/loras/Wan2.2 --filename nsfw_wan_14b_spooning_leg_lifted_sex_position.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/pworship_high_noise.safetensors --relative-path models/loras/Wan2.2 --filename pworship_high_noise.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/pworship_low_noise.safetensors --relative-path models/loras/Wan2.2 --filename pworship_low_noise.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/spanking_for_wan_v1_e128.safetensors --relative-path models/loras/Wan2.2 --filename spanking_for_wan_v1_e128.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/sockjob_wan_v1.safetensors --relative-path models/loras/Wan2.2 --filename sockjob_wan_v1.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan-thiccum-v3.safetensors --relative-path models/loras/Wan2.2 --filename wan-thiccum-v3.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan2.2-i2v-high-oral-insertion-v1.0.safetensors --relative-path models/loras/Wan2.2 --filename wan2.2-i2v-high-oral-insertion-v1.0.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan2.2-i2v-low-oral-insertion-v1.0.safetensors --relative-path models/loras/Wan2.2 --filename wan2.2-i2v-low-oral-insertion-v1.0.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan22-jellyhips-i2v-13epoc-high-k3nk.safetensors --relative-path models/loras/Wan2.2 --filename wan22-jellyhips-i2v-13epoc-high-k3nk.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan22-jellyhips-i2v-23epoc-low-k3nk.safetensors --relative-path models/loras/Wan2.2 --filename wan22-jellyhips-i2v-23epoc-low-k3nk.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/wan_shoejob_footjob_14B_v10_e15.safetensors --relative-path models/loras/Wan2.2 --filename wan_shoejob_footjob_14B_v10_e15.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/zurimix-high-i2v.safetensors --relative-path models/loras/Wan2.2 --filename zurimix-high-i2v.safetensors && \
    comfy model download --url https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/zurimix-low-i2v.safetensors --relative-path models/loras/Wan2.2 --filename zurimix-low-i2v.safetensors


