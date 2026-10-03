# 🌠 Stellar:Vim - Speed and Modern

> [!NOTE]
> This is a fork of the original [author's](https://github.com/cworld1/nvim-config) config. His config is the bone of my config. So please have a look on his config too.

> [!WARNING]
> This configuration is only for nvim nightly 0.13

## About

This repository hosts my [NeoVim](https://neovim.io/) configuration for Desktop environment.

Use this on Linux for best experience ฅ₍^•⩊ •マⳊ

![Preview image](https://github.com/user-attachments/assets/9a469134-1fb6-4be4-b310-510057dea321)

| ![Preview image](https://github.com/user-attachments/assets/d320b9b2-b3d1-479d-a092-96c5b6d3fa59) | ![Preview image](https://github.com/user-attachments/assets/dcd7d37b-3443-4fd0-9a0e-8512d927f1e5) |
| --------------------------------------------------------- | --------------------------------------------------------- |

| ![Preview image](https://github.com/user-attachments/assets/75fd8e84-747e-4c48-93d1-0154aa0b94a7) | ![Preview image](https://github.com/user-attachments/assets/6c84841c-fb4f-4a1d-a34d-85528bec0cb5) |
| --------------------------------------------------------- | --------------------------------------------------------- |

![Discord Presence](https://github.com/user-attachments/assets/2f496144-e675-4558-8bd6-bbc80e9e025f)

## Features

### Summarization

- **Fast.** Less than **30ms** to start, say no to heavy plugins for ui only
- **Simple.** Run out of the box with only less plugins.
- **Modern.** Pure `lua` config.
- **Modular.** Easy to customize.
- **Powerful.** Near full functionality to code, supports cjk.
- **Beautiful.** Author really puts effort on TUI.
- **Minimalist.** Plugins(DIY) with snacks integration.

### Extras

- List of features that became **Pluginless**
  - [x] [incline.nvim](https://github.com/b0o/incline.nvim)
  - [x] [vim-suda](https://github.com/lambdalisue/vim-suda)
  - [x] [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
  - [x] [todo-comments](https://github.com/folke/todo-comments.nvim) (Key: `<Leader>st`)
  - [x] [fidget.nvim](https://github.com/j-hui/fidget.nvim)
  - [x] [mini.surround](https://github.com/nvim-mini/mini.surround)
  - [x] [mini.pairs](https://github.com/nvim-mini/mini.pairs?tab=readme-ov-file)
  - [x] [aerial.nvim](https://github.com/stevearc/aerial.nvim) (Key: `<Leader>co`)
  - [x] [trouble.nvim](https://github.com/folke/trouble.nvim) (Key: `<Leader>cD`)
  - [x] [yazi.nvim](https://github.com/mikavilpas/yazi.nvim) (Key: `<Leader>fy`)
  - [x] [git-blame.nvim](https://github.com/f-person/git-blame.nvim.git) (Key: `<Leader>uB`)
  - [x] [persistence.nvim](https://github.com/folke/persistence.nvim)
  - [x] [im-select.nvim](https://github.com/keaising/im-select.nvim)
  - [x] [dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim)

- List of self made plugins:
  - [x] [jisho.nvim](https://github.com/Imngzx/jisho.nvim)
  - [x] [ascetic.nvim](https://github.com/Imngzx/ascetic.nvim)
  - [x] [Powered by **Resonance.nvim**](https://github.com/Imngzx/resonance.nvim)

> [!TIP]
> Can test launch speed with:

```sh
❯ nvim --startuptime nvim_speed.log +q && nvim nvim_speed.log
# or
❯ PROF=1 nvim 

#NOTE: if you on windows, please:
❯ $env:PROF="1"; nvim # for pwsh

❯ set PROF=1 && nvim # for cmd
```

## Info

- Supported nvim version: `0.13 nightly`
- Plugin manager: `vim.pack`
- Language server protocol: `nvim-lspconfig`
- Leader key: `Space`
- Default LSP for Lua-language: `lua_ls`

> [!NOTE]
> If you want to see the file structure of my config, please use `tree` in terminal

## Installation

Making sure you've installed [NeoVim-nightly 0.13](https://github.com/neovim/neovim/releases/nightly), tree-sitter-cli-git, and GCC on both Windows and Linux.

> [!TIP]
> Install tectonic for latex rendering, it is supported in this config

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

After those steps above, please `<Leader>pm` to open Mason panel, it'll handle auto install as soon as you open it.

Then please having fun!

## Project Structure

- `lua/config`: basic settings
- `lua/custom`: custom tools & functions
- `lua/libs`: shared libraries
- `lua/lsp`: LSP configuration for separate languages
- `lua/plugins`: plugin configurations
- `lua/lsp/init.lua`: simple lsp configurations
- `init.lua`: entry point

## Contributions

As the author is only a beginner in learning it, there are obvious mistakes in his notes. Readers are also invited to make a lot of mistakes. In addition, you are welcome to use PR or Issues to improve them.

## License

This project is licensed under the Apache 2.0 License.
