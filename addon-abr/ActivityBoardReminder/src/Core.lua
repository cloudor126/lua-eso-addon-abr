--========================================
--        vars
--========================================
local addon = ActivityBoardReminder
local l = {} -- private table
local m = {l=l} -- public table

--========================================
--        l
--========================================

--========================================
--        m
--========================================

m.isGrouped -- #()->(#boolean)
= function()
  return IsUnitGrouped("player")
end

m.isLeader -- #()->(#boolean)
= function()
  return IsUnitGrouped("player") and IsUnitGroupLeader("player")
end

m.canEdit -- #()->(#boolean)
= function()
  return not IsUnitGrouped("player") or IsUnitGroupLeader("player")
end

m.getGroupSize -- #()->(#number)
= function()
  return GetGroupSize()
end

m.getGroupMember -- #(#number:index)->(#table|nil)
= function(index)
  local unitTag = GetGroupUnitTagByIndex(index)
  if unitTag then
    return {
      unitTag = unitTag,
      name = GetUnitName(unitTag),
      displayName = GetUnitDisplayName(unitTag),
      isLeader = IsUnitGroupLeader(unitTag),
    }
  end
  return nil
end

m.getGroupMembers -- #()->(#list<#table>)
= function()
  local members = {}
  local size = GetGroupSize()
  for i = 1, size do
    local member = m.getGroupMember(i)
    if member then
      table.insert(members, member)
    end
  end
  return members
end

--========================================
--        register
--========================================
addon.register("Core#M", m)
