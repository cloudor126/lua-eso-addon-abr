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
  -- TODO: Initialize UI
  addon.debug("Viewer module initialized")
end

--========================================
--        m
--========================================

--========================================
--        register
--========================================
addon.register("Viewer#M", m)
addon.hookStart(l.onStart)