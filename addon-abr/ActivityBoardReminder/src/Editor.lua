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
l.selectedBookId = nil

l.getSavedVars -- #()->(#table)
= function()
  return book.getSavedVars()
end

l.createEditorUI -- #()->()
= function()
  local win = viewer.getWindow()
  if not win then return end

  -- Book selector button
  l.bookBtn = WINDOW_MANAGER:CreateControl("ABREditorBookBtn", win, CT_BUTTON)
  l.bookBtn:SetAnchor(TOPLEFT, win, TOPLEFT, 10, 10)
  l.bookBtn:SetDimensions(150, 25)
  l.bookBtn:SetText("[Select Book]")
  l.bookBtn:SetFont("ZoFontGameSmall")
  l.bookBtn:SetHandler("OnClicked", function()
    l.cycleBook()
  end)
  l.bookBtn:SetHidden(true)

  -- New book name input
  l.newBookName = WINDOW_MANAGER:CreateControl("ABREditorNewBookName", win, CT_EDITBOX)
  l.newBookName:SetAnchor(TOPLEFT, l.bookBtn, TOPRIGHT, 10, 0)
  l.newBookName:SetDimensions(120, 25)
  l.newBookName:SetFont("ZoFontGameSmall")
  l.newBookName:SetText("")
  l.newBookName:SetHidden(true)

  -- New book button
  l.newBookBtn = WINDOW_MANAGER:CreateControl("ABREditorNewBookBtn", win, CT_BUTTON)
  l.newBookBtn:SetAnchor(TOPLEFT, l.newBookName, TOPRIGHT, 5, 0)
  l.newBookBtn:SetDimensions(40, 25)
  l.newBookBtn:SetText("New")
  l.newBookBtn:SetFont("ZoFontGameSmall")
  l.newBookBtn:SetHandler("OnClicked", function()
    local name = l.newBookName:GetText()
    if name and name ~= "" then
      local b = book.createBook(name)
      l.selectedBookId = b.id
      l.updateBookButton()
      l.loadCurrentPage()
      l.newBookName:SetText("")
    end
  end)
  l.newBookBtn:SetHidden(true)

  -- Delete book button
  l.deleteBookBtn = WINDOW_MANAGER:CreateControl("ABREditorDeleteBookBtn", win, CT_BUTTON)
  l.deleteBookBtn:SetAnchor(TOPLEFT, l.newBookBtn, TOPRIGHT, 5, 0)
  l.deleteBookBtn:SetDimensions(40, 25)
  l.deleteBookBtn:SetText("Del")
  l.deleteBookBtn:SetFont("ZoFontGameSmall")
  l.deleteBookBtn:SetHandler("OnClicked", function()
    if l.selectedBookId then
      book.deleteBook(l.selectedBookId)
      l.selectedBookId = nil
      l.updateBookButton()
      l.loadCurrentPage()
    end
  end)
  l.deleteBookBtn:SetHidden(true)

  -- Edit box for page content (multiline)
  l.editBox = WINDOW_MANAGER:CreateControl("ABREditorEditBox", win, CT_EDITBOX)
  l.editBox:SetAnchor(TOPLEFT, win, TOPLEFT, 10, 40)
  l.editBox:SetAnchor(BOTTOMRIGHT, win, BOTTOMRIGHT, -10, -80)
  l.editBox:SetFont("ZoFontGameMedium")
  l.editBox:SetText("")
  l.editBox:SetMultiLine(true)
  l.editBox:SetMaxInputChars(2000)
  l.editBox:SetHidden(true)
  l.editBox:SetHandler("OnFocusLost", function()
    l.saveCurrentPage()
  end)

  -- Add page button
  l.addPageBtn = WINDOW_MANAGER:CreateControl("ABREditorAddPageBtn", win, CT_BUTTON)
  l.addPageBtn:SetAnchor(BOTTOMLEFT, win, BOTTOMLEFT, 10, -40)
  l.addPageBtn:SetDimensions(50, 25)
  l.addPageBtn:SetText("+Pg")
  l.addPageBtn:SetFont("ZoFontGameSmall")
  l.addPageBtn:SetHandler("OnClicked", function()
    if l.selectedBookId then
      local content = l.editBox:GetText()
      book.addPage(l.selectedBookId, content)
      l.loadCurrentPage()
    end
  end)
  l.addPageBtn:SetHidden(true)

  -- Delete page button
  l.delPageBtn = WINDOW_MANAGER:CreateControl("ABREditorDelPageBtn", win, CT_BUTTON)
  l.delPageBtn:SetAnchor(LEFT, l.addPageBtn, RIGHT, 5, 0)
  l.delPageBtn:SetDimensions(50, 25)
  l.delPageBtn:SetText("-Pg")
  l.delPageBtn:SetFont("ZoFontGameSmall")
  l.delPageBtn:SetHandler("OnClicked", function()
    if l.selectedBookId then
      local currentPage = book.getCurrentPage()
      book.deletePage(l.selectedBookId, currentPage)
      l.loadCurrentPage()
    end
  end)
  l.delPageBtn:SetHidden(true)

  -- Publish button
  l.publishBtn = WINDOW_MANAGER:CreateControl("ABREditorPublishBtn", win, CT_BUTTON)
  l.publishBtn:SetAnchor(BOTTOMRIGHT, win, BOTTOMRIGHT, -10, -40)
  l.publishBtn:SetDimensions(60, 25)
  l.publishBtn:SetText("Publish")
  l.publishBtn:SetFont("ZoFontGameSmall")
  l.publishBtn:SetHandler("OnClicked", function()
    if l.selectedBookId then
      l.saveCurrentPage()
      m.publishPage(l.selectedBookId, book.getCurrentPage())
      d("|c00FF00[ABR]|r Published current page")
    end
  end)
  l.publishBtn:SetHidden(true)
end

l.cycleBook -- #()->()
= function()
  local books = book.getAllBooks()
  local ids = {}
  for id, b in pairs(books) do
    table.insert(ids, id)
  end

  if #ids == 0 then
    l.selectedBookId = nil
    l.updateBookButton()
    return
  end

  -- Find current index
  local currentIndex = 0
  for i, id in ipairs(ids) do
    if id == l.selectedBookId then
      currentIndex = i
      break
    end
  end

  -- Cycle to next
  local nextIndex = (currentIndex % #ids) + 1
  l.selectedBookId = ids[nextIndex]
  book.setCurrentBook(l.selectedBookId)
  l.updateBookButton()
  l.loadCurrentPage()
end

l.updateBookButton -- #()->()
= function()
  if not l.bookBtn then return end

  local b = book.getBook(l.selectedBookId)
  if b then
    l.bookBtn:SetText(b.name)
  else
    l.bookBtn:SetText("[Select Book]")
  end
end

l.saveCurrentPage -- #()->()
= function()
  if not l.selectedBookId then return end
  local content = l.editBox:GetText()
  local currentPage = book.getCurrentPage()
  book.updatePage(l.selectedBookId, currentPage, content)
end

l.loadCurrentPage -- #()->()
= function()
  if not l.editBox then return end

  if not l.selectedBookId then
    l.editBox:SetText("")
    return
  end

  local b = book.getBook(l.selectedBookId)
  if not b then
    l.editBox:SetText("")
    return
  end

  local currentPage = book.getCurrentPage()
  local page = b.pages[currentPage]
  if page then
    l.editBox:SetText(page.content)
  else
    l.editBox:SetText("")
  end
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
  if l.editBox then
    l.bookBtn:SetHidden(false)
    l.newBookName:SetHidden(false)
    l.newBookBtn:SetHidden(false)
    l.deleteBookBtn:SetHidden(false)
    l.editBox:SetHidden(false)
    l.addPageBtn:SetHidden(false)
    l.delPageBtn:SetHidden(false)
    l.publishBtn:SetHidden(false)
    l.updateBookButton()
    l.loadCurrentPage()
  end
  addon.debug("Editor mode enabled")
end

l.hideEditor -- #()->()
= function()
  if l.editBox then
    l.bookBtn:SetHidden(true)
    l.newBookName:SetHidden(true)
    l.newBookBtn:SetHidden(true)
    l.deleteBookBtn:SetHidden(true)
    l.editBox:SetHidden(true)
    l.addPageBtn:SetHidden(true)
    l.delPageBtn:SetHidden(true)
    l.publishBtn:SetHidden(true)
  end
  addon.debug("Editor mode disabled")
end

l.onStart -- #()->()
= function()
  core = addon.load("Core#M")
  book = addon.load("Book#M")
  network = addon.load("Network#M")
  viewer = addon.load("Viewer#M")

  l.createEditorUI()

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

  book.setCurrentBook(bookId)

  -- Publish first page
  if b.pages[1] then
    return network.sendSyncBook(bookId, 1, b.pages[1].content)
  end

  return true
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
