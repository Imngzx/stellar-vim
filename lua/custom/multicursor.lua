local M = {}

local api = vim.api

local ns_mc
local mcursor

---@return boolean
local function mcursor_active()
  return mcursor.active()
end

---@return table
local function get_matches()
  local total = vim.fn.searchcount({ maxcount = 0 }).total
  return { total = total }
end

---@param word string
---@return string
local function escape_search(word)
  return vim.fn.escape(word, '\\')
end

local function multicursor_all_matches()
  if get_matches().total == 0 then
    vim.notify('No search pattern set', vim.log.levels.WARN)
    return
  end
  vim.cmd('normal! zqgn')
end

local function multicursor_word_under_cursor()
  local word = vim.fn.expand('<cword>')
  if word == '' then
    return
  end
  vim.fn.setreg('/', '\\V' .. escape_search(word))
  vim.opt.hlsearch = true
  vim.cmd('normal! zqgn')
end

local function multicursor_visual_matches()
  vim.cmd('normal! zqgn')
end

local function clear_multicursors()
  if mcursor_active() then
    api.nvim_buf_clear_namespace(0, ns_mc, 0, -1)
    vim.notify('Multicursors cleared', vim.log.levels.INFO)
  else
    vim.notify('No active multicursors', vim.log.levels.INFO)
  end
end

local function restore_multicursors()
  mcursor.restore()
end

local function multicursor_numbers()
  if not mcursor_active() then
    vim.notify('No active multicursors', vim.log.levels.WARN)
    return
  end
  mcursor.number(1, 1, '%d')
end

local function follow_mode_state()
  local state = vim.bo.follow and 'ON' or 'OFF'
  vim.notify('Follow mode is ' .. state, vim.log.levels.INFO)
end

local function multicursor_numbers_padded()
  if not mcursor_active() then
    vim.notify('No active multicursors', vim.log.levels.WARN)
    return
  end
  mcursor.number(1, 1, '%03d')
end

local function jump_next_cursor(remove)
  if not mcursor_active() then
    return
  end
  mcursor.jump(true, vim.v.count1)
  if remove then
    vim.cmd('normal! Q')
  end
end

local function jump_prev_cursor(remove)
  if not mcursor_active() then
    return
  end
  mcursor.jump(false, vim.v.count1)
  if remove then
    vim.cmd('normal! Q')
  end
end

local function setup_keymaps()
  local map = vim.keymap.set

  map('n', '<leader>jQ', restore_multicursors, { desc = 'Multicursor: restore previous session' })
  map('n', '<leader>jc', clear_multicursors, { desc = 'Multicursor: clear all' })
  map('n', '<leader>jt', function()
    vim.cmd('normal! q=')
    follow_mode_state()
  end, { desc = 'Multicursor: Toggle follow mode' })

  map('n', '<leader>j*', multicursor_word_under_cursor, { desc = 'Multicursor: all matches of word under cursor' })
  map('n', '<leader>j/', multicursor_all_matches, { desc = 'Multicursor: all matches of search pattern' })
  map('n', '<leader>jn', 'zqgn', { desc = 'Multicursor: add cursor at next match' })
  map('n', '<leader>jN', 'zqgN', { desc = 'Multicursor: add cursor at prev match' })

  map('n', '<leader>jl', 'Vzqj', { desc = 'Multicursor: each line in current paragraph' })
  map('n', '<leader>jL', 'Vzqj', { desc = 'Multicursor: each line in visual selection' })

  map('x', '<leader>j', 'zq', { desc = 'Multicursor: at motion' })
  map('x', '<leader>jl', 'vQ', { desc = 'Multicursor: each line in selection' })
  map('x', '<leader>j*', multicursor_visual_matches, { desc = 'Multicursor: each match in selection' })

  map('n', '<leader>ji', multicursor_numbers, { desc = 'Multicursor: insert numbers 1,2,3...' })
  map('n', '<leader>jI', multicursor_numbers_padded, { desc = 'Multicursor: insert padded numbers 001,002...' })

  map('n', ']c', function() jump_next_cursor(false) end, { desc = 'Multicursor: jump to next cursor' })
  map('n', '[c', function() jump_prev_cursor(false) end, { desc = 'Multicursor: jump to prev cursor' })
  map('n', ']C', function() jump_next_cursor(true) end, { desc = 'Multicursor: jump to next cursor & remove' })
  map('n', '[C', function() jump_prev_cursor(true) end, { desc = 'Multicursor: jump to prev cursor & remove' })
end

function M.setup()
  ns_mc = api.nvim_create_namespace('nvim.multicursor')
  mcursor = require('vim._core.mcursor')
  setup_keymaps()
end

return M

