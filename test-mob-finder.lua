local F={db={}}
local frames={}
local function widget()
    local w={scripts={},attributes={},shown=false,value='',level=1}
    setmetatable(w,{__index=function(_,k)
        if k=='CreateTexture' or k=='CreateFontString' then return widget end
        return function() end
    end})
    function w:SetAttribute(k,v) self.attributes[k]=v end
    function w:SetScript(k,v) self.scripts[k]=v end
    function w:SetText(v) self.value=v end
    function w:GetText() return self.value end
    function w:SetShown(v) self.shown=v end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:SetRotation(v) self.rotation=v end
    function w:SetPoint(...) self.point={...} end
    function w:GetWidth() return 200 end
    function w:GetHeight() return 200 end
    function w:GetFrameLevel() return self.level end
    function w:SetChecked(v) self.checked=v end
    function w:GetChecked() return self.checked end
    function w:GetCenter() return 100,100 end
    frames[#frames+1]=w;return w
end
CreateFrame=widget;UIParent=widget();UISpecialFrames={}
F.MenuText=function() return widget() end
local messages,sounds,banners={},0,0
F.Print=function(v) messages[#messages+1]=v end
PlaySound=function() sounds=sounds+1 end
RaidWarningFrame={};RaidNotice_AddMessage=function() banners=banners+1 end
local clock,combat=100,false
GetTime=function() return clock end;InCombatLockdown=function() return combat end
GetPlayerFacing=function() return 0 end;GetCVar=function() return '0' end
local units={}
UnitExists=function(u) return units[u]~=nil end
UnitName=function(u) return units[u] and units[u].name end
UnitGUID=function(u) return units[u] and units[u].guid end
UnitIsPlayer=function(u) return units[u] and units[u].player or false end
UnitPlayerControlled=function(u) return units[u] and units[u].controlled or false end
UnitIsDeadOrGhost=function(u) return units[u] and units[u].dead or false end
UnitPosition=function(u)
    if u=='player' then return 100,100,0,1 end
    local v=units[u];if v then return v.x,v.y,0,v.instance end
end
local function mob(name,id,x,y)
    return {name=name,guid='Creature-0-0-0-0-'..id..'-ABCD',x=x,y=y,instance=1}
end
F.SearchBeasts=function(name) return {{id=10,record={name='Wolf'}},{id=11,record={name='Wolf Alpha'}}} end
Minimap=widget();WorldMapFrame=widget();local canvas=widget()
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return 50 end
WorldMapFrame:Show()
CreateVector2D=function(x,y) return {x=x,y=y} end
C_Map={GetMapPosFromWorldPos=function(instance,v,map) return map,{GetXY=function() return 0.25,0.5 end} end}
C_Minimap={GetViewRadius=function() return 100 end}
assert(loadfile('HunterTools/MobFinder.lua'))('test',F)
local s=F.MobFinderSettings();assert(s.enabled and s.radius==100)
assert(F.WatchMob('Wolf'));assert(#s.watches==1 and #s.watches[1].ids==1)
F.WatchMob('wolf');assert(#s.watches==1)
units.nameplate1=mob('Wolf',10,120,100);units.target=units.nameplate1
F.OpenMobFinder();assert(F.mobFinderPanel.shown and sounds==1 and banners==1)
assert(F.mobFinderFound.name=='Wolf' and F.mobFinderFound.distance==20)
assert(F.mobFinderPanel.arrow.shown and F.mobFinderPanel.arrow.rotation==0)
assert(F.mobFinderMiniPin.shown and F.mobFinderMapPin.shown)
assert(F.mobFinderMiniPin.point[4]==0 and F.mobFinderMiniPin.point[5]==20)
assert(F.mobFinderTargetPopup.shown,'first detection must show Target popup')
F.mobFinderTargetPopup.dismiss.scripts.OnClick()
F.ScanMobFinder();assert(sounds==1,'same sighting must not repeat');assert(not F.mobFinderTargetPopup.shown,'dismissed popup must not reopen for a continuous sighting')
clock=200;F.ScanMobFinder();assert(sounds==2,'a later independent scan can rearm after a gap')
clock=201;F.ScanMobFinder();assert(sounds==2)
units={};F.ScanMobFinder();assert(not F.mobFinderFound and not F.mobFinderPanel.arrow.shown and not F.mobFinderMiniPin.shown and not F.mobFinderMapPin.shown)
units.mouseover=mob('Wolf Alpha',11);F.ScanMobFinder();assert(not F.mobFinderFound,'exact name matching by default')
s.partial=true;F.ScanMobFinder();assert(F.mobFinderFound.name=='Wolf Alpha' and not F.mobFinderPanel.arrow.shown,'nameplate detection works without coordinates')
units.mouseover.dead=true;F.ScanMobFinder();assert(not F.mobFinderFound)
units.mouseover.dead=false;units.mouseover.controlled=true;F.ScanMobFinder();assert(not F.mobFinderFound)
units.mouseover.controlled=false;units.mouseover.player=true;F.ScanMobFinder();assert(not F.mobFinderFound)
units={target=mob('Wolf',10,500,100)};F.ScanMobFinder();assert(not F.mobFinderFound,'readable distance outside radius must not alert')
units.target=mob('Wolf',10,120,100);s.enabled=false;F.ScanMobFinder();assert(not F.mobFinderFound)
s.enabled=true;combat=true
UnitName=function() error('must not inspect units in combat') end
F.ScanMobFinder();assert(not F.mobFinderFound and not F.mobFinderPanel.arrow.shown)
F.WatchMob('Cat');assert(#s.watches==1)
combat=false;UnitName=function(u) return units[u] and units[u].name end
local secret={};issecretvalue=function(v) return v==secret end
UnitPosition=function(u) if u=='player' then return 100,100,0,1 end;return secret,secret,0,secret end
F.ScanMobFinder();assert(F.mobFinderFound and not F.mobFinderPanel.arrow.shown)
units={};ClosestUnitPosition=function() return secret,secret,secret end
F.ScanMobFinder();assert(not F.mobFinderFound,'restricted location data cannot create a sighting')
ClosestUnitPosition=function() return 120,100,20 end
F.ScanMobFinder();assert(F.mobFinderFound and F.mobFinderFound.source:find('alive status unknown',1,true))
UnitPosition=function() return 100,100,0,2 end
assert(F.MobFinderRelative(110,100,1)==nil,'different instances cannot establish direction')
C_Map.GetMapPosFromWorldPos=function() return 50,{GetXY=function() return secret,secret end} end
assert(F.MobFinderMapPoint({x=10,y=20,instance=1},50)==nil)
ClosestUnitPosition=nil;issecretvalue=nil
-- Removing a watch immediately stops detection; options and empty list remain usable.
s.watches={};F.ScanMobFinder();assert(not F.mobFinderFound)
for i=1,8 do assert(F.WatchMob('Mob '..i,100+i)) end
assert(not F.WatchMob('Ninth',200) and #s.watches==8)
F.mobFinderPanel.rows[1].scripts.OnClick();assert(#s.watches==7)
F.mobFinderPanel.input:SetText('New mob');F.mobFinderPanel.input.scripts.OnEnterPressed();assert(#s.watches==8)
F.mobFinderPanel.pause.scripts.OnClick();assert(not s.enabled)
F.mobFinderPanel.pause.scripts.OnClick();assert(s.enabled)
F.mobFinderDriver.scripts.OnEvent(nil,'PLAYER_ENTERING_WORLD');assert(not F.mobFinderFound)
print('PASS: watch names/IDs/deduplication/limits, exact and partial matching, target/nameplate deduplication, repeat suppression, distance radius, player/pet/dead exclusion, pause/remove, UI, combat/secret guards, current arrows/map/minimap points and instance mismatch')

-- Regression: detection without UnitPosition must still try nearest-NPC coordinates,
-- including IDs discovered through a partial-name sighting rather than the database.
s.watches={{name='Rare',ids={}}};s.partial=true;s.enabled=true
units={target=mob('Rare Alpha',999)}
UnitPosition=function(unit) if unit=='player' then return 100,100,0,1 end end
ClosestUnitPosition=function(id) assert(id==999);return 120,100,20 end
F.ScanMobFinder()
assert(F.mobFinderFound.distance==20 and F.mobFinderPanel.arrow.shown)
assert(F.mobFinderPanel.status.value:find('Live coordinates available',1,true))
local restricted={};issecretvalue=function(v) return v==restricted end
ClosestUnitPosition=function() return restricted,restricted,restricted end
F.ScanMobFinder()
assert(F.mobFinderFound and not F.mobFinderPanel.arrow.shown and F.mobFinderPanel.status.value:find('Location unavailable',1,true))
F.DebugMobFinder();assert(messages[#messages]:find('restricted',1,true))
print('PASS: location fallback after coordinate-less detection, partial-match NPC IDs, explicit unavailable status and restricted-value diagnostics')

-- Official map-marker positions provide live navigation without UnitPosition(NPC).
issecretvalue=nil;ClosestUnitPosition=nil
s.watches={{name='Rare',ids={999}}};s.partial=true;s.reference=true;s.enabled=true
UnitPosition=function() return nil end
C_Map.GetBestMapForUnit=function() return 50 end
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return 0.5,0.5 end} end
C_Map.GetWorldPosFromMapPos=function(map,v) return 1,{GetXY=function() return (1-v.y)*200,(1-v.x)*200 end} end
C_Map.GetMapPosFromWorldPos=function() return 50,{GetXY=function() return 0.5,0.4 end} end
C_VignetteInfo={
 GetVignettes=function() return {'vignette-one'} end,
 GetVignetteInfo=function() return {name='Rare Alpha',objectGUID='Creature-0-0-0-0-999-ABCD',isDead=false,onMinimap=true} end,
 GetVignettePosition=function() return {GetXY=function() return 0.5,0.4 end} end,
}
units={};F.ScanMobFinder()
assert(F.mobFinderFound and F.mobFinderFound.source=='Live map marker' and F.mobFinderPanel.arrow.shown)
assert(F.mobFinderMiniPin.shown and F.mobFinderMapPin.shown)
-- No live marker means no replacement coordinates or invented navigation.
C_VignetteInfo.GetVignettes=function() return {} end
local before=sounds
F.ScanMobFinder()
assert(not F.mobFinderFound and not F.mobFinderNavigation and not F.mobFinderPanel.arrow.shown and sounds==before)
units={target=mob('Rare Alpha',999)};F.ScanMobFinder()
assert(F.mobFinderFound and not F.mobFinderPanel.arrow.shown)
C_VignetteInfo.GetVignettes=function() return {'vignette-one'} end
C_VignetteInfo.GetVignetteInfo=function() return {name='Rare Alpha',objectGUID='Creature-0-0-0-0-999-ABCD',isDead=true,onMinimap=true} end
units={};F.ScanMobFinder();assert(not F.mobFinderFound)
C_VignetteInfo.GetVignetteInfo=function() return {name='Unrelated',objectGUID='Creature-0-0-0-0-888-ABCD',isDead=false,onMinimap=true} end
F.ScanMobFinder();assert(not F.mobFinderFound)
print('PASS: native live map-marker navigation, map-to-world/player-position fallback, disappearing/dead/unmatched marker cleanup and no addon dependencies')

-- Detection prepares a secure, click-only exact-name target action; it never targets.
InCombatLockdown=function() return false end
TargetUnit=function() error('automatic targeting must never occur') end
TargetByName=function() error('automatic targeting must never occur') end
F.ShowMobFinderTarget({name='Rare Alpha'})
local popup=F.mobFinderTargetPopup
assert(popup.shown and popup.target.attributes.type=='macro' and popup.target.attributes.macrotext=='/targetexact Rare Alpha')
popup.target.scripts.PostClick();assert(not popup.shown)
F.ShowMobFinderTarget({name='Rare Alpha'});popup.dismiss.scripts.OnClick();assert(not popup.shown)
F.ShowMobFinderTarget({name='Rare Alpha'});clock=clock+16;F.ScanMobFinder();assert(not popup.shown)
popup.target.attributes.macrotext='unchanged'
F.ShowMobFinderTarget({name='bad\n/attack'});assert(popup.target.attributes.macrotext=='unchanged')
F.ShowMobFinderTarget({name='[bad]'});assert(popup.target.attributes.macrotext=='unchanged')
InCombatLockdown=function() return true end
F.ShowMobFinderTarget({name='Rare Alpha'});assert(popup.target.attributes.macrotext=='unchanged')
assert(popup.attributes['_onstate-combat']:find('Hide',1,true))
print('PASS: secure Target popup, exact full-name macro only, no automatic targeting or attack, dismiss/timeout and combat/input guards')

InCombatLockdown=function() return false end
local plate=widget();plate:Show()
function plate:IsForbidden() return false end
C_NamePlate={GetNamePlateForUnit=function() return plate end}
units={target=mob('Rare Alpha',999)}
F.ShowMobFinderTarget({name='Rare Alpha'});popup.target.scripts.PostClick()
local ping=F.mobFinderTargetPing
assert(ping and ping.shown and ping.point[2]==plate and ping.targetGUID==units.target.guid)
clock=clock+4;F.UpdateMobFinderTargetPing();assert(not ping.shown)
F.RequestMobFinderTargetPing('Rare Alpha');assert(ping.shown)
units.target=mob('Other',888);F.UpdateMobFinderTargetPing();assert(not ping.shown)
units={};F.RequestMobFinderTargetPing('Rare Alpha');assert(not ping.shown)
units.target=mob('Rare Alpha',999);F.UpdateMobFinderTargetPing();assert(ping.shown,'target acquisition may arrive after PostClick')
plate:Hide();F.UpdateMobFinderTargetPing();assert(not ping.shown)
F.RequestMobFinderTargetPing('Rare Alpha');clock=clock+2;F.UpdateMobFinderTargetPing()
assert(messages[#messages]:find('nameplate unavailable',1,true))
plate:Show();function plate:IsForbidden() return true end
F.RequestMobFinderTargetPing('Rare Alpha');assert(not ping.shown)
InCombatLockdown=function() return true end;F.UpdateMobFinderTargetPing();assert(not ping.shown)
print('PASS: click-to-target nameplate ping, delayed acquisition, timeout, target change, hidden/forbidden plates, missing plate feedback and combat cleanup')
