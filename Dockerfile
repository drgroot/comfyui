FROM ghcr.io/ai-dock/comfyui:latest-cuda

ENV COMFYUI_DIR=/opt/ComfyUI
ENV COMFYUI_VERSION=v0.14.2
ENV COMFYUI_VENV_PIP=/opt/environments/python/comfyui/bin/pip
ENV COMFYUI_VENV_PYTHON=/opt/environments/python/comfyui/bin/python

RUN set -eux; \
    if ! command -v git >/dev/null 2>&1; then \
      apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*; \
    fi; \
    if [ -d "${COMFYUI_DIR}/.git" ]; then \
      git -C "${COMFYUI_DIR}" fetch --depth 1 origin "refs/tags/${COMFYUI_VERSION}"; \
      git -C "${COMFYUI_DIR}" checkout -q FETCH_HEAD; \
    else \
      rm -rf "${COMFYUI_DIR}"; \
      git clone --depth 1 --branch "${COMFYUI_VERSION}" https://github.com/comfyanonymous/ComfyUI "${COMFYUI_DIR}"; \
    fi; \
    if [ -f "${COMFYUI_DIR}/requirements.txt" ]; then \
      "${COMFYUI_VENV_PIP}" install --no-cache-dir -r "${COMFYUI_DIR}/requirements.txt"; \
    fi; \
    test -d "${COMFYUI_DIR}/custom_nodes"; \
    clone_if_missing() { \
      repo="$1"; \
      dest="$2"; \
      if [ -d "$dest/.git" ] || [ -d "$dest" ]; then \
        echo "Skipping existing custom node: $dest"; \
      else \
        git clone --depth 1 "$repo" "$dest"; \
      fi; \
    }; \
    clone_if_missing https://github.com/ltdrdata/ComfyUI-Impact-Pack "${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Pack"; \
    clone_if_missing https://github.com/ltdrdata/ComfyUI-Impact-Subpack "${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Subpack"; \
    clone_if_missing https://github.com/ltdrdata/ComfyUI-Manager.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager"; \
    clone_if_missing https://github.com/brianfitzgerald/style_aligned_comfy "${COMFYUI_DIR}/custom_nodes/style_aligned_comfy"; \
    clone_if_missing https://github.com/MoonGoblinDev/Civicomfy "${COMFYUI_DIR}/custom_nodes/Civicomfy"; \
    clone_if_missing https://github.com/kijai/ComfyUI-WanVideoWrapper "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper"; \
    clone_if_missing https://github.com/city96/ComfyUI-GGUF "${COMFYUI_DIR}/custom_nodes/ComfyUI-GGUF"; \
    clone_if_missing https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite"; \
    clone_if_missing https://github.com/kijai/ComfyUI-KJNodes "${COMFYUI_DIR}/custom_nodes/ComfyUI-KJNodes"; \
    clone_if_missing https://github.com/Fannovel16/comfyui_controlnet_aux "${COMFYUI_DIR}/custom_nodes/comfyui_controlnet_aux"; \
    "${COMFYUI_VENV_PYTHON}" -c "import os; from pathlib import Path; path = Path(os.environ.get('COMFYUI_DIR', '/opt/ComfyUI')) / 'custom_nodes/ComfyUI-Impact-Pack/modules/impact/core.py'; text = path.read_text(encoding='utf-8') if path.is_file() else None; old = 'def get_schedulers():\\n    return list(comfy.samplers.SCHEDULER_HANDLERS) + ADDITIONAL_SCHEDULERS\\n'; new = 'def get_schedulers():\\n    handlers = getattr(comfy.samplers, \\'SCHEDULER_HANDLERS\\', None)\\n    if handlers is None:\\n        names = getattr(comfy.samplers, \\'SCHEDULER_NAMES\\', [])\\n        return list(names) + ADDITIONAL_SCHEDULERS\\n    return list(handlers) + ADDITIONAL_SCHEDULERS\\n'; (text is not None and old in text) and path.write_text(text.replace(old, new), encoding='utf-8')"; \
    for req in \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Pack/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Subpack/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/style_aligned_comfy/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/Civicomfy/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/lynx/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/fantasyportrait/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-GGUF/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/ComfyUI-KJNodes/requirements.txt" \
      "${COMFYUI_DIR}/custom_nodes/comfyui_controlnet_aux/requirements.txt"; do \
      if [ -f "$req" ]; then "${COMFYUI_VENV_PIP}" install --no-cache-dir -r "$req"; fi; \
    done; \
    TORCH_VERSION="$("${COMFYUI_VENV_PYTHON}" -c "import torch; print(torch.__version__)")"; \
    TORCH_BASE="${TORCH_VERSION%%+*}"; \
    TORCH_SUFFIX="${TORCH_VERSION#*+}"; \
    if [ "$TORCH_SUFFIX" = "$TORCH_VERSION" ]; then \
      TORCH_INDEX="https://download.pytorch.org/whl/cpu"; \
    else \
      TORCH_INDEX="https://download.pytorch.org/whl/${TORCH_SUFFIX}"; \
    fi; \
    if ! "${COMFYUI_VENV_PIP}" install --no-cache-dir --index-url "${TORCH_INDEX}" "torchaudio==${TORCH_VERSION}"; then \
      "${COMFYUI_VENV_PIP}" install --no-cache-dir --index-url "${TORCH_INDEX}" "torchaudio==${TORCH_BASE}"; \
    fi; \
    "${COMFYUI_VENV_PIP}" install --no-cache-dir ultralytics piexif orjson; \
    "${COMFYUI_VENV_PYTHON}" -c "import os, sysconfig; \
site_dir = sysconfig.get_paths()['purelib']; \
path = os.path.join(site_dir, 'sitecustomize.py'); \
content = 'import os, sys\\n\\ncomfyui_dir = os.environ.get(\"COMFYUI_DIR\", \"/opt/ComfyUI\")\\nif comfyui_dir and comfyui_dir not in sys.path:\\n    sys.path.insert(0, comfyui_dir)\\n\\ntry:\\n    import folder_paths\\nexcept Exception:\\n    folder_paths = None\\n\\nif folder_paths is not None and not hasattr(folder_paths, \"get_user_directory\") and hasattr(folder_paths, \"user_directory\"):\\n    def get_user_directory() -> str:\\n        return folder_paths.user_directory\\n\\n    folder_paths.get_user_directory = get_user_directory\\n\\nif folder_paths is not None:\\n    try:\\n        folder_map = folder_paths.folder_names_and_paths\\n        supported_exts = folder_paths.supported_pt_extensions\\n    except Exception:\\n        folder_map = None\\n\\n    if folder_map is not None and \"text_encoders\" not in folder_map:\\n        if \"clip\" in folder_map:\\n            folder_map[\"text_encoders\"] = (list(folder_map[\"clip\"][0]), supported_exts)\\n        else:\\n            models_dir = getattr(folder_paths, \"models_dir\", os.path.join(comfyui_dir, \"models\"))\\n            folder_map[\"text_encoders\"] = ([os.path.join(models_dir, \"text_encoders\")], supported_exts)\\n\\ntry:\\n    import comfy.samplers as samplers\\nexcept Exception:\\n    samplers = None\\n\\nif samplers is not None and not hasattr(samplers, \"SCHEDULER_HANDLERS\") and hasattr(samplers, \"SCHEDULER_NAMES\"):\\n    samplers.SCHEDULER_HANDLERS = {name: (lambda model_sampling, steps, name=name: samplers.calculate_sigmas(model_sampling, name, steps)) for name in samplers.SCHEDULER_NAMES}\\n'; \
open(path, 'w', encoding='utf-8').write(content)"; \
    chmod -R g+rwX "${COMFYUI_DIR}/custom_nodes"; \
    find "${COMFYUI_DIR}/custom_nodes" -type d -exec chmod g+s {} +; \
    chown -R 1000:1111 "${COMFYUI_DIR}/custom_nodes"

# Persist models, inputs, outputs, and ComfyUI state in Kubernetes.
VOLUME ["/opt/ComfyUI/models"]

EXPOSE 8188
