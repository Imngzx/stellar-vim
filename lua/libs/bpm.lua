local M = {}
local _bpm

function M.get()
  if not _bpm then
    pcall(function() _bpm = require('bpm') end)
  end
  return _bpm
end

function M.is_available()
  return M.get() ~= nil
end

function M.call(fn, ...)
  local bpm = M.get()
  if bpm and bpm[fn] then
    return bpm[fn](...)
  end
end

return M