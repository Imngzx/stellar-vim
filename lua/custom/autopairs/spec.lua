local str_byte = string.byte

local function make_pair(left, right)
  return {
    left,
    right,
    l_byte = str_byte(left),
    r_byte = str_byte(right),
    is_bracket = left ~= right,
  }
end

local parens = make_pair('(', ')')
local brackets = make_pair('[', ']')
local braces = make_pair('{', '}')
local angle = make_pair('<', '>')
local double_quote = make_pair('"', '"')
local single_quote = make_pair("'", "'")
local backtick = make_pair('`', '`')

return {
  open_pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
  },
  close_pairs = {
    [')'] = true,
    [']'] = true,
    ['}'] = true,
  },
  quotes = {
    ['"'] = true,
    ["'"] = true,
    ['`'] = true,
  },
  surrounds = {
    ['('] = parens,
    [')'] = parens,
    ['b'] = parens,
    ['['] = brackets,
    [']'] = brackets,
    ['{'] = braces,
    ['}'] = braces,
    ['<'] = angle,
    ['>'] = angle,
    ['"'] = double_quote,
    ["'"] = single_quote,
    ['`'] = backtick,
  },
  tabout_pairs = {
    parens,
    brackets,
    braces,
    double_quote,
    single_quote,
    backtick,
  },
}
