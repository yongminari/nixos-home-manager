# 96GB Optimized Local LLM Infrastructure: Gemma 4

This plan leverages the **96GB RAM** on the **AI X1 Pro** to host a high-performance, multi-session LLM environment using **Gemma 4**.

## 1. Memory & VRAM Management Strategy
With 96GB of system RAM and an AMD Radeon GPU, we can maximize performance by:

-   **Shared Memory (GTT) Expansion**: For AMD GPUs, we can configure the kernel to allow the GPU to use a larger portion of system RAM. 
    -   *Action*: Set `boot.kernelParams = [ "amdgpu.gttsize=65536" ];` (allowing up to 64GB of system RAM for the GPU).
-   **Concurrent Model Residency**:
    -   **Gemma 4 E2B/E4B (Always-On)**: These will be kept resident in VRAM (~10-15GB total) for instantaneous routing of simple tasks.
    -   **Gemma 4 31B (Heavy Duty)**: Allocated ~40-60GB. With 96GB total, we can run this model with a **256K context window** or in **higher precision (Q8 or BF16)** without swapping to disk.
-   **KVM/Podman Isolation**: Ensure the Podman containers have access to the full memory range but are capped slightly below 96GB to prevent system OOM.

## 2. Updated Model Routing (96GB Context)
| Task Type | Model | RAM/VRAM Goal | Logic |
| :--- | :--- | :--- | :--- |
| **Instant / Simple** | `gemma4:e4b` | ~8GB (Resident) | Latency < 20ms |
| **Deep Reasoning** | `gemma4:26b-a4b` | ~20GB (Resident) | MoE architecture for fast expert-level logic. |
| **Heavy / Large Context**| `gemma4:31b` | ~45-60GB (Dynamic) | Full dense model for complex docs (up to 256K tokens). |

## 3. Infrastructure (Podman + ROCm)
-   **Container 1: Ollama (ROCm)**
    -   Configured with `OLLAMA_NUM_PARALLEL=4` to handle multiple concurrent sessions.
    -   `OLLAMA_MAX_LOADED_MODELS=3` to keep the above models in memory.
-   **Container 2: LiteLLM**
    -   Routes based on `task_type` or `priority` header.
-   **Container 3: Open WebUI**
    -   Frontend for multiple users/sessions.

## 4. Implementation Steps
1.  **NixOS Kernel Tuning**: Update `hosts/ai-x1-pro/configuration.nix` with `amdgpu.gttsize`.
2.  **Define local-ai Module**: Create `modules/services/local-ai.nix`.
3.  **Podman Deployment**: Use `oci-containers` with proper resource limits.
4.  **Model Pull & Warm-up**: Scripted initialization of Gemma 4 models.

Do you approve of this 96GB-optimized plan? If so, I will start by writing the `local-ai.nix` module.
