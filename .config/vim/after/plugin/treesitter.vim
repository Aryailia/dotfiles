" Unfortunately there is no good tree-sitter integration as of yet for vim

if has('nvim-0.8')
  lua <<EOF
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" to install on :TSUpdate
  ensure_installed = {
    -- Compiled Type 3
    "c",
    "go",
    "rust",

    -- Interpreted Type 3
    "vim",
    "bash",
    "cmake",
    "lua",
    "perl",
    "python",
    "r",
    "ruby",
    "typescript",

    -- Markup and Type 2 (context-free languages)
    "help",
    "bibtex",
    "html",
    "markdown",
    "nix",
    "scss",
    -- "sql",
    "terraform",

    "toml",
    "yaml",
    "json",
  },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = false,

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
    disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
            return true
        end
    end,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },

  --refactor = {
  --  navigation = {
  --    enable = true,
  --    keymaps = {
  --      goto_definition = "gnd",
  --      list_definitions = "gnD",
  --      list_definitions_toc = "gO",
  --      goto_next_usage = "[g",
  --      goto_previous_usage = "]g",
  --    },
  --  },

  --  smart_rename = {
  --    enable = true,
  --    keymaps = {
  --      smart_rename = "grr",
  --    },
  --  },
  --},
}
EOF




endif
