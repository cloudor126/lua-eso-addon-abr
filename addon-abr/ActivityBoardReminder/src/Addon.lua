--========================================
--        vars
--========================================
local l = {} -- private table for local use
local m = {l=l} -- public table for module use
local NAME = 'ActivityBoardReminder'
local SHORT_NAME = 'ABR'
local VERSION = '@@ADDON_VERSION@@'

--========================================
--        l
--========================================
l.dict = {} -- localization dictionary
l.extensionMap = {} -- extensions for types
l.registry = {} -- module registry
l.started = false
l.startListeners = {} -- start listeners for initiation

l.onAddonStarted -- event handler
= function(eventCode, addonName)
  if NAME ~= addonName then return end
  EVENT_MANAGER:UnregisterForEvent(addonName, eventCode)
  l.start()
end

l.start -- initialization
= function()
  if l.started then return end
  l.started = true
  while #l.startListeners > 0 do
    table.remove(l.startListeners, 1)()
  end
end

--========================================
--        m
--========================================
m.name = NAME
m.shortName = SHORT_NAME
m.version = VERSION

m.callExtension -- call all registered extensions
= function(key, ...)
  local list = l.extensionMap[key] or {}
  for _, ext in ipairs(list) do
    ext(...)
  end
end

m.extend -- register an extension
= function(key, extension)
  local list = l.extensionMap[key]
  if not list then
    list = {}
    l.extensionMap[key] = list
  end
  table.insert(list, extension)
end

m.hookStart -- register start listener
= function(listener)
  if l.started then listener() end
  table.insert(l.startListeners, listener)
end

m.load -- load a registered module
= function(typeName)
  return l.registry[typeName]
end

m.putText -- add localization text
= function(key, value)
  l.dict[key] = value
end

m.register -- register a module
= function(typeName, typeProto)
  l.registry[typeName] = typeProto
end

m.text -- get localized text
= function(key, ...)
  if select('#', ...) == 0 then
    return l.dict[key] or key
  end
  return l.dict[key] and string.format(l.dict[key], ...) or string.format(key, ...)
end

m.debug -- debug output
= function(format, ...)
  local s = string.format(format, ...)
  d('|c0000dd['..SHORT_NAME..']|r ' .. s)
end

--========================================
--        register
--========================================
_G[NAME] = m
EVENT_MANAGER:RegisterForEvent(m.name, EVENT_ADD_ON_LOADED, l.onAddonStarted)