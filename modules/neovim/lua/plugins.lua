local utils = require('utils')
local options = require('options')
local safe_require = utils.safe_require

-- [테마 설정]
safe_require("tokyonight", function(tokyonight)
  tokyonight.setup({
    style = options.theme_style,
    transparent = options.is_transparent,
    styles = {
      sidebars = utils.is_remote and "dark" or "transparent",
      floats = utils.is_remote and "dark" or "transparent",
    },
  })
  vim.cmd.colorscheme "tokyonight"
end)

-- [기본 UI 컴포넌트]
safe_require("lualine", function(lualine) lualine.setup { options = { theme = 'tokyonight' } } end)
safe_require("bufferline", function(bufferline) bufferline.setup{} end)
safe_require("gitsigns", function(gitsigns) gitsigns.setup() end)
safe_require("ibl", function(ibl) ibl.setup() end)
safe_require("Comment", function(comment) comment.setup() end)
safe_require("nvim-autopairs", function(autopairs) autopairs.setup() end)
safe_require("mini.icons", function(icons) icons.setup(); icons.mock_nvim_web_devicons() end)

-- [파일 탐색기 & 관리]
safe_require("oil", function(oil)
  oil.setup()
  vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
end)

safe_require("neo-tree", function(neotree)
  neotree.setup({
    close_if_last_window = true,
    filesystem = { follow_current_file = { enabled = true }, use_libuv_file_watcher = true },
    window = { width = 30, mappings = { ["<space>"] = "none" } }
  })
  vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { silent = true })
end)

-- [검색 & 유틸리티]
safe_require("telescope.builtin", function(builtin)
  vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = "Find files" })
  vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = "Live grep" })
  vim.keymap.set('n', '<leader>s', builtin.lsp_document_symbols, { desc = "Outline" })
  vim.keymap.set('n', '<leader>d', builtin.lsp_definitions, { desc = "Definition" })
  vim.keymap.set('n', '<leader>r', builtin.lsp_references, { desc = "References" })
end)

safe_require("toggleterm", function(toggleterm)
  toggleterm.setup({ open_mapping = [[<C-/>]], direction = 'float', float_opts = { border = 'curved' } })
  vim.keymap.set({'n', 't'}, '<C-/>', '<cmd>ToggleTerm<cr>')
  vim.keymap.set({'n', 't'}, '<C-_>', '<cmd>ToggleTerm<cr>')
end)

safe_require("trouble", function(trouble)
  trouble.setup({})
  vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>")
end)

safe_require("lazygit", function(lazygit)
  vim.keymap.set("n", "<leader>G", "<cmd>LazyGit<cr>", { desc = "LazyGit"})
end)

-- [Obsidian 설정]
safe_require("obsidian", function(obsidian)
  local vault_path = vim.fn.expand("~/Documents/obsidian_personal_note")
  if vim.fn.isdirectory(vault_path) == 1 then
    obsidian.setup({
      workspaces = { { name = "notes", path = vault_path } },
      ui = { enable = true, concealcursor = "nv" },
      checkboxes = {
        [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
        ["x"] = { char = "", hl_group = "ObsidianDone" },
        ["v"] = { char = "", hl_group = "ObsidianCheck" },
      },
      legacy_commands = false, -- 경고 제거
    })
  end
  vim.keymap.set("n", "<leader>on", "<cmd>Obsidian new<cr>")
  vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>")
end)

-- [LSP & 자동완성]
local cmp_ok, cmp = pcall(require, "cmp")
if cmp_ok then
  cmp.setup({
    snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
    mapping = cmp.mapping.preset.insert({
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
    }),
    sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'luasnip' } }, { { name = 'buffer' }, { name = 'path' } })
  })
end

-- Treesitter Config
safe_require("nvim-treesitter.configs", function(configs) configs.setup { highlight = { enable = true }, indent = { enable = true } } end)

-- [LSP Config (Neovim 0.11+ Modern Way)]
local capabilities = {}
local cmp_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if cmp_lsp_ok then capabilities = cmp_nvim_lsp.default_capabilities() end

local servers = { 'gopls', 'nil_ls' }

-- Neovim 0.11에서 새로 도입된 vim.lsp.config API를 우선 사용합니다.
if vim.lsp.config then
  for _, lsp in ipairs(servers) do
    vim.lsp.config(lsp, { capabilities = capabilities })
    vim.lsp.enable(lsp)
  end
  -- clangd 전용 안전 설정
  vim.lsp.config('clangd', {
    capabilities = capabilities,
    cmd = { "clangd", "--offset-encoding=utf-16" }
  })
  vim.lsp.enable('clangd')
else
  -- 구 버전(0.10 이하) 호환성을 위한 nvim-lspconfig Fallback
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok then
    for _, lsp in ipairs(servers) do lspconfig[lsp].setup { capabilities = capabilities } end
    lspconfig.clangd.setup { capabilities = capabilities, cmd = { "clangd", "--offset-encoding=utf-16" } }
  end
end
