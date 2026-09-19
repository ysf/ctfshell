local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "nvim-lua/plenary.nvim" },

  { "nvim-lualine/lualine.nvim" },
  { "nvim-tree/nvim-web-devicons" },
  { "SmiteshP/nvim-navic" },

  { "sainnhe/sonokai" },
  { "croaker/mustang-vim" },
  { "tomasr/molokai" },
  { "Yazeed1s/minimal.nvim" },
  { "rebelot/kanagawa.nvim" },

  { "jpalardy/vim-slime" },
  { "lambdalisue/suda.vim" },
  { "tmux-plugins/vim-tmux-focus-events" },
  { "ggandor/leap.nvim" },

  { "tpope/vim-sensible" },
  { "tpope/vim-obsession" },
  { "tpope/vim-repeat" },
  { "tpope/vim-surround" },
  { "tpope/vim-markdown" },
  { "tpope/vim-fugitive" },

  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  {
      "L3MON4D3/LuaSnip",
      dependencies = { "rafamadriz/friendly-snippets" },
      build = "make install_jsregexp"
  },
  { "saadparwaiz1/cmp_luasnip" },

  { "dstein64/vim-startuptime" },

  { "nifey/sarif.nvim" },
  { "nvim-telescope/telescope.nvim" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "fatih/vim-go", build = ":GoUpdateBinaries" },
  { "charlespascoe/vim-go-syntax" },
  { "jiangmiao/auto-pairs" },
})

-- Telescope keymaps
------------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>e", "<cmd>Telescope find_files<cr>")
map("n", "<leader>g", "<cmd>Telescope live_grep<cr>")
map("n", "<leader>b", "<cmd>Telescope buffers<cr>")
map("n", "<leader>h", "<cmd>Telescope help_tags<cr>")

-- cscope mappings
------------------------------------------------------------
map("n", "<F2>", ":cscope add cscope.out<CR>", { silent = true })
map("n", "<leader>d", ":cs find g <C-R>=expand('<cword>')<CR><CR>")


-- vim-slime opts + helpers (tmux)
------------------------------------------------------------
local function TmuxSendKeys(seq)
  local pane = (vim.g.slime_default_config and vim.g.slime_default_config.target_pane) or "{last}"
  local args = { "send-keys", "-t", pane }
  for _, k in ipairs(seq) do table.insert(args, k) end
  vim.system({ "tmux", unpack(args) }):wait()
end

vim.g.slime_target = "tmux"
vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }
vim.g.slime_dont_ask_default = 1

map("n", "ä", function() TmuxSendKeys({ "Up", "Enter" }) end)

-- suda
------------------------------------------------------------
vim.cmd([[cmap w!! w suda://%]])

-- leap
------------------------------------------------------------
map({'n', 'x', 'o'}, 's', '<Plug>(leap)')

-- Options
------------------------------------------------------------
local o, wo, bo = vim.opt, vim.wo, vim.bo

o.termguicolors = true
o.mouse = "a"
o.signcolumn = "yes"
o.cmdheight = 1
o.updatetime = 300
o.shortmess:append("c")
o.cursorline = true
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#666666" })
vim.api.nvim_set_hl(0, "CursorLineNr", {})
vim.api.nvim_set_hl(0, "SignColumn", { ctermbg = 0 })
vim.api.nvim_set_hl(0, "Comment", { italic = true })

o.number = true
o.relativenumber = true

o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch = true

o.splitright = true
o.scrolloff = 7

o.autowrite = true
o.writebackup = false
o.backup = false
o.swapfile = false
o.undofile = true
o.undolevels = 1000
o.undoreload = 10000

local undodir = vim.fn.expand("~/.config/vim/undodir")
o.undodir = undodir
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

o.matchtime = 2
o.showmatch = true
o.backspace = { "indent", "eol", "start" }
o.linebreak = true
o.textwidth = 500
o.smarttab = true
o.fileformat = "unix"
o.fileformat = "unix"
o.autoindent = true
o.smartindent = true
o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.list = true
o.history = 700
o.wildmenu = true
o.hidden = true
o.lazyredraw = true
o.clipboard = "unnamedplus"

vim.cmd([[set ffs=unix,dos,mac]])
vim.cmd([[set matchpairs+=<:>]])
vim.cmd([[set whichwrap+=<,>,h,l]])

-- Keymaps
------------------------------------------------------------
map("n", "<leader>,", ":nohl<cr>")

-- alt movement without moving screen
map("n", "<C-j>", "7j")
map("n", "<C-k>", "7k")

-- jj/kk = esc
map("i", "jj", "<esc>")
map("i", "kk", "<esc>")

-- Maintain wrapped line movement like gk/gj
map({"n","v"}, "j", "gj")
map({"n","v"}, "k", "gk")
map("n", "<Down>", "gj")
map("n", "<Up>", "gk")
map("v", "<Down>", "gj")
map("v", "<Up>", "gk")
map("i", "<Down>", "<C-o>gj")
map("i", "<Up>", "<C-o>gk")

-- Window / buffer helpers
map("n", "<leader>w", ":w!<cr>")
map("n", "<leader>a", ":close<cr>")
map("n", "<leader>c", ":bd<cr>")
map("n", "<leader><tab>", ":bnext<cr>")
map("n", "<leader>v", ":e ~/.config/nvim/init.lua<cr>")
map("n", "<leader>p", ":!%:p<cr>")
map("n", "<leader><leader>", "<c-^>")

-- Reselect visual after indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Quick replace word under cursor (like your *``cgn macro)
map("n", "<leader>r", "*``cgn")

-- Autocmds
------------------------------------------------------------
local aug = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  callback = function(ev)
    local bo = vim.bo[ev.buf]
    if bo.modifiable and bo.buftype == "" then
      bo.fileformat = "unix"
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
    local copy_to_unnamedplus = require("vim.ui.clipboard.osc52").copy("+")
    copy_to_unnamedplus(vim.v.event.regcontents)
    local copy_to_unnamed = require("vim.ui.clipboard.osc52").copy("*")
    copy_to_unnamed(vim.v.event.regcontents)
  end,
})

au({"FocusLost"}, { pattern = "*", command = "wall" })
au({"BufLeave","FocusLost"}, { pattern = "*", command = "silent! wall" })
au("BufWritePre", { pattern = "*", command = [[%s/\s\+$//e]] })

au("FileType", { pattern = {"ruby","vim"}, callback = function()
  vim.bo.softtabstop = 2
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
end })

local numgrp = aug("numbertoggle", { clear = true })
au({"BufEnter","FocusGained","InsertLeave"}, { group = numgrp, callback = function() vim.wo.relativenumber = true end })
au({"BufLeave","FocusLost","InsertEnter"}, { group = numgrp, callback = function() vim.wo.relativenumber = false end })

au("BufReadPost", {
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end
})

-- Treesitter
------------------------------------------------------------
require('nvim-treesitter.configs').setup({
  ensure_installed = {
    "c","cpp","lua","rust","python","java","bash","make","ruby",
    "json","markdown","yaml","toml","typescript","javascript",
    "dockerfile","nix"
  },
  sync_install = false,
  auto_install = true,
  highlight = { enable = true, additional_vim_regex_highlighting = false },
})

-- LSP / CMP
------------------------------------------------------------
local lspconfig = require('lspconfig')
local cmp = require('cmp')
local luasnip = require('luasnip')

map('n', '[d', vim.diagnostic.goto_prev, { silent = true })
map('n', ']d', vim.diagnostic.goto_next, { silent = true })
map('n', '<space>q', vim.diagnostic.setloclist, { silent = true })

local navic = require('nvim-navic')

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  map('n', 'K', vim.lsp.buf.hover, bufopts)
  map('n', 'gi', vim.lsp.buf.implementation, bufopts)
  map('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  map('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  map('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  map('n', '<space>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, bufopts)
  map('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  map('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  map('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  map('n', 'gr', vim.lsp.buf.references, bufopts)
  map('n', '<space>f', function() vim.lsp.buf.format({ async = true }) end, bufopts)
  -- navic breadcrumbs when available
  if client.server_capabilities.documentSymbolProvider then
    pcall(navic.attach, client, bufnr)
  end
end

local lsp_defaults = {
  flags = { debounce_text_changes = 150 },
  capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities()),
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    vim.api.nvim_exec_autocmds('User', { pattern = 'LspAttached' })
  end,
}

lspconfig.util.default_config = vim.tbl_deep_extend('force', lspconfig.util.default_config, lsp_defaults)

lspconfig.pylsp.setup({
  cmd = { "pylsp" }, -- update if needed
})
lspconfig.pyright.setup({})
lspconfig.ts_ls.setup({}) -- you used ts_ls in your file
lspconfig.clangd.setup({})
lspconfig.rust_analyzer.setup({ settings = { ["rust-analyzer"] = {} } })

-- nvim-cmp
local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line-1, line, true)[1]:sub(col, col):match("%s") == nil
end

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'path' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
  }),
})

-- cmdline completion
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = { { name = 'buffer' } }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } })
})

require("luasnip.loaders.from_vscode").lazy_load()

-- Lualine
------------------------------------------------------------
local lualine = require('lualine')
local colors = {
  bg = "#202328", fg = "#bbc2cf", yellow = "#ECBE7B", cyan = "#008080",
  darkblue = "#081633", green = "#98be65", orange = "#FF8800", violet = "#a9a1e1",
  magenta = "#c678dd", blue = "#51afef", red = "#ec5f67",
}

local function hide_in_width() return vim.fn.winwidth(0) > 80 end

local config = {
  options = {
    component_separators = "",
    section_separators = "",
    theme = {
      normal   = { c = { fg = colors.fg, bg = colors.bg } },
      inactive = { c = { fg = colors.fg, bg = colors.bg } },
    },
  },
  sections = { lualine_a = {}, lualine_b = {}, lualine_y = {}, lualine_z = {}, lualine_c = {}, lualine_x = {}, },
  inactive_sections = { lualine_a = {}, lualine_v = {}, lualine_y = {}, lualine_z = {}, lualine_c = {}, lualine_x = {}, },
}

local function ins_left(component) table.insert(config.sections.lualine_c, component) end
local function ins_right(component) table.insert(config.sections.lualine_x, component) end

ins_left({ function() return "▊" end, color = { fg = colors.blue }, padding = 0 })

ins_left({
  function()
    local mode_color = { n=colors.red, i=colors.green, v=colors.blue, ['\22']=colors.blue, V=colors.blue,
      c=colors.magenta, no=colors.red, s=colors.orange, S=colors.orange, ['\19']=colors.orange,
      ic=colors.yellow, R=colors.violet, Rv=colors.violet, cv=colors.red, ce=colors.red,
      r=colors.cyan, rm=colors.cyan, ['r?']=colors.cyan, ['!']=colors.red, t=colors.red }
    vim.api.nvim_set_hl(0, 'LualineMode', { fg = mode_color[vim.fn.mode()] or colors.blue, bg = colors.bg })
    return ''
  end,
  color = 'LualineMode', padding = 0,
})

ins_left({ function()
  local file = vim.fn.expand('%:p')
  if file == '' then return '' end
  local size = vim.fn.getfsize(file)
  if size <= 0 then return '' end
  local suf = { 'b','k','m','g' }
  local i = 1
  while size > 1024 do size = size / 1024; i = i + 1 end
  return string.format('%.1f%s', size, suf[i])
end })

ins_left({ 'filename', color = { fg = colors.magenta, gui = 'bold' } })
ins_left({ 'location' })
ins_left({ 'progress', color = { fg = colors.fg, gui = 'bold' } })
ins_left({ 'diagnostics', sources = { 'nvim_diagnostic' }, symbols = { error=' ', warn=' ', info=' ' } })
ins_left({ function() return navic.get_location() end, cond = function() return navic.is_available() end })
ins_left({ function() return '%=' end })
ins_left({ function()
  local buf_ft = vim.bo.filetype
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return 'No Active Lsp' end
  local names = {}
  for _, c in ipairs(clients) do
    local fts = c.config.filetypes
    if not fts or vim.tbl_contains(fts, buf_ft) then table.insert(names, c.name) end
  end
  return (#names > 0) and table.concat(names, ',') or 'No Active Lsp'
end, icon = ' LSP:', color = { fg = colors.violet, gui = 'bold' } })

ins_right({ 'o:encoding', cond = hide_in_width, color = { fg = colors.green, gui = 'bold' } })
ins_right({ 'fileformat', icons_enabled = false, color = { fg = colors.green, gui = 'bold' } })
ins_right({ 'branch', icon = '', color = { fg = colors.violet, gui = 'bold' } })
ins_right({ 'diff', symbols = { added=' ', modified='柳 ', removed=' ' }, cond = hide_in_width })
ins_right({ function() return '▊' end, color = { fg = colors.blue }, padding = 0 })

lualine.setup(config)

-- Telescope
------------------------------------------------------------
require('telescope').setup({
  defaults = {
      file_ignore_patterns = { "node_modules", "__pycache__", "LICENSE" } },
  pickers = {
    colorscheme = {
      enable_preview = true,
      on_cancel = function ()
        local mytheme = require('plugins.mytheme')
        mytheme.setup()
      end,
      on_hover = function (colorscheme)
        require('plugins.mytheme').setup(colorscheme)
      end,
      on_change = function (colorscheme)
        require('plugins.mytheme').save(colorscheme)
      end
    }
  }
})

vim.cmd([[colorscheme kanagawa]])

