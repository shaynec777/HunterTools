local shift=true
IsShiftKeyDown=function() return shift end
local F={db={},FEED_EFFECT=1539}
local frames={}
local function widget()
    local w={scripts={},shown=true}
    setmetatable(w,{__index=function(_,key)
        if key=='CreateFontString' or key=='CreateTexture' then return widget end
        return function() end
    end})
    function w:SetScript(event,fn) self.scripts[event]=fn end
    function w:SetText(value) self.text=value end
    function w:GetStringHeight() return #(self.text or '')>0 and 100 or 0 end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:GetCenter() return 400,300 end
    function w:StartMoving() self.moving=true end
    function w:StopMovingOrSizing() self.moving=false end
    frames[#frames+1]=w;return w
end
CreateFrame=widget;UIParent={GetCenter=function() return 100,100 end}
local hooks,postCall={},nil
GameTooltip={HookScript=function(_,event,fn) hooks[event]=fn end}
TooltipDataProcessor={AddTooltipPostCall=function(_,fn) postCall=fn end};Enum={TooltipDataType={Unit=2}}
InCombatLockdown=function() return false end
UnitClass=function() return 'Hunter','HUNTER' end
UnitExists=function() return true end
UnitGUID=function() return 'pet-one' end
UnitName=function() return 'Strider' end
UnitLevel=function() return 17 end
UnitCreatureFamily=function() return 'Tallstrider' end
UnitHealth=function() return 240 end;UnitHealthMax=function() return 300 end
UnitPower=function() return 35 end;UnitPowerMax=function() return 100 end
UnitIsDeadOrGhost=function() return false end
C_PetInfo={GetPetHappiness=function() return 3,125,1 end,GetPetLoyalty=function() return 'Faithful' end,GetPetTrainingPoints=function() return 40,25 end}
C_Spell={GetSpellName=function() return 'Feed Pet Effect' end}
C_UnitAuras={GetAuraDataBySpellName=function() return nil end}
UnitIsUnit=function(unit,other) return unit=='mouseover' and other=='pet' end
F.PetDietText=function() return 'Pet eats: Fruit, Cheese' end
F.foodCount=12;F.food={name='Apple'}
F.FindFood=function() F.bagsDirty=false end
time=function() return 1000 end
F.PetRole=function(family) return family=='Tallstrider' and 'Defensive (Classic baseline)' or 'Unknown' end
assert(loadfile('HunterTools/PetStatus.lua'))('test',F)
local s=F.PetStatusSettings();assert(not s.enabled and s.tooltipEnabled and #F.petStatusFields==12)
s.windowFields.health=false;assert(s.tooltipFields.health,'surfaces must not share their table')
s.windowFields.health=true
local d=F.PetStatusData();assert(d.name=='Strider' and d.health=='240 / 300 (80%)')
assert(d.role=='Defensive (Classic baseline)' and s.windowFields.role and s.tooltipFields.role)
s.windowFields.role=false;assert(s.tooltipFields.role)
assert(d.happiness=='Happy â€¢ 125% damage' and d.loyalty=='Faithful â€¢ rising')
assert(d.training=='15 available / 40 total (25 spent)' and d.food:find('12 suitable items',1,true))
F.db.petLastFeeds={['pet-one']={food='Apple',at=880}};assert(F.PetStatusData().lastFeed=='Apple â€¢ 2 min ago')
F.foodEntryPending=true;assert(F.PetStatusData().food=='Inventory settlingâ€¦');F.foodEntryPending=nil
local lineCount=#F.PetStatusLines(d,s.windowFields);s.windowFields.diet=false;assert(#F.PetStatusLines(d,s.windowFields)==lineCount-1)
local added={}
local tip={GetUnit=function() return 'Strider','mouseover' end,AddLine=function(_,v) added[#added+1]=v end}
postCall(tip);assert(#added>2 and table.concat(added):find('Diet: Fruit, Cheese',1,true))
local before=#added;postCall(tip);assert(#added==before,'do not duplicate tooltip lines')
hooks.OnTooltipCleared(tip);s.tooltipFields.diet=false;added={};postCall(tip);assert(not table.concat(added):find('Diet:',1,true))
hooks.OnTooltipCleared(tip);tip.GetUnit=function() return 'Other','target' end;added={};postCall(tip);assert(#added==0,'do not show own pet data on another unit')
s.enabled=true;F.UpdatePetStatusWindow();local p=F.petStatusWindow;assert(p.shown and p.name.text=='Strider' and p.health.shown and p.focus.shown)
F.OpenConfig=function() F.menuOpened=true end;p.scripts.OnMouseUp(nil,'RightButton');assert(F.menuOpened)
s.windowFields.health=false;F.UpdatePetStatusWindow();assert(not p.health.shown and p.focus.shown)
shift=false;p.scripts.OnDragStart();assert(p.moving~=true,'plain drag must not move')
shift=true;p.scripts.OnDragStart();assert(p.moving);p.scripts.OnDragStop();assert(not p.moving and s.x==300 and s.y==200)
s.locked=true;p.scripts.OnDragStart();assert(not p.moving)
F.ResetPetStatusPosition();assert(s.x==270 and s.y==-160)
InCombatLockdown=function() return true end
UnitName=function() error('restricted pet query') end
assert(F.PetStatusData().paused);F.UpdatePetStatusWindow();assert(not p.health.shown and not p.focus.shown and p.details.text:find('paused',1,true))
added={};tip.GetUnit=function() error('must not inspect tooltip unit in combat') end;postCall(tip);assert(#added==0)
InCombatLockdown=function() return false end;UnitName=function() return 'Strider' end
s.enabled=false;F.UpdatePetStatusWindow();assert(not p.shown)
UnitExists=function() return false end;assert(F.PetStatusData().missing)
UnitExists=function() return true end;UnitHealth=nil;C_PetInfo.GetPetLoyalty=function() error('API unavailable') end
issecretvalue=function(v) return v=='secret' end;UnitPower=function() return 'secret' end
d=F.PetStatusData();assert(d.health=='Unavailable' and d.focus=='Unavailable' and d.loyalty:find('Unavailable',1,true))
issecretvalue=nil
F.db.petStatus={enabled=false,tooltipEnabled=false,x=0/0,y='bad',windowFields='bad'}
s=F.PetStatusSettings();assert(not s.enabled and not s.tooltipEnabled and s.x==270 and s.y==-160 and s.windowFields.health)
print('PASS: pet status fields, independent options, unit tooltips, deduplication, movement/lock/reset, saved preferences, missing APIs and combat/secret guards')

InCombatLockdown=function() return false end;UnitExists=function() return true end
Enum.SpellBookSpellBank={Pet=1}
local names={[10]='Bite',[20]='Growl'}
C_SpellBook={HasPetSpells=function() return 3 end,GetSpellBookItemInfo=function(i) return {spellID=({20,10,10})[i]} end}
C_Spell.GetSpellName=function(id) return names[id] end
C_Spell.GetSpellSubtext=function(id) return id==10 and 'Rank 3' or 'Rank 2' end
assert(F.CurrentPetAbilities()=='Bite (Rank 3); Growl (Rank 2)')
s.windowFields.abilities=true;s.tooltipFields.abilities=true
assert(F.PetStatusData().abilities=='Bite (Rank 3); Growl (Rank 2)')
C_SpellBook.GetSpellBookItemInfo=function(i) if i==2 then return {} end;return {spellID=20} end
assert(F.CurrentPetAbilities():find('Partial list',1,true))
C_SpellBook.HasPetSpells=function() return 0 end
assert(F.CurrentPetAbilities():find('loading',1,true))
C_SpellBook=nil
HasPetSpells=function() return 1 end
GetSpellBookItemName=function() return 'Claw','Rank 2' end
assert(F.CurrentPetAbilities()=='Claw (Rank 2)')
InCombatLockdown=function() return true end
HasPetSpells=function() error('must not inspect pet spellbook during combat') end
assert(F.CurrentPetAbilities()=='Unavailable during combat')
InCombatLockdown=function() return false end;UnitExists=function() return false end
assert(F.CurrentPetAbilities()=='No pet')
print('PASS: current-pet spellbook names/ranks, deduplication, independent display settings, partial/empty loading, legacy fallback, combat and missing-pet guards')
