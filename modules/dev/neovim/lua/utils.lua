-- 안전한 설정을 위한 헬퍼 함수
local function safe_require(module, config_fn)
  local ok, mod = pcall(require, module)
  if ok then config_fn(mod) end
end

-- [환경 감지]
local is_ssh = os.getenv("SSH_CONNECTION") ~= nil or os.getenv("SSH_CLIENT") ~= nil or os.getenv("SSH_TTY") ~= nil
local is_multiplexer = os.getenv("ZELLIJ") ~= nil or os.getenv("TMUX") ~= nil
local is_ghostty = os.getenv("TERM_PROGRAM") == "Ghostty" or os.getenv("TERM") == "xterm-ghostty"

return {
  safe_require = safe_require,
  is_ssh = is_ssh,
  is_remote = is_ssh,
  is_multiplexer = is_multiplexer,
  is_ghostty = is_ghostty,
}
