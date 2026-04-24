local utils = require('utils')

-- [기본 옵션]
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.ignorecase = true     -- Case insensitive searching
vim.opt.smartcase = true      -- Smart case
vim.g.mapleader = " "         

-- [테마 배경색 설정]
-- 원격지(SSH/Docker)에서 접속 시 배경을 light 모드로 전환
if utils.is_remote then
  vim.opt.background = "light"
else
  vim.opt.background = "dark"
end

-- [클립보드 설정]
if utils.is_remote or utils.is_multiplexer then
  vim.g.clipboard = {
    name = 'osc52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = function() return { vim.fn.getreg('"', 1, true), vim.fn.getregtype('"') } end,
      ['*'] = function() return { vim.fn.getreg('"', 1, true), vim.fn.getregtype('"') } end,
    },
  }
end

vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.conceallevel = 2
vim.opt.laststatus = 3
vim.opt.cmdheight = 1

-- [Diagnostic 하이라이트 설정]
-- Error: 빨간색 가운데 줄 (strikethrough), Warn: 노란색 가운데 줄
vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { underline = false, strikethrough = true, sp = "Red" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { underline = false, strikethrough = true, sp = "Yellow" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { underline = false, strikethrough = true, sp = "LightBlue" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { underline = false, strikethrough = true, sp = "LightGrey" })

return {
  theme_style = theme_style,
  is_transparent = is_transparent,
}
