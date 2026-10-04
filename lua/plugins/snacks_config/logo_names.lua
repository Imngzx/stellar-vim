local M = {}

local default = require('plugins.snacks_config.logos.neovim_default')
local stellarvim = require('plugins.snacks_config.logos.stellarvim_default')
local minato_aqua = require('plugins.snacks_config.logos.minato_aqua')
local pekora = require('plugins.snacks_config.logos.pekora')
local ayanami = require('plugins.snacks_config.logos.ayanami_rei')
local doom = require('plugins.snacks_config.logos.doom')
local nerv = require('plugins.snacks_config.logos.nerv')
local miku = require('plugins.snacks_config.logos.miku')

-- Stellar:Vim defaults
M.StellarVim_default = stellarvim.logo

-- Neovim
M.Neovim_Default = default.Neovim_Default
M.Neovim_Block = default.Neovim_Block
M.Neovim_Dos_Rebel = default.Neovim_Dos_Rebel
M.Neovim_Rowan_Cap = default.Neovim_Rowan_Cap
M.Neovim_Isometric = default.Neovim_Isometric
M.Neovim_Ogre = default.Neovim_Ogre
M.Neovim_Slant_Relief = default.Neovim_Slant_Relief
M.Neovim_Bloody = default.Neovim_Bloody
M.Neovim_Delta_Corps = default.Neovim_Delta_Corps
M.Neovim_Elite = default.Neovim_Elite
M.Neovim_The_Edge = default.Neovim_The_Edge
M.Neovim_Banner3 = default.Neovim_Banner3
M.Neovim_Colossal = default.Neovim_Colossal
M.Neovim_Decimal = default.Neovim_Decimal
M.Neovim_Def_Leppard = default.Neovim_Def_Leppard
M.Neovim_Larry_3D = default.Neovim_Larry_3D
M.Neovim_Lean = default.Neovim_Lean
M.Neovim_Morse = default.Neovim_Morse
M.Neovim_Sharp = default.Neovim_Sharp

-- Anime characters
M.Minato_Aqua = minato_aqua.logo
M.Pekora = pekora.logo
M.Ayanami_Rei_1 = ayanami.Ayanami_Rei_1
M.Ayanami_Rei_2 = ayanami.Ayanami_Rei_2
M.Miku_1 = miku.miku_1
M.Miku_2 = miku.miku_2
M.Miku_3 = miku.miku_3
M.Miku_4 = miku.miku_4
M.Miku_5 = miku.miku_5
M.miku_6 = miku.miku_6
M.miku_7 = miku.miku_7
M.miku_8 = miku.miku_8
M.miku_9 = miku.miku_9
M.miku_10 = miku.miku_10

-- Doom
M.Doom = doom.DooM
M.Doom_graffiti = doom.MF_DooM_graffiti
M.Doom_RIP = doom.MF_DooM_rip
M.NERV = nerv.NERV

return M
