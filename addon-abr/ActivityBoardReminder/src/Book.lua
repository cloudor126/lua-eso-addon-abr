--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local l = {} -- private table
local m = {l=l} -- public table

local SV_NAME = "ABRSV"
local SV_VER = "1.0"

--========================================
--        l
--========================================
l.savedVars = nil
l.savedVarsDefaults = {
  books = {},
  currentBookId = nil,
  currentPage = 1,
  windowPosition = {x = 100, y = 100},
  isEditMode = false,
}

l.onStart -- #()->()
= function()
  addon.callExtension(m.EXTKEY_ADD_DEFAULTS)
  l.savedVars = ZO_SavedVars:NewAccountWide(SV_NAME, SV_VER, nil, l.savedVarsDefaults)
  addon.debug("Book module initialized")
end

--========================================
--        m
--========================================
m.EXTKEY_ADD_DEFAULTS = "Book:addDefaults"

m.getSavedVars -- #()->(#table)
= function()
  return l.savedVars
end

m.addDefaults -- #(#table:defaults)->()
= function(defaults)
  zo_mixin(l.savedVarsDefaults, defaults)
end

-- Book operations
m.createBook -- #(#string:name)->(#table)
= function(name)
  local sv = l.savedVars
  local id = GetTimeStamp()
  local book = {
    id = id,
    name = name,
    pages = {},
    createdTime = id,
    lastModified = id,
  }
  sv.books[id] = book
  return book
end

m.getBook -- #(#number:id)->(#table|nil)
= function(id)
  return l.savedVars.books[id]
end

m.updateBook -- #(#number:id, #table:updates)->(#boolean)
= function(id, updates)
  local book = l.savedVars.books[id]
  if not book then return false end
  for k, v in pairs(updates) do
    book[k] = v
  end
  book.lastModified = GetTimeStamp()
  return true
end

m.deleteBook -- #(#number:id)->()
= function(id)
  l.savedVars.books[id] = nil
  if l.savedVars.currentBookId == id then
    l.savedVars.currentBookId = nil
    l.savedVars.currentPage = 1
  end
end

m.getAllBooks -- #()->(#table)
= function()
  return l.savedVars.books
end

-- Page operations
m.addPage -- #(#number:bookId, #string:content)->(#number|nil)
= function(bookId, content)
  local book = l.savedVars.books[bookId]
  if not book then return nil end
  local page = {
    content = content or "",
    fontSize = 14,
  }
  table.insert(book.pages, page)
  book.lastModified = GetTimeStamp()
  return #book.pages
end

m.updatePage -- #(#number:bookId, #number:pageIndex, #string:content)->(#boolean)
= function(bookId, pageIndex, content)
  local book = l.savedVars.books[bookId]
  if not book or not book.pages[pageIndex] then return false end
  book.pages[pageIndex].content = content
  book.lastModified = GetTimeStamp()
  return true
end

m.deletePage -- #(#number:bookId, #number:pageIndex)->(#boolean)
= function(bookId, pageIndex)
  local book = l.savedVars.books[bookId]
  if not book or not book.pages[pageIndex] then return false end
  table.remove(book.pages, pageIndex)
  book.lastModified = GetTimeStamp()
  return true
end

-- Current book state
m.setCurrentBook -- #(#number:bookId)->()
= function(bookId)
  l.savedVars.currentBookId = bookId
  l.savedVars.currentPage = 1
end

m.setCurrentPage -- #(#number:pageNum)->()
= function(pageNum)
  l.savedVars.currentPage = pageNum
end

m.getCurrentBook -- #()->(#table|nil)
= function()
  return l.savedVars.books[l.savedVars.currentBookId]
end

m.getCurrentPage -- #()->(#number)
= function()
  return l.savedVars.currentPage
end

--========================================
--        register
--========================================
addon.register("Book#M", m)
addon.hookStart(l.onStart)