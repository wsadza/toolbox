-- ============================================================
-- Basic settings
-- ============================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true

opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.splitright = true
opt.splitbelow = true
opt.wrap = false

opt.updatetime = 250
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Persistent undo
opt.undofile = true

-- Disable non-used providers
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- ============================================================
-- General keymaps
-- ============================================================

local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit all without saving" })

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

map("v", "J", ":move '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "K", ":move '<-2<cr>gv=gv", { desc = "Move selection up" })

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Keep selection after indentation
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Open NvimTree
map("n", "<leader>pv", "<cmd>NvimTreeOpen<cr>", { desc = "Open file tree" })

-- Disable recording macro
map("n", "q", "<Nop>", { silent = true })

-- ============================================================
-- Bootstrap lazy.nvim
-- ============================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local result = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})

	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to install lazy.nvim:\n", "ErrorMsg" },
			{ result, "WarningMsg" },
		}, true, {})
		return
	end
end

vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- Plugins
-- ============================================================

require("lazy").setup({

	-- ----------------------------------------------------------
  -- CodeCompanion
	-- ----------------------------------------------------------

  {
    "olimorris/codecompanion.nvim",
  
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  
    config = function()
      local adapters = require("codecompanion.adapters")
  
      local caveman_prompt = [[
  Respond terse like smart caveman. All technical substance stay. Only fluff die.
  
  ACTIVE EVERY RESPONSE. No filler drift.
  
  Rules:
  - Remove filler, pleasantries, unnecessary hedging, and repetition.
  - Fragments allowed when meaning remains clear.
  - Keep technical terminology exact.
  - Keep code blocks, commands, paths, API names, function names, symbols,
    and exact error messages unchanged.
  - Never invent abbreviations.
  - Preserve user's language.
  - Never announce or name this style.
  - State each fact once.
  - Write normal, explicit prose for security warnings, irreversible actions,
    and ordered instructions where compression could cause ambiguity.
  - Code, commit messages, and pull-request content use normal task-appropriate form.
  
  Pattern:
  [problem or fact]. [reason]. [next action].
  ]]
  
      require("codecompanion").setup({
        adapters = {
          http = {
            local_llama = function()
              return adapters.extend("openai_compatible", {
                name = "local_llama",
  
                env = {
                  url = "http://0.0.0.0:8080",
                  api_key = "local",
                },
  
                schema = {
                  model = {
                    default = os.getenv("LLAMA_ARG_MODEL") or "local",
                  },
                },
              })
            end,
          },
        },
  
        interactions = {
          chat = {
            adapter = "local_llama",
  
            opts = {
              system_prompt = function()
                return caveman_prompt
              end,
            },
          },
  
          inline = {
            adapter = "local_llama",
          },
        },
      })
  
      vim.keymap.set(
        { "n", "v" },
        "<leader>ac",
        "<cmd>CodeCompanionChat Toggle<cr>",
        { desc = "AI chat", silent = true }
      )
  
      vim.keymap.set(
        { "n", "v" },
        "<leader>aa",
        "<cmd>CodeCompanionActions<cr>",
        { desc = "AI actions", silent = true }
      )
  
      vim.keymap.set(
        "x",
        "<leader>ae",
        ":CodeCompanion /explain<cr>",
        { desc = "AI explain selection", silent = true }
      )
  
      vim.keymap.set(
        "x",
        "<leader>af",
        ":CodeCompanion /fix<cr>",
        { desc = "AI fix selection", silent = true }
      )
    end,
  },

	-- ----------------------------------------------------------
	-- OSC52
	-- ----------------------------------------------------------

	{
		"ojroques/nvim-osc52",
		config = function()
			local osc52 = require("osc52")

			osc52.setup()

			vim.api.nvim_create_autocmd("TextYankPost", {
				group = vim.api.nvim_create_augroup("Osc52Yank", { clear = true }),
				callback = function()
					if vim.v.event.operator ~= "y" then
						return
					end

					local lines = vim.v.event.regcontents

					if type(lines) ~= "table" or vim.tbl_isempty(lines) then
						lines = vim.fn.getreg('"', 1, true)
					end

					local text = table.concat(lines, "\n")

					if text ~= "" then
						osc52.copy(text)
					end
				end,
			})
		end,
	},

	-- ----------------------------------------------------------
	-- Theme
	-- ----------------------------------------------------------

	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "night",
				transparent = false,
			})

			vim.cmd.colorscheme("tokyonight")
		end,
	},

	-- ----------------------------------------------------------
	-- Icons
	-- ----------------------------------------------------------

	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},

	-- ----------------------------------------------------------
	-- Status line
	-- ----------------------------------------------------------

	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					globalstatus = true,
				},
			})
		end,
	},

	-- ----------------------------------------------------------
	-- Which-key
	-- ----------------------------------------------------------

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
	},

	-- ----------------------------------------------------------
	-- File explorer
	-- ----------------------------------------------------------

	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{
				"<leader>e",
				"<cmd>NvimTreeToggle<cr>",
				desc = "Toggle file explorer",
			},
		},
		opts = {
			view = {
				width = 35,
			},
			renderer = {
				group_empty = true,
			},
			filters = {
				dotfiles = false,
			},
		},
	},

	-- ----------------------------------------------------------
	-- Telescope
	-- ----------------------------------------------------------

	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = vim.fn.executable("make") == 1,
			},
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
						},
					},
				},
			})

			pcall(telescope.load_extension, "fzf")

			local builtin = require("telescope.builtin")

			map("n", "<leader>ff", builtin.find_files, {
				desc = "Find files",
			})

			map("n", "<leader>fg", builtin.live_grep, {
				desc = "Search project",
			})

			map("n", "<leader>fb", builtin.buffers, {
				desc = "Find buffers",
			})

			map("n", "<leader>fh", builtin.help_tags, {
				desc = "Search help",
			})

			map("n", "<leader>fr", builtin.oldfiles, {
				desc = "Recent files",
			})

			map("n", "<leader>fd", builtin.diagnostics, {
				desc = "Search diagnostics",
			})
		end,
	},

	-- ----------------------------------------------------------
	-- Treesitter
	--
	-- The classic configuration API is currently kept on the
	-- master branch. This avoids mixing the newer main-branch
	-- design with the familiar configs.setup API.
	-- ----------------------------------------------------------

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
  
    config = function()
      local parsers = {
        "bash",
        "css",
        "dockerfile",
        "gitignore",
        "go",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "regex",
        "sql",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }
  
      -- Expose the list for image/bootstrap installation.
      --vim.g.treesitter_parsers = parsers
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

	-- ----------------------------------------------------------
	-- Git signs
	-- ----------------------------------------------------------

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			current_line_blame = false,
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	-- ----------------------------------------------------------
	-- Comments
	-- ----------------------------------------------------------

	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		opts = {},
	},

	-- ----------------------------------------------------------
	-- Surround text objects
	-- ----------------------------------------------------------

	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		opts = {},
	},

	-- ----------------------------------------------------------
	-- Autopairs
	-- ----------------------------------------------------------

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	-- ----------------------------------------------------------
	-- NvimTree
	-- ----------------------------------------------------------

	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{
				"<leader>e",
				"<cmd>NvimTreeToggle<cr>",
				desc = "Toggle file explorer",
			},
		},
		opts = {
			view = {
				width = 35,
			},
			renderer = {
				group_empty = true,
			},
			filters = {
				dotfiles = false,
			},
		},
	},

	-- ----------------------------------------------------------
	-- Mason
	-- ----------------------------------------------------------

	{
    "mason-org/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {},
	},

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      automatic_enable = true,
    },
  },
  
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "bash-language-server",
        "clangd",
        "css-lsp",
        "dockerfile-language-server",
        "gopls",
        "html-lsp",
        "json-lsp",
        "lua-language-server",
        "marksman",
        "sqls",
        "typescript-language-server",
        "yaml-language-server",
        "stylua",
        "prettierd",
        "prettier",
        "shfmt",
        "goimports",
        "gofumpt",
      },
      run_on_start = true,
      start_delay = 3000,
    },
  },

	-- ----------------------------------------------------------
	-- LSP configurations
	-- ----------------------------------------------------------

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.config("*", {
				capabilities = capabilities,
			})

      vim.lsp.config("sqls", {
        settings = {
          sqls = {},
        },
      })

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						telemetry = {
							enable = false,
						},
					},
				},
			})

			-- LSP keymaps are created only when an LSP attaches.
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(event)
					local opts = {
						buffer = event.buf,
						silent = true,
					}

					map(
						"n",
						"gd",
						vim.lsp.buf.definition,
						vim.tbl_extend("force", opts, {
							desc = "Go to definition",
						})
					)

					map(
						"n",
						"gD",
						vim.lsp.buf.declaration,
						vim.tbl_extend("force", opts, {
							desc = "Go to declaration",
						})
					)

					map(
						"n",
						"gr",
						vim.lsp.buf.references,
						vim.tbl_extend("force", opts, {
							desc = "Find references",
						})
					)

					map(
						"n",
						"gi",
						vim.lsp.buf.implementation,
						vim.tbl_extend("force", opts, {
							desc = "Go to implementation",
						})
					)

					map(
						"n",
						"K",
						vim.lsp.buf.hover,
						vim.tbl_extend("force", opts, {
							desc = "Hover documentation",
						})
					)

					map(
						"n",
						"<C-k>",
						vim.lsp.buf.signature_help,
						vim.tbl_extend("force", opts, {
							desc = "Signature help",
						})
					)

					map(
						"n",
						"<leader>rn",
						vim.lsp.buf.rename,
						vim.tbl_extend("force", opts, {
							desc = "Rename symbol",
						})
					)

					map(
						{ "n", "v" },
						"<leader>ca",
						vim.lsp.buf.code_action,
						vim.tbl_extend("force", opts, {
							desc = "Code action",
						})
					)

					map(
						"n",
						"<leader>wa",
						vim.lsp.buf.add_workspace_folder,
						vim.tbl_extend("force", opts, {
							desc = "Add workspace folder",
						})
					)

					map(
						"n",
						"<leader>wr",
						vim.lsp.buf.remove_workspace_folder,
						vim.tbl_extend("force", opts, {
							desc = "Remove workspace folder",
						})
					)
				end,
			})
		end,
	},

	-- ----------------------------------------------------------
	-- Completion
	-- ----------------------------------------------------------

	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",

			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),

					["<C-e>"] = cmp.mapping.abort(),

					["<CR>"] = cmp.mapping.confirm({
						select = true,
					}),

					["<C-j>"] = cmp.mapping.select_next_item(),

					["<C-k>"] = cmp.mapping.select_prev_item(),

					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
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
				}),

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),
			})

			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})

			local ok, autopairs_cmp = pcall(require, "nvim-autopairs.completion.cmp")

			if ok then
				cmp.event:on("confirm_done", autopairs_cmp.on_confirm_done())
			end
		end,
	},

	-- ----------------------------------------------------------
	-- Formatting
	-- ----------------------------------------------------------

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({
						async = true,
						lsp_format = "fallback",
					})
				end,
				mode = { "n", "v" },
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				jsonc = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				markdown = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				go = { "goimports", "gofmt" },
				sh = { "shfmt" },
			},

			default_format_opts = {
				lsp_format = "fallback",
			},

			--format_on_save = {
			--	timeout_ms = 1000,
			--	lsp_format = "fallback",
			--},
		},
	},


	-- ----------------------------------------------------------
	-- Diagnostics list
	-- ----------------------------------------------------------

	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Project diagnostics",
			},
			{
				"<leader>xb",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer diagnostics",
			},
			{
				"<leader>xs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Document symbols",
			},
		},
		opts = {},
	},
}, {
	checker = {
		enabled = true,
		notify = false,
	},

	change_detection = {
		notify = false,
	},
})

-- ============================================================
-- Diagnostics
-- ============================================================

vim.diagnostic.config({
	virtual_text = {
		spacing = 2,
		prefix = "●",
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
	},
})

map("n", "[d", function()
	vim.diagnostic.jump({
		count = -1,
		float = true,
	})
end, {
	desc = "Previous diagnostic",
})

map("n", "]d", function()
	vim.diagnostic.jump({
		count = 1,
		float = true,
	})
end, {
	desc = "Next diagnostic",
})

map("n", "<leader>d", vim.diagnostic.open_float, {
	desc = "Show diagnostic",
})

-- Rounded LSP windows
local original_open_floating_preview = vim.lsp.util.open_floating_preview

vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "rounded"

	return original_open_floating_preview(contents, syntax, opts, ...)
end
