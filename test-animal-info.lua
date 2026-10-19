local F={db={range={showPetAbilities=false,showPetDiet=true}},Print=function() end}
local hooks,events,post={}, {}, nil
local function widget()
 local w={scripts={}}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' then return widget end;return function() end end})
 function w:SetScript(e,f) self.scripts[e]=f end
 function w:SetChecked(v) self.checked=v end
 function w:GetChecked() return self.checked end
 function w:RegisterEvent(e) events[e]=self end
 return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={}
GameTooltip={HookScript=function(_,e,f) hooks[e]=f end}
TooltipDataProcessor={AddTooltipPostCall=function(_,f) post=f end};Enum={TooltipDataType={Unit=2}}
local combat=false
InCombatLockdown=function() return combat end
UnitClass=function() return 'Hunter','HUNTER' end
UnitExists=function() return true end
UnitIsUnit=function(a,b) return a==b end
UnitPlayerControlled=function() return false end
UnitCreatureFamily=function(unit) return unit=='target' and 'Boar' or 'Cat' end
UnitGUID=function() return 'Creature-0-123-1-2-3100-0000ABCD' end
UnitLevel=function() return 40 end
GetTime=function() return 100 end
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
local slots={{itemID=117,stackCount=8},{itemID=117,stackCount=4,isLocked=true},{itemID=787,stackCount=7},{itemID=999,stackCount=2}}
C_Container={GetContainerNumSlots=function() return #slots end,GetContainerItemInfo=function(_,s) return slots[s] end}
C_Item={GetItemInfo=function(id) return 'food',nil,nil,id==117 and 1 or 25 end}
C_TooltipInfo={GetUnit=function() return nil end}
assert(loadfile('HunterTools/Range.lua'))('test',F)
assert(loadfile('HunterTools/PetDatabase.lua'))('test',F)
assert(loadfile('HunterTools/PetFoodTypes.lua'))('test',F)
assert(loadfile('HunterTools/TargetPetInfo.lua'))('test',F)
F.foodCatalog={[999]={}}
local s=F.AnimalSettings()
assert(not s.target.abilities and s.mouseover.abilities and s.target.diet)
s.target.role=false;assert(s.mouseover.role)
local text=F.TargetPetDetails()
assert(not text:find('Abilities:',1,true) and not text:find('Role:',1,true))
assert(text:find('Meat (12)',1,true) and text:find('Fish (7)',1,true) and text:find('estimate): 7',1,true) and text:find('Partial count',1,true))
local lines={};local tip={GetUnit=function() return 'Cat','mouseover' end,AddLine=function(_,v) lines[#lines+1]=v end}
F.db.range.enabled=false
post(tip);text=table.concat(lines,'\n');assert(text:find('Cat - level 40',1,true) and text:find('Role: Offensive',1,true),'hover must use hovered animal and work with Range disabled')
local count=#lines;post(tip);assert(#lines==count)
hooks.OnTooltipCleared(tip);s.mouseover.enabled=false;post(tip);assert(#lines==count)
s.mouseover.enabled=true;combat=true;UnitExists=function() error('combat unit read') end;post(tip);assert(F.TargetPetDetails()==nil)
combat=false;UnitExists=function() return true end
slots[1].stackCount=20;events.BAG_UPDATE_DELAYED.scripts.OnEvent();assert(F.AnimalFoodCounts('Meat',40):find('Meat (24)',1,true))
C_TooltipInfo.GetUnit=function() return {lines={{leftText='Diet: Fish'},{leftText='Abilities: Bite Rank 2'}}} end
s.target.abilities=true;assert(F.TargetPetDetails():find('Bite Rank 2',1,true))
UnitPlayerControlled=function() return true end;assert(F.TargetPetDetails()==nil)
UnitPlayerControlled=function() return false end
issecretvalue=function(v) return v=='secret' end;UnitCreatureFamily=function() return 'secret' end;assert(not F.TargetPetDetails():find('secret',1,true),'restricted family is replaced only by public reference data')
issecretvalue=nil;UnitCreatureFamily=function() return 'Cat' end
assert(F.PetRole('Custom Beast')=='Unknown')
assert(loadfile('HunterTools/ConfigUI.lua'))('test',F)
F.UpdateRangeWindow=function() end
F.OpenAnimalSettings();local c=F.animalSettingsPanel.fields.target.food;c.checked=false;c.scripts.OnClick();assert(not s.target.food and s.mouseover.food)
combat=true;c.checked=true;c.scripts.OnClick();assert(not s.target.food and not c.checked)
print('PASS: animal settings migration, separate surfaces, hover identity, Range independence, diet stack counts, partial coverage, level estimate, inventory invalidation, live overrides, tooltip deduplication, role fallback, combat and secret guards, config controls')

-- Forever identity records must not fabricate pet skills or depend on family API availability.
combat=false;UnitCreatureFamily=function() return nil end
UnitCreatureType=function() return 'Beast' end
UnitGUID=function() return 'Creature-0-123-1-2-250868-0000ABCD' end
UnitLevel=function() return 6 end
C_TooltipInfo.GetUnit=function() return nil end
assert(loadfile('HunterTools/ForeverPetData.lua'))('test',F)
s.target.food=true;s.target.role=true;s.target.abilities=true
local detail=F.TargetPetDetails()
assert(detail and detail:find('Family unknown',1,true) and detail:find('Zephras Isle',1,true))
assert(detail:find('Abilities: no database record',1,true) and detail:find('Role: Unknown',1,true))
assert(not detail:find('Bite',1,true) and not detail:find('Eats: Meat',1,true))
assert(not F.foreverPetCreatureDB[250868].tameable,'do not infer tameability from a quest or comment')
assert(F.foreverPetCreatureDB[251245].family=='Cat' and F.foreverPetCreatureDB[251245].tameable)
UnitGUID=function() return 'Creature-0-123-1-2-251245-0000ABCD' end
assert(F.TargetPetDetails():find('Cat',1,true) and F.TargetPetDetails():find('tameable: Wowhead Forever',1,true))
UnitCreatureFamily=function() return 'Wolf' end
assert(F.TargetPetDetails():find('Wolf',1,true),'live family must override static reference')
C_TooltipInfo.GetUnit=function() return {lines={{leftText='Diet: Meat'},{leftText='Abilities: Bite Rank 2'}}} end
assert(F.TargetPetDetails():find('Bite Rank 2',1,true))
UnitGUID=function() return 'Creature-0-123-1-2-999999-0000ABCD' end
UnitCreatureFamily=function() return nil end
assert(F.TargetPetDetails(),'unlisted beasts with no family still show available Beast Lore details')
UnitCreatureType=function() return 'Humanoid' end
assert(F.TargetPetDetails()==nil,'do not add beast information to unrelated NPCs')
local count=0;for id,row in pairs(F.foreverPetCreatureDB) do
 count=count+1;assert(row.source:find('/forever/npc='..id..'/',1,true))
 assert(not row.abilities and not row.diet,'unverified fields must remain absent')
end
assert(count==27 and F.foreverPetCreatureDB[262523].zone=='Mulgore')
assert(F.foreverPetCreatureDB[251661].zone=='Zephras Isle','same-name NPCs remain separate by ID')
print('PASS: partial Forever coverage, source URLs, new beast family fallback, live precedence, tameability provenance, unknown ranks/diets, and same-name NPC IDs')

assert(F.foreverPetFamilyDiets['Bird of Prey']=='Meat')
assert(F.foreverPetCreatureDB[254589].family=='Wolf')
assert(F.foreverPetCreatureDB[253283].family=='Raptor')
UnitGUID=function() return 'Creature-0-123-1-2-256092-0000ABCD' end
UnitCreatureFamily=function() return nil end
UnitCreatureType=function() return 'Beast' end
C_TooltipInfo.GetUnit=function() return nil end
local bird=F.TargetPetDetails()
assert(bird:find('Eats: Meat',1,true) and bird:find('Diet reference: Wowhead Forever.',1,true))
assert(not bird:find('Classic baseline - Forever may differ.',1,true))
C_TooltipInfo.GetUnit=function() return {lines={{leftText='Diet: Fish'}}} end
assert(F.TargetPetDetails():find('Eats: Fish',1,true),'live Beast Lore overrides Wowhead family diet')
print('PASS: direct Wowhead family diets, new taxonomy, and live diet precedence')

-- Explicit beast lookup works on a druid, regardless of hunter display settings.
local messages={};F.Print=function(text) messages[#messages+1]=text end
UnitClass=function() return 'Druid','DRUID' end
UnitName=function() return 'Test Beast' end
UnitCreatureFamily=function() return 'Boar' end
UnitGUID=function() return 'Creature-0-123-1-2-3100-0000ABCD' end
C_TooltipInfo.GetUnit=function() return {lines={{leftText='Abilities: Bite Rank 2'}}} end
F.MarkTargetAbilities=function() error('non-hunter must not receive learned-status labels') end
s.target.enabled=false;s.mouseover.enabled=false;F.db.range.enabled=false
local displayed,heading,height,scroll,shown
F.beastDetailPanel={
 title={SetText=function(_,text) heading=text end},
 text={SetText=function(_,text) displayed=text end,GetStringHeight=function() return 600 end},
 content={SetHeight=function(_,value) height=value end},
 scroll={SetVerticalScroll=function(_,value) scroll=value end},Show=function() shown=true end,
}
F.OpenBeastDetail()
assert(shown and heading=='Test Beast - Beast details' and height==610 and scroll==0)
assert(displayed:find('Bite Rank 2',1,true) and displayed:find('Role:',1,true) and displayed:find('In bags:',1,true))
assert(displayed:find('does not apply',1,true) and not s.target.enabled and not s.mouseover.enabled)
combat=true;UnitExists=function() error('must not query target in combat') end
F.OpenBeastDetail();assert(messages[#messages]=='View beast details after combat.')
combat=false;UnitExists=function() return false end
local searches=0;F.OpenBeastSearch=function(text) assert(text=='');searches=searches+1 end
F.OpenBeastDetail();assert(searches==1)
UnitExists=function() return true end;UnitCreatureFamily=function() return nil end
UnitCreatureType=function() return 'Humanoid' end;UnitGUID=function() return 'Creature-0-0-0-0-999999-ABCD' end
F.OpenBeastDetail();assert(searches>1)
UnitCreatureType=function() return 'Beast' end;UnitPlayerControlled=function() return true end
F.OpenBeastDetail();assert(searches>1)
print('PASS: druid beast lookup, all fields independent of toggles, scroll reset, no hunter learning labels, combat, no target, non-beast and controlled-pet guards')
