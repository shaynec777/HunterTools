local F={ReminderPetName=function() return 'Fang' end}
assert(loadfile('HunterTools/InstanceCheck.lua'))('test',F)
InCombatLockdown=function() return false end
C_Spell={GetSpellName=function(id) return id==6795 and 'Growl' or 'Aspect of the Pack' end}
GetPetActionInfo=function(i) if i==4 then return 'Growl',nil,false,false,true,true end end
C_UnitAuras={GetAuraDataBySpellName=function() return {sourceUnit='player'} end}
local e=F.InstanceEffects(); assert(e.growlOn and e.packOn)
assert(F.InstanceEffectMacro(e,'both')=='/petautocastoff Growl')
assert(F.InstanceEffectMacro(e,'growl')=='/petautocastoff Growl')
assert(F.InstanceEffectMacro(e,'pack')=='','Pack must be replaced through the aspect chooser, never cancelled')
C_UnitAuras.GetAuraDataBySpellName=function() return {sourceUnit='party1'} end
GetPetActionInfo=function() return 'Growl',nil,false,false,true,false end
e=F.InstanceEffects(); assert(not e.growlOn and not e.packOn)
assert(F.InstanceEffectMacro(e,'both')=='')
InCombatLockdown=function() return true end
GetPetActionInfo=function() error('must not query pet in combat') end
assert(F.InstanceEffects()==nil)
InCombatLockdown=function() return false end
local now=100
GetTime=function() return now end
UnitClass=function() return 'Hunter','HUNTER' end
local kind='party'
IsInInstance=function() return kind~=nil,kind end
local shown=false
F.instancePrompt={Hide=function() shown=false end,Show=function() shown=true end,
    message={SetText=function() end},buttons={}}
for _,which in ipairs({'growl','pack','both'}) do
    F.instancePrompt.buttons[which]={SetAttribute=function() end,SetShown=function() end}
end
GetPetActionInfo=function() return 'Growl',nil,false,false,true,true end
F.QueueInstanceCheck(); F.CheckInstancePrompt(); assert(not shown)
now=101; F.CheckInstancePrompt(); assert(shown)
kind=nil; F.CheckInstancePrompt(); assert(not shown and not F.instanceCheckPending)
kind='pvp'; F.QueueInstanceCheck(); now=102; F.CheckInstancePrompt(); assert(not shown)
kind='raid'; F.QueueInstanceCheck(); now=103
InCombatLockdown=function() return true end; F.CheckInstancePrompt(); assert(not shown and F.instanceCheckPending)
InCombatLockdown=function() return false end; F.CheckInstancePrompt(); assert(shown)
GetPetActionInfo=function() end; now=110; F.CheckInstancePrompt(); assert(not shown and not F.instanceCheckPending)
print('PASS: Growl/Pack detection, player-owned aura, selective disable macros and combat guard')

kind='party'; now=120; GetPetActionInfo=function() end
F.QueueInstanceCheck(); now=121; F.CheckInstancePrompt(); assert(not shown)
GetPetActionInfo=function() return 'Growl',nil,false,false,true,true end
now=122; F.CheckInstancePrompt(); assert(not shown,'turning Growl on after entry must not prompt')
F.QueueInstanceCheck(); now=123; F.CheckInstancePrompt(); assert(shown,'new entry checks Growl again')
GetPetActionInfo=function() end; now=124; F.CheckInstancePrompt(); assert(not shown)
GetPetActionInfo=function() return 'Growl',nil,false,false,true,true end
now=125; F.CheckInstancePrompt(); assert(not shown,'re-enabling Growl must not reopen a completed warning')
print('PASS: entry-only warning, intentional Growl enable and fresh entry reset')
