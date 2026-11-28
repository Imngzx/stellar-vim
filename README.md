# 🌠 Stellar:Vim - Speed and Modern

> [!NOTE]
> This is a fork of the original [author's](https://github.com/cworld1/nvim-config) config. His config is the bone of my config. So please have a look on his config too.

> [!WARNING]
> This configuration only runs on nvim nightly 0.13, also AI involved during development

## About

This repository hosts my [NeoVim](https://neovim.io/) configuration for my daily life. Can't live without it :(

Use this on **Linux** for best experience ฅ₍^•⩊ •マⳊ

<https://github.com/user-attachments/assets/47e870a8-48a5-4d85-a613-c9dcf9103ba2>

![Preview image](https://github.com/user-attachments/assets/9a469134-1fb6-4be4-b310-510057dea321)

| ![Preview image](https://github.com/user-attachments/assets/d320b9b2-b3d1-479d-a092-96c5b6d3fa59) | ![Preview image](https://github.com/user-attachments/assets/dcd7d37b-3443-4fd0-9a0e-8512d927f1e5) |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |

| ![Preview image](https://github.com/user-attachments/assets/75fd8e84-747e-4c48-93d1-0154aa0b94a7) | ![Preview image](https://github.com/user-attachments/assets/6c84841c-fb4f-4a1d-a34d-85528bec0cb5) |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |

| ![Discord Presence](https://github.com/user-attachments/assets/2f496144-e675-4558-8bd6-bbc80e9e025f) | ![Preview image](https://github.com/user-attachments/assets/e4825e61-861c-4641-a3d9-b1a3d1074ab9) |
| ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |

## Features

### Summarization

- **Speed.** Less than **30ms** to start, **tested on i7-7700hq.**
- **Simple.** LSP configuration design is very human
- **Modern.** **Only** runs on `nightly 0.13` version.
- **Modular.** Easy for maintenance.
- **Unstable.** _Stable configuration_ will **RUINS** the dev experience.
- **Powerful.** Full functionality to code, supports cjk.
- **Beautiful.** Author really puts effort on it's UI.
- **Minimalist.** Less plugins but more features.
- **Intelligence.** Code completion knew what to suggest next
- **Performance.** Heavy optimizations are involved.

### Remarkable Recent Improvements

![Preview image](https://github.com/user-attachments/assets/ee38211b-9b58-4b4d-890f-ea82bc7f783f)

Made LSP configuration and installation more effortless by making it declarative and unified.

- `lua/lsp/servers.lua` handles LSP installation and registering.
- `lua/lsp/servers/*.lua` handles custom LSP configuration. W/o this, it will revert back to [nvim-lspconfig's](https://github.com/neovim/nvim-lspconfig) default config
- `lua/lsp/init.lua` the **BOSS** behind this LSP configuration system.

### Remarkable Plugin

![Preview image](https://github.com/user-attachments/assets/12148776-0d18-4a3f-b893-427aaca43333)

This plugin called [jisho.nvim](https://github.com/Imngzx/jisho.nvim). This can be triggered by pressing `<leader>tj`. It's main purpose is to **use** [jisho's API](https://jisho.org) inside NeoVim, and give access to users for searching words in Japanese or English.

### What Makes This Configuration Interesting?

![Preview image](https://github.com/user-attachments/assets/1283e31e-6dc3-47c2-99ae-7a0781bc117c)

| ![Preview image](https://github.com/user-attachments/assets/23a32d87-acce-4918-a23a-933225b84843) | ![Preview image](https://github.com/user-attachments/assets/a7221cce-8d9f-43b0-8cbf-411e3689b8ed) |
| -------------- | --------------- |

Yes, you're right. It's power mode detection and dual picker config!

#### Cause of this feature exists in my config

In my use case, frame drops are often happened here when power-saver mode is enabled.
But fzf-lua didn't have any frame drops.
So I use fzf-lua instead of snacks during power-saver mode.

## Extras

- List of features that became **Pluginless**
  - [x] [incline.nvim](https://github.com/b0o/incline.nvim)
  - [x] [vim-suda](https://github.com/lambdalisue/vim-suda)
  - [x] [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
  - [x] [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
  - [x] [todo-comments](https://github.com/folke/todo-comments.nvim) (Key: `<Leader>st`)
  - [x] [fidget.nvim](https://github.com/j-hui/fidget.nvim)
  - [x] [mini.surround](https://github.com/nvim-mini/mini.surround)
  - [x] [mini.pairs](https://github.com/nvim-mini/mini.pairs)
  - [x] [aerial.nvim](https://github.com/stevearc/aerial.nvim) (Key: `<Leader>co`)
  - [x] [trouble.nvim](https://github.com/folke/trouble.nvim) (Key: `<Leader>cD`)
  - [x] [yazi.nvim](https://github.com/mikavilpas/yazi.nvim) (Key: `<Leader>fy`)
  - [x] [git-blame.nvim](https://github.com/f-person/git-blame.nvim.git) (Key: `<Leader>uB`)
  - [x] [persistence.nvim](https://github.com/folke/persistence.nvim)
  - [x] [im-select.nvim](https://github.com/keaising/im-select.nvim)
  - [x] [dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim)

- List of self made plugins:
  - [x] [**Resonance.nvim**](https://github.com/Imngzx/resonance.nvim)
  - [x] [jisho.nvim](https://github.com/Imngzx/jisho.nvim)
  - [x] [ascetic.nvim](https://github.com/Imngzx/ascetic.nvim)

- List of self modded plugins:
  - [x] [showkeys](https://github.com/Imngzx/showkeys)

> [!TIP]
> Can test launch speed with:

```sh
~
❯ nvim --startuptime nvim_speed.log +q && nvim nvim_speed.log

# or

~
❯ go install github.com/rhysd/vim-startuptime@latest
# then
~
❯ vim-startuptime -vimpath nvim -warmup 3 -count 200
# or treat it as config2
❯ NVIM_APPNAME=stellar-vim vim-startuptime -vimpath nvim -warmup 3 -count 200

# or

~
❯ PROF=1 nvim

#NOTE: if you on windows, please:
❯ $env:PROF="1"; nvim # for pwsh

❯ set PROF=1 && nvim # for cmd
```

## Info

- Supported nvim version: `0.13 nightly`
- Plugin manager: `resonance.nvim`, a `vim.pack` wrapper
- Language server protocol: `nvim-lspconfig`
- Leader key: `Space`
- Default LSP for Lua-language: `lua_ls`

> [!NOTE]
> If you want to see the file structure of my config, please use `tree` in terminal

## Installation

### Making sure you've **installed**

- [NeoVim-nightly 0.13 latest commit](https://github.com/neovim/neovim/releases/nightly) (can be installed via bob)
- `git`
- `tree-sitter-cli`
- `gcc`
- `make`, for plugins that build themselves (e.g. `flash-any.nvim`)
- `curl`, `unzip`, `tar`, `gzip`, used by Mason to install LSP servers and tools
- `node` + `npm`, for Mason's JS-based servers and `telegram.nvim`
- `yarn`, for `markdown-preview.nvim` (browser preview)
- `wl-clipboard` on **Linux**
- `ripgrep`
- `inotify-tools`
- `fd`
- `yazi`
- `lazygit`
- `python`
- `pandoc` for pasting rich text as markdown `<leader>cp` (browser preview on `<leader>cz` uses `mpls`, installed via Mason)
- `fcitx5` on **Linux**
- `im-select` for **WSL**
- `tdlib`, `npm`, `kitty`||`ghostty` on **Linux** and **MacOS**, for [**ChuYanLon/telegram.nvim**](https://github.com/ChuYanLon/telegram.nvim)
- `tectonic` on **Linux** and **MacOS**, optional for latex rendering
- `clice` as LSP for C and CPP
- `vim-startuptime,` optional
- `kitty`||`ghostty` on **Linux** and **MacOS**, for image support
- `gpg`, optional, lets Neogit verify signed commits

### How To Install System Dependencies?

#### **How to install tdlib? (On Linux)**

```fish

~ 23s
❯ cd /tmp

/tmp
❯ git clone https://github.com/tdlib/td.git
  cd td
  mkdir build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=~/.local \
          -DCMAKE_CXX_FLAGS="-O2 -g0" \
          ..
  cmake --build . --target install -j$(nproc)

```

#### How to install im-select?

1. Open powershell, then:

```sh
# If you're a normal user:
~
❯ Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# or

# If you're administrator, use this workaround:
~
❯ irm get.scoop.sh -outfile 'install.ps1'
  .\install.ps1 -RunAsAdmin [-OtherParameters ...]


# then restart terminal
 
##################################

~
❯ scoop install git 
  scoop bucket add im-select https://github.com/daipeihust/im-select
  scoop update

  # 2. Install the im-select package
  scoop install im-select

```

#### How To Install clice? (for education usage)

```sh
~
❯ cd ~/.local/bin/

# get the installation link for clice in the github release page
~/.local/bin
❯ curl -L -o ~/.local/bin/clice.tar.gz https://github.com/clice-io/clice/releases/download/v0.1.2026101607/clice-0.1.2026101607.x86_64-unknown-linux-gnu.tar.gz
  % Total    % Received % Xferd  Average Speed  Time    Time    Time   Current
                                 Dload  Upload  Total   Spent   Left   Speed
  0      0   0      0   0      0      0      0                              0
100 24.50M 100 24.50M   0      0 35.22M      0                              0

~/.local/bin
❯ tar -xvf clice-0.1.2026101607.x86_64-unknown-linux-gnu.tar.gz

# it's gonna be sooo many dialogues later, dun worry

~/.local/bin
❯ sudo mv clice/bin/clice /usr/local/bin/clice
[sudo] password for alice:


# verify installation
~/.local/bin
❯ clice
A C++ development toolkit built on LLVM/Clang

Subcommands:
  serve       Start LSP server
  query       Ask the persisted index about the workspace
  refactor    Rewrite the workspace's sources through the persisted index
  index       Index a workspace ahead of time
  lint        Lint C++ source files
  format      Format C++ source files
  inspect     Run a feature on a source file and print raw results as JSON
  scan        Scan the project's include and module dependencies
  analyze     Analyze the indexed workspace for refactoring
  modularize  Wrap a partition's libraries as modules over their headers, rewrite its program modules into module units, or merge the wrappings of several build configurations

# verify installation
~/.local/bin
❯ which clice
/usr/local/bin/clice

~/.local/bin
❯ rm -rf  clice/ clice.tar.gz

```

### Config Installation

_For Windows:_

```bash
git clone https://github.com/Imngzx/stellar-vim.git "${env:LOCALAPPDATA}\nvim"
nvim
```

_For \*nix:_

```bash
git clone https://github.com/Imngzx/stellar-vim.git $XDG_CONFIG_HOME/nvim
nvim
```

After steps above, please `<Leader>pm` or `:Mason` to open Mason panel, it'll handle auto install as soon as you open it.

Then please having fun!

### Adding Plugins

Plugins are **auto-imported**, the same idea as lazy.nvim's `import`. You
never edit a plugin list: drop a file into `lua/plugins/` that **returns** its
spec, restart, and resonance.nvim installs and lazy-loads it.

```lua
-- lua/plugins/jisho.lua
return {
  'https://github.com/Imngzx/jisho.nvim',            -- full URL, not 'author/plugin'
  dependencies = { 'https://github.com/atusy/budoux.lua' },
  cmd = { 'Jisho' },                                 -- lazy trigger: event / cmd / keys / ft
  config = function()
    require('jisho').setup({ layout = 'spacious' })
  end,
}
```

A file can also return a list of specs `return { { ... }, { ... } }` (see
`lua/plugins/core/ui.lua`).

| Put the file in | Loaded | For |
|---|---|---|
| `lua/plugins/` | after startup (`VeryLazy`) | almost everything |
| `lua/plugins/core/` | at startup, highest `priority` first | theme and core UI only |

- **Disable a plugin:** add `cond = false` to its spec (or a function, e.g.
  `cond = require('libs.power').is_ac` to load it only on AC power). Don't
  delete the file.
- **Big configs:** use a folder with an `init.lua` that returns the spec
  (`lua/plugins/heirline/`); other files in that folder are just helpers.
- **Remove a plugin:** delete its file, then `:Resonance` (`<leader>pL`) to
  see what's still installed.
- More details: [`note/knowledge/resonance.md`](note/knowledge/resonance.md).

### Config Managing

As you can see there's a python script in this config, this is still experimental but I hope it helps.

```bash

# use these at your own risk, feel free to make issues and pr
python3 scripts.py update                     # Git pull --rebase --autostash
python3 scripts.py clean --force              # Remove plugins (site/pack) & resonance state
python3 scripts.py both --force               # Update + clean
python3 scripts.py uninstall --force --force  # FULL UNINSTALL (double --force for safety)

```

## Project Structure

- `init.lua`: entry point
- `lua/config/`: basic settings
- `lua/custom/`: custom tools & features, gems happens here
- `lua/libs/`: shared libraries
- `lua/lsp/servers.lua` & `lua/lsp/servers/*.lua`: LSP installation & configuration for separate languages
- `lua/plugins/`: plugin specs, one file each, auto-imported after startup
- `lua/plugins/core/`: theme & core UI specs, imported at startup
- `lua/plugins/<plugin_name>/`: plugin configurations (**BIG**, entry is `init.lua`)

## Contributions

As the author is only a beginner in learning it, there are obvious mistakes in his notes. Readers are also invited to make a lot of mistakes. In addition, you are welcome to use PR or Issues to improve them.

## License

This project is licensed under the Apache 2.0 License.
