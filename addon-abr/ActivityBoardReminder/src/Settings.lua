--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local book = nil -- Book#M
local viewer = nil -- Viewer#M
local l = {} -- private table
local m = {l=l} -- public table

--========================================
--        l
--========================================
l.menuOptions = {} -- list of menu options

l.getSavedVars -- #()->(#table)
= function()
  return book.getSavedVars()
end

l.resetWindowPosition -- #()->()
= function()
  local sv = l.getSavedVars()
  sv.windowPosition = {x = 100, y = 100}
  viewer.refresh()
  d("|c00FF00[ABR]|r Window position reset to default (100, 100)")
end

l.onStart -- #()->()
= function()
  book = addon.load("Book#M")
  viewer = addon.load("Viewer#M")

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
    slashCommand = "/abrset",
    registerForRefresh = true,
    registerForDefaults = true,
  }
  LAM2:RegisterAddonPanel('ABRAddonOptions', panelData)

  -- add base menu options
  m.addMenuOptions(
    {
      type = "header",
      name = "General",
    },
    {
      type = "button",
      name = "Reset Window Position",
      tooltip = "Reset the viewer window to default position",
      func = l.resetWindowPosition,
    }
  )

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