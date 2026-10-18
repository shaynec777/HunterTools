local F={db={},ReminderPetName=function() return 'Wolf' end,Print=function() end}
local created={}
local function widget(kind,name,parent)
    local w={kind=kind,scripts={},attributes={},shown=false,children={}}
    if parent and parent.children then parent.children[#parent.children+1]=w end
    setmetatable(w,{__index=function(_,key)
        if key=='CreateFontString' or key=='CreateTexture' then return function(self) return widget('FontString',nil,self) end end
        return function() end
    end})
    function w:SetScript(e,fn) self.scripts[e]=fn end
    function w:SetAttribute(k,v) self.attributes[k]=v end
    function w:SetText(v) self.text=v end
    function w:SetTexture(v) self.texture=v end
    function w:SetChecked(v) self.checked=v end
    function w:GetChecked() return self.checked end
    function w:SetShown(v) self.shown=v end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    created[#created+1]=w;return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={}
RegisterStateDriver=function(frame,state,condition) frame.driver=condition end
local combat,mounted,dead=false,false,false
local now=100;GetTime=function() return now end
InCombatLockdown=function() return combat end;IsMounted=function() return mounted end
UnitIsDeadOrGhost=function() return dead end;UnitOnTaxi=function() return false end
UnitClass=function() return 'Hunter','HUNTER' end
local inside,kind=false,'none';IsInInstance=function() return inside,kind end
local names={[13165]='Aspect of the Hawk',[14318]='Aspect of the Hawk',[13163]='Aspect of the Monkey',[13159]='Aspect of the Pack',[6795]='Growl'}
local known={[14318]=true,[13163]=true,[13159]=true}
C_Spell={GetSpellName=function(id) return names[id] end,GetSpellTexture=function(id) return id+10 end}
C_SpellBook={IsSpellKnown=function(id) return known[id] or false end}
local active,source=nil,'player'
C_UnitAuras={GetAuraDataBySpellName=function(_,name) if name==active then return {sourceUnit=source,auraInstanceID=42} end end}
local growl=false
GetPetActionInfo=function(slot) if slot==1 and growl then return 'Growl',nil,false,false,true,true end end
F.InstanceSettings=function() F.db.instanceChecks=F.db.instanceChecks or {};return F.db.instanceChecks end
F.HideConfigPages=function() for _,p in ipairs({F.aspectPrompt,F.aspectSettingsPanel,F.instancePrompt}) do p:Hide() end end
F.OpenConfig=function() end
assert(loadfile('HunterTools/InstanceCheck.lua'))('test',F)
assert(loadfile('HunterTools/AspectReminder.lua'))('test',F)
local state=F.AspectState();assert(#state.choices==3 and state.choices[1].id==14318)
F.CheckAspectPrompt();assert(not F.aspectPrompt)
now=104;F.CheckAspectPrompt();local p=F.aspectPrompt;assert(p.shown and p.reason=='missing')
assert(p.driver=='[combat] combat; peace' and p.buttons[1].attributes.type=='spell' and p.buttons[1].attributes.spell==14318)
assert(p.buttons[1].aspectIcon.texture==14328 and p.buttons[1].text==names[14318])
p.keep.scripts.OnClick();assert(F.db.aspects.intentionalNone and not p.shown)
now=200;F.CheckAspectPrompt();assert(not p.shown,'intentional no aspect must survive later checks')
active=names[14318];F.CheckAspectPrompt();assert(not F.db.aspects.intentionalNone and not p.shown)
F.ObserveAspectCancellation('party1',42);assert(not F.db.aspects.intentionalNone)
F.ObserveAspectCancellation('player',99);assert(not F.db.aspects.intentionalNone)
F.ObserveAspectCancellation('player',42);F.CheckAspectPrompt();assert(F.db.aspects.intentionalNone,'delayed aura removal must not erase a cancellation choice')
active=nil;F.CheckAspectPrompt();assert(F.db.aspects.intentionalNone and not p.shown)
active=names[14318];F.CheckAspectPrompt();assert(not F.db.aspects.intentionalNone)
active=nil;F.CheckAspectPrompt();now=204;F.CheckAspectPrompt();assert(p.shown)
p.disable.scripts.OnClick();assert(not F.db.aspects.enabled and not p.shown)
F.CheckAspectPrompt();assert(not p.shown)
F.db.aspects.enabled=true;F.aspectMissingSince=nil
mounted=true;F.CheckAspectPrompt();assert(not p.shown);mounted=false
dead=true;F.CheckAspectPrompt();assert(not p.shown);dead=false
local count=#created;combat=true
C_SpellBook.IsSpellKnown=function() error('must not inspect spells in combat') end
F.CheckAspectPrompt();F.ShowAspectChooser('missing');assert(#created==count)
combat=false;C_SpellBook.IsSpellKnown=function(id) return known[id] or false end
-- Pack entry warning combines safe replacement buttons and a separate Growl action.
inside=true;kind='party';active=names[13159];growl=true
F.QueueInstanceCheck();now=206;F.CheckInstancePrompt();assert(p.shown and p.reason=='pack')
assert(p.growl.shown and p.growl.attributes.macrotext=='/petautocastoff Growl')
for _,button in ipairs(p.buttons) do if button.shown then assert(button.attributes.spell~=13159 and button.attributes.type=='spell') end end
assert(not F.instancePrompt or not F.instancePrompt.shown)
-- A failed click retains the warning; actual aura replacement resolves it.
p.buttons[1].scripts.PostClick();now=208;F.CheckInstancePrompt();assert(p.shown)
active=names[14318];F.CheckInstancePrompt();F.CheckAspectPrompt();assert(not p.shown and F.instancePrompt.shown)
assert(F.instancePrompt.buttons.growl and not F.instancePrompt.buttons.pack and not F.instancePrompt.buttons.both)
-- An explicit Keep Pack applies only to this entry.
active=names[13159];F.QueueInstanceCheck();now=210;F.CheckInstancePrompt();assert(p.shown)
p.keep.scripts.OnClick();F.CheckInstancePrompt();assert(not p.shown and F.instanceEntryEffects.pack==false)
growl=false;F.CheckInstancePrompt();F.CheckInstancePrompt();assert(not p.shown)
F.QueueInstanceCheck();now=212;F.CheckInstancePrompt();assert(p.shown)
p.later.scripts.OnClick();F.CheckInstancePrompt();assert(not p.shown)
now=513;F.CheckInstancePrompt();assert(p.shown)
p.disable.scripts.OnClick();F.CheckInstancePrompt();assert(not p.shown and F.db.instanceChecks.pack==false)
-- Another hunter's Pack is not treated as our own Pack.
F.db.instanceChecks.pack=true;source='party1';F.QueueInstanceCheck();now=515;F.CheckInstancePrompt();assert(not p.shown)
-- Secret or failing aura reads cannot manufacture a missing-aspect warning.
inside=false;kind='none';F.instanceAspectRequest=nil;F.instancePrompt:Hide()
issecretvalue=function(v) return v=='secret' end
C_UnitAuras.GetAuraDataBySpellName=function() return 'secret' end
F.CheckAspectPrompt();now=530;F.CheckAspectPrompt();assert(not p.shown)
C_UnitAuras.GetAuraDataBySpellName=function() error('unavailable') end
F.CheckAspectPrompt();assert(not p.shown)
issecretvalue=nil;C_UnitAuras.GetAuraDataBySpellName=function() return nil end
F.OpenAspectSettings();assert(F.aspectSettingsPanel.shown and F.aspectSettingsPanel.enabled.checked)
F.aspectSettingsPanel.enabled.checked=false;F.aspectSettingsPanel.enabled.scripts.OnClick();assert(not F.AspectSettings().enabled)
print('PASS: learned/highest-rank choices, grace period, intentional absence/reset, toggles, combat/travel, secure casts, Pack replacement/keep/snooze, Growl coordination, aura provenance and secret/error guards')

F.aspectSettingsPanel:Hide()
for _,key in ipairs({'petListPanel','animalSettingsPanel','ammoUpgradePanel','protectionPanel','weaponSettingsPanel'}) do
    F[key]={IsShown=function() return true end}
    assert(F.AspectMenuOpen(),key..' must suppress the aspect chooser')
    F.ShowAspectChooser('missing',{},{choices={}})
    assert(not p.shown,key..' must hide an already visible chooser')
    F[key]=nil
end
assert(not F.AspectMenuOpen())
print('PASS: all additional settings pages suppress aspect pop-ups')
