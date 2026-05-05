-- 안전한 설정을 위한 헬퍼 함수
local function safe_require(module, config_fn)
  local ok, mod = pcall(require, module)
  if ok then config_fn(mod) end
end

-- [환경 감지]
local is_ssh = os.getenv("SSH_CONNECTION") ~= nil or os.getenv("SSH_CLIENT") ~= nil or os.getenv("SSH_TTY") ~= nil
local is_container = vim.fn.filereadable("/.dockerenv") == 1 
                  or vim.fn.filereadable("/run/.containerenv") == 1 
                  or os.getenv("DISTROBOX_ENTER_PATH") ~= nil
                  or os.getenv("DOCKER_CONTAINER") ~= nil

local is_remote = is_ssh or is_container  -- 진짜 원격/격리 세션 여부
local is_multiplexer = os.getenv("ZELLIJ") ~= nil or os.getenv("TMUX") ~= nil

return {
  safe_require = safe_require,
  is_ssh = is_ssh,
  is_container = is_container,
  is_remote = is_remote,
  is_multiplexer = is_multiplexer,
}
