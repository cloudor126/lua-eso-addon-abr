--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local l = {} -- private table
local m = {l=l} -- public table

--========================================
--        l
--========================================
l.menuOptions = {} -- list of menu options

l.onStart -- #()->()
= function()
  -- let modules add their defaults
  addon.callExtension(m.EXTKEY_ADD_DEFAULTS)

  -- register addon panel
  local LAM2 = LibAddonMenu2
  if LAM2 == nil then return end

  local panelData = {
    type = 'panel',
    name = addon.text("Activity Board Reminder"),
    displayName = "Activity Board Reminder",
    author = "Cloudor",
    version = addon.version,
    website = "https://www.esoui.com/downloads/info-ActivityBoardReminder.html",
    registerForRefresh = true,
    registerForDefaults = true,
  }
  LAM2:RegisterAddonPanel('ABRAddonOptions', panelData)

  -- let modules add their menu options
  addon.callExtension(m.EXTKEY_ADD_MENUS)
  LAM2:RegisterOptionControls('ABRAddonOptions', l.menuOptions)
end

--========================================
--        m
--========================================
m.EXTKEY_ADD_DEFAULTS = "Settings:addDefaults"
m.EXTKEY_ADD_MENUS = "Settings:addMenus"

m.addMenuOptions -- #(#table:...)->()
= function(...)
  for i = 1, select('#', ...) do
    local option = select(i, ...)
    table.insert(l.menuOptions, option)
  end
end

--========================================
--        register
--========================================
addon.register("Settings#M", m)
addon.hookStart(l.onStart)