{ pkgs, ...}: {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      withNodeJs = true;
      waylandSupport = true;
      withPython3 = true;
      plugins = with pkgs.vimPlugins; [
        vim-wakatime
        yazi-nvim
        neogit
        fzf-lua
        mini-icons
        bufferline-nvim
        nvim-tree-lua
        onenord-nvim
        indent-blankline-nvim
        (pkgs.vimUtils.buildVimPlugin { # if you're trying to build this please comment this out, this is not intended to be for public use yet ;)
          name = "skript-syntax-highlighting";
          src = builtins.path {
            path = ./skript-syntax-highlighting;
            name = "skript-syntax-highlighting";
          };
        })
        (pkgs.vimUtils.buildVimPlugin { # Jabs
          pname = "jabs.nvim";
          version = "1.0";
          src = pkgs.fetchFromGitHub {
            owner = "matbme";
            repo = "JABS.nvim";
            rev = "main";
            hash = "sha256-5ZH/ZH9r6GHWAMu2iwdedbh8+xUM/XIYSNf+E8kwFro=";
          };
        })
      ];
      coc = {
        enable = false;
        settings = {
          "coc.preferences.enableMessageDialog" = true;
        };
      };
      initLua = ''
	  vim.opt.laststatus = 0
	  vim.opt.number = true
	  vim.opt.ruler = false
	  vim.opt.cmdheight = 0
    vim.o.guifont = "Iosevka Nerd Font Mono:h14"
    vim.o.termguicolors = true

	  require('onenord').setup({
	    theme = "dark",
	    styles = {
	      comments = "NONE",
	      strings = "NONE",
	      keywords = "NONE",
	      functions = "NONE",
	      variables = "NONE",
	      diagnostics = "underline",
	    },
	    disable = {
	      background = false,
	      float_background = true,
	      cursorline = false,
	      eob_lines = false,
	    },
	    inverse = {
	      match_paren = false,
	    },
	    custom_highlights = {},
	    custom_colors = {},
	  })

	  require("ibl").setup()

	  require('mini.icons').setup()
	  vim.opt.clipboard = "unnamedplus"

	  -- fzf-lua
	  require("fzf-lua").setup({
	    oldfiles = {
	      include_current_session = true,
	    },
	  })
	  vim.keymap.set("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Recent files" })
	  vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Open buffers" })

	  -- nvim-tree
	  require("nvim-tree").setup({
	    view = { width = 30 },
	    actions = { open_file = { quit_on_open = false } },
	  })
	  vim.keymap.set("n", "<C-b>", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle tree" })

	  -- bufferline
	  require("bufferline").setup({
	    options = {
	      offsets = {
		{ filetype = "NvimTree", text = "Files", separator = true },
	      },
	      sort_by = "insert_after_current",
	    },
	  })

	  -- leader (must be set before any leader keymaps below)
	  vim.g.mapleader = " "

	  -- jabs
	  require("jabs").setup({
	    position = { "center", "center" },
	    relative = "editor",
	    width = 60,
	    height = 15,
	    border = "rounded",
	    sort_mru = true,
	    split_filename = true,
	    split_filename_path_width = 30,
	    keymap = {
	      jump = "<Space>",
	      close = "d",
	      h_split = "s",
	      v_split = "v",
	      preview = "P",
	    },
	    highlight = {
	      current = "JABSCurrentBuffer",
	      hidden = "JABSHidden",
	      split = "JABSSplit",
	      alternate = "JABSAlternate",
	    },
	  })
	  vim.keymap.set("n", "<C-Tab>", "<cmd>JABSOpen<cr>", { desc = "Buffer switcher" })
	  vim.keymap.set("n", "<C-S-Tab>", "<cmd>JABSOpen<cr>", { desc = "Buffer switcher" })
	  vim.keymap.set("n", "<A-Tab>", "<C-^>", { desc = "Toggle last buffer" })

	  -- TODO CLEAN THIS UP ITS SO MESSY
	  local function load_code_workspace()
	    local cwd = vim.fn.getcwd()
	    local matches = vim.fn.glob(cwd .. "/*.code-workspace", false, true)
	    if #matches == 0 then
	      return
	    end

	    local file = matches[1]
	    local content = vim.fn.readfile(file)
	    local ok, parsed = pcall(vim.json.decode, table.concat(content, "\n"))
	    if not ok or not parsed.folders then
	      return
	    end

	    local base = vim.fn.fnamemodify(file, ":h")
	    local folders = {}
	    for _, f in ipairs(parsed.folders) do
	      local path = f.path
	      if path == "." then
		path = base
	      elseif not path:match("^/") then
		path = base .. "/" .. path
	      end
	      table.insert(folders, vim.fn.fnamemodify(path, ":p"))
	    end

	    -- Store roots so we can cycle through them
	    _G.workspace_roots = folders
	    _G.workspace_index = 1

	    -- Start with the first root
	    vim.cmd("cd " .. vim.fn.fnameescape(folders[1]))
	    require("nvim-tree.api").tree.change_root(folders[1])
	    vim.cmd("NvimTreeOpen")
	  end

	  local function cycle_workspace_root()
	    if not _G.workspace_roots or #_G.workspace_roots == 0 then
	      return
	    end
	    _G.workspace_index = (_G.workspace_index % #_G.workspace_roots) + 1
	    local folder = _G.workspace_roots[_G.workspace_index]
	    vim.cmd("cd " .. vim.fn.fnameescape(folder))
	    require("nvim-tree.api").tree.change_root(folder)
	  end

	  vim.api.nvim_create_user_command("Workspace", load_code_workspace, {})
	  vim.keymap.set("n", "<leader>ws", cycle_workspace_root, { desc = "Cycle workspace root" })

	  -- Auto-load on startup if a .code-workspace exists
	  vim.api.nvim_create_autocmd("VimEnter", {
	    callback = function()
	      local matches = vim.fn.glob(vim.fn.getcwd() .. "/*.code-workspace", false, true)
	      if #matches > 0 then
		load_code_workspace()
	      end
	    end,
	  })

			-- Buffer save scroll position
			vim.api.nvim_create_autocmd("BufLeave", {
				callback = function()
					vim.b.winview = vim.fn.winsaveview()
				end,
			})
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function()
					if vim.b.winview then
						vim.fn.winrestview(vim.b.winview)
					end
				end,
			})

	  vim.filetype.add({ extension = { sk = "skript" } })

	  -- :Project command
	  local projects_dir = "/home/alec/Projects"

	  vim.api.nvim_create_user_command("Project", function(opts)
	  local input = opts.args
	  local path
	  if input:match("^/") or input:match("^~") then
	    path = vim.fn.expand(input)
	  else
	    path = projects_dir .. "/" .. input
	  end

	  if vim.fn.isdirectory(path) == 0 then
	    return
	  end

	  vim.cmd("cd " .. vim.fn.fnameescape(path))

	  local api = require("nvim-tree.api")
	  api.tree.change_root(path)
	  api.tree.open()  -- ensure tree is visible
	  -- Auto-load workspace if present
	  local matches = vim.fn.glob(path .. "/*.code-workspace", false, true)
	  if #matches > 0 then
	    vim.cmd("Workspace")
	  end
	end, {
	  nargs = 1,
	  complete = function(arg_lead)
	    local results = {}
	    local entries = vim.fn.readdir(projects_dir)
	    for _, entry in ipairs(entries) do
	      if vim.fn.isdirectory(projects_dir .. "/" .. entry) == 1 then
		if entry:lower():find(arg_lead:lower(), 1, true) then
		  table.insert(results, entry)
		end
	      end
	    end
	    return results
	  end,
	})
	vim.cmd([[cnoreabbrev P Project]])
	vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>silent write<cr>", { desc = "Save file" })
	'';
    };
    neovide = {
      enable = true;
      settings = {
        maximized = true;
        no-multigrid = true;
      };
    };
  };
}
