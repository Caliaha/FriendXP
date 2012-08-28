FriendXP = LibStub("AceAddon-3.0"):NewAddon("FriendXP", "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0","AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("FriendXP")
local LSM = LibStub("LibSharedMedia-3.0")
--local LDB = LibStub:GetLibrary("LibDataBroker-1.1",true)
local LQT = LibStub("LibQTip-1.0")

LSM:Register("background", "Wireless Icon", "Interface\\Addons\\FriendXP\\Artwork\\wlan_wizard.tga")
LSM:Register("background", "Wireless Icon2", "Interface\\Addons\\FriendXP\\Artwork\\wlan_wizard2.tga")
LSM:Register("background", "Wireless Incoming", "Interface\\Addons\\FriendXP\\Artwork\\wlan_incoming.tga")
LSM:Register("background", "PartyXPBar", "Interface\\Addons\\FriendXP\\Artwork\\partyxpbar.tga")
LSM:Register("border", "Thin Square 1px", "Interface\\Addons\\FriendXP\\Artwork\\Square 1px.tga")
LSM:Register("border", "Thin Square 2px", "Interface\\Addons\\FriendXP\\Artwork\\Square 2px.tga")

local newFriends = { }; -- Needs renaming
local fonts = { };

local Miniframes = { };
local frameCache = { };

local Miniframe = nil;
local xpbar = nil;

local configGenerated = false;
local activeFriend = "";

-- local whatevers
local gsub = string.gsub


FriendXP.LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("FriendXP", {
 type = "launcher",
 label = "FriendXP",
 icon = "Interface\\ICONS\\Achievement_DoubleRainbow.blp",
 OnClick = function(clickedFrame, button)
  if (button == "LeftButton") then
   FriendXP:SendXP()
  elseif (button == "RightButton") then
   if (configGenerated) then
    InterfaceOptionsFrame_OpenToCategory(FriendXP.configFrame)
   else
    FriendXP:WorldEnter()
   end
  end
 end,
})

-- Need to rework the options menu
local function giveOptions(self)
 local maxwidth = self:Round(UIParent:GetWidth(),0);
 local maxheight = self:Round(UIParent:GetHeight(),0);
 local db = self.db.profile -- To shorten some of the variables
 local options = {
 name = "FriendXP",
 type = "group",
 args = {
  enabled = {
   name = L["Enabled"],
   order = 1,
   type = "toggle",
   set = function(info, value) self.db.profile.enabled = value; if (value) then self:Enable() else self:Disable() end; end,
   get = function(info) return self.db.profile.enabled end
  },
  unlocked = {
   name = L["Toggle Lock"],
   desc = L["UnlockDesc"],
   type = "execute",
   func = function() FriendXP:ToggleLock() end,
  },
  debug = {
   name = L["Debug"],
   order = 2,
   type = "toggle",
   set = function(info, value) self.db.profile.debug = value end,
   get = function(info) return self.db.profile.debug end,
  },
  online = {
   name = L["Check Online Status"],
   desc = L["CheckOnlineDesc"],
   order = 3,
   type = "toggle",
   get = function(info) return self.db.profile.checkOnline end,
   set = function(info, value) self.db.profile.checkOnline = value end,
  },
  doLevelUp = {
   name = L["Level Up Message"],
   desc = L["LevelUpMessageDesc"],
   order = 4,
   type = "toggle",
   get = function(i) return self.db.profile.doLevelUp end,
   set = function(i, v) self.db.profile.doLevelUp = v end,
  },
  integrateParty = {
   name = L["IntegrateParty"],
   desc = L["IntegratePartyDesc"],
   type = "toggle",
   get = function(i) return self.db.profile.integrateParty end,
   set = function(i, v) self.db.profile.integrateParty = v; self:HookBlizzPartyFrames() end,
  },
  ignoreWhisper = {
   name = L["Ignore Whispers"],
   desc = L["IgnoreWhisper_Desc"],
   type = "toggle",
   get = function(i) return self.db.profile.ignoreWhisper end,
   set = function(i, v) self.db.profile.ignoreWhisper = v end,
  },
  onlyFriends = {
   name = L["Only allow friends"],
   desc = L["OnlyFriendsDesc"],
   type = "toggle",
   get = function(i) return self.db.profile.onlyFriends end,
   set = function(i, v) self.db.profile.onlyFriends = v end,
  },
 --[[ friend = {
   name = L["AddFriend"],
   desc = L["AddFriend_Desc"],
   order = 4,
   type = "input",
   get = function(info) return "" end,
   set = function(i, v) self:AddFriend(v); self:UpdateSettings() end,
  },
  friendlist = {
   name = "List of friends to delete",
   desc = "Select a friend to delete",
   type = "select",
   values = function() return self.db.profile.friends end, --Need to verify if working
   --get = function(info) return self.db.profile.friends end,
   set = function(i, v) self.Print("i",i,"v",v,"combined",self.db.profile.friends[v]); self:DeleteFriend(v); end,
   style = "dropdown",
  }, ]]
  friendttl = {
   name = L["FriendTTL"],
   desc = L["FriendTTL_Desc"],
   type = "range",
   min = 10, max = 1800, step = 1,
   set = function(i, v) self.db.profile.miniframe.threshold = v end,
   get = function(i) return self.db.profile.miniframe.threshold end,
  },
  sendoptions = {
   name = L["Broadcast To"],
   order = 0.9,
   type = "group",
   args = {
    friendAll = {
     name = L["SendFriends"],
     desc = L["SendFriendsDesc"],
     type = "toggle",
     get = function(i) return self.db.profile.sendAll end,
     set = function(i, v) self.db.profile.sendAll = v end,
    },
    partyAll = {
     name = L["SendParty"],
     desc = L["SendPartyDesc"],
     type = "toggle",
     get = function(i) return self.db.profile.partyAll end,
     set = function(i, v) self.db.profile.partyAll = v end,
    },
    bgAll = {
     name = L["SendBattleground"],
     desc = L["SendBattlegroundDesc"],
     type = "toggle",
     get = function(i) return self.db.profile.bgAll end,
     set = function(i, v) self.db.profile.bgAll = v end,
    },
    guildAll = {
     name = L["SendGuild"],
     desc = L["SendGuildDesc"],
     type = "toggle",
     get = function(i) return self.db.profile.guildAll end,
     set = function(i, v) self.db.profile.guildAll = v end,
    },
   },
  },
  friendbar = {
   name = "FriendBar",
   order = 1,
   type = "group",
   args = {
    enabled = {
     name = L["Enabled"],
     order = 1,
     type = "toggle",
     set = function(i, v) self.db.profile.friendbar.enabled = v; self:ToggleFriendbar() end,
     get = function(i) return self.db.profile.friendbar.enabled end,
    },
    fontheader = {
     name = L["Font"],
     order = 3,
     type = "header",
    },
    face = {
     name = L["FontFace"],
     desc = "Fontface",
     order = 3.1,
     type = "select",
     values = LSM:HashTable("font"),
     dialogControl = "LSM30_Font",
     get = function(info) return self.db.profile.friendbar.text.font end,
     set = function(info, value) self.db.profile.friendbar.text.font = value; self:UpdateSettings() end,
    },
    style = {
     name = L["FontStyle"],
     order = 3.2,
     type = "select",
     style = "dropdown",
     values = { [""] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick Outline", ["MONOCHROME"] = "Monochrome", },
     set = function(i, v) self.db.profile.friendbar.text.style = v; self:UpdateSettings() end,
     get = function(i) return self.db.profile.friendbar.text.style end,
    },
    size = {
     name = L["FontSize"],
     desc = "Size of the text",
     order = 3.3,
     type = "range",
     min = 1, max = 40, step = 1,
     get = function(info) return self.db.profile.friendbar.text.size end,
     set = function(info, value) self.db.profile.friendbar.text.size = value; self:UpdateSettings(); end,
    },
    textcolor = {
     name = L["FontColor"],
     order = 3.4,
     type = "color",
     hasAlpha = true,
     get = function(info) return self.db.profile.friendbar.text.color.r, self.db.profile.friendbar.text.color.g, self.db.profile.friendbar.text.color.b, self.db.profile.friendbar.text.color.a end,
     set = function(info, r, g, b, a) self.db.profile.friendbar.text.color.r = r; self.db.profile.friendbar.text.color.g = g; self.db.profile.friendbar.text.color.b = b; self.db.profile.friendbar.text.color.a = a; self:UpdateSettings() end,
    },
    formatstring = {
     name = "Format String",
     order = 3.5,
     type = "input",
     width = "double",
     get = function(i) return self.db.profile.friendbar.formatstring end,
     set = function(i, v) self.db.profile.friendbar.formatstring = v; if (activeFriend ~= "") then self:UpdateFriendXP_HELPER(activeFriend) end end,
    },
    styleheader = {
     name = L["Bar Style"],
     order = 2,
     type = "header",
    },
    texture = {
     name = "Bar Texture",
     desc = "Texture of the power bar",
     order = 2.1,
     type = "select",
     values = LSM:HashTable("statusbar"),
     dialogControl = "LSM30_Statusbar",
     get = function(info) return self.db.profile.friendbar.texture end,
     set = function(info, value) self.db.profile.friendbar.texture = value; self:UpdateSettings() end,
    },
    color = {
     name = "Experience bar color",
     desc = "Color of the experience bar",
     order = 2.2,
     type = "color",
     hasAlpha = false,
     get = function(info) return self.db.profile.friendbar.color.r, self.db.profile.friendbar.color.g, self.db.profile.friendbar.color.b, self.db.profile.friendbar.color.a end,
     set = function(info, r, g, b, a) self.db.profile.friendbar.color.r = r; self.db.profile.friendbar.color.g = g; self.db.profile.friendbar.color.b = b; self.db.profile.friendbar.color.a = a; self:UpdateSettings() end,
    },
    bgcolor = {
     name = "Experience bar background color",
     desc = "Color of the background bar",
     order = 2.3,
     type = "color",
     hasAlpha = true,
     get = function(info) return self.db.profile.friendbar.bgcolor.r, self.db.profile.friendbar.bgcolor.g, self.db.profile.friendbar.bgcolor.b, self.db.profile.friendbar.bgcolor.a end,
     set = function(info, r, g, b, a) self.db.profile.friendbar.bgcolor.r = r; self.db.profile.friendbar.bgcolor.g = g; self.db.profile.friendbar.bgcolor.b = b; self.db.profile.friendbar.bgcolor.a = a; self:UpdateSettings() end,
    },
    restcolor = {
     name = "Rest bar color",
     desc = "Color of the rest bonus bar",
     order = 2.4,
     type = "color",
     hasAlpha = false,
     get = function(info) return self.db.profile.friendbar.rest.r,self.db.profile.friendbar.rest.g,self.db.profile.friendbar.rest.b,self.db.profile.friendbar.rest.a end,
     set = function(info, r, g, b, a) self.db.profile.friendbar.rest.r = r; self.db.profile.friendbar.rest.g = g; self.db.profile.friendbar.rest.b = b; self.db.profile.friendbar.rest.a = a; self:UpdateSettings() end,
    },
    locationheader = {
     name = L["Size and Position"],
     order = 1,
     type = "header",
    },
    width = {
     name = L["Width"],
     order = 1.1,
     desc = "Width of the total xp bar",
     type = "range",
     min = 0.01, max = 1, step = 0.01,
     get = function(info) return self.db.profile.friendbar.width end,
     set = function(info, value) self.db.profile.friendbar.width = tonumber(value);  self:UpdateSettings() end,
    },
    height = {
     name = L["Height"],
     order = 1.2,
     desc = "Height of the total xp bar",
     type = "range",
     min = 0.01, max = 60, step = 0.01,
     get = function(info) return self.db.profile.friendbar.height end,
     set = function(info,value) self.db.profile.friendbar.height = tonumber(value); self:UpdateSettings() end,
    },
    posx = {
     name = "X",
     desc = "Position along the x axis",
     order = 1.3,
     type = "range",
     min = 0, max = maxwidth, step = 1,
     get = function(info) return self.db.profile.friendbar.x end,
     set = function(info, value) self.db.profile.friendbar.x = tonumber(value); self:UpdateSettings() end,
    },
    posy = {
     name = "Y",
     desc = "Position along the y axis",
     order = 1.4,
     type = "range",
     min = -maxheight, max = 0, step = 1,
     get = function(info) return self.db.profile.friendbar.y end,
     set = function(info, value) self.db.profile.friendbar.y = tonumber(value); self:UpdateSettings() end,
    },
    mischeader = {
     name = L["Miscellaneous"],
     order = 4,
     type = "header",
    },
    framestrata = {
     name = L["Frame Strata"],
     order = 4.1,
     type = "select",
     style = "dropdown",
     values = { ["BACKGROUND"] = "Background", ["LOW"] = "Low", ["MEDIUM"] = "Medium", ["HIGH"] = "High", ["DIALOG"] = "Dialog" },
     set = function(i, v) self.db.profile.friendbar.framestrata = v; self:UpdateSettings() end,
     get = function(i) return self.db.profile.friendbar.framestrata end,
    },
    framelevel = {
     name = L["Frame Level"],
     order = 4.2,
     type = "range",
     min = 1, max = 100, step = 1,
     get = function(i) return self.db.profile.friendbar.framelevel end,
     set = function(i, v) self.db.profile.friendbar.framelevel = v; self:UpdateSettings(); end
    },

   },
  },
  tooltip = {
   name = L["LDB Tooltip"],
   type = "group",
   order = 3,
   args = {
    headerheader = {
     name = L["Header Font Style"],
     order = 1,
     type = "header",
    },
    face = {
     name = "Header Font Face",
     desc = "Font face",
     order = 1.1,
     type = "select",
     values = LSM:HashTable("font"),
     dialogControl = "LSM30_Font",
     get = function(info) return self.db.profile.tooltip.header.font end,
     set = function(info, value) self.db.profile.tooltip.header.font = value; self:UpdateFonts("header", self.db.profile.tooltip.header.size, self.db.profile.tooltip.header.color.r, self.db.profile.tooltip.header.color.g, self.db.profile.tooltip.header.color.g); end,
    },
    headersize = {
     name = "Header Size",
     desc = "Header Size",
     order = 1.2,
     type = "range",
     min = 8, max = 24, step = 1,
     get = function(info) return self.db.profile.tooltip.header.size end,
     set = function(info, value) self.db.profile.tooltip.header.size = value; self:UpdateFonts("header", self.db.profile.tooltip.header.size, self.db.profile.tooltip.header.color.r, self.db.profile.tooltip.header.color.g, self.db.profile.tooltip.header.color.b); end,
    },
    headercolor = {
     name = "Header Color",
     order = 1.3,
     type = "color",
     hasAlpha = false,
     get = function(info) return self.db.profile.tooltip.header.color.r, self.db.profile.tooltip.header.color.g, self.db.profile.tooltip.header.color.b, 1 end,
     set = function(info, r, g, b) self.db.profile.tooltip.header.color.r = r; self.db.profile.tooltip.header.color.g = g; self.db.profile.tooltip.header.color.b = b; self:UpdateFonts("header", self.db.profile.tooltip.header.size, self.db.profile.tooltip.header.color.r, self.db.profile.tooltip.header.color.g, self.db.profile.tooltip.header.color.b); end,
    },
    normalheader = {
     name = L["Normal Font Style"],
     order = 2,
     type = "header",
    },
    normalface = {
     name = "Normal Font face",
     desc = "Normal tooltip font face",
     order = 2.1,
     type = "select",
     values = LSM:HashTable("font"),
     dialogControl = "LSM30_Font",
     get = function(info) return self.db.profile.tooltip.normal.font end,
     set = function(info, value) self.db.profile.tooltip.normal.font = value; self:UpdateFonts("normal", self.db.profile.tooltip.normal.size, self.db.profile.tooltip.normal.color.r, self.db.profile.tooltip.normal.color.g, self.db.profile.tooltip.normal.color.g); end,
    },
    normalsize = {
     name = "Normal Size",
     desc = "Normal Size",
     order = 2.2,
     type = "range",
     min = 8, max = 24, step = 1,
     get = function(info) return self.db.profile.tooltip.normal.size end,
     set = function(info, value) self.db.profile.tooltip.normal.size = value; self:UpdateFonts("normal", self.db.profile.tooltip.normal.size, self.db.profile.tooltip.normal.color.r, self.db.profile.tooltip.normal.color.g, self.db.profile.tooltip.normal.color.g); end,
    },
    normalcolor = {
     name = "Normal Color",
     type = "color",
     order = 2.3,
     hasAlpha = false,
     get = function(info) return self.db.profile.tooltip.normal.color.r, self.db.profile.tooltip.normal.color.g, self.db.profile.tooltip.normal.color.b end,
     set = function(info, r, g, b) self.db.profile.tooltip.normal.color.r = r; self.db.profile.tooltip.normal.color.g = g; self.db.profile.tooltip.normal.color.b = b; self:UpdateFonts("normal", self.db.profile.tooltip.normal.size, self.db.profile.tooltip.normal.color.r, self.db.profile.tooltip.normal.color.g, self.db.profile.tooltip.normal.color.b); end,
    },
   },
  },
  miniframe = {
   name = "Miniframe",
   type = "group",
   order = 2,
   args = {
    enabled = {
     name = "Enable Miniframe",
     order = 1,
     type = "toggle",
     set = function(i, v) self.db.profile.miniframe.enabled = v; self:SetupMiniframe() end,
     get = function(i) return self.db.profile.miniframe.enabled end,
    },
    friendlimitheader = {
     name = L["Size Limits"],
     order = 2,
     type = "header",
    },
    friendlimit = {
     name = "Friend Limit",
     desc = "Maximun number of friends to show",
     width = "half",
     order = 2.1,
     type = "input",
     get = function(i) return tostring(self.db.profile.miniframe.friendlimit) end,
     set = function(i, v) self.db.profile.miniframe.friendlimit = tonumber(v); self:UpdateMiniframe() end,
    },
    columnlimit = {
     name = "Column Limit",
     desc = "Number of friends to show per column",
     width = "half",
     order = 2.2,
     type = "input",
     get = function(i) return tostring(self.db.profile.miniframe.columnlimit) end,
     set = function(i, v) self.db.profile.miniframe.columnlimit = tonumber(v); self:UpdateMiniframe() end,
    },
    locationheader = {
     name = L["Position"],
     order = 3,
     type = "header",
    },
    posx = {
     name = "X",
     desc = "Position along the x axis",
     order = 3.1,
     type = "range",
     min = 0, max = maxwidth, step = 1,
     get = function(info) return self.db.profile.miniframe.x end,
     set = function(info, value) self.db.profile.miniframe.x = tonumber(value); self:SetupMiniframe() end,
    },
    posy = {
     name = "Y",
     desc = "Position along the y axis",
     order = 3.2,
     type = "range",
     min = -maxheight, max = 0, step = 1,
     get = function(info) return self.db.profile.miniframe.y end,
     set = function(info, value) self.db.profile.miniframe.y = tonumber(value); self:SetupMiniframe() end,
    },
    styleheader = {
     name = L["Miniframe Style"],
     order = 4,
     type = "header",
    },
    border = {
     name = "Miniframe Border",
     order = 4.1,
     type = "select",
     values = LSM:HashTable("border"),
     dialogControl = "LSM30_Border",
     get = function(info) return self.db.profile.miniframe.border.border end,
     set = function(info, value) self.db.profile.miniframe.border.border = value; self:SetupMiniframe() end,
    },
    bordercolor = {
     name = "Miniframe Border Color",
     order = 4.2,
     type = "color",
     hasAlpha = true,
     get = function(info) return self.db.profile.miniframe.border.color.r, self.db.profile.miniframe.border.color.g, self.db.profile.miniframe.border.color.b, self.db.profile.miniframe.border.color.a end,
     set = function(info, r, g, b, a) self.db.profile.miniframe.border.color.r = r; self.db.profile.miniframe.border.color.g = g; self.db.profile.miniframe.border.color.b = b; self.db.profile.miniframe.border.color.a = a; self:SetupMiniframe(); end,
    },
    bordersize = {
     name = "Border size",
     order = 4.3,
     type = "range",
     min = 1, max = 64, step = 1,
     get = function(i) return self.db.profile.miniframe.border.bordersize end,
     set = function(i, v) self.db.profile.miniframe.border.bordersize = v; self:SetupMiniframe() end,
    },
    insetleft = {
     name = "Left Inset",
     order = 4.6,
     width = "half",
     type = "input",
     get = function(i) return tostring(self.db.profile.miniframe.border.inset.left) end,
     set = function(i, v) self.db.profile.miniframe.border.inset.left = tonumber(v); self:SetupMiniframe() end,
    },
    insetright = {
     name = "Right Inset",
     order = 4.7,
     width = "half",
     type = "input",
     get = function(i) return tostring(self.db.profile.miniframe.border.inset.right) end,
     set = function(i, v) self.db.profile.miniframe.border.inset.right = tonumber(v); self:SetupMiniframe() end,
    },
    insettop = {
     name = "Top Inset",
     order = 4.8,
     width = "half",
     type = "input",
     get = function(i) return tostring(self.db.profile.miniframe.border.inset.top) end,
     set = function(i, v) self.db.profile.miniframe.border.inset.top = tonumber(v); self:SetupMiniframe() end,
    },
    insetbottom = {
     name = "Bottom Inset",
     order = 4.9,
     width = "half",
     type = "input",
     get = function(i) return tostring(self.db.profile.miniframe.border.inset.bottom) end,
     set = function(i, v) self.db.profile.miniframe.border.inset.bottom = tonumber(v); self:SetupMiniframe() end,
    },
    background = {
     name = "Miniframe background",
     order = 4.4,
     type = "select",
     values = LSM:HashTable("background"),
     dialogControl = "LSM30_Background",
     get = function(info) return self.db.profile.miniframe.texture end,
     set = function(info, value) self.db.profile.miniframe.texture = value; self:SetupMiniframe() end,
    },
    bgcolor = {
     name = "Miniframe background color",
     order = 4.5,
     type = "color",
     hasAlpha = true,
     get = function(info) return self.db.profile.miniframe.bgcolor.r, self.db.profile.miniframe.bgcolor.g, self.db.profile.miniframe.bgcolor.b, self.db.profile.miniframe.bgcolor.a end,
     set = function(info, r, g, b, a) self.db.profile.miniframe.bgcolor.r = r; self.db.profile.miniframe.bgcolor.g = g; self.db.profile.miniframe.bgcolor.b = b; self.db.profile.miniframe.bgcolor.a = a; self:SetupMiniframe() end,
    },
    xpbarheader = {
     name = "Mini XP Bar",
     order = 5,
     type = "header",
    },
    xpbarX = {
     name = "XP Bar Offset X",
     order = 5.1,
     type = "range",
     min = 0, max = maxwidth, step = 1,
     get = function(info) return self.db.profile.miniframe.xp.offsetx end,
     set = function(info, value) self.db.profile.miniframe.xp.offsetx = tonumber(value); self:UpdateMiniframe() end,
    },
    xpbarY = {
     name = "XP Bar Offset Y",
     order = 5.2,
     type = "range",
     min = 0, max = maxheight, step = 1,
     get = function(info) return self.db.profile.miniframe.xp.offsety end,
     set = function(info, value) self.db.profile.miniframe.xp.offsety = tonumber(value); self:UpdateMiniframe() end,
    },
    xpbarWidth = {
     name = "XP Bar Width",
     order = 5.3,
     type = "range",
     min = 0, max = maxwidth, step = 1,
     get = function(info) return self.db.profile.miniframe.xp.width end,
     set = function(info, value) self.db.profile.miniframe.xp.width = tonumber(value); self:SetupMiniframe(); self:UpdateMiniframe() end,
    },
    xpbarHeight = {
     name = "XP Bar Height",
     order = 5.4,
     type = "range",
     min = 0, max = maxheight, step = 1,
     get = function(info) return self.db.profile.miniframe.xp.height end,
     set = function(info, value) self.db.profile.miniframe.xp.height = tonumber(value); self:SetupMiniframe(); self:UpdateMiniframe() end,
    },
    xpbartexture = {
     name = "XP Bar Texture",
     order = 5.5,
     type = "select",
     values = LSM:HashTable("statusbar"),
     dialogControl = "LSM30_Statusbar",
     get = function(info) return self.db.profile.miniframe.xp.texture end,
     set = function(info, value) self.db.profile.miniframe.xp.texture = value; self:UpdateMiniframe() end,
    },
    xpbarbgcolor = {
     name = "XP Bar Background Color",
     order = 5.6,
     type = "color",
     hasAlpha = true,
     get = function(info) return self.db.profile.miniframe.xp.bgcolor.r, self.db.profile.miniframe.xp.bgcolor.g, self.db.profile.miniframe.xp.bgcolor.b, self.db.profile.miniframe.xp.bgcolor.a end,
     set = function(info, r, g, b, a) self.db.profile.miniframe.xp.bgcolor.r = r; self.db.profile.miniframe.xp.bgcolor.g = g; self.db.profile.miniframe.xp.bgcolor.b = b; self.db.profile.miniframe.xp.bgcolor.a = a; self:UpdateMiniframe() end,
    },
    xpbarrestenabled = {
     name = "XP Bar Restbonus Enabled",
     order = 5.7,
     type = "toggle",
     get = function(i) return self.db.profile.miniframe.rest.enabled end,
     set = function(i, v) self.db.profile.miniframe.rest.enabled = v; self:UpdateMiniframe() end
    },
	namelength = {
     name = "Name Length",
     desc = "Name will be truncated to this length, 0 to disable",
     order = 5.8,
     type = "range",
     min = 0, max = 20, step = 1,
     set = function(i, v) self.db.profile.miniframe.xp.namelen = v; self:UpdateMiniframe() end,
     get = function(i) return self.db.profile.miniframe.xp.namelen end,
    },
    xpbarrestcustom = {
     name = L["CustomRestXPBarColorToggle"],
	 desc = L["CustomRestXPBarColorToggleDesc"],
     order = 5.81,
     type = "toggle",
     get = function(i) return self.db.profile.miniframe.rest.custom end,
     set = function(i, v) self.db.profile.miniframe.rest.custom = v; self:UpdateMiniframe() end
    },
    xpbarrestcolor = {
     name = L["CustomRestXPBarColor"],
     order = 5.82,
     type = "color",
     hasAlpha = false,
     get = function(i) return self.db.profile.miniframe.rest.color.r, self.db.profile.miniframe.rest.color.g, self.db.profile.miniframe.rest.color.b end,
     set = function(i, r, g, b) self.db.profile.miniframe.rest.color.r = r; self.db.profile.miniframe.rest.color.g = g; self.db.profile.miniframe.rest.color.b = b; self:UpdateMiniframe() end,
    },
    xpbarcustom = {
	 name = L["CustomXPBarColorToggle"],
	 desc = L["CustomXPBarColorToggleDesc"],
	 order = 5.83,
	 type = "toggle",
	 get = function(i) return db.miniframe.xp.custom end,
	 set = function(i, v) db.miniframe.xp.custom = v; self:UpdateMiniframe() end,
	},
	xpbarcolor = {
	 name = L["CustomXPBarColor"],
	 order = 5.84,
	 type = "color",
	 hasAlpha = false,
	 get = function(i) local x = db.miniframe.xp.color; return x.r, x.g, x.b end,
	 set = function(i, r, g, b) local x = db.miniframe.xp.color; x.r = r; x.g = g; x.b = b; self:UpdateMiniframe() end
	},
    face = {
     name = L["Font Face"],
     desc = "Fontface",
     order = 5.910,
     type = "select",
     values = LSM:HashTable("font"),
     dialogControl = "LSM30_Font",
     get = function(info) return self.db.profile.miniframe.xp.text.font end,
     set = function(info, value) self.db.profile.miniframe.xp.text.font = value; self:UpdateMiniframe() end,
    },
    style = {
     name = L["Font Style"],
     order = 5.911,
     type = "select",
     style = "dropdown",
     values = { [""] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick Outline", ["MONOCHROME"] = "Monochrome", },
     set = function(i, v) self.db.profile.miniframe.xp.text.style = v; self:UpdateMiniframe() end,
     get = function(i) return self.db.profile.miniframe.xp.text.style end,
    },
    size = {
     name = L["Font Size"],
     desc = "Size of the text",
     order = 5.912,
     type = "range",
     min = 1, max = 40, step = 1,
     get = function(info) return self.db.profile.miniframe.xp.text.size end,
     set = function(info, value) self.db.profile.miniframe.xp.text.size = value; self:UpdateMiniframe(); end,
    },
    textcolor = {
     name = L["Font Color"],
     order = 5.913,
     type = "color",
     hasAlpha = true,
     get = function(info) return self.db.profile.miniframe.xp.text.color.r, self.db.profile.miniframe.xp.text.color.g, self.db.profile.miniframe.xp.text.color.b, self.db.profile.miniframe.xp.text.color.a end,
     set = function(info, r, g, b, a) self.db.profile.miniframe.xp.text.color.r = r; self.db.profile.miniframe.xp.text.color.g = g; self.db.profile.miniframe.xp.text.color.b = b; self.db.profile.miniframe.xp.text.color.a = a; self:UpdateMiniframe() end,
    },
    formatstring = {
     name = L["Format String"],
     desc = "Changes the way information is displayed on the mini xp bars, default is %l: %n",
     order = 5.914,
     type = "input",
     width = "double",
     get = function(i) return self.db.profile.miniframe.formatstring end,
     set = function(i, v) self.db.profile.miniframe.formatstring = v; self:UpdateMiniframe() end,
    },
    flashoutgoingheader = {
     name = "Comm - Outgoing Indicator",
     order = 6,
     type = "header",
    },
    oenabled = {
     name = L["Enabled"],
     order = 6.1,
     type = "toggle",
     get = function(i) return self.db.profile.miniframe.outgoing.enabled end,
     set = function(i, v) self.db.profile.miniframe.outgoing.enabled = v end,
    },
    flash = {
     name = "Texture",
     order = 6.2,
     type = "select",
     values = LSM:HashTable("background"),
     dialogControl = "LSM30_Background",
     get = function(info) return self.db.profile.miniframe.outgoing.texture end,
     set = function(info, value) self.db.profile.miniframe.outgoing.texture = value; self:SetupMiniframe() end,
    },
    opoint = {
     name = "Point",
     order = 6.3,
     type = "select",
     style = "dropdown",
     values = { ["TOP"] = "Top", ["RIGHT"] = "Right", ["BOTTOM"] = "Bottom", ["LEFT"] = "Left", ["CENTER"] = "Center", ["TOPRIGHT"] = "Top-Right", ["TOPLEFT"] = "Top-Left", ["BOTTOMRIGHT"] = "Bottom-Right", ["BOTTOMLEFT"] = "Bottom-Left" },
     get = function(i) return self.db.profile.miniframe.outgoing.point end,
     set = function(i, v) self.db.profile.miniframe.outgoing.point = v; self:SetupMiniframe() end,
    },
    orelativepoint = {
     name = "Relative Point",
     order = 6.4,
     type = "select",
     style = "dropdown",
     values = { ["TOP"] = "Top", ["RIGHT"] = "Right", ["BOTTOM"] = "Bottom", ["LEFT"] = "Left", ["CENTER"] = "Center", ["TOPRIGHT"] = "Top-Right", ["TOPLEFT"] = "Top-Left", ["BOTTOMRIGHT"] = "Bottom-Right", ["BOTTOMLEFT"] = "Bottom-Left" },
     get = function(i) return self.db.profile.miniframe.outgoing.relativePoint end,
     set = function(i, v) self.db.profile.miniframe.outgoing.relativePoint = v; self:SetupMiniframe() end,
    },
    flashposx = {
     name = "X Position",
     desc = "Position along the x axis",
     order = 6.5,
     type = "range",
     min = -600, max = 600, step = 1,
     get = function(info) return self.db.profile.miniframe.outgoing.x end,
     set = function(info, value) self.db.profile.miniframe.outgoing.x = value; self:SetupMiniframe() end,
    },
    flashposy = {
     name = "Y Position",
     desc = "Position along the y axis",
     order = 6.6,
     type = "range",
     min = -600, max = 600, step = 1,
     get = function(info) return self.db.profile.miniframe.outgoing.y end,
     set = function(info, value) self.db.profile.miniframe.outgoing.y = value; self:SetupMiniframe() end,
    },
    flashheight = {
     name = "Height",
     order = 6.7,
     type = "range",
     min = 8, max = 100, step = 1,
     get = function(info) return self.db.profile.miniframe.outgoing.height end,
     set = function(info, value) self.db.profile.miniframe.outgoing.height = tonumber(value); self:SetupMiniframe() end,
    },
    flashwidth = {
     name = "Width",
     order = 6.8,
     type = "range",
     min = 8, max = 100, step = 1,
     get = function(info) return self.db.profile.miniframe.outgoing.width end,
     set = function(info, value) self.db.profile.miniframe.outgoing.width = tonumber(value); self:SetupMiniframe() end,
    },
    flashincomingheader = {
     name = "Comm - Incoming Indicator",
     order = 7,
     type = "header",
    },
    ienabled = {
     name = L["Enabled"],
     order = 7.1,
     type = "toggle",
     get = function(i) return self.db.profile.miniframe.incoming.enabled end,
     set = function(i, v) self.db.profile.miniframe.incoming.enabled = v end,
    },
    iflash = {
     name = "Texture",
     order = 7.2,
     type = "select",
     values = LSM:HashTable("background"),
     dialogControl = "LSM30_Background",
     get = function(info) return self.db.profile.miniframe.incoming.texture end,
     set = function(info, value) self.db.profile.miniframe.incoming.texture = value; self:SetupMiniframe() end,
    },
    ipoint = {
      name = "Point",
      order = 7.3,
      type = "select",
      style = "dropdown",
      values = { ["TOP"] = "Top", ["RIGHT"] = "Right", ["BOTTOM"] = "Bottom", ["LEFT"] = "Left", ["CENTER"] = "Center", ["TOPRIGHT"] = "Top-Right", ["TOPLEFT"] = "Top-Left", ["BOTTOMRIGHT"] = "Bottom-Right", ["BOTTOMLEFT"] = "Bottom-Left" },
      get = function(i) return self.db.profile.miniframe.incoming.point end,
      set = function(i, v) self.db.profile.miniframe.incoming.point = v; self:SetupMiniframe() end,
     },
     irelativepoint = {
      name = "Relative Point",
      order = 7.4,
      type = "select",
      style = "dropdown",
      values = { ["TOP"] = "Top", ["RIGHT"] = "Right", ["BOTTOM"] = "Bottom", ["LEFT"] = "Left", ["CENTER"] = "Center", ["TOPRIGHT"] = "Top-Right", ["TOPLEFT"] = "Top-Left", ["BOTTOMRIGHT"] = "Bottom-Right", ["BOTTOMLEFT"] = "Bottom-Left" },
      get = function(i) return self.db.profile.miniframe.incoming.relativePoint end,
      set = function(i, v) self.db.profile.miniframe.incoming.relativePoint = v; self:SetupMiniframe() end,
     },
    iflashposx = {
     name = "X Position",
     desc = "Position along the x axis",
     order = 7.5,
     type = "range",
     min = -600, max = 600, step = 1,
     get = function(info) return self.db.profile.miniframe.incoming.x end,
     set = function(info, value) self.db.profile.miniframe.incoming.x = tonumber(value); self:SetupMiniframe() end,
    },
    iflashposy = {
     name = "Y Position",
     desc = "Position along the y axis",
     order = 7.6,
     type = "range",
     min = -600, max = 600, step = 1,
     get = function(info) return self.db.profile.miniframe.incoming.y end,
     set = function(info, value) self.db.profile.miniframe.incoming.y = value; self:SetupMiniframe() end,
    },
    iflashheight = {
     name = "Height",
     order = 7.7,
     type = "range",
     min = 8, max = 100, step = 1,
     get = function(info) return self.db.profile.miniframe.incoming.height end,
     set = function(info, value) self.db.profile.miniframe.incoming.height = value; self:SetupMiniframe() end,
    },
    iflashwidth = {
     name = "Width",
     order = 7.8,
     type = "range",
     min = 8, max = 100, step = 1,
     get = function(info) return self.db.profile.miniframe.incoming.width end,
     set = function(info, value) self.db.profile.miniframe.incoming.width = tonumber(value); self:SetupMiniframe() end,
    },
    mischeader = {
     name = L["Miscellaneous"],
     order = 8,
     type = "header",
    },
    framestrata = {
     name = "Frame Strata",
     order = 8.1,
     type = "select",
     style = "dropdown",
     values = { ["BACKGROUND"] = "Background", ["LOW"] = "Low", ["MEDIUM"] = "Medium", ["HIGH"] = "High", ["DIALOG"] = "Dialog" },
     set = function(i, v) self.db.profile.miniframe.framestrata = v; self:SetupMiniframe() end,
     get = function(i) return self.db.profile.miniframe.framestrata end,
    },
    framelevel = {
     name = "Frame Level",
     order = 8.2,
     type = "range",
     min = 1, max = 100, step = 1,
     get = function(i) return self.db.profile.miniframe.framelevel end,
     set = function(i, v) self.db.profile.miniframe.framelevel = v; self:SetupMiniframe(); end
    },
   },
  },
 },
}

 options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
 return options
end

function FriendXP:FriendKey(mode,friend)
 if (mode == "get") then
  local realmname = GetRealmName()
  local key = realmname .. "-" .. friend;
  self:Debug("Player key " .. key);
  return key
 end

 if (mode == "splode") then
  local mid = string.find(friend, "-", 1, true)
  if (mid == nil) then
   return nil
  end
  local realm = string.sub(friend,  1, mid - 1)
  local friend = string.sub(friend, mid + 1, -1)
  return realm, friend
 end
end

function FriendXP:AddFriend(friend)
 self.Print("Adding",friend,"to table.")
 tinsert(self.db.profile.friends, self:FriendKey("get", friend))
 self.Print("Listing friends")
 table.foreach(self.db.profile.friends, self.Print)
end

function FriendXP:DeleteFriend(friend)
 self.Print("Deleting",self.db.profile.friends[friend]);
 table.remove(self.db.profile.friends, friend)
end

function FriendXP:CreateFriendXPBar() -- Should merge its update functions here aswell like SetupMiniframe
 if (xpbar) then return end
 xpbar = CreateFrame("Frame", nil, UIParent)
 xpbar.bg = xpbar:CreateTexture(nil, 'BACKGROUND')
 xpbar.rest = CreateFrame('StatusBar', nil, xpbar)
 xpbar.xp = CreateFrame('StatusBar', nil, xpbar.rest)

 xpbar:SetFrameStrata(self.db.profile.friendbar.framestrata)
 xpbar:SetFrameLevel(self.db.profile.friendbar.framelevel)

 xpbar.bg:SetAllPoints(true)
 xpbar.xp:SetAllPoints(true)
 xpbar.rest:SetAllPoints(true)

 xpbar.text = xpbar.xp:CreateFontString(nil, 'OVERLAY')
 xpbar.text:SetFont(LSM:Fetch("font", self.db.profile.friendbar.text.font), self.db.profile.friendbar.text.size, self.db.profile.friendbar.text.style)
 xpbar.text:SetPoint("CENTER")

 xpbar.bg:SetTexture(LSM:Fetch("statusbar", self.db.profile.friendbar.texture))
 xpbar.rest:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.profile.friendbar.texture))
 xpbar.xp:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.profile.friendbar.texture))

 xpbar.bg:SetVertexColor(self.db.profile.friendbar.bgcolor.r, self.db.profile.friendbar.bgcolor.g, self.db.profile.friendbar.bgcolor.b, self.db.profile.friendbar.bgcolor.a)
 xpbar.xp:SetStatusBarColor(self.db.profile.friendbar.color.r, self.db.profile.friendbar.color.g, self.db.profile.friendbar.color.b)
 xpbar.rest:SetStatusBarColor(self.db.profile.friendbar.rest.r, self.db.profile.friendbar.rest.g, self.db.profile.friendbar.rest.b)

 xpbar.xp:SetMinMaxValues(0, 1000)
 xpbar.xp:SetValue(0)
 xpbar.rest:SetMinMaxValues(0, 1000)
 xpbar.rest:SetValue(0)

 -- For moving
 xpbar.move = CreateFrame("Frame", nil, UIParent)
 xpbar.move:SetBackdrop({bgFile = LSM:Fetch("background", "Solid")})
 xpbar.move:SetBackdropColor(1,0,0,0.75)
 xpbar.move:SetAllPoints(true)
 xpbar.move:Hide()

 xpbar:Hide()
end

function FriendXP:UpdateSettings()
 xpbar:ClearAllPoints()
 xpbar:SetFrameStrata(self.db.profile.friendbar.framestrata)
 xpbar:SetFrameLevel(self.db.profile.friendbar.framelevel)
 xpbar:SetPoint("TOPLEFT", UIParent, self.db.profile.friendbar.x, self.db.profile.friendbar.y)
 xpbar:SetHeight(self.db.profile.friendbar.height)
 xpbar:SetWidth(UIParent:GetWidth() * self.db.profile.friendbar.width)

 xpbar.bg:SetTexture(LSM:Fetch("statusbar", self.db.profile.friendbar.texture))
 xpbar.rest:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.profile.friendbar.texture))
 xpbar.xp:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.profile.friendbar.texture))

 xpbar.bg:SetVertexColor(self.db.profile.friendbar.bgcolor.r, self.db.profile.friendbar.bgcolor.g, self.db.profile.friendbar.bgcolor.b, self.db.profile.friendbar.bgcolor.a)
 xpbar.xp:SetStatusBarColor(self.db.profile.friendbar.color.r, self.db.profile.friendbar.color.g, self.db.profile.friendbar.color.b)
 xpbar.rest:SetStatusBarColor(self.db.profile.friendbar.rest.r, self.db.profile.friendbar.rest.g, self.db.profile.friendbar.rest.b)

 -- Not sure what this is for
 if xpbar.xp:GetStatusBarTexture().SetHorizTile then
  xpbar.xp:GetStatusBarTexture():SetHorizTile(false)
 end
 if xpbar.rest:GetStatusBarTexture().SetHorizTile then
  xpbar.rest:GetStatusBarTexture():SetHorizTile(false)
 end

 xpbar.text:SetFont(LSM:Fetch("font", self.db.profile.friendbar.text.font), self.db.profile.friendbar.text.size, self.db.profile.friendbar.text.style)
 xpbar.text:SetTextColor(self.db.profile.friendbar.text.color.r, self.db.profile.friendbar.text.color.g, self.db.profile.friendbar.text.color.b, self.db.profile.friendbar.text.color.a);

 if (self.db.profile.enabled and self.db.profile.friendbar.enabled) then
  xpbar:Show()
 else
  xpbar:Hide()
 end
end

-- Returns friend table, really need to redo the activeFriends table to avoid all this looping (DONE)
function FriendXP:FetchFriend(friend)
 if (newFriends[friend]) then
  return newFriends[friend]
 end
end

function FriendXP:UpdateFriendXP_HELPER(friend)
 self:UpdateFriendXP(self:FetchFriend(friend))
end

function FriendXP:UpdateFriendXP(ft) -- Friendbar
 -- Need to modify function to only need friend name/index to show friend
 -- May also need to work on the activeFriends table to make that easier
 -- like -- function FriendXP:UpdateFriendXP(id)
 if (self.db.profile.friendbar.enabled and self.db.profile.enabled) then
  xpbar:Show()
 else
  xpbar:Hide()
  return
 end

 if (ft == nil) then return end

 if (activeFriend ~= "" and activeFriend ~= ft["name"]) then
  self:Debug("Returning because activeFriend " .. activeFriend .. " is not selected " .. ft["name"])
  return
 end

 xpbar.xp:SetMinMaxValues(0, ft["totalxp"])
 xpbar.xp:SetValue(ft["xp"])
 xpbar.rest:SetMinMaxValues(0, ft["totalxp"])

 local isDisabled = "";
 if (ft["xpdisabled"] == 1) then
  isDisabled = L["XPGainsDisabled"]
 end

 if (ft["restbonus"] and ft["restbonus"] > 0) then
  xpbar.rest:SetValue(ft["xp"] + ft["restbonus"])
  --xpbar.text:SetFormattedText("%s (%d): %d / %d (%d%%) " .. L["Remaining"] .. ": %d " .. L["Rested"] .. ": %d %s", friend, level, xp, totalxp, self:Round((xp/totalxp)*100), (totalxp - xp), restbonus, isDisabled)
 else
  xpbar.rest:SetValue(0)
  --xpbar.text:SetFormattedText("%s (%d): %d / %d (%d%%) Remaining: %d %s", friend, level, xp, totalxp, self:Round((xp/totalxp)*100), (totalxp - xp), isDisabled)
 end
 xpbar.text:SetText(self:FormatString(self.db.profile.friendbar.formatstring, ft))
end

function FriendXP:FormatString(string, ft)
 self:Debug("Format String: " .. string)
 local pname = ft["name"]
 if (self.db.profile.miniframe.xp.namelen > 0) then
  pname = strsub(ft["name"], 0, self.db.profile.miniframe.xp.namelen)
 end
 string = gsub(string, "%%n", pname)
 string = gsub(string, "%%l", tostring(ft["level"]))
 string = gsub(string, "%%xp", tostring(ft["xp"]))
 string = gsub(string, "%%txp", tostring(ft["totalxp"]))
 string = gsub(string, "%%p", self:Round((ft["xp"]/ft["totalxp"])*100))
 string = gsub(string, "%%rm", ft["totalxp"] - ft["xp"])

 if (ft["restbonus"] > 0) then
  string = gsub(string, "(%%rs)(.-)(%%re)", "%2")
  string = gsub(string, "%%r", tostring(ft["restbonus"]))
 else
  string = gsub(string, "%%rs.-%%re", "")
 end
 if (ft["xpdisabled"] == 1) then
  string = gsub(string, "%%d", L["XPGainsDisabled"])
 else
  string = gsub(string, "%%d", "")
 end

 return string
end

function FriendXP:FlashFrame(frame)
 local alpha = frame:GetAlpha()
 if (frame.direction == nil) then
  frame.direction = 0;
 end
 local direction = frame.direction

 if (direction == 0) then
  alpha = alpha + 0.1;
  if (alpha > 1) then
   alpha = 1;
   frame.direction = 1;
  end
 else
  alpha = alpha - 0.1;
  if (alpha < 0) then
   alpha = 0;
   frame.direction = 0;
  end
 end

 frame:SetAlpha(alpha)

 if (frame:GetAlpha() <= 0) then
  frame:SetAlpha(0)
  frame:Hide()
 end
end

function FriendXP:SetupMiniframe()
 if (Miniframe == nil) then
  Miniframe = CreateFrame("Frame", nil, UIParent)
  Miniframe:SetBackdrop({bgFile = LSM:Fetch("background", self.db.profile.miniframe.texture), edgeFile = LSM:Fetch("border", self.db.profile.miniframe.border.border), tile = false, tileSize = 0, edgeSize = self.db.profile.miniframe.border.bordersize, insets = { left = self.db.profile.miniframe.border.inset.left, right = self.db.profile.miniframe.border.inset.right, top = self.db.profile.miniframe.border.inset.top, bottom = self.db.profile.miniframe.border.inset.bottom }})
  Miniframe.flash = CreateFrame("Frame", nil, Miniframe)
  Miniframe.flash:Hide()
  Miniframe.incoming = CreateFrame("Frame", nil, Miniframe)
  Miniframe.incoming:Hide()
  --Miniframe.flash:SetScript("OnUpdate", function(self) local alpha = self:GetAlpha(); alpha = alpha - 0.03; if (alpha < 0) then alpha = 0; end; self:SetAlpha(alpha); if (self:GetAlpha() <= 0) then self:SetAlpha(1); self:Hide(); end; end)
  Miniframe.flash:SetScript("OnUpdate", function(self) FriendXP:FlashFrame(self) end)
  Miniframe.incoming:SetScript("OnUpdate", function(self) FriendXP:FlashFrame(self) end)

 -- For moving
  Miniframe.move = CreateFrame("Frame", nil, UIParent)
  Miniframe.move:SetBackdrop({bgFile = LSM:Fetch("background", "Solid")})
  Miniframe.move:SetBackdropColor(1,0,0,0.75)
  Miniframe.move:SetAllPoints(Miniframe)
  Miniframe.move:Hide()

 end

 if (self.db.profile.miniframe.enabled == true and self.db.profile.enabled) then
  Miniframe:Show()
 else
  Miniframe:Hide()
 end

 Miniframe.flash:SetBackdrop({bgFile = LSM:Fetch("background", self.db.profile.miniframe.outgoing.texture), tile = false, tileSize = 0, })
 Miniframe.flash:ClearAllPoints()
 Miniframe.flash:SetPoint(self.db.profile.miniframe.outgoing.point, Miniframe, self.db.profile.miniframe.outgoing.relativePoint, self.db.profile.miniframe.outgoing.x, self.db.profile.miniframe.outgoing.y)
 Miniframe.flash:SetWidth(self.db.profile.miniframe.outgoing.width);
 Miniframe.flash:SetHeight(self.db.profile.miniframe.outgoing.height);

 Miniframe.incoming:SetBackdrop({bgFile = LSM:Fetch("background", self.db.profile.miniframe.incoming.texture), tile = false, tileSize = 0, })
 Miniframe.incoming:ClearAllPoints()
 Miniframe.incoming:SetPoint(self.db.profile.miniframe.incoming.point, Miniframe, self.db.profile.miniframe.incoming.relativePoint, self.db.profile.miniframe.incoming.x, self.db.profile.miniframe.incoming.y)
 Miniframe.incoming:SetWidth(self.db.profile.miniframe.incoming.width);
 Miniframe.incoming:SetHeight(self.db.profile.miniframe.incoming.height);


 Miniframe:ClearAllPoints()
 Miniframe:SetFrameStrata(self.db.profile.miniframe.framestrata)
 Miniframe:SetFrameLevel(self.db.profile.miniframe.framelevel)
 Miniframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.profile.miniframe.x, self.db.profile.miniframe.y);

 Miniframe:SetBackdrop({bgFile = LSM:Fetch("background", self.db.profile.miniframe.texture), edgeFile = LSM:Fetch("border", self.db.profile.miniframe.border.border), tile = false, tileSize = 0, edgeSize = self.db.profile.miniframe.border.bordersize, insets = { left = self.db.profile.miniframe.border.inset.left, right = self.db.profile.miniframe.border.inset.right, top = self.db.profile.miniframe.border.inset.top, bottom = self.db.profile.miniframe.border.inset.bottom }})
 Miniframe:SetBackdropColor(self.db.profile.miniframe.bgcolor.r, self.db.profile.miniframe.bgcolor.g, self.db.profile.miniframe.bgcolor.b, self.db.profile.miniframe.bgcolor.a)
 Miniframe:SetBackdropBorderColor(self.db.profile.miniframe.border.color.r, self.db.profile.miniframe.border.color.g, self.db.profile.miniframe.border.color.b, self.db.profile.miniframe.border.color.a)

end

local miniframes = { } -- Holds frame refs
function FriendXP:UpdateMiniframe()
 if (Miniframe == nil) then self:Debug("MINIFRAME UNDEFINED") return end

 if (self.db.profile.miniframe.enabled and self.db.profile.enabled) then
  Miniframe:Show()
 else
  Miniframe:Hide()
 end

 local b = 0 -- Column Counter
 local x = 0 -- Counter for frame position in column goes 1 to columnlimit, then increments b and resets to 0
 local y = 0 -- A counter for each frame

 local player = UnitName("player")

 self:RemoveOutdated_NEW()
 --self:RecycleAllFrames()

 if (newFriends[player] ~= nil) then -- Ensure that the player is always the first
  self:CreateMinibar(newFriends[player], b, y, x)
 else
  self:Debug("PLAYER DATA WAS NIL")
 end

 for key, value in pairs(newFriends) do
  local ft = newFriends[key]
  if (ft["name"] ~= player) then -- Ignore player
   y = y + 1; -- Replacement for x's original function
   if (x >= self.db.profile.miniframe.columnlimit - 1) then
    x = 0;
    b = b + 1;
   else
    x = x + 1;
   end
   self:CreateMinibar(ft, b, y, x)
  end
 end

  -- Needs more work
  if (b == 0) then
   -- Componenets of height:
   -- Height of each statusbar + the 2px buffer i give it
   -- Buffer around top and bottom in the form off xp.offset.y
   -- the +2 at the end is just for a little more wiggle room
   -- added the + height at the beginning to account for the button
   Miniframe:SetHeight((self.db.profile.miniframe.xp.offsety * 2) + ((self.db.profile.miniframe.xp.height + 2) * (x + 1)) + 2)
   Miniframe:SetWidth(self.db.profile.miniframe.xp.height + self.db.profile.miniframe.xp.width + (self.db.profile.miniframe.xp.offsetx * 2))
   --Miniframe:Show()
  else
   Miniframe:SetHeight((self.db.profile.miniframe.xp.offsety * 2) + ((self.db.profile.miniframe.xp.height + 2) * (self.db.profile.miniframe.columnlimit)) + 2)
   Miniframe:SetWidth((self.db.profile.miniframe.xp.height*(b+1)) + (self.db.profile.miniframe.xp.width * (b + 1)) + (self.db.profile.miniframe.xp.offsetx * 2) + (4 * b))
   --Miniframe:Show()
  end
end

function FriendXP:CreateMinibar(ft, b, y, x) -- This whole function needs work
 if (ft == nil) then return end -- FIXME

 local db = self.db.profile.miniframe -- Shorten some repetitive stuff

 local class = strupper(ft["class"]);
 if (class == nil) then
  class = "MAGE";
 end
 --["name"],ft["level"],ft["xp"] .. "/" .. ft["totalxp"],ft["restbonus"],)
 local frame = self:GetFrame(ft["name"]);
 frame:SetPoint("TOPLEFT", Miniframe, "TOPLEFT", db.xp.offsetx + ((db.xp.width) * b) + (4*b) + (db.xp.height * (b+1)), (-(db.xp.height+2) * x)-db.xp.offsety - 2)
 frame:SetWidth(db.xp.width);
 frame:SetHeight(db.xp.height);
 frame:SetMinMaxValues(0, ft["totalxp"])
 --frame.xp:ClearAllPoints()
 --frame.xp:SetAllPoints(true)
 frame.xp:SetMinMaxValues(0, ft["totalxp"])


 if (ft["level"] == ft["maxlevel"]) then
  frame.xp:SetValue(ft["totalxp"])
 else
  frame.xp:SetValue(ft["xp"])
 end
 if (db.rest.enabled) then
     if (ft["restbonus"] + ft["xp"] > ft["totalxp"]) then
   frame:SetValue(ft["totalxp"])
  else
   frame:SetValue(ft["restbonus"] + ft["xp"])
  end
 else
  frame:SetValue(0)
 end
 frame:SetStatusBarTexture(LSM:Fetch("statusbar", db.xp.texture))
  --frame:SetStatusBarColor(self.db.profile.miniframe.rest.color.r, self.db.profile.miniframe.rest.color.g, self.db.profile.miniframe.rest.color.b)
 if (db.rest.custom) then
  frame:SetStatusBarColor(db.rest.color.r, db.rest.color.g, db.rest.color.b)
 else
  frame:SetStatusBarColor(RAID_CLASS_COLORS[class]["r"] - 0.2, RAID_CLASS_COLORS[class]["g"] - 0.2, RAID_CLASS_COLORS[class]["b"] - 0.2)
 end
 frame:Show()

 frame.xp:SetStatusBarTexture(LSM:Fetch("statusbar", db.xp.texture))
 if (db.xp.custom) then
  frame.xp:SetStatusBarColor(db.xp.color.r, db.xp.color.g, db.xp.color.b)
 else
  frame.xp:SetStatusBarColor(RAID_CLASS_COLORS[class]["r"], RAID_CLASS_COLORS[class]["g"], RAID_CLASS_COLORS[class]["b"])
 end
 frame.bg:ClearAllPoints()
 frame.bg:SetAllPoints(true)
 frame.bg:SetTexture(LSM:Fetch("statusbar", db.xp.texture))
 frame.bg:SetVertexColor(db.xp.bgcolor.r, db.xp.bgcolor.g, db.xp.bgcolor.b, db.xp.bgcolor.a)
 frame.text:SetFont(LSM:Fetch("font", db.xp.text.font), db.xp.text.size, db.xp.text.style)
 frame.text:SetTextColor(db.xp.text.color.r, db.xp.text.color.g, db.xp.text.color.b, db.xp.text.color.a);
 local pname = ft["name"];
 if (db.xp.namelen > 0) then
  pname = strsub(ft["name"], 0, db.xp.namelen)
 end
 frame.text:SetPoint("LEFT")
 frame.text:SetText(self:FormatString(db.formatstring, ft))
  --frame.text:SetFormattedText("%d:%s", ft["level"], pname)

 -- Tooltip
 frame:SetScript("OnEnter", function() self:MiniTooltip(frame, true, ft) end)
 frame:SetScript("OnLeave", function() self:MiniTooltip(frame, false) end)

 -- Configure the button
 local buttonBg = "Interface/BUTTONS/UI-CheckBox-Check-Disabled.blp";
 local buttonNoXP = "";
 if (activeFriend == ft["name"]) then
  buttonBg = "Interface/BUTTONS/UI-CheckBox-Check.blp";
 end
 if (ft["xpdisabled"] == 1) then
  buttonNoXP = "Interface/BUTTONS/UI-GroupLoot-Pass-Up.blp";
 end
 frame.button:SetScript("OnMouseDown", function() self:Debug("Setting activeFriend to " .. ft["name"]); if (activeFriend ~= ft["name"]) then activeFriend = ft["name"]; self:UpdateFriendXP_HELPER(activeFriend); else activeFriend = ""; end; self:UpdateMiniframe(); end)
 frame.buttonbg:SetPoint("LEFT", frame, "LEFT", -db.xp.height, 0);
 frame.buttonbg:SetHeight(db.xp.height);
 frame.buttonbg:SetWidth(db.xp.height);
 frame.buttonbg:SetBackdrop({bgFile = buttonNoXP, tile = false, tileSize = 0, edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0}})
 frame.button:SetBackdrop({bgFile = buttonBg, tile = false, tileSize = 0, edgeSize = db.border.bordersize, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
end

function FriendXP:RemoveOutdated_NEW()
 for key, value in pairs(newFriends) do
  if (key ~= UnitName("player")) then
   if (newFriends[key]["lastTime"] < GetTime() - self.db.profile.miniframe.threshold) then
    self:RemoveFromActive(key)
    self:RecycleFrame(key)
   end
  end
 end
end

--[[
function FriendXP:RemoveOutdated()
 for key, value in pairs(newFriends) do
  if (value["lastTime"] < GetTime() - self.db.profile.miniframe.threshold) then
   self:RemoveFromActive(value["name"])
  end
 end
end
]]--

function FriendXP:GetCreateXPBar(key)
 if (miniframes[key] ~= nil) then
  self:Debug("Updating " .. key)
  return miniframes[key]
 else
  -- Fetch a frame
  local frame = next(frameCache)
  if frame then
    self:Debug("Recycling " .. key);
    frameCache[frame] = nil;
    miniframes[key] = frame;
    return miniframes[key]
  else
   self:Debug("Creating " .. key);
   frame = CreateFrame("StatusBar", nil, Miniframe)
   frame.xp = CreateFrame("StatusBar", nil, frame)
   frame.bg = frame:CreateTexture(nil, 'BACKGROUND')
   frame.text = frame.xp:CreateFontString(nil, 'OVERLAY')
   frame.buttonbg = CreateFrame("Frame", nil, frame)
   frame.button = CreateFrame("Button", nil, frame.buttonbg)
   frame.button:RegisterForClicks("AnyDown")
   frame.button:ClearAllPoints()
   frame.button:SetAllPoints(frame.buttonbg)
   miniframes[key] = frame;
   return miniframes[key]
  end
 end
end

function FriendXP:GetFrame(name) -- Player name is new frame ref thingy
 if (miniframes[name] ~= nil) then
  self:Debug("Updating" .. name)
  return miniframes[name]
 end
 local frame = next(frameCache)
 if frame then
  self:Debug("Recycling " .. name);
  frameCache[frame] = nil;
  miniframes[name] = frame
  return frame
 else
  self:Debug("Creating " .. name);
  frame = CreateFrame("StatusBar", nil, Miniframe)
  frame.id = y
  frame.xp = CreateFrame("StatusBar", nil, frame)
  frame.xp:SetAllPoints(true)
  frame.bg = frame:CreateTexture(nil, 'BACKGROUND')
  frame.text = frame.xp:CreateFontString(nil, 'OVERLAY')
  frame.buttonbg = CreateFrame("Frame", nil, frame)
  frame.button = CreateFrame("Button", nil, frame.buttonbg)
  frame.button:RegisterForClicks("AnyDown")
  frame.button:ClearAllPoints()
  frame.button:SetAllPoints(true)
  miniframes[name] = frame;
  return frame
 end
end

-- Need to first RemoveFromActive("friend")
-- then RecycleFrame to hide their miniframe if it exists
function FriendXP:RecycleFrame(name) -- Key is Y
 if (miniframes[name] ~= nil) then
  self:Debug("Recycling Frame " .. name);
  miniframes[name]:Hide()
  miniframes[name]:ClearAllPoints()
  frameCache[miniframes[name]] = true
  miniframes[name] = nil;
 end
end

function FriendXP:RecycleAllFrames()
 for key, value in pairs(miniframes) do
  if (miniframes[key] ~= nil) then
   self:Debug("RecycleAllFrames recycling " .. key)
   self:RecycleFrame(key)
  end
 end
end

function FriendXP:OnInitialize()
 local maxwidth = self:Round(UIParent:GetWidth(),0)
 local maxheight = self:Round(UIParent:GetHeight(),0)
-- defaults that are commented out need to be removed later
 local defaults = { -- Still needs work on better out of the box defaults
  profile = {
   enabled = true,
   version = 1.09,
   debug = false,
   checkOnline = true,
   integrateParty = true,
   sendAll = true,
   partyAll = true,
   bgAll = false,
   guildAll = false,
   ignoreWhisper = false,
   onlyFriends = false,
   doLevelUp = true,
   friendbar = {
    enabled = true,
    framelevel = 1,
    framestrata = "MEDIUM",
    x = maxwidth/2 - (maxwidth*0.75)/2,
    y = -20,
    formatstring = "%n (%l): %xp / %txp (%p%) Remaining: %rm%rs Rested: %r%re %d",
    height = 16,
    width = 0.50,
    texture = "Blizzard",
    color = { -- Experience Bar Color, Purple
     r = 0.6,
     g = 0,
     b = 0.6,
    },
    rest = { -- Rest Bar Color, Blue
     r = 0.25,
     g = 0.25,
     b = 1,
    },
    bgcolor = {
     r = 0,
     g = 0,
     b = 0,
     a = 0.5,
    },
    text = {
     font = "Friz Quadrata TT",
     size = 12,
     style = "",
     color = {
      r = 0,
      g = 1,
      b = 0,
      a = 1,
     },
    },
   },
   miniframe = {
    rest = {
     enabled = true,
     custom = false,
     color = {
      r = 0,
      g = 0,
      b = 1,
     },
    },
    tooltip = {
     enabled = true,
     combatDisable = true,
    },
    formatstring = "%l: %n",
    enabled = true,
    framelevel = 1,
    framestrata = "MEDIUM",
    threshold = 180,
    x = 20,
    y = -maxheight + 400,
    friendlimit = 10,
    columnlimit = 5,
    incoming = {
     enabled = false,
     x = 0,
     y = -16,
     width = 32,
     height = 32,
     texture = "Wireless Incoming",
     point = "BOTTOMRIGHT",
     relativePoint = "TOPRIGHT",
    },
    outgoing = {
     enabled = true,
     x = 0,
     y = 16,
     width = 32,
     height = 32,
     texture = "Wireless Icon",
     point = "TOPLEFT",
     relativePoint = "TOPLEFT",
    },
    border = {
     border = "Blizzard Dialog", -- Whatever the default, need to include it myself
     bordersize = 16,
     color = {
      r = 1,
      g = 0,
      b = 1,
      a = 1,
     },
     inset = {
      left = 4,
      right = 4,
      top = 4,
      bottom = 4,
     },
    },
    texture = "Solid",
    bgcolor = {
     r = 0,
     g = 0,
     b = 0,
     a = 0.5,
    },
    xp = {
     texture = "Blizzard",
     bgcolor = {
      r = 1,
      g = 0,
      b = 0,
      a = 0.5,
     },
     color = {
      r = 1,
      g = 1,
      b = 1,
     },
     custom = false,
     namelen = 0,
     offsetx = 10,
     offsety = 6,
     height = 16,
     width = 80,
     text = {
      font = "Friz Quadrata TT",
      size = 10,
      style = "", -- Not yet implemented
      color = {
       r = 1,
       g = 1,
       b = 1,
       a = 1,
      },
     },
    },
   },
   friends = {
   },
   tooltip = {
    header = {
     font = "Friz Quadrata TT",
     size = 16,
     color = {
      r = 1,
      g = 0,
      b = 0,
     },
    },
    normal = {
     font = "Friz Quadrata TT",
     size = 12,
     color = {
      r = 1,
      g = 1,
      b = 1,
     },
    },
   },
  },
 }
 self.db = LibStub("AceDB-3.0"):New("FriendXPDB", defaults, true)
 self.db.RegisterCallback(self, "OnProfileChanged", "UpdateDb")
 self.db.RegisterCallback(self, "OnProfileCopied", "UpdateDb")
 self.db.RegisterCallback(self, "OnProfileReset", "UpdateDb")
 self:CreateFriendXPBar()
 LSM.RegisterCallback(self, "LibSharedMedia_Registered","UpdateMedia")
 self:RegisterChatCommand("friendxp","HandleIt")
 self:RegisterEvent("PLAYER_ENTERING_WORLD","WorldEnter")
 self:RegisterComm("friendxp")
 --self:RegisterAddonMessagePrefix("friendxp")
 self.fonts = { }
 self:CreateFonts()
 self:SetupMiniframe()
 self:HookBlizzPartyFrames()

 self:SetEnabledState(self.db.profile.enabled)
end

function FriendXP:CreateFonts()
 self.fonts["class"] = { }
 fonts["header"] = CreateFont("FriendXPFontHeader")
 fonts["header"]:SetFont(LSM:Fetch("font", FriendXP.db.profile.tooltip.header.font),self.db.profile.tooltip.header.size)
 fonts["header"]:SetTextColor(self.db.profile.tooltip.header.color.r, self.db.profile.tooltip.header.color.g, self.db.profile.tooltip.header.color.b)
 fonts["normal"] = CreateFont("FriendXPFontNormal")
 fonts["normal"]:SetFont(LSM:Fetch("font", FriendXP.db.profile.tooltip.normal.font), self.db.profile.tooltip.normal.size)
 fonts["normal"]:SetTextColor(self.db.profile.tooltip.normal.color.r, self.db.profile.tooltip.normal.color.g, self.db.profile.tooltip.normal.color.b)
--RAID_CLASS_COLORS[class]["r"], RAID_CLASS_COLORS[class]["g"], RAID_CLASS_COLORS[class]["b"]
 for i, v in pairs(RAID_CLASS_COLORS) do
  self.fonts["class"][i] = CreateFont("FriendXPClassColor" .. i)
  self.fonts["class"][i]:SetFont(LSM:Fetch("font", self.db.profile.tooltip.normal.font), self.db.profile.tooltip.normal.size)
  self.fonts["class"][i]:SetTextColor(RAID_CLASS_COLORS[i]["r"], RAID_CLASS_COLORS[i]["g"], RAID_CLASS_COLORS[i]["b"])
 end
end

-- Made this long time ago, seems like it needs improvement
function FriendXP:UpdateFonts(thing, size, r, g, b)
 if (not fonts[thing]) then
  return
 end
 local things = self.db.profile.tooltip
 fonts[thing]:SetFont(LSM:Fetch("font", things[thing]["font"]), size)
 fonts[thing]:SetTextColor(r, g, b)
end

function FriendXP:UpdateFont(thing)
 if (not fonts[thing]) then
  return
 end

 local things = self.db.profile.tooltip
 fonts[thing]:SetFont(LSM:Fetch("font", things[thing]["font"]), things[thing]["size"])
 fonts[thing]:SetTextColor(things[thing]["color"]["r"], things[thing]["color"]["g"], things[thing]["color"]["b"])
end

function FriendXP:UpdateFONTS() -- Going do something about all these update fonts someday
 for i, v in pairs(RAID_CLASS_COLORS) do
  self.fonts["class"][i]:SetFont(LSM:Fetch("font", self.db.profile.tooltip.normal.font), self.db.profile.tooltip.normal.size)
  self.fonts["class"][i]:SetTextColor(RAID_CLASS_COLORS[i]["r"], RAID_CLASS_COLORS[i]["g"], RAID_CLASS_COLORS[i]["b"])
 end
end

function FriendXP:UpdateMedia(event, mediatype, key)
 local doUpdate = false
 if mediatype == "font" then
  if key == self.db.profile.friendbar.text.font then doUpdate = true end
  if key == self.db.profile.tooltip.header.font then doUpdate = true end
  if key == self.db.profile.tooltip.normal.font then doUpdate = true end
 elseif mediatype == "statusbar" then
  if key == self.db.profile.friendbar.texture then doUpdate = true end
 elseif mediatype == "border" then
  if key == self.db.profile.miniframe.border.border then doUpdate = true end
 elseif mediatype == "background" then
  if key == self.db.profile.miniframe.texture then doUpdate = true end
  if key == self.db.profile.miniframe.outgoing.texture then doUpdate = true end
  if key == self.db.profile.miniframe.incoming.texture then doUpdate = true end
 end

 if doUpdate == true then
  self:UpdateSettings();
  self:UpdateFont("header");
  self:UpdateFont("normal");
  self:UpdateFONTS();
  self:SetupMiniframe();
  self:UpdateMiniframe();
 end
end

function FriendXP:UpdateDb()
 self:UpdateSettings();
 self:SetupMiniframe();
 self:UpdateMiniframe();
 self:UpdateFonts("header", self.db.profile.tooltip.header.size, self.db.profile.tooltip.header.color.r, self.db.profile.tooltip.header.color.g, self.db.profile.tooltip.header.color.b)
 self:UpdateFonts("normal", self.db.profile.tooltip.normal.size, self.db.profile.tooltip.normal.color.r, self.db.profile.tooltip.normal.color.g, self.db.profile.tooltip.normal.color.b)
end

function FriendXP:OnEnable()
 --self:RegisterEvent("PLAYER_XP_UPDATE","SendXP")
 self:RegisterBucketEvent({ "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "ENABLE_XP_GAIN", "DISABLE_XP_GAIN" }, 2, "SendXP")
 self:ScheduleRepeatingTimer("SendXP", 45)
 self:UpdateSettings()

 if (self.db.profile.friendbar.enabled == true and self.db.profile.enabled) then
  xpbar:Show()
 else
  xpbar:Hide()
 end
 if (self.db.profile.miniframe.enabled == true and self.db.profile.enabled) then
  Miniframe:Show()
 else
  Miniframe:Hide()
 end
end

function FriendXP:OnDisable()
 --self:UnregisterAllEvents()
 self:UnregisterAllBuckets()
 self:CancelAllTimers()
 xpbar:Hide()
 Miniframe:Hide()
end

-- Does this have a use anymore?
function FriendXP:ToggleFriendbar()
 if (self.db.profile.friendbar.enabled == true and self.db.profile.enabled) then
  xpbar:Show()
 else
  xpbar:Hide()
 end
end

function FriendXP:WorldEnter()
 LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("FriendXP", giveOptions(FriendXP))  -- I do this here instead of in OnInitialize() because values are accurate now
 self.configFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FriendXP", "FriendXP")
 self:UnregisterEvent("PLAYER_ENTERING_WORLD")

 configGenerated = true

 self:SendXP();
end

function FriendXP:HandleIt(input)
 if not input then
  --self.Print(self,"Needs more cowbell.")
  return
 end

 local command, nextposition = self:GetArgs(input,1,1)

 if (command == "add") then
  local friend = self:GetArgs(input,2,nextposition)
  if (friend == nil) then
   return
  end
  return
 end

 if (command == "active") then
  for i,v in ipairs(activeFriends) do
   self.Print(self,"Index",i,"Name",activeFriends[i]["name"])
  end
  return
 end

 if (command == "togglelock") then
  self:ToggleLock()
  return
 end

 if (command == "send") then
  self:SendXP()
  self:UpdateMiniframe()
  self.Print(self,"Sent experience")
  return
 end

 InterfaceOptionsFrame_OpenToCategory(self.configFrame)
end

function FriendXP:SendXP()
 if (self.db.profile.miniframe.enabled and self.db.profile.miniframe.outgoing.enabled) then
  Miniframe.flash:Show()
 end

 local restbonus = GetXPExhaustion()
 local xpdisabled = IsXPUserDisabled()
 if (restbonus == nil) then
  restbonus = 0
 end
 if (xpdisabled == true) then
  xpdisabled = 1
 else
  xpdisabled = 0
 end

 local player = UnitName("player");
 local xp = UnitXP("player");
 local xptotal = UnitXPMax("player");
 local level = UnitLevel("player");
 local _, class = UnitClass("player");
 local maxlevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
 newFriends[player] = {
  name = player,
  xp = xp,
  totalxp = xptotal,
  level = level,
  restbonus = restbonus,
  xpdisabled = xpdisabled,
  class = class,
  lastTime = GetTime(),
  maxlevel = maxlevel,
 }

 self:UpdateMiniframe()

 if (activeFriend == player) then -- If the player is selected to be shown on the friendbar, then do update
  self:UpdateFriendXP_HELPER(player)
 end

 local msg = self:Serialize(player, xp, xptotal, level, restbonus, xpdisabled, class, maxlevel)

 if (self.db.profile.guildAll == true and IsInGuild()) then -- Send to entire guild
  self:SendCommMessage("friendxp", msg, "GUILD", friend)
 end

 if (self.db.profile.bgAll and UnitInBattleground("player")) then -- Send to battleground
  self:Debug("Sending to Battleground")
  self:SendCommMessage("friendxp", msg, "BATTLEGROUND", friend)
 end

 if (self.db.profile.partyAll and UnitInBattleground("player") == nil) then -- Send to party
  self:Debug("Sending to party")
  self:SendCommMessage("friendxp", msg, "RAID", friend)
 end

 if (self.db.profile.sendAll == true) then -- Send to all friends
  local numberOfFriends, onlineFriends = GetNumFriends() -- Normal friends first
  if (numberOfFriends > 0) then
   for friendL = 1, numberOfFriends do
    local nameT, levelT, classT, areaT, connectedT, statusT, noteT = GetFriendInfo(friendL)
    if (nameT ~= nil and connectedT ~= nil) then
     self:SendCommMessage("friendxp", msg, "WHISPER", nameT)
    end
   end
  end

  local numberOfBFriends, BonlineFriends = BNGetNumFriends() -- Then do RealID Friends
  if (numberOfBFriends > 0) then
   for Bfriend = 1, numberOfBFriends do
    local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, messageTime, canSoR  = BNGetFriendInfo(Bfriend)
    self:Debug("Sending to BNet " .. presenceName)
    self:Debug(toonName)
    if (toonID ~= nil and isOnline == true) then

     if (CanCooperateWithToon(toonID) or UnitInParty(toonName)) then
      self:Debug("Sent")
      local _, _, _, realmName, _, _, _, _, _, _, _ = BNGetToonInfo(toonID)
      if (realmName == GetRealmName()) then
       self:SendCommMessage("friendxp", msg, "WHISPER", toonName)
      end
     end
    end
   end
  end

  return -- Don't need to bother sending to individual friends
 end

 for i, v in ipairs(self.db.profile.friends) do -- Loop through all friends
  local realm, friend = self:FriendKey("splode",v)
  if ((self.db.profile.checkOnline == true and self:FriendCheck(realm,friend)) or self.db.profile.checkOnline == false) then -- Whisper it to friend if online
   self:SendCommMessage("friendxp", msg, "WHISPER", friend)
  end
 end
end

-- prefix, message, distribution, sender
function FriendXP:OnCommReceived(a,b,c,d)
 self:Debug("OnCommReceived: Prefix " .. a .. ":" .. b .. ":" .. ", Channel " .. c .. ":" .. d)
 if (a ~= "friendxp") then
  return
 end

 if (c == "GUILD" and self.db.profile.guildAll == false) then -- Only process GUILD if Send to guild is enabled
  return
 end

 if (c == "BATTLEGROUND" and self.db.profile.bgAll == false) then -- Only process BATTLEGROUND if Send to bg is enabled
  return
 end

 if (c == "RAID" and self.db.profile.partyAll == false) then -- Only process PARTY/RAID if send to party is enabled
  return
 end

 if (c == "WHISPER" and self.db.profile.ignoreWhisper == true) then -- Ignore all whispers
  return
 end

-- the format should be-> playername:xp:xptotal:level:restbonus:xpdisabled:class

--[[
 local mid = string.find(b, ":", 1, true)
 if (mid == nil) then
  return
 end
 local mid2 = string.find(b, ":", mid + 1, true)
 local mid3 = string.find(b, ":", mid2 + 1, true)
 local mid4 = string.find(b, ":", mid3 + 1, true)
 local mid5 = string.find(b, ":", mid4 + 1, true)
 local mid6 = string.find(b, ":", mid5 + 1, true)
 local mid7 = string.find(b, ":", mid6 + 1, true)

 local name = string.sub(b,  1, mid - 1)
 local xp = string.sub(b, mid + 1, mid2 - 1)
 local xptotal = string.sub(b, mid2 + 1, mid3 - 1)
 local level = string.sub(b, mid3 + 1, mid4 - 1)
 local restbonus = string.sub(b, mid4 + 1, mid5 - 1)
 local xpdisabled = string.sub(b, mid5 + 1, mid6 - 1)
 local class = string.sub(b, mid6 + 1, -1)
 local maxlevel = 85 -- Just a default incase sender is using old version

 if (mid7 ~= nil) then
  class = string.sub(b, mid6 +1, mid7 - 1)
  maxlevel = string.sub(b, mid7 +1, -1)
 end
 ]]--
 local success, name, xp, xptotal, level, restbonus, xpdisabled, class, maxlevel = self:Deserialize(b)
 if (not sucess) then
  self:Debug("Couldn't not deserialize message " .. name)
 end

 self:Debug(name .. " " .. xp .. " " .. xptotal .. " " .. level .. " " .. restbonus .. " " .. class .. " " .. maxlevel)

 if (UnitName("player") == name) then -- Don't show stuff we sent, mainly for PARTY and GUILD
  self:Debug("Returning from OnComm because name == player")
  return
 end
 -- Make sure player is only sending their info
 -- add crosserver support to tell between Player and Player-Realm
 if (strupper(name) ~= strupper(d)) then
  local Tmid = string.find(d, "-", 1, true)
  if (Tmid) then
   self:Debug("Tmid " .. Tmid)
   local Tname = string.sub(d, 1, Tmid - 1)
   self:Debug("Name Tname" .. name .. " " .. Tname)
   if (strupper(name) ~= strupper(Tname)) then
    self:Debug("Sending player is not equal to sent string")
    --return FIXME
   end
  else
  -- return -- Names didn't match and not from different realm FIXME
  end
 end

 if (not self:FriendCheck(GetRealmName(), name) and self.db.profile.onlyFriends) then
  self:Debug("not processing " .. name .. ", because onlyFriends")
  return
 end

 if (restbonus == nil) then --need to see if these serve a purpose
  restbonus = 0
 end
 if (xpdisabled == nil) then
  xpdisabled = 0
 end

 if (name ~= nil and xp ~= nil and xptotal ~= nil and level ~= nil and class ~= nil and maxlevel ~= nil) then
  if (self.db.profile.miniframe.enabled and self.db.profile.miniframe.incoming.enabled) then -- Only flash on valid updates
   Miniframe.incoming:Show()
  end
  --self:UpdateFriendXP(name, tonumber(level), tonumber(xp), tonumber(xptotal), tonumber(restbonus), tonumber(xpdisabled))
  if self.db.profile.debug then self.Print(self,"UpdateFriendXP",name,level,xp,xptotal,restbonus,xpdisabled) end
--[[  friendTable = {
   ["name"] = name,
   ["xp"] = tonumber(xp),
   ["totalxp"] = tonumber(xptotal),
   ["level"] = tonumber(level),
   ["restbonus"] = tonumber(restbonus),
   ["xpdisabled"] = tonumber(xpdisabled),
   ["class"] = class,
   ["lastTime"] = GetTime(),
  }
  self:UpdateFriendXP(friendTable)
  ]]--
  if (self.db.profile.doLevelUp) then
   local previousLevel = self:GetLevelByPlayer(name)
   if (previousLevel ~= nil and previousLevel < tonumber(level)) then
    self:DoLevelUp(name, level)
   end
  end

  end
 newFriends[name] = {
  name = name,
  xp = tonumber(xp),
  totalxp = tonumber(xptotal),
  level = tonumber(level),
  restbonus = tonumber(restbonus),
  xpdisabled = tonumber(xpdisabled),
  class = class,
  lastTime = GetTime(),
  maxlevel = tonumber(maxlevel)
 }

 self:UpdateFriendXP_HELPER(name)
 self:UpdateMiniframe();
end

function FriendXP:RemoveFromActive(friend)
 if (newFriends[friend]) then
  self:Debug("Removing " .. friend .. " from newFriends table")
  newFriends[friend] = nil
  --table.remove(newFriends, friend)
 end
end

function FriendXP:GetLevelByPlayer(friend)
 if (newFriends[friend]) then
  self:Debug("GetLevelByPlayer returning newFriends entry")
  return newFriends[friend]["level"]
 end

 return nil
end

function FriendXP:DoLevelUp(friend, level)
 UIErrorsFrame:AddMessage(friend .. " has reached level " .. level .. "!", 1.0, 1.0, 0.0, 1, 5)
 PlaySoundFile("Sound\\interface\\LevelUp.wav")
 return
end

function FriendXP:Round(n, precision)
 local m = 10^(precision or 0)
 return floor(m*n + 0.5)/m
end

-- Cycles through friend list and real id friends to see if any given friend is online
-- Maybe should just cache this information somehow
function FriendXP:FriendCheck(realm, friend)
--[[ if (realm ~= GetRealmName()) then -- Removed for RealID
  --return false
 end ]]--

 local numberOfFriends, onlineFriends = GetNumFriends()
 local numberOfBFriends, BonlineFriends = BNGetNumFriends()
 if (onlineFriends > 0) then
  for i = 1,onlineFriends do
   local name, level, class, area, connected, status, note = GetFriendInfo(i)
   if (name == friend and realm == GetRealmName()) then
    return true
   end
  end
 end
 if (BonlineFriends > 0) then
  for Bfriend = 1,BonlineFriends do
  local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, messageTime, canSoR  = BNGetFriendInfo(Bfriend)
   if (CanCooperateWithToon(toonID) or UnitInParty(toonName)) then
    if (toonName == friend) then
     return true
    end
   end
  end
 end

 return false
end

function FriendXP:Debug(msg)
 if (not self.db.profile.debug) then
  return
 end

 self.Print(self,"Debug",msg)
end

function FriendXP.LDB.OnEnter(self)
 local tooltip = LQT:Acquire("FriendXP", 5, "LEFT", "RIGHT", "RIGHT", "RIGHT", "RIGHT")
 self.tooltip = tooltip
 if _G.TipTac and _G.TipTac.AddModifiedTip then
  _G.TipTac:AddModifiedTip(self.tooltip, true)
 end

 tooltip:SetHeaderFont(fonts["header"])
 tooltip:SetFont(fonts["normal"])
 tooltip:AddHeader('Name','Level','XP', 'Rest Bonus', L["XPDisabled"])
 tooltip:AddSeparator()
 for key, value in pairs(newFriends) do
  local ft = newFriends[key]
  local xpdisablemsg = "";
  if (ft["xpdisabled"] == 1) then
   xpdisablemsg = "XP Disabled";
  end
  tooltip:AddLine(ft["name"],ft["level"],ft["xp"] .. "/" .. ft["totalxp"],ft["restbonus"], xpdisablemsg)
 end
 tooltip:SmartAnchorTo(self)
 tooltip:Show()
end

function FriendXP.LDB.OnLeave(self)
 LQT:Release(self.tooltip)
 self.tooltip = nil
end

function FriendXP:MiniTooltip(frame, show, fd)
 if (show) then
  if (not self.db.profile.miniframe.tooltip.enabled) then
   return
  end
  if (InCombatLockdown() and self.db.profile.miniframe.tooltip.combatDisable) then
   return
  end
  local tooltip = LQT:Acquire("FriendXP", 2, "LEFT", "RIGHT")
  self.tooltip = tooltip

  tooltip:SetFont(self.fonts["class"][fd["class"]])
  tooltip:AddLine(fd["name"])
  tooltip:SetFont(fonts["normal"])
  tooltip:AddLine(L["Level"] .. ":", fd["level"])
  tooltip:AddLine(L["Experience"] .. ":", fd["xp"] .. "/" .. fd["totalxp"] .. " (" .. self:Round((fd["xp"]/fd["totalxp"])*100) .. "%)")
  tooltip:AddLine(L["Rest Bonus"] .. ":", fd["restbonus"])
  tooltip:AddLine(L["Remaining"] .. ":", fd["totalxp"] - fd["xp"])
  tooltip:AddLine(L["Bars Left"] .. ":", self:Round((fd["totalxp"] - fd["xp"])/(fd["totalxp"]/20)))
  if (fd["xpdisabled"] == 1) then
   tooltip:AddLine(L["XPDisabled"])
  end
  tooltip:SmartAnchorTo(frame)
  tooltip:Show()
 else
  LQT:Release(self.tooltip)
  self.tooltip = nil
 end
end

function FriendXP:ToggleLock()
 if (not self.unlocked) then
  Miniframe.move:ClearAllPoints()
  Miniframe.move:SetFrameStrata("TOOLTIP")
  Miniframe.move:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.profile.miniframe.x, self.db.profile.miniframe.y);
  Miniframe.move:SetWidth(Miniframe:GetWidth())
  Miniframe.move:SetHeight(Miniframe:GetHeight())
  Miniframe.move:Show()
  Miniframe.move:SetMovable(true)
  Miniframe.move:EnableMouse(true)
  Miniframe.move:SetScript("OnMouseDown", function(self, button) FriendXP:DragStart(self, button, "miniframe") end)
  Miniframe.move:SetScript("OnMouseUp", function(self, button) FriendXP:DragStop(self, button, "miniframe") end)
  Miniframe:SetAllPoints(Miniframe.move)

  xpbar.move:ClearAllPoints()
  xpbar.move:SetFrameStrata("TOOLTIP")
  xpbar.move:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.profile.friendbar.x, self.db.profile.friendbar.y)
  xpbar.move:SetWidth(xpbar:GetWidth())
  xpbar.move:SetHeight(xpbar:GetHeight())
  xpbar.move:Show()
  xpbar.move:SetMovable(true)
  xpbar.move:EnableMouse(true)
  xpbar.move:SetScript("OnMouseDown", function(self, button) FriendXP:DragStart(self, button, "friendbar") end)
  xpbar.move:SetScript("OnMouseUp", function(self, button) FriendXP:DragStop(self, button, "friendbar") end)
  xpbar:SetAllPoints(xpbar.move)

  self.unlocked = true
 else
  self.unlocked = false
  Miniframe.move:Hide()
  Miniframe.move:SetMovable(false)
  Miniframe.move:EnableMouse(false)
  Miniframe.move:SetScript("OnMouseDown", nil)
  Miniframe.move:SetScript("OnMouseUp", nil)

  xpbar.move:Hide()
  xpbar.move:SetMovable(false)
  xpbar.move:EnableMouse(false)
  xpbar.move:SetScript("OnMouseDown", nil)
  xpbar.move:SetScript("OnMouseUp", nil)
  self:SetupMiniframe()
  self:UpdateSettings()
 end
end

function FriendXP:DragStart(frame, button, name)
 if (button == "LeftButton" and not frame.isMoving) then
  frame.isMoving = true
  frame:StartMoving()
 end
end

function FriendXP:DragStop(frame, button, name)
 if (button == "LeftButton" and frame.isMoving == true) then
  local maxheight = self:Round(UIParent:GetHeight(),0);
  frame.isMoving = false
  self.db.profile[name].x = self:Round(frame:GetLeft(), 0)
  self.db.profile[name].y = -maxheight + self:Round(frame:GetTop(), 0)

 -- self:Print(self.db.profile[name].x, self.db.profile[name].y)
 -- local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
 -- self:Print(point, relativeTo, relativePoint, xOfs, yOfs)
--  self:Print(self.db.profile.miniframe.x, self.db.profile.miniframe.y)
 -- self:Print(frame:GetLeft(), frame:GetBottom())
 -- self:Print(frame:GetRight(), frame:GetTop())
  frame:StopMovingOrSizing()

 end
end

local partyXPFrames = { }
--FriendXP.tmp = partyXPFrames -- FIXME (Just to allow me access withing WoW for testing)
function FriendXP:HookBlizzPartyFrames()
 for i = 1, 4 do -- Hide all frames
  if (partyXPFrames[i]) then partyXPFrames[i]:Hide() end
 end
 if (not self.db.profile.integrateParty) then return end
 for i = 1, 4 do
  if (partyXPFrames[i] == nil) then
   local partyXP = CreateFrame("Frame", nil, _G["PartyMemberFrame" .. i])
   partyXP:SetBackdrop({bgFile = LSM:Fetch("background", "Solid")})
   partyXP:SetBackdropColor(0,0,0,.5)
   partyXP:SetPoint("TOPLEFT", _G["PartyMemberFrame" .. i], "TOPLEFT", 46, -31)
   partyXP:SetWidth(66)
   partyXP:SetHeight(4)
   partyXP.frame = CreateFrame("Frame", nil, partyXP)
   partyXP.frame:SetBackdrop({bgFile = LSM:Fetch("background", "PartyXPBar"), tile = false, tileSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
   partyXP.frame:ClearAllPoints()
   partyXP.frame:SetHeight(32)
   partyXP.frame:SetWidth(128)
   partyXP.frame:SetPoint("TOPLEFT", _G["PartyMemberFrame" .. i], "TOPLEFT", 42, -30)

   partyXP.xpbar = CreateFrame("StatusBar", nil, partyXP)
   partyXP.xpbar:SetAllPoints(true)

   partyXP.xpbar:SetStatusBarTexture(LSM:Fetch("statusbar", "Blizzard"))
   partyXP.xpbar:SetStatusBarColor(1,0,1)
   partyXP.xpbar:SetMinMaxValues(0, 1000)
   partyXP.xpbar:SetValue(200)

   partyXP.text = partyXP.xpbar:CreateFontString(nil, 'OVERLAY')
   partyXP.text:SetFont(LSM:Fetch("font", "Friz Quadrata TT"), 10)
   partyXP.text:SetAllPoints(true)

   --partyXP.frame:SetFrameLevel(partyXP.xpbar:GetFrameLevel() - 1)
   --partyXP.frame:Hide()

   partyXPFrames[i] = partyXP
   partyXPFrames[i]:SetScript("OnUpdate", function(self)
   	   if (FriendXP.db.profile.integrateParty == false ) then self:Hide() return end
   	   local xp, total, percent, restbonus = FriendXP:GetXPByUnit("party" .. i)
   	   if (xp ~= nil) then
            if (restbonus > 0) then
             self.xpbar:SetStatusBarColor(0.25, 0.25, 1) -- Rested blue (I think)
            else
             self.xpbar:SetStatusBarColor(0.6, 0, 0.6) -- Weary Purple (I think)
            end
   	    self.xpbar:SetMinMaxValues(0, total)
   	    self.xpbar:SetValue(xp)
   	    self.text:SetText(percent .. "%")
   	   else
   	    self.xpbar:SetValue(0)
   	    self.text:SetText("N/A") -- Probably should just hide frame instead (But can't process OnUpdate then)
   	   end
   	  end)

  else
   partyXPFrames[i]:Show()
  end
 end
end

function FriendXP:GetXPByUnit(unit, formatString)
 self:Debug("GetXPByUnit called with " .. unit)
 local name, _ = UnitName(unit)
 if (name == nil) then return nil end

 local ft = self:FetchFriend(name)
 if (ft and formatString == nil) then
  return ft["xp"], ft["totalxp"], self:Round((ft["xp"]/ft["totalxp"])*100), ft["restbonus"]
 elseif(ft == nil and formatString == nil) then
  return nil, nil, nil, nil
 elseif (ft and formatString ~= nil) then
  return self:FormatString(formatString, ft)
 else
  return nil
 end
end

--[[
function FriendXP:SplitName(toon) -- Breaks name into name, realm
 local mid = string.find(toon, " ", 1, true)
 if (mid == nil) then return toon end

 local name = string.sub(toon, 1, mid - 1)
 local realm = string.sub(toon, mid + 1, -1)

 return name, realm
end
]]--
