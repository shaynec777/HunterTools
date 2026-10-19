local F={db={}};local messages={};local sounds,banners=0,0
local function widget()
 local w={scripts={},attributes={},shown=false,value=''}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' or k=='CreateTexture' then return widget end;return function() end end})
 function w:SetScript(k,v) self.scripts[k]=v end
 function w:SetAttribute(k,v) self.attributes[k]=v end
 function w:SetText(v) self.value=v end
 function w:GetText() return self.value end
 function w:SetChecked(v) self.checked=v end
 function w:GetChecked() return self.checked end
 function w:SetShown(v) self.shown=v end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 function w:IsShown() return self.shown end
 function w:GetCenter() return 100,100 end
 return w
end
CreateFrame=widget;UIParent=widget();UISpecialFrames={}
F.MenuText=function() return widget() end
F.Print=function(msg) messages[#messages+1]=msg end
PlaySound=function() sounds=sounds+1 end
RaidWarningFrame={};RaidNotice_AddMessage=function() banners=banners+1 end
local combat,clock=false,100
InCombatLockdown=function() return combat end;GetTime=function() return clock end
local units={}
UnitExists=function(u) return units[u]~=nil end
UnitIsPlayer=function(u) return units[u] and units[u].player or false end
UnitName=function(u) return units[u] and units[u].name end
UnitGUID=function(u) return units[u] and units[u].guid end
UnitPlayerControlled=function(u) return units[u] and units[u].player or false end
UnitIsDeadOrGhost=function(u) return units[u] and units[u].dead or false end
UnitIsUnit=function(u,v) return units[u] and units[v] and units[u].guid==units[v].guid or false end
F.SearchBeasts=function() return {} end
assert(loadfile('HunterTools/MobFinder.lua'))('test',F)
assert(loadfile('HunterTools/PlayerFinder.lua'))('test',F)
local s=F.PlayerFinderSettings();assert(not s.partial)
assert(F.WatchPlayer(' Leon '));assert(#s.watches==1 and s.watches[1]=='Leon')
F.WatchPlayer('leon');assert(#s.watches==1)
units.target={name='Leona Star',guid='Player-1-ABC',player=true};units.nameplate1=units.target
F.OpenPlayerFinder();assert(F.playerFinderPanel.shown and not F.playerFinderFound)
s.partial=true;F.ScanPlayerFinder();assert(F.playerFinderFound.name=='Leona Star' and sounds==1 and banners==1)
local popup=F.playerFinderTargetPopup
assert(popup.shown and popup.isPlayer and popup.target.attributes.type=='target' and popup.target.attributes.unit=='nameplate1' and popup.target.attributes.macrotext==nil)
assert(not F.mobFinderTargetPopup,'player and mob popups are separate')
popup.dismiss.scripts.OnClick();F.ScanPlayerFinder();assert(sounds==1 and not popup.shown)
assert(not F.db.mobFinder,'player watches must not create mob watches')
units.target.player=false;F.ScanPlayerFinder();assert(not F.playerFinderFound)
units.target.player=true;units.target.dead=true;F.ScanPlayerFinder();assert(not F.playerFinderFound)
units.target.dead=false;units.player=units.target;F.ScanPlayerFinder();assert(not F.playerFinderFound,'ignore self')
units.player=nil;s.enabled=false;F.ScanPlayerFinder();assert(not F.playerFinderFound)
s.enabled=true;combat=true
UnitName=function() error('do not read unit names in combat') end
F.ScanPlayerFinder();assert(not F.playerFinderFound)
F.WatchPlayer('Another');assert(#s.watches==1)
combat=false;UnitName=function(u) return units[u] and units[u].name end
local secret={};issecretvalue=function(v) return v==secret end
units.target.name=secret;F.ScanPlayerFinder();assert(not F.playerFinderFound)
issecretvalue=nil;units={}
F.WatchPlayer('Bad\n/attack');assert(#s.watches==1)
F.WatchPlayer('[bad]');assert(#s.watches==1)
s.watches={};assert(F.WatchPlayer('Leona Star'));assert(s.watches[1]=='Leona Star')
for i=2,8 do assert(F.WatchPlayer('Player'..i)) end
assert(not F.WatchPlayer('Ninth') and #s.watches==8)
F.playerFinderPanel.rows[1].scripts.OnClick();assert(#s.watches==7)
F.playerFinderPanel.input:SetText('New Player');F.playerFinderPanel.input.scripts.OnEnterPressed();assert(#s.watches==8)
-- Player-target pings reuse the safe nameplate highlight but accept player targets.
units.target={name='Leona Star',guid='Player-1-ABC',player=true}
local plate=widget();plate:Show();function plate:IsForbidden() return false end
C_NamePlate={GetNamePlateForUnit=function() return plate end}
F.ShowFinderTargetPopup({name='Leona Star',guid='Player-1-ABC',unit='target'},true);F.playerFinderTargetPopup.target.scripts.PostClick()
assert(F.mobFinderTargetPing.shown and F.mobFinderTargetPing.targetGUID=='Player-1-ABC')
F.mobFinderTargetPing:Hide();F.RequestMobFinderTargetPing('Leona Star',false)
assert(not F.mobFinderTargetPing.shown,'mob targeting flow must still reject player-controlled units')
print('PASS: separate player settings/watches/popups, name-only and multiword names, exact/partial matching, deduplication, full-name secure target, repeat suppression, NPC/dead/self exclusions, pause, combat/secrets/input/limit guards, UI and player-only target ping')

-- Secure player targeting bypasses macros and follows GUID identity, not a recycled token.
F.ShowFinderTargetPopup({name='Leona Star',guid='Player-1-ABC',unit='target'},true)
local targetPopup=F.playerFinderTargetPopup
assert(targetPopup.target.attributes.type=='target' and targetPopup.target.attributes.unit=='target')
units.nameplate2=units.target;units.target={name='Other',guid='Player-1-DEF',player=true}
targetPopup.target.scripts.PreClick(targetPopup.target)
assert(targetPopup.target.attributes.type=='target' and targetPopup.target.attributes.unit=='nameplate2')
units.nameplate2=nil;targetPopup.target.scripts.PreClick(targetPopup.target)
assert(targetPopup.target.attributes.type=='macro' and targetPopup.target.attributes.unit==nil and targetPopup.target.attributes.macrotext=='/targetexact Leona Star','must use captured full name instead of a replacement player')
targetPopup.target.scripts.PostClick()
combat=true;targetPopup.target.attributes.type='sentinel'
targetPopup.target.scripts.PreClick(targetPopup.target);assert(targetPopup.target.attributes.type=='sentinel','no secure attribute writes during combat')
print('PASS: native secure player targeting, stable nameplate preference, click-time GUID validation, recycled token resolution, unavailable-target feedback and combat write guard')

combat=false
units={mouseover={name='Darius',surname='Winterspoon',guid='Player-1-DARIUS',player=true}}
UnitNameUnmodified=function(unit) local u=units[unit];if u then return u.name,u.surname end end
assert(F.PlayerFinderName('mouseover')=='Darius Winterspoon')
s.watches={'Darius'};s.partial=true;s.enabled=true
F.ScanPlayerFinder();local darius=F.playerFinderTargetPopup
assert(F.playerFinderFound.name=='Darius Winterspoon' and darius.mobName=='Darius Winterspoon')
units.mouseover=nil;darius.target.scripts.PreClick(darius.target)
assert(darius.target.attributes.type=='macro' and darius.target.attributes.macrotext=='/targetexact Darius Winterspoon' and darius.target.attributes.unit==nil)
units.target={name='Darius Winterspoon',surname='Winterspoon',guid='Player-1-DARIUS',player=true}
assert(F.PlayerFinderName('target')=='Darius Winterspoon','do not duplicate an already expanded surname')
local secretSurname={};issecretvalue=function(v) return v==secretSurname end
units.target.name='Darius';units.target.surname=secretSurname
assert(F.PlayerFinderName('target')=='Darius','never stringify a secret surname')
issecretvalue=nil
print('PASS: Forever first-name/surname expansion, partial first-name watch, captured full-name macro after mouseover loss, no duplicate surname and restricted-surname guard')
