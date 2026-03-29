local utils = require('utils')

-- 테마 설정용
local theme_style = utils.is_remote and "day" or "moon"
local is_transparent = not utils.is_remote

-- [기본 옵션]
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.ignorecase = true     -- Case insensitive searching
vim.opt.smartcase = true      -- Smart case
vim.g.mapleader = " "         

-- [클립보드 설정]
if utils.is_remote or utils.is_multiplexer then
  vim.g.clipboard = {
    name = 'osc52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
end

vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.conceallevel = 2
vim.opt.laststatus = 3
vim.opt.cmdheight = 1

return {
  theme_style = theme_style,
  is_transparent = is_transparent,
}
