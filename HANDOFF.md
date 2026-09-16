# AI Host Local Service Handoff

## Context

- Target host: `ai-x1-pro`
- Baseline branch: `main`
- Baseline includes: `21d992c fix(git): let repositories detect case sensitivity`
- This repository owns only the NixOS-level configuration for the local AI service: GPU, Podman, systemd, firewall, secrets, packages, and persistent paths.
- Application prompts, workflows, model evaluation, and application code are out of scope.

Before doing anything, verify the host:

```console
hostname
```

Continue only when the result is exactly `ai-x1-pro`. Do not switch the `ai-x1-pro` configuration from another machine.

## Current Configuration

The host imports `modules/services/local-ai.nix` and currently declares three rootful Podman containers:

- `ollama`: ROCm image, model data persisted at `/var/lib/ollama`, default container network, no published port.
- `litellm`: host network, listens on port 4000, and points every model to `http://localhost:11434`.
- `open-webui`: host network, disables authentication, and sets `OLLAMA_BASE_URL=http://localhost:4000`.

The host globally opens TCP port 8080 in `hosts/ai-x1-pro/configuration.nix`.

## Confirmed Issues

1. LiteLLM uses `localhost:11434`, but Ollama does not use the host network and does not publish port 11434. The declared topology therefore does not provide the expected host-local path from LiteLLM to Ollama.
2. Open WebUI's `OLLAMA_BASE_URL` is specifically for an Ollama-compatible backend. LiteLLM is an OpenAI-compatible proxy and should be configured through Open WebUI's OpenAI connection variables if LiteLLM is retained.
3. Open WebUI has no `/app/backend/data` volume, so configuration and conversation data are not intentionally persisted across recreation.
4. `WEBUI_AUTH=False` is combined with a globally open firewall port 8080. This is unsafe unless unauthenticated access to the entire reachable network is explicitly intended.
5. `general_settings.master_key: sk-1234` is tracked in `modules/services/litellm_config.yaml`. Secrets must be supplied through `sops-nix`, not committed YAML.
6. All three container images use floating tags (`rocm`, `main`, and `main-latest`), making upgrades and rollbacks unpredictable.
7. `ports` and `--network=host` are declared together for Open WebUI and LiteLLM. Select one networking model and remove the redundant settings.

Primary references:

- Open WebUI environment variables: <https://docs.openwebui.com/reference/env-configuration/>
- Open WebUI container persistence and connection examples: <https://docs.openwebui.com/getting-started/quick-start/>
- LiteLLM proxy and Ollama configuration: <https://docs.litellm.ai/>

## Runtime Audit on `ai-x1-pro`

Collect evidence before editing:

```console
systemctl --no-pager --full status podman-ollama podman-litellm podman-open-webui
podman ps -a
podman inspect ollama litellm open-webui
sudo ss -ltnp | rg ':(8080|4000|11434)\b'
sudo journalctl -u podman-ollama -u podman-litellm -u podman-open-webui -b --no-pager
curl --fail --show-error http://127.0.0.1:11434/api/tags
curl --fail --show-error http://127.0.0.1:4000/v1/models
curl --fail --show-error http://127.0.0.1:8080/health
sudo du -sh /var/lib/ollama /var/lib/open-webui 2>/dev/null
```

Record which components are actually used. In particular, decide whether LiteLLM still provides needed routing. If it is unused, removing LiteLLM is simpler and safer than repairing an unnecessary proxy.

## Recommended Architecture

Choose one topology based on observed use; do not mix host networking and published bridge ports.

### Preferred when LiteLLM is unnecessary

- Keep Ollama and Open WebUI only.
- Put them on one explicit Podman bridge network.
- Connect Open WebUI directly to `http://ollama:11434`.
- Publish only Open WebUI's port.

### When LiteLLM routing is required

- Put Ollama, LiteLLM, and Open WebUI on one explicit Podman bridge network.
- LiteLLM connects to `http://ollama:11434`.
- Open WebUI connects to LiteLLM using `OPENAI_API_BASE_URL=http://litellm:4000/v1` and a scoped API key.
- Publish only Open WebUI's port unless port 4000 has a documented external consumer.

For either topology:

- Persist `/var/lib/open-webui:/app/backend/data`.
- Keep `/var/lib/ollama:/root/.ollama`.
- Create persistent directories declaratively with `systemd.tmpfiles.rules`.
- Enable Open WebUI authentication and provide a stable `WEBUI_SECRET_KEY` through `sops-nix`.
- Put the LiteLLM key in `secrets/secrets.yaml` and inject it through a sops-generated environment file if LiteLLM remains.
- Pin reviewed image versions or digests. Document the update procedure rather than following floating `main` tags.
- Restrict firewall access to the intended interface or network. Prefer WireGuard-only exposure when remote access is the goal.

## Scope and Placement

- Keep the entire service host-specific through `hosts/ai-x1-pro/configuration.nix` importing `modules/services/local-ai.nix`.
- Do not add these containers, firewall ports, ROCm packages, or persistent directories to common hosts.
- Add new secrets through `modules/core/sops.nix` or a dedicated AI-host secret module, without exposing decrypted values in the Nix store.
- Preserve existing Ollama model data during migration.

## Verification

After editing, stage new files before Flake evaluation:

```console
git add .
git diff --check
nh os build .#ai-x1-pro
```

On `ai-x1-pro`, apply and verify:

```console
nh os switch .#ai-x1-pro
systemctl --no-pager --full status podman-ollama podman-open-webui
systemctl --no-pager --full status podman-litellm  # only if retained
podman ps
sudo ss -ltnp | rg ':(8080|4000|11434)\b'
curl --fail --show-error http://127.0.0.1:8080/health
```

Also verify from an intended remote client that authentication is required and from an unintended network that the service is unreachable.

## Completion Criteria

- Every retained container can reach its declared upstream service.
- Only required host ports are listening and allowed through the firewall.
- Open WebUI data and Ollama models survive container recreation.
- No plaintext service key remains in tracked files or the Nix store.
- Container image versions are reproducible.
- `nh os build .#ai-x1-pro` and the live health checks pass.
- Remove this handoff document after the work is completed, committed, and pushed.
