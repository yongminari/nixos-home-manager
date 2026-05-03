{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true; 
    withRuby = false;
    withPython3 = false;
    vimAlias = true;

    extraLuaPackages = ps: [ ps.jsregexp ];

    plugins = with pkgs.vimPlugins; [
      ayu-vim
      which-key-nvim 
      nvim-web-devicons
      lualine-nvim
      neo-tree-nvim
      nui-nvim 
      plenary-nvim
      telescope-nvim
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
      gitsigns-nvim
      indent-blankline-nvim
      bufferline-nvim
      mini-nvim
      oil-nvim
      comment-nvim
      nvim-autopairs
      trouble-nvim
      toggleterm-nvim
      neogit
      diffview-nvim
      lazygit-nvim
      git-conflict-nvim
      obsidian-nvim
      hlchunk-nvim
      rainbow-delimiters-nvim
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
    ];

    # 1. 진입점 설정 (분리된 모듈들을 호출)
    initLua = ''
      require('utils')
      require('options')
      require('keymaps')
      require('plugins')
    '';
  };

  # 2. Lua 모듈들을 ~/.config/nvim/lua/ 경로에 배치
  xdg.configFile = {
    "nvim/lua/utils.lua".source = ./neovim/lua/utils.lua;
    "nvim/lua/options.lua".source = ./neovim/lua/options.lua;
    "nvim/lua/keymaps.lua".source = ./neovim/lua/keymaps.lua;
    "nvim/lua/plugins.lua".source = ./neovim/lua/plugins.lua;
  };
}
