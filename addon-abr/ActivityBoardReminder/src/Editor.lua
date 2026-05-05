--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local l = {} -- private table
local m = {l=l} -- public table

--========================================
--        l
--========================================
l.onStart -- #()->()
= function()
  -- TODO: Initialize editor
  addon.debug("Editor module initialized")
end

--========================================
--        m
--========================================

--========================================
--        register
--========================================
addon.register("Editor#M", m)
addon.hookStart(l.onStart)