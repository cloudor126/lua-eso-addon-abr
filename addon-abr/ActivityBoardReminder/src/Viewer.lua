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
l.titleLabel = nil -- LabelControl
l.closeButton = nil -- ButtonControl

-- Selection area
l.bookDropdown = nil -- ComboBoxControl
l.bookDropdownObject = nil -- ZO_ComboBox object
l.bookMenuBtn = nil -- ButtonControl

l.pagePrevBtn = nil -- ButtonControl
l.pageLabel = nil -- LabelControl
l.pageNextBtn = nil -- ButtonControl
l.pageMenuBtn = nil -- ButtonControl

-- Content area
l.contentLabel = nil -- LabelControl (view mode)
l.editBoxContainer = nil -- Control (edit mode)
l.editBox = nil -- EditControl (edit mode)

-- Control area
l.editButton = nil -- ButtonControl

l.isEditMode = false
l.leaderMode = true -- Leader mode (show selection/control areas, allow editing)

l.getSavedVars -- #()->(#table)
= function()
  return book.getSavedVars()
end

l.createUI -- #()->()
= function()
  local sv = l.getSavedVars()

  -- Calculate center position if not set
  local posX = sv.windowPosition.x
  local posY = sv.windowPosition.y
  if posX == 300 and posY == 300 then
    posX = GuiRoot:GetWidth() / 2 - 200
    posY = GuiRoot:GetHeight() / 2 - 200
  end

  -- Create top-level window
  l.window = WINDOW_MANAGER:CreateTopLevelWindow("ABRViewerWindow")
  l.window:SetDimensions(400, 400)
  l.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
  l.window:SetClampedToScreen(true)
  l.window:SetMouseEnabled(true)

  -- Main background
  local bg = WINDOW_MANAGER:CreateControl("ABRViewerBg", l.window, CT_BACKDROP)
  bg:SetAnchorFill(l.window)
  bg:SetCenterColor(0, 0, 0, 0.9)
  bg:SetEdgeColor(0.5, 0.5, 0.5, 1)
  bg:SetEdgeTexture("", 2, 2, 2)

  -- Title bar background
  l.titleBar = WINDOW_MANAGER:CreateControl("ABRViewerTitleBar", l.window, CT_BACKDROP)
  l.titleBar:SetAnchor(TOPLEFT, l.window, TOPLEFT, 0, 0)
  l.titleBar:SetAnchor(TOPRIGHT, l.window, TOPRIGHT, 0, 0)
  l.titleBar:SetHeight(30)
  l.titleBar:SetCenterColor(0.15, 0.15, 0.15, 1)
  l.titleBar:SetEdgeColor(0.3, 0.3, 0.3, 1)
  l.titleBar:SetEdgeTexture("", 1, 1, 1)

  -- Title label
  l.titleLabel = WINDOW_MANAGER:CreateControl("ABRViewerTitle", l.titleBar, CT_LABEL)
  l.titleLabel:SetAnchor(LEFT, l.titleBar, LEFT, 10, 0)
  l.titleLabel:SetAnchor(RIGHT, l.titleBar, RIGHT, -40, 0)
  l.titleLabel:SetHeight(30)
  l.titleLabel:SetFont("ZoFontGameBold")
  l.titleLabel:SetText("Activity Board Reminder")
  l.titleLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
  l.titleLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)

  -- Close button
  l.closeButton = WINDOW_MANAGER:CreateControl("ABRViewerClose", l.titleBar, CT_BUTTON)
  l.closeButton:SetAnchor(RIGHT, l.titleBar, RIGHT, -5, 0)
  l.closeButton:SetDimensions(24, 24)
  l.closeButton:SetNormalTexture("/esoui/art/buttons/decline_up.dds")
  l.closeButton:SetPressedTexture("/esoui/art/buttons/decline_down.dds")
  l.closeButton:SetMouseOverTexture("/esoui/art/buttons/decline_over.dds")
  l.closeButton:SetHandler("OnClicked", function()
    l.closeWindow()
  end)

  -- Leader mode toggle button (left of close button)
  l.leaderBtn = WINDOW_MANAGER:CreateControl("ABRViewerLeaderBtn", l.titleBar, CT_BUTTON)
  l.leaderBtn:SetAnchor(RIGHT, l.closeButton, LEFT, -5, 0)
  l.leaderBtn:SetDimensions(24, 24)
  l.leaderBtn:SetNormalTexture("/esoui/art/campaign/campaign_tabicon_summary_up.dds")
  l.leaderBtn:SetPressedTexture("/esoui/art/campaign/campaign_tabicon_summary_down.dds")
  l.leaderBtn:SetMouseOverTexture("/esoui/art/campaign/campaign_tabicon_summary_over.dds")
  l.leaderBtn:SetHandler("OnClicked", function()
    l.toggleLeaderMode()
  end)
  l.updateLeaderButton()

  -- Selection area background
  l.selectionArea = WINDOW_MANAGER:CreateControl("ABRViewerSelectionArea", l.window, CT_BACKDROP)
  l.selectionArea:SetAnchor(TOPLEFT, l.window, TOPLEFT, 10, 35)
  l.selectionArea:SetAnchor(TOPRIGHT, l.window, TOPRIGHT, -10, 35)
  l.selectionArea:SetHeight(40)
  l.selectionArea:SetCenterColor(0.1, 0.1, 0.1, 0.8)
  l.selectionArea:SetEdgeColor(0.3, 0.3, 0.3, 1)
  l.selectionArea:SetEdgeTexture("", 1, 1, 1)

  -- Book label
  l.bookLabel = WINDOW_MANAGER:CreateControl("ABRViewerBookLabel", l.selectionArea, CT_LABEL)
  l.bookLabel:SetAnchor(LEFT, l.selectionArea, LEFT, 10, 0)
  l.bookLabel:SetDimensions(45, 30)
  l.bookLabel:SetFont("ZoFontGame")
  l.bookLabel:SetText("Book:")
  l.bookLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)

  -- Book dropdown
  l.bookDropdown = WINDOW_MANAGER:CreateControlFromVirtual("ABRViewerBookDropdown", l.selectionArea, "ZO_ComboBox")
  l.bookDropdown:SetAnchor(LEFT, l.bookLabel, RIGHT, 5, 0)
  l.bookDropdown:SetDimensions(120, 30)
  l.bookDropdownObject = ZO_ComboBox_ObjectFromContainer(l.bookDropdown)

  -- Book menu button (dropdown arrow)
  l.bookMenuBtn = WINDOW_MANAGER:CreateControl("ABRViewerBookMenuBtn", l.selectionArea, CT_BUTTON)
  l.bookMenuBtn:SetAnchor(LEFT, l.bookDropdown, RIGHT, 2, 0)
  l.bookMenuBtn:SetDimensions(20, 20)
  l.bookMenuBtn:SetNormalTexture("/esoui/art/buttons/scrollbox_downarrow_up.dds")
  l.bookMenuBtn:SetPressedTexture("/esoui/art/buttons/scrollbox_downarrow_down.dds")
  l.bookMenuBtn:SetMouseOverTexture("/esoui/art/buttons/scrollbox_downarrow_over.dds")
  l.bookMenuBtn:SetHandler("OnClicked", function()
    l.showBookMenu()
  end)

  -- Page prev button
  l.pagePrevBtn = WINDOW_MANAGER:CreateControl("ABRViewerPagePrevBtn", l.selectionArea, CT_BUTTON)
  l.pagePrevBtn:SetAnchor(LEFT, l.bookMenuBtn, RIGHT, 15, 0)
  l.pagePrevBtn:SetDimensions(28, 28)
  l.pagePrevBtn:SetNormalTexture("/esoui/art/buttons/large_leftarrow_up.dds")
  l.pagePrevBtn:SetPressedTexture("/esoui/art/buttons/large_leftarrow_down.dds")
  l.pagePrevBtn:SetMouseOverTexture("/esoui/art/buttons/large_leftarrow_over.dds")
  l.pagePrevBtn:SetDisabledTexture("/esoui/art/buttons/large_leftarrow_disabled.dds")
  l.pagePrevBtn:SetHandler("OnClicked", function()
    l.prevPage()
  end)

  -- Page label (shows current/total)
  l.pageLabel = WINDOW_MANAGER:CreateControl("ABRViewerPageLabel", l.selectionArea, CT_LABEL)
  l.pageLabel:SetAnchor(LEFT, l.pagePrevBtn, RIGHT, 2, 0)
  l.pageLabel:SetDimensions(50, 30)
  l.pageLabel:SetFont("ZoFontGame")
  l.pageLabel:SetText("1/1")
  l.pageLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
  l.pageLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)

  -- Page next button
  l.pageNextBtn = WINDOW_MANAGER:CreateControl("ABRViewerPageNextBtn", l.selectionArea, CT_BUTTON)
  l.pageNextBtn:SetAnchor(LEFT, l.pageLabel, RIGHT, 2, 0)
  l.pageNextBtn:SetDimensions(28, 28)
  l.pageNextBtn:SetNormalTexture("/esoui/art/buttons/large_rightarrow_up.dds")
  l.pageNextBtn:SetPressedTexture("/esoui/art/buttons/large_rightarrow_down.dds")
  l.pageNextBtn:SetMouseOverTexture("/esoui/art/buttons/large_rightarrow_over.dds")
  l.pageNextBtn:SetDisabledTexture("/esoui/art/buttons/large_rightarrow_disabled.dds")
  l.pageNextBtn:SetHandler("OnClicked", function()
    l.nextPage()
  end)

  -- Page menu button (dropdown arrow)
  l.pageMenuBtn = WINDOW_MANAGER:CreateControl("ABRViewerPageMenuBtn", l.selectionArea, CT_BUTTON)
  l.pageMenuBtn:SetAnchor(LEFT, l.pageNextBtn, RIGHT, 2, 0)
  l.pageMenuBtn:SetDimensions(20, 20)
  l.pageMenuBtn:SetNormalTexture("/esoui/art/buttons/scrollbox_downarrow_up.dds")
  l.pageMenuBtn:SetPressedTexture("/esoui/art/buttons/scrollbox_downarrow_down.dds")
  l.pageMenuBtn:SetMouseOverTexture("/esoui/art/buttons/scrollbox_downarrow_over.dds")
  l.pageMenuBtn:SetHandler("OnClicked", function()
    l.showPageMenu()
  end)

  -- Content area (view mode)
  l.contentLabel = WINDOW_MANAGER:CreateControl("ABRViewerContent", l.window, CT_LABEL)
  l.contentLabel:SetAnchor(TOPLEFT, l.window, TOPLEFT, 15, 85)
  l.contentLabel:SetAnchor(BOTTOMRIGHT, l.window, BOTTOMRIGHT, -15, -50)
  l.contentLabel:SetFont("ZoFontGameMedium")
  l.contentLabel:SetText("")
  l.contentLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
  l.contentLabel:SetVerticalAlignment(TEXT_ALIGN_TOP)

  -- Content area (edit mode) - initially hidden
  l.editBoxContainer = WINDOW_MANAGER:CreateControlFromVirtual("ABREditorEditBoxContainer", l.window, "ZO_EditBackdrop")
  l.editBoxContainer:SetAnchor(TOPLEFT, l.window, TOPLEFT, 15, 85)
  l.editBoxContainer:SetAnchor(BOTTOMRIGHT, l.window, BOTTOMRIGHT, -15, -50)
  l.editBoxContainer:SetHidden(true)

  l.editBox = WINDOW_MANAGER:CreateControlFromVirtual("ABREditorEditBox", l.editBoxContainer, "ZO_DefaultEditMultiLineForBackdrop")
  l.editBox:SetAnchor(TOPLEFT, l.editBoxContainer, TOPLEFT, 4, 4)
  l.editBox:SetAnchor(BOTTOMRIGHT, l.editBoxContainer, BOTTOMRIGHT, -4, -4)
  l.editBox:SetMaxInputChars(2000)
  l.editBox:SetHandler("OnTextChanged", function()
    l.saveCurrentPage()
  end)
  l.editBox:SetHandler("OnEscape", function(self)
    self:LoseFocus()
  end)
  l.editBox:SetHidden(true)

  -- Control area background
  l.controlArea = WINDOW_MANAGER:CreateControl("ABRViewerControlArea", l.window, CT_BACKDROP)
  l.controlArea:SetAnchor(BOTTOMLEFT, l.window, BOTTOMLEFT, 10, -10)
  l.controlArea:SetAnchor(BOTTOMRIGHT, l.window, BOTTOMRIGHT, -10, -10)
  l.controlArea:SetHeight(30)
  l.controlArea:SetCenterColor(0.1, 0.1, 0.1, 0.8)
  l.controlArea:SetEdgeColor(0.3, 0.3, 0.3, 1)
  l.controlArea:SetEdgeTexture("", 1, 1, 1)

  -- Edit/Done button
  l.editButton = WINDOW_MANAGER:CreateControlFromVirtual("ABRViewerEditBtn", l.controlArea, "ZO_DefaultButton")
  l.editButton:SetAnchor(CENTER, l.controlArea, CENTER, 0, 0)
  l.editButton:SetDimensions(60, 24)
  l.editButton:SetText("Edit")
  l.editButton:SetClickSound("Click")
  l.editButton:SetHandler("OnClicked", function()
    l.toggleEditMode()
  end)

  -- Make window movable via title bar
  l.window:SetMovable(true)
  l.titleBar:SetMouseEnabled(true)
  l.titleBar.OnMouseDown = function()
    l.window:OnMouseDown()
  end

  -- Save position when moved
  l.window:SetHandler("OnMoveStop", function()
    local savedVars = l.getSavedVars()
    savedVars.windowPosition.x = l.window:GetLeft()
    savedVars.windowPosition.y = l.window:GetTop()
  end)

  l.window:SetHidden(true)
end

l.showBookMenu -- #()->()
= function()
  if IsMenuVisible() then
    ClearMenu()
    return
  end

  ClearMenu()

  AddMenuItem("New Book", function()
    l.showNewBookDialog()
  end, MENU_ADD_OPTION_LABEL)

  local currentBook = book.getCurrentBook()
  if currentBook then
    AddMenuItem("Rename Book", function()
      l.showRenameBookDialog()
    end, MENU_ADD_OPTION_LABEL)

    AddMenuItem("Clone Book", function()
      book.cloneBook(currentBook.id)
      l.populateBookDropdown()
      l.updateDisplay()
    end, MENU_ADD_OPTION_LABEL)

    -- Delete with red color at the end
    local deleteColor = ZO_ColorDef:New(1, 0, 0, 1)
    AddMenuItem("Delete Book", function()
      l.showDeleteBookConfirmDialog()
    end, MENU_ADD_OPTION_LABEL, "ZoFontGameBold", deleteColor, deleteColor)
  end

  ShowMenu(l.bookMenuBtn, 2, MENU_TYPE_COMBO_BOX)
end

l.showPageMenu -- #()->()
= function()
  if IsMenuVisible() then
    ClearMenu()
    return
  end

  ClearMenu()

  local currentBook = book.getCurrentBook()
  if not currentBook then return end

  local currentPage = book.getCurrentPage()

  AddMenuItem("Add Page", function()
    l.addPage()
  end, MENU_ADD_OPTION_LABEL)

  AddMenuItem("Insert Page", function()
    l.insertPage()
  end, MENU_ADD_OPTION_LABEL)

  if #currentBook.pages > 0 then
    AddMenuItem("Clone Page", function()
      l.clonePage()
    end, MENU_ADD_OPTION_LABEL)

    -- Move page operations (conditional)
    if currentPage > 1 then
      AddMenuItem("Move Page Backward", function()
        l.movePageBackward()
      end, MENU_ADD_OPTION_LABEL)
    end

    if currentPage < #currentBook.pages then
      AddMenuItem("Move Page Forward", function()
        l.movePageForward()
      end, MENU_ADD_OPTION_LABEL)
    end

    -- Delete with red color at the end
    local deleteColor = ZO_ColorDef:New(1, 0, 0, 1)
    AddMenuItem("Delete Page", function()
      l.showDeletePageConfirmDialog()
    end, MENU_ADD_OPTION_LABEL, "ZoFontGameBold", deleteColor, deleteColor)
  end

  ShowMenu(l.pageMenuBtn, 2, MENU_TYPE_COMBO_BOX)
end

l.showInputDialog -- #(#string:title, #string:text, #function:callback, #string:defaultText)->()
= function(title, text, callback, defaultText)
  local uniqueId = "ABRInputDialog"
  ESO_Dialogs[uniqueId] = {
    canQueue = true,
    title = { text = title },
    mainText = { text = text },
    editBox = {
      defaultText = defaultText or "",
      maxChars = 50,
    },
    buttons = {
      {
        text = SI_DIALOG_ACCEPT,
        callback = function(dialog)
          local editBox = dialog:GetNamedChild("EditBox")
          local name = editBox and editBox:GetText() or ""
          if name and name ~= "" then
            if callback then callback(name) end
          end
        end,
      },
      {
        text = SI_DIALOG_CANCEL,
      },
    },
  }
  ZO_Dialogs_ShowDialog(uniqueId, nil, { mainTextParams = {} })
end

l.showNewBookDialog -- #()->()
= function()
  l.showInputDialog("New Book", "Enter book name:", function(name)
    local b = book.createBook(name)
    l.selectBook(b.id)
    l.populateBookDropdown()
    -- Auto enter edit mode for new book
    if not l.isEditMode then
      l.isEditMode = true
      l.showEditMode()
    end
    l.updateDisplay()
  end, "")
end

l.showRenameBookDialog -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  l.showInputDialog("Rename Book", "Enter new name:", function(name)
    if currentBook then
      book.updateBook(currentBook.id, { name = name })
      l.populateBookDropdown()
      l.updateDisplay()
    end
  end, currentBook.name)
end

l.showConfirmationDialog -- #(#string:title, #string:text, #function:confirmCallback)->()
= function(title, text, confirmCallback)
  local uniqueId = "ABRConfirmDialog"
  ESO_Dialogs[uniqueId] = {
    canQueue = true,
    title = { text = title },
    mainText = { text = text },
    buttons = {
      {
        text = SI_DIALOG_CONFIRM,
        callback = function()
          if confirmCallback then confirmCallback() end
        end,
      },
      {
        text = SI_DIALOG_CANCEL,
      },
    },
  }
  ZO_Dialogs_ShowDialog(uniqueId, nil, { mainTextParams = {} })
end

l.showDeleteBookConfirmDialog -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end

  -- Find current book's index in sorted list
  local sortedBooks = l.getSortedBooks()
  local currentIndex = 0
  for i, b in ipairs(sortedBooks) do
    if b.id == currentBook.id then
      currentIndex = i
      break
    end
  end

  l.showConfirmationDialog("Delete Book", "Are you sure you want to delete this book?",
    function()
      book.deleteBook(currentBook.id)

      -- Get updated sorted list after deletion
      sortedBooks = l.getSortedBooks()

      if #sortedBooks > 0 then
        -- Select appropriate book: last one if deleted last, otherwise same index
        local newIndex = math.min(currentIndex, #sortedBooks)
        l.selectBook(sortedBooks[newIndex].id)
      end

      l.populateBookDropdown()
      l.updateDisplay()
    end)
end

l.showDeletePageConfirmDialog -- #()->()
= function()
  l.showConfirmationDialog("Delete Page", "Are you sure you want to delete this page?",
    function()
      l.deletePage()
    end)
end

l.getSortedBooks -- #()->(#table)
= function()
  local books = book.getAllBooks()
  local sortedBooks = {}
  for id, b in pairs(books) do
    table.insert(sortedBooks, {id = id, name = b.name})
  end
  table.sort(sortedBooks, function(a, b) return a.name < b.name end)
  return sortedBooks
end

l.populateBookDropdown -- #()->()
= function()
  l.bookDropdownObject:ClearItems()
  local sortedBooks = l.getSortedBooks()

  for _, b in ipairs(sortedBooks) do
    local entry = l.bookDropdownObject:CreateItemEntry(b.name, function()
      l.selectBook(b.id)
    end)
    l.bookDropdownObject:AddItem(entry)
  end
end

l.selectBook -- #(#number:bookId)->()
= function(bookId)
  book.setCurrentBook(bookId)
  local currentBook = book.getCurrentBook()
  -- Auto create first page if book has no pages
  if currentBook and #currentBook.pages == 0 then
    book.addPage(bookId, "")
  end
  l.updateDisplay()
end

l.prevPage -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook or #currentBook.pages == 0 then return end

  local currentPage = book.getCurrentPage()
  if currentPage > 1 then
    if l.isEditMode then
      l.saveCurrentPage()
    end
    book.setCurrentPage(currentPage - 1)
    if l.isEditMode then
      l.showEditMode()
    end
    l.updateDisplay()
  end
end

l.nextPage -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook or #currentBook.pages == 0 then return end

  local currentPage = book.getCurrentPage()
  if currentPage < #currentBook.pages then
    if l.isEditMode then
      l.saveCurrentPage()
    end
    book.setCurrentPage(currentPage + 1)
    if l.isEditMode then
      l.showEditMode()
    end
    l.updateDisplay()
  end
end

l.addPage -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  local currentPage = book.getCurrentPage()
  -- If no pages, add at position 1
  if #currentBook.pages == 0 then
    book.insertPage(currentBook.id, 1, "")
    book.setCurrentPage(1)
  else
    -- Add page after current page
    book.insertPage(currentBook.id, currentPage + 1, "")
    book.setCurrentPage(currentPage + 1)
  end
  -- Enter edit mode and clear content for new page
  if not l.isEditMode then
    l.isEditMode = true
  end
  l.showEditMode()
  l.updateDisplay()
end

l.insertPage -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  local currentPage = book.getCurrentPage()
  -- If no pages, insert at position 1
  if #currentBook.pages == 0 then
    book.insertPage(currentBook.id, 1, "")
    book.setCurrentPage(1)
  else
    -- Insert page before current page
    book.insertPage(currentBook.id, currentPage, "")
    -- New page is now at current position, no need to change page
  end
  -- Enter edit mode and clear content for new page
  if not l.isEditMode then
    l.isEditMode = true
  end
  l.showEditMode()
  l.updateDisplay()
end

l.movePageForward -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  local currentPage = book.getCurrentPage()
  if book.movePageForward(currentBook.id, currentPage) then
    book.setCurrentPage(currentPage + 1)
    if l.isEditMode then
      l.showEditMode()
    end
    l.updateDisplay()
  end
end

l.movePageBackward -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  local currentPage = book.getCurrentPage()
  if book.movePageBackward(currentBook.id, currentPage) then
    book.setCurrentPage(currentPage - 1)
    if l.isEditMode then
      l.showEditMode()
    end
    l.updateDisplay()
  end
end

l.clonePage -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  local currentPage = book.getCurrentPage()
  local page = currentBook.pages[currentPage]
  if page then
    -- Insert cloned page after current page
    book.insertPage(currentBook.id, currentPage + 1, page.content)
    -- Select the new cloned page
    book.setCurrentPage(currentPage + 1)
    -- Enter edit mode for cloned page
    if not l.isEditMode then
      l.isEditMode = true
    end
    l.showEditMode()
    l.updateDisplay()
  end
end

l.deletePage -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  local currentPage = book.getCurrentPage()
  book.deletePage(currentBook.id, currentPage)
  l.updateDisplay()
end

l.toggleEditMode -- #()->()
= function()
  l.isEditMode = not l.isEditMode
  if l.isEditMode then
    l.showEditMode()
  else
    l.hideEditMode()
  end
end

l.toggleLeaderMode -- #()->()
= function()
  l.leaderMode = not l.leaderMode
  l.updateLeaderButton()
  -- Exit edit mode if disabling leader mode
  if not l.leaderMode and l.isEditMode then
    l.isEditMode = false
    l.hideEditMode()
  end
  l.updateDisplay()
end

l.updateLeaderButton -- #()->()
= function()
  -- Change alpha to indicate mode
  l.leaderBtn:SetAlpha(l.leaderMode and 1.0 or 0.5)
end

l.showEditMode -- #()->()
= function()
  l.contentLabel:SetHidden(true)
  l.editBoxContainer:SetHidden(false)
  l.editBox:SetHidden(false)
  l.editButton:SetText("Done")
  l.titleLabel:SetText("Edit Mode")
  -- Load current page content into edit box
  local currentBook = book.getCurrentBook()
  if currentBook then
    local currentPage = book.getCurrentPage()
    local page = currentBook.pages[currentPage]
    if page then
      l.editBox:SetText(page.content)
    else
      l.editBox:SetText("")
    end
  end
end

l.hideEditMode -- #()->()
= function()
  l.saveCurrentPage()
  l.contentLabel:SetHidden(false)
  l.editBoxContainer:SetHidden(true)
  l.editBox:SetHidden(true)
  l.editButton:SetText("Edit")
  l.titleLabel:SetText("Activity Board Reminder")
  l.updateDisplay()
end

l.saveCurrentPage -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  if not currentBook then return end
  local content = l.editBox:GetText()
  local currentPage = book.getCurrentPage()
  book.updatePage(currentBook.id, currentPage, content)
end

l.closeWindow -- #()->()
= function()
  if l.isEditMode then
    l.hideEditMode()
  end
  l.window:SetHidden(true)
end

l.updateDisplay -- #()->()
= function()
  local currentBook = book.getCurrentBook()
  local currentPage = book.getCurrentPage()
  local canEdit = core.canEdit()
  local showLeaderUI = canEdit and l.leaderMode

  -- Leader button only visible for leaders/ungrouped
  l.leaderBtn:SetHidden(not canEdit)

  -- Show selection and control areas only in leader mode
  l.selectionArea:SetHidden(not showLeaderUI)
  l.bookLabel:SetHidden(not showLeaderUI)
  l.bookDropdown:SetHidden(not showLeaderUI)
  l.bookMenuBtn:SetHidden(not showLeaderUI)
  l.pagePrevBtn:SetHidden(not showLeaderUI)
  l.pageLabel:SetHidden(not showLeaderUI)
  l.pageNextBtn:SetHidden(not showLeaderUI)
  l.pageMenuBtn:SetHidden(not showLeaderUI)
  l.controlArea:SetHidden(not showLeaderUI)
  l.editButton:SetHidden(not showLeaderUI)

  -- Adjust content area anchor based on mode
  if showLeaderUI then
    l.contentLabel:SetAnchor(TOPLEFT, l.window, TOPLEFT, 15, 85)
    l.editBoxContainer:SetAnchor(TOPLEFT, l.window, TOPLEFT, 15, 85)
  else
    l.contentLabel:SetAnchor(TOPLEFT, l.window, TOPLEFT, 15, 45)
    l.editBoxContainer:SetAnchor(TOPLEFT, l.window, TOPLEFT, 15, 45)
  end

  if not currentBook or #currentBook.pages == 0 then
    l.contentLabel:SetText(showLeaderUI and "No book selected. Click Book menu to create one." or "Waiting for leader...")
    l.pageLabel:SetText("0/0")
    l.window:SetHidden(not showLeaderUI)
    return
  end

  l.window:SetHidden(false)
  local page = currentBook.pages[currentPage]
  if page then
    l.contentLabel:SetText(page.content)
  else
    l.contentLabel:SetText("")
  end

  -- Update book dropdown selection
  l.bookDropdownObject:SetSelectedItem(currentBook.name)

  -- Update page label
  l.pageLabel:SetText(string.format("%d/%d", currentPage, #currentBook.pages))

  -- Update prev/next button states
  l.pagePrevBtn:SetEnabled(currentPage > 1)
  l.pageNextBtn:SetEnabled(currentPage < #currentBook.pages)
end

l.onSyncBook -- #(#string:unitTag, #number:bookId, #number:pageNum, #string:content)->()
= function(unitTag, bookId, pageNum, content)
  book.setCurrentBook(bookId)
  book.setCurrentPage(pageNum)
  if content and content ~= "" then
    local b = book.getBook(bookId)
    if b and b.pages[pageNum] then
      b.pages[pageNum].content = content
    end
  end
  l.populateBookDropdown()
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
  local settings = addon.load("Settings#M")

  l.createUI()

  -- Register network handlers
  addon.extend(network.EXTKEY_ON_SYNC_BOOK, l.onSyncBook)
  addon.extend(network.EXTKEY_ON_CHANGE_PAGE, l.onChangePage)
  addon.extend(network.EXTKEY_ON_CLOSE, l.onClose)

  -- Register slash command
  SLASH_COMMANDS["/abr"] = function()
    l.populateBookDropdown()
    l.updateDisplay()
  end

  -- Add description to settings panel
  addon.extend(settings.EXTKEY_ADD_DESCRIPTIONS, function(addMenuOptions)
    addMenuOptions({
      type = "description",
      text = "Slash Commands:\n  /abr - Open the viewer window",
    })
  end)

  addon.debug("Viewer module initialized")
end

--========================================
--        m
--========================================
m.EXTKEY_ON_EDIT_MODE_CHANGED = "Viewer:onEditModeChanged"

m.show -- #()->()
= function()
  l.populateBookDropdown()
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

-- Register extension before onStart
addon.extend("Settings:addDescriptions", function(addMenuOptions)
  addMenuOptions({
    type = "description",
    text = "Slash Commands:\n  /abr - Open the viewer window",
  })
end)

addon.hookStart(l.onStart)
