local utils = require('utils')
local options = require('options')
local safe_require = utils.safe_require

-- [테마 설정: Ayu]
-- 로컬에서는 'dark', 원격 환경(SSH/Container)에서는 'mirage' 사용
if utils.is_remote then
  vim.g.ayucolor = "mirage"
else
  vim.g.ayucolor = "dark"
end

-- ayu-vim은 주로 Vimscript이므로 pcall로 직접 호출
local ok, _ = pcall(vim.cmd.colorscheme, "ayu")
if not ok then
  -- ayu가 없을 경우 기본 colorscheme 유지 혹은 다른 처리
end

-- [기본 UI 컴포넌트]
safe_require("lualine", function(lualine)
  local lualine_theme = 'ayu_dark'
  if utils.is_remote then lualine_theme = 'ayu_mirage' end
  lualine.setup { options = { theme = lualine_theme } }
end)
safe_require("bufferline", function(bufferline) bufferline.setup{} end)
safe_require("gitsigns", function(gitsigns) gitsigns.setup() end)
safe_require("ibl", function(ibl)
  local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
  }

  local hooks = require("ibl.hooks")
  hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#F07178" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#FFCC66" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#59C2FF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#FFB454" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#C2D94C" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#D4BFFF" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#95E6CB" })
  end)

  ibl.setup({
    indent = { char = "│", highlight = highlight },
    scope = { enabled = false }, -- hlchunk와 겹치지 않게 scope는 끕니다.
  })
end)

safe_require("rainbow-delimiters", function(rd)
  -- rainbow-delimiters는 기본적으로 위에서 설정한 RainbowRed 등의 하이라이트 그룹을 사용하도록 연동될 수 있습니다.
end)

safe_require("hlchunk", function(hlchunk)
  hlchunk.setup({
    chunk = {
      enable = true,
      use_treesitter = true,
      style = {
        { fg = "#ffcc66" }, -- 현재 블록의 강조 색상
        { fg = "#c34043" }, -- 오류 등이 있을 때의 색상
      },
    },
    indent = {
      enable = true,
      use_treesitter = true,
    },
  })
end)
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

safe_require("neogit", function(neogit)
  neogit.setup({
    integrations = {
      diffview = true,
    },
  })
  vim.keymap.set("n", "<leader>ng", "<cmd>Neogit<cr>", { desc = "Neogit" })
end)

safe_require("diffview", function(diffview)
  diffview.setup({})
  vim.keymap.set("n", "<leader>dv", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open" })
  vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })
  -- Compatibility Keymaps
  vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open (Legacy)" })
  vim.keymap.set("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close (Legacy)" })
end)

safe_require("git-conflict", function(git_conflict)
  git_conflict.setup()
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
      legacy_commands = false,
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
safe_require("nvim-treesitter", function(ts)
  ts.setup()
end)

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
    if lang then
      pcall(vim.treesitter.start, args.buf, lang)
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- [Container/Distrobox 하이브리드 지원 로직]
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "/opt/*", "/usr/include/*" },
  callback = function(args)
    local file = args.file
    if vim.fn.filereadable(file) == 1 then return end

    local cmd = string.format("distrobox enter ros-jazzy -- cat '%s'", file)
    local content = vim.fn.systemlist(cmd)
    if vim.v.shell_error == 0 then
      vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, content)
      vim.api.nvim_set_option_value("readonly", true, { buf = args.buf })
      vim.api.nvim_set_option_value("buftype", "nowrite", { buf = args.buf })
      local ft = vim.filetype.match({ filename = file })
      if ft then vim.api.nvim_set_option_value("filetype", ft, { buf = args.buf }) end
    end
  end,
})

-- [LSP Config (Neovim 0.11+ Modern Way)]
local capabilities = {}
local cmp_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if cmp_lsp_ok then capabilities = cmp_nvim_lsp.default_capabilities() end

local servers = { 'gopls', 'nil_ls', 'pyright', 'bashls', 'yamlls', 'taplo', 'jsonls', 'cmake', 'autotools_ls' }

if vim.lsp.config then
  for _, lsp in ipairs(servers) do
    vim.lsp.config(lsp, { capabilities = capabilities })
    vim.lsp.enable(lsp)
  end

  local is_ros_project = vim.env.ROS_DISTRO ~= nil or 
                         vim.env.AMENT_PREFIX_PATH ~= nil or
                         #vim.fs.find('package.xml', { upward = true }) > 0
  
  local clangd_cmd = { 
    "clangd", 
    "--offset-encoding=utf-16",
    "--query-driver=/nix/store/*/bin/clang++,/nix/store/*/bin/g++,/usr/bin/clang++,/usr/bin/g++"
  }
  
  if is_ros_project and vim.fn.executable("clangd-distrobox") == 1 then
    clangd_cmd = { "clangd-distrobox", "--offset-encoding=utf-16" }
  end

  vim.lsp.config('clangd', { capabilities = capabilities, cmd = clangd_cmd })
  vim.lsp.enable('clangd')
else
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok then
    for _, lsp in ipairs(servers) do lspconfig[lsp].setup { capabilities = capabilities } end
    local is_ros_project = vim.env.ROS_DISTRO ~= nil or 
                           vim.env.AMENT_PREFIX_PATH ~= nil or
                           #vim.fs.find('package.xml', { upward = true }) > 0

    local clangd_cmd = { 
      "clangd", 
      "--offset-encoding=utf-16",
      "--query-driver=/nix/store/*/bin/clang++,/nix/store/*/bin/g++,/usr/bin/clang++,/usr/bin/g++"
    }
    
    if is_ros_project and vim.fn.executable("clangd-distrobox") == 1 then
      clangd_cmd = { "clangd-distrobox", "--offset-encoding=utf-16" }
    end
    lspconfig.clangd.setup { capabilities = capabilities, cmd = clangd_cmd }
  end
end

-- [LSP 단어 하이라이트 설정]
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight') then
      local group = vim.api.nvim_create_augroup('lsp_document_highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

local function set_lsp_highlights()
  vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#3d424d", underline = true, sp = "#ffcc66" })
  vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#3d424d", underline = true, sp = "#ffcc66" })
  vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#3d424d", underline = true, bold = true, sp = "#ffcc66" })
end

set_lsp_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_lsp_highlights })

-- [Diagnostic 하이라이트 설정]
vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { underline = false, strikethrough = true, sp = "Red" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { underline = false, strikethrough = true, sp = "Yellow" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { underline = false, strikethrough = true, sp = "LightBlue" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { underline = false, strikethrough = true, sp = "LightGrey" })
