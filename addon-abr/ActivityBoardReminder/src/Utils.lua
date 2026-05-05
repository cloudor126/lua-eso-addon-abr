--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local l = {} -- private table
local m = {l=l} -- public table

--========================================
--        l
--========================================

--========================================
--        m
--========================================

-- String utilities
m.split -- #(#string:str, #string:delimiter)->(#list<#string>)
= function(str, delimiter)
  local result = {}
  local pattern = "(.-)" .. delimiter .. "()"
  local lastPos = 1
  for part, pos in string.gmatch(str, pattern) do
    table.insert(result, part)
    lastPos = pos
  end
  table.insert(result, string.sub(str, lastPos))
  return result
end

m.join -- #(#list<#string>:arr, #string:delimiter)->(#string)
= function(arr, delimiter)
  return table.concat(arr, delimiter)
end

m.trim -- #(#string:str)->(#string)
= function(str)
  return str:match("^%s*(.-)%s*$")
end

m.isEmpty -- #(#string|nil:str)->(#boolean)
= function(str)
  return str == nil or m.trim(str) == ""
end

-- Table utilities
m.deepCopy -- #(#table:orig)->(#table)
= function(orig)
  local copy = {}
  for k, v in pairs(orig) do
    if type(v) == "table" then
      copy[k] = m.deepCopy(v)
    else
      copy[k] = v
    end
  end
  return copy
end

m.contains -- #(#table:tbl, #any:value)->(#boolean)
= function(tbl, value)
  for _, v in pairs(tbl) do
    if v == value then return true end
  end
  return false
end

m.size -- #(#table:tbl)->(#number)
= function(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

-- Time utilities
m.formatTime -- #(#number:timestamp)->(#string)
= function(timestamp)
  return GetDateStringFromTimestamp(timestamp)
end

--========================================
--        register
--========================================
addon.register("Utils#M", m)