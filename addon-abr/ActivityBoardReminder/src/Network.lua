--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local l = {} -- private table
local m = {l=l} -- public table

local PROTOCOL_ID = 240
local PROTOCOL_NAME = "ABRBook"

-- Actions
local ACTION_SYNC_BOOK = 0
local ACTION_CHANGE_PAGE = 1
local ACTION_CLOSE = 2

--========================================
--        l
--========================================
l.handler = nil
l.protocol = nil
l.isInitialized = false

l.initHandler -- #()->(#boolean)
= function()
  local LGB = LibGroupBroadcast
  if not LGB then
    addon.debug("LibGroupBroadcast not found")
    return false
  end

  l.handler = LGB:RegisterHandler(addon.name, "ABR")
  if not l.handler then
    addon.debug("Failed to register handler")
    return false
  end

  l.handler:SetDisplayName("Activity Board Reminder")
  l.handler:SetDescription("Syncs activity announcement content to group members")

  return true
end

l.initProtocol -- #()->(#boolean)
= function()
  local LGB = LibGroupBroadcast
  if not LGB or not l.handler then return false end

  l.protocol = l.handler:DeclareProtocol(PROTOCOL_ID, PROTOCOL_NAME)
  if not l.protocol then
    addon.debug("Failed to declare protocol")
    return false
  end

  l.protocol:AddField(LGB.CreateNumericField("action", {numBits = 3}))
  l.protocol:AddField(LGB.CreateNumericField("bookId", {numBits = 16}))
  l.protocol:AddField(LGB.CreateNumericField("pageNum", {numBits = 8}))
  l.protocol:AddField(LGB.CreateStringField("content", {maxLength = 1000}))

  l.protocol:OnData(function(unitTag, data)
    addon.callExtension(m.EXTKEY_ON_DATA, unitTag, data)
  end)

  local options = {
    isRelevantInCombat = true,
    replaceQueuedMessages = true
  }

  if not l.protocol:Finalize(options) then
    addon.debug("Failed to finalize protocol")
    return false
  end

  return true
end

l.onStart -- #()->()
= function()
  if not l.initHandler() then return end
  if not l.initProtocol() then return end
  l.isInitialized = true
  addon.debug("Network initialized with protocol ID %d", PROTOCOL_ID)
end

--========================================
--        m
--========================================
m.EXTKEY_ON_DATA = "Network:onData"

m.isReady -- #()->(#boolean)
= function()
  return l.isInitialized and l.protocol ~= nil
end

m.sendSyncBook -- #(#number:bookId, #number:pageNum, #string:content)->(#boolean)
= function(bookId, pageNum, content)
  if not m.isReady() then return false end
  return l.protocol:Send({
    action = ACTION_SYNC_BOOK,
    bookId = bookId,
    pageNum = pageNum,
    content = content or ""
  })
end

m.sendChangePage -- #(#number:bookId, #number:pageNum)->(#boolean)
= function(bookId, pageNum)
  if not m.isReady() then return false end
  return l.protocol:Send({
    action = ACTION_CHANGE_PAGE,
    bookId = bookId,
    pageNum = pageNum,
    content = ""
  })
end

m.sendClose -- #()->(#boolean)
= function()
  if not m.isReady() then return false end
  return l.protocol:Send({
    action = ACTION_CLOSE,
    bookId = 0,
    pageNum = 0,
    content = ""
  })
end

--========================================
--        register
--========================================
addon.register("Network#M", m)
addon.hookStart(l.onStart)
