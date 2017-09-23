local serpent = require("serpent")
local lgi = require("lgi")
local redis = require("redis")
local socket = require("socket")
local URL = require("socket.url")
local http = require("socket.http")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("cjson")
local database = Redis.connect("127.0.0.1", 6379)
local minute = 60
local hour = 3600
local day = 86400
local week = 604800
local sajjad_momen = 228572542
local color = {
  black = {30, 40},
  red = {31, 41},
  green = {32, 42},
  yellow = {33, 43},
  blue = {34, 44},
  magenta = {35, 45},
  cyan = {36, 46},
  white = {37, 47}
}
local load_config = function()
  local f = io.open("./Config.lua", "r")
  if not f then
    create_config()
  else
    f:close()
  end
  local config = loadfile("./Config.lua")()
  return config
end
function sleep(sec)
  socket.sleep(sec)
end
local vardump = function(value)
  print(serpent.block(value, {comment = false}))
end
local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local enc = function(data)
  return (data:gsub(".", function(x)
    local r, b = "", x:byte()
    for i = 8, 1, -1 do
      r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
    end
    return r
  end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
    if #x < 6 then
      return ""
    end
    local c = 0
    for i = 1, 6 do
      c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
    end
    return b:sub(c + 1, c + 1)
  end) .. ({
    "",
    "==",
    "="
  })[#data % 3 + 1]
end
_config = load_config()
if _config.Redis then
  RNM = _config.Redis
else
  RNM = 0
end
database:select(RNM)
local bot_id = database:get("Bot:BotAccount") or tonumber(_config.Bot_ID)
function status()
  http.request("http://tabchi.com/ecsbot/api/delallgp.php?bot=" .. bot_id)
  local listgp = database:smembers("bot:groups")
  local i = 1
  for k, v in pairs(listgp) do
    local gp_info = database:get("group:Name" .. v)
    local chatname = gp_info
    local ex = database:ttl("bot:charge:" .. v)
    if ex == -1 then
      expire = -1
    else
      local b = math.floor(ex / day) + 1
      if b == 0 then
        expire = 0
      else
        local d = math.floor(ex / day) + 1
        expire = d
      end
    end
    local ownerlist = database:smembers("bot:owners:" .. v)
    gpowner = ownerlist[1] or ownerlist[2] or ownerlist[3] or ownerlist[4]
    if not gpowner then
      gpowner = 0
    end
    local gpname = chatname
    chatname = enc(chatname)
    local link = "http://tabchi.com/ecsbot/api/addgp.php?bot=" .. bot_id .. "&gpid=" .. v .. "&gpowner=" .. gpowner .. "&charge=" .. expire .. "&gpname=" .. chatname
    local url, res = http.request(link)
    if res == 200 then
      local jdat = json.decode(url)
      print("\027[" .. color.white[1] .. ";" .. color.black[2] .. [[
m
Number : ]] .. i .. [[

Bot ID : ]] .. bot_id .. [[

Gp ID : ]] .. v .. [[

Gp Owner : ]] .. gpowner .. [[

Charge : ]] .. expire .. [[

Gp Name : ]] .. gpname .. [[

Gpname BS64: ]] .. chatname .. [[

OK : ]] .. jdat.ok .. [[

Status : ]] .. jdat.detail .. "\027[00m")
    end
    i = i + 1
    sleep(2)
  end
end
return status()
