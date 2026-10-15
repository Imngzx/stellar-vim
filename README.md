# 🌠 Stellar:Vim - Speed and Modern

> [!NOTE]
> This is a fork of the original [author's](https://github.com/cworld1/nvim-config) config. His config is the bone of my config. So please have a look on his config too.

> [!WARNING]
> This configuration only runs on nvim nightly 0.13, also AI involved during development

## About

This repository hosts my [NeoVim](https://neovim.io/) configuration for my daily life. Can't live without it :(

Use this on **Linux** for best experience ฅ₍^•⩊ •マⳊ

![Preview image](https://github.com/user-attachments/assets/9a469134-1fb6-4be4-b310-510057dea321)

| ![Preview image](https://github.com/user-attachments/assets/d320b9b2-b3d1-479d-a092-96c5b6d3fa59) | ![Preview image](https://github.com/user-attachments/assets/dcd7d37b-3443-4fd0-9a0e-8512d927f1e5) |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |

| ![Preview image](https://github.com/user-attachments/assets/75fd8e84-747e-4c48-93d1-0154aa0b94a7) | ![Preview image](https://github.com/user-attachments/assets/6c84841c-fb4f-4a1d-a34d-85528bec0cb5) |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |

| ![Discord Presence](https://github.com/user-attachments/assets/2f496144-e675-4558-8bd6-bbc80e9e025f) | ![Preview image](https://github.com/user-attachments/assets/e4825e61-861c-4641-a3d9-b1a3d1074ab9) |
| ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |

## Features

### Summarization

- **Fast.** Less than **30ms** to start, **tested on i7-7700hq.**
- **Simple.** Less plugins, more features.
- **Modern.** Pure `lua` config.
- **Modular.** Easy for maintenance.
- **Unstable.** Stable config will ruins dev experience.
- **Powerful.** Near full functionality to code, supports cjk.
- **Beautiful.** Author really puts effort on it's UI.
- **Minimalist.** Plugins(DIY) with snacks integration.
- **Performance.** FFI, luaJIT syntax, C-API and etc are involved.

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
- `wl-clipboard` on **Linux**
- `ripgrep`
- `fd`
- `yazi`
- `lazygit`
- `python`
- `pandoc` for markdown rendering in browser `<leader>cz`
- `fcitx5` on **Linux**
- `im-select` for **WSL**
- `tdlib`, `npm`, `kitty`||`ghostty` on **Linux** and **MacOS**, for [**ChuYanLon/telegram.nvim**](https://github.com/ChuYanLon/telegram.nvim)
- `tectonic` on **Linux** and **MacOS**, optional for latex rendering
- `vim-startuptime,` optional
- `kitty`||`ghostty` on **Linux** and **MacOS**, for image support

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

### Config Managing

As you can see there's a python script in this config, this is still experimental but I hope it helps.

```bash

# use these at your own risk, feel free to make issues and pr
python3 scripts.py update                     # Git pull --rebase --autostash
python3 scripts.py clean --force              # Remove plugins (site/pack/core)
python3 scripts.py both --force               # Update + clean
python3 scripts.py uninstall --force --force  # FULL UNINSTALL (double --force for safety)

```

## Project Structure

- `init.lua`: entry point
- `lua/config`: basic settings
- `lua/custom`: custom tools & features, gems happens here
- `lua/libs`: shared libraries
- `lua/lsp/init.lua`: simple lsp configurations
- `lua/lsp/servers.lua` & `lua/lsp/servers/*.lua`: LSP installation & configuration for separate languages
- `lua/plugins`: plugin configurations
- `lua/plugins/<plugin_name>/`: plugin configurations (**BIG**)

## Contributions

As the author is only a beginner in learning it, there are obvious mistakes in his notes. Readers are also invited to make a lot of mistakes. In addition, you are welcome to use PR or Issues to improve them.

## License

This project is licensed under the Apache 2.0 License.
