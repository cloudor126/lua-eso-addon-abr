--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local core = nil -- Core#M
local book = nil -- Book#M
local network = nil -- Network#M
local viewer = nil -- Viewer#M
local l = {} -- private table
local m = {l=l} -- public table

--========================================
--        l
--========================================
l.isEditMode = false

l.getSavedVars -- #()->(#table)
= function()
  return book.getSavedVars()
end

l.onEditModeChanged -- #(#boolean:isEdit)->()
= function(isEdit)
  l.isEditMode = isEdit
  if isEdit then
    l.showEditor()
  else
    l.hideEditor()
  end
end

l.showEditor -- #()->()
= function()
  -- TODO: Show editor UI
  addon.debug("Editor mode enabled")
end

l.hideEditor -- #()->()
= function()
  -- TODO: Hide editor UI
  addon.debug("Editor mode disabled")
end

l.onStart -- #()->()
= function()
  core = addon.load("Core#M")
  book = addon.load("Book#M")
  network = addon.load("Network#M")
  viewer = addon.load("Viewer#M")

  -- Register for edit mode changes
  addon.extend(viewer.EXTKEY_ON_EDIT_MODE_CHANGED, l.onEditModeChanged)

  addon.debug("Editor module initialized")
end

--========================================
--        m
--========================================

m.publishBook -- #(#number:bookId)->(#boolean)
= function(bookId)
  if not core.isLeader() then return false end

  local b = book.getBook(bookId)
  if not b then return false end

  local currentPage = book.getCurrentPage()
  local page = b.pages[currentPage]
  local content = page and page.content or ""

  return network.sendSyncBook(bookId, currentPage, content)
end

m.publishPage -- #(#number:bookId, #number:pageNum)->(#boolean)
= function(bookId, pageNum)
  if not core.isLeader() then return false end

  local b = book.getBook(bookId)
  if not b or not b.pages[pageNum] then return false end

  book.setCurrentBook(bookId)
  book.setCurrentPage(pageNum)

  return network.sendSyncBook(bookId, pageNum, b.pages[pageNum].content)
end

--========================================
--        register
--========================================
addon.register("Editor#M", m)
addon.hookStart(l.onStart)