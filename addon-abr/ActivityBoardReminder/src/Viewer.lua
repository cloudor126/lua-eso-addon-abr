--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local core = nil -- Core#M
local book = nil -- Book#M
local network = nil -- Network#M
local l = {} -- private table
local m = {l=l} -- public table

--========================================
--        l
--========================================
l.window = nil -- TopLevelWindow
l.contentLabel = nil -- LabelControl
l.pageLabel = nil -- LabelControl
l.prevButton = nil -- ButtonControl
l.nextButton = nil -- ButtonControl
l.editButton = nil -- ButtonControl
l.closeButton = nil -- ButtonControl

l.isDragging = false
l.dragStartX = 0
l.dragStartY = 0

l.getSavedVars -- #()->(#table)
= function()
  return book.getSavedVars()
end

l.createUI -- #()->()
= function()
  local sv = l.getSavedVars()

  -- Create top-level window
  l.window = WINDOW_MANAGER:CreateTopLevelWindow("ABRViewerWindow")
  l.window:SetDimensions(400, 300)
  l.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, sv.windowPosition.x, sv.windowPosition.y)
  l.window:SetClampedToScreen(true)
  l.window:SetMouseEnabled(true)

  -- Background
  local bg = WINDOW_MANAGER:CreateControl("ABRViewerBg", l.window, CT_BACKDROP)
  bg:SetAnchorFill(l.window)
  bg:SetCenterColor(0, 0, 0, 0.8)
  bg:SetEdgeColor(0.5, 0.5, 0.5, 1)
  bg:SetEdgeTexture("", 2, 2, 2)

  -- Content label
  l.contentLabel = WINDOW_MANAGER:CreateControl("ABRViewerContent", l.window, CT_LABEL)
  l.contentLabel:SetAnchor(TOPLEFT, l.window, TOPLEFT, 10, 10)
  l.contentLabel:SetAnchor(BOTTOMRIGHT, l.window, BOTTOMRIGHT, -10, -40)
  l.contentLabel:SetFont("ZoFontGameMedium")
  l.contentLabel:SetText("")
  l.contentLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
  l.contentLabel:SetVerticalAlignment(TEXT_ALIGN_TOP)

  -- Page label
  l.pageLabel = WINDOW_MANAGER:CreateControl("ABRViewerPage", l.window, CT_LABEL)
  l.pageLabel:SetAnchor(BOTTOMLEFT, l.window, BOTTOMLEFT, 10, -10)
  l.pageLabel:SetDimensions(100, 20)
  l.pageLabel:SetFont("ZoFontGameSmall")
  l.pageLabel:SetText("Page: 1")

  -- Prev button
  l.prevButton = WINDOW_MANAGER:CreateControl("ABRViewerPrev", l.window, CT_BUTTON)
  l.prevButton:SetAnchor(BOTTOMRIGHT, l.window, BOTTOMRIGHT, -130, -10)
  l.prevButton:SetDimensions(50, 20)
  l.prevButton:SetText("<")
  l.prevButton:SetFont("ZoFontGameSmall")
  l.prevButton:SetHandler("OnClicked", function()
    l.prevPage()
  end)

  -- Next button
  l.nextButton = WINDOW_MANAGER:CreateControl("ABRViewerNext", l.window, CT_BUTTON)
  l.nextButton:SetAnchor(BOTTOMRIGHT, l.window, BOTTOMRIGHT, -70, -10)
  l.nextButton:SetDimensions(50, 20)
  l.nextButton:SetText(">")
  l.nextButton:SetFont("ZoFontGameSmall")
  l.nextButton:SetHandler("OnClicked", function()
    l.nextPage()
  end)

  -- Edit button
  l.editButton = WINDOW_MANAGER:CreateControl("ABRViewerEdit", l.window, CT_BUTTON)
  l.editButton:SetAnchor(BOTTOMRIGHT, l.window, BOTTOMRIGHT, -10, -10)
  l.editButton:SetDimensions(50, 20)
  l.editButton:SetText("Edit")
  l.editButton:SetFont("ZoFontGameSmall")
  l.editButton:SetHandler("OnClicked", function()
    l.toggleEditMode()
  end)

  -- Make window movable
  l.window:SetMovable(true)

  -- Save position when moved
  l.window:SetHandler("OnMoveStop", function()
    local _, _, _, offsetX, offsetY = l.window:GetAnchor()
    sv.windowPosition.x = offsetX
    sv.windowPosition.y = offsetY
  end)

  l.window:SetHidden(true)
end

l.prevPage -- #()->()
= function()
  local sv = l.getSavedVars()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end

  local newPage = sv.currentPage - 1
  if newPage < 1 then newPage = 1 end
  if newPage ~= sv.currentPage then
    book.setCurrentPage(newPage)
    l.updateDisplay()
    if core.isLeader() then
      network.sendChangePage(currentBook.id, newPage)
    end
  end
end

l.nextPage -- #()->()
= function()
  local sv = l.getSavedVars()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end

  local newPage = sv.currentPage + 1
  if newPage > #currentBook.pages then newPage = #currentBook.pages end
  if newPage ~= sv.currentPage then
    book.setCurrentPage(newPage)
    l.updateDisplay()
    if core.isLeader() then
      network.sendChangePage(currentBook.id, newPage)
    end
  end
end

l.toggleEditMode -- #()->()
= function()
  local sv = l.getSavedVars()
  sv.isEditMode = not sv.isEditMode
  addon.callExtension(m.EXTKEY_ON_EDIT_MODE_CHANGED, sv.isEditMode)
end

l.updateDisplay -- #()->()
= function()
  local sv = l.getSavedVars()

  -- Update window position
  l.window:ClearAnchors()
  l.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, sv.windowPosition.x, sv.windowPosition.y)

  local currentBook = book.getCurrentBook()
  local currentPage = book.getCurrentPage()

  if not currentBook or #currentBook.pages == 0 then
    l.contentLabel:SetText("")
    l.pageLabel:SetText("Page: 0/0")
    l.window:SetHidden(true)
    return
  end

  l.window:SetHidden(false)
  local page = currentBook.pages[currentPage]
  if page then
    l.contentLabel:SetText(page.content)
  else
    l.contentLabel:SetText("")
  end
  l.pageLabel:SetText(string.format("Page: %d/%d", currentPage, #currentBook.pages))

  -- Update button visibility based on permissions
  l.editButton:SetHidden(not core.canEdit())
  l.prevButton:SetHidden(not core.canEdit())
  l.nextButton:SetHidden(not core.canEdit())
end

l.onSyncBook -- #(#string:unitTag, #number:bookId, #number:pageNum, #string:content)->()
= function(unitTag, bookId, pageNum, content)
  -- Received book sync from leader
  book.setCurrentBook(bookId)
  book.setCurrentPage(pageNum)
  -- If content is provided, cache it locally
  if content and content ~= "" then
    local b = book.getBook(bookId)
    if b and b.pages[pageNum] then
      b.pages[pageNum].content = content
    end
  end
  l.updateDisplay()
end

l.onChangePage -- #(#string:unitTag, #number:bookId, #number:pageNum)->()
= function(unitTag, bookId, pageNum)
  book.setCurrentBook(bookId)
  book.setCurrentPage(pageNum)
  l.updateDisplay()
end

l.onClose -- #(#string:unitTag)->()
= function(unitTag)
  book.setCurrentBook(nil)
  l.window:SetHidden(true)
end

l.onStart -- #()->()
= function()
  core = addon.load("Core#M")
  book = addon.load("Book#M")
  network = addon.load("Network#M")

  l.createUI()

  -- Register network handlers
  addon.extend(network.EXTKEY_ON_SYNC_BOOK, l.onSyncBook)
  addon.extend(network.EXTKEY_ON_CHANGE_PAGE, l.onChangePage)
  addon.extend(network.EXTKEY_ON_CLOSE, l.onClose)

  addon.debug("Viewer module initialized")
end

--========================================
--        m
--========================================
m.EXTKEY_ON_EDIT_MODE_CHANGED = "Viewer:onEditModeChanged"

m.show -- #()->()
= function()
  l.updateDisplay()
end

m.hide -- #()->()
= function()
  l.window:SetHidden(true)
end

m.refresh -- #()->()
= function()
  l.updateDisplay()
end

m.getWindow -- #()->(#Control)
= function()
  return l.window
end

--========================================
--        register
--========================================
addon.register("Viewer#M", m)
addon.hookStart(l.onStart)