"""Offline persistence checks; no game settings or network are touched."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
addon = root.name
database = addon + 'DB'
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
cv={}; warnings=0; failWrite=false
function GetBuildInfo() return nil,nil,nil,16001 end
function InCombatLockdown() return false end
function print() warnings=warnings+1 end
C_CVar={
 GetCVar=function(key) return cv[key] end,
 RegisterCVar=function(key,value) if cv[key]==nil then cv[key]=value end end,
 SetCVar=function(key,value) if failWrite then error('write failed') end; cv[key]=value end
}
C_Timer={NewTicker=function(_,fn) tick=fn end}
function CreateFrame()
 frame={RegisterEvent=function() end,SetScript=function(_,_,fn) event=fn end}
 return frame
end
''')
source = (root/'SettingsBackup.lua').read_text(encoding='utf-8')
lua.globals().addon = addon
lua.globals().database = database
lua.execute('_G[database]={text="A: café", nested={enabled=true, value=42}}')
lua.execute(source, addon)
lua.execute('''
event(nil,'ADDON_LOADED',addon); tick()
local prefix='VCSettings1_'..addon..'_'
local head=cv[prefix..'Head']; assert(head)
_G[database].nested.value=99; failWrite=true; tick()
assert(cv[prefix..'Head']==head,'failed write must preserve committed backup')
failWrite=false; _G[database]=nil
''')
lua.execute(source, addon)
lua.execute('''
event(nil,'ADDON_LOADED',addon)
assert(_G[database].text=='A: café' and _G[database].nested.value==42)
local prefix='VCSettings1_'..addon..'_'
cv[prefix..'Head']='A:1:4:0'
_G[database]={keep=true}
''')
lua.execute(source, addon)
lua.execute('''
event(nil,'ADDON_LOADED',addon)
assert(_G[database].keep,'corrupt backup must preserve saved variables')
-- A well-formed scalar must also be rejected as an invalid settings table.
local raw='b1'; local sum=0
for i=1,#raw do sum=(sum*33+raw:byte(i))%2147483647 end
local prefix='VCSettings1_'..addon..'_'
cv[prefix..'A1']='6231'; cv[prefix..'Head']='A:1:2:'..sum
''')
lua.execute(source, addon)
lua.execute("event(nil,'ADDON_LOADED',addon); assert(_G[database].keep)")
print('PASS: backup round trip, UTF-8, failed writes, corruption and scalar rejection')
