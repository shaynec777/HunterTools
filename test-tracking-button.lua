local shift=true
IsShiftKeyDown=function() return shift end
local settings={enabled=true,locked=false,x=-28,y=-180}
local state={choices={{id=14318,name='Tracking of the Hawk'},{id=13163,name='Tracking of the Monkey'}}}
local F={db={},TrackingSettings=function() return settings end,TrackingState=function() return state end}
local combat=false;InCombatLockdown=function() return combat end
UnitClass=function() return 'Hunter','HUNTER' end;GetTime=function() return 100 end
C_Spell={GetSpellTexture=function(id) return id+10 end}
local created=0
local function widget()
    created=created+1
    local w={scripts={},attributes={},refs={},shown=false,moving=false}
    setmetatable(w,{__index=function(_,key)
        if key=='SetFrameRef' then return nil end -- Click template does not supply base-template methods.
        if key=='CreateTexture' or key=='CreateFontString' then return widget end
        return function() end
    end})
    function w:SetChecked(v) self.checked=v end
    function w:GetChecked() return self.checked end
    function w:SetScript(k,v) self.scripts[k]=v end
    function w:SetAttribute(k,v) self.attributes[k]=v end
    function w:SetPoint(...) self.point={...} end
    function w:SetTexture(v) self.texture=v end
    function w:SetShown(v) self.shown=v end
    function w:SetText(v) self.text=v end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:GetCenter() return 400,200 end
    function w:StartMoving() self.moving=true end
    function w:StopMovingOrSizing() self.moving=false end
    return w
end
CreateFrame=widget;UIParent={GetCenter=function() return 500,300 end}
SecureHandlerSetFrameRef=function(frame,key,value) frame.refs[key]=value end
SecureHandlerWrapScript=function(button,script,header,pre,post)
    assert(type(pre)=='string','Forever rejects a nil secure pre-handler body')
    local newbutton,message=assert(loadstring(pre))()
    assert(newbutton==nil and message~=nil,'post-handler only runs when pre-handler returns a message')
    button.secureClose=post
end
RegisterStateDriver=function() end
UISpecialFrames={}
assert(loadfile('HunterTools/SpellDropdown.lua'))('test',F)
assert(loadfile('HunterTools/TrackingButton.lua'))('test',F)
local readTrackingState=F.TrackingState
settings=F.TrackingSettings();settings.reminder=false
F.TrackingState=function() return state end
F.UpdateTrackingButton();local b,p=F.trackingButton,F.trackingPicker
assert(b.shown and b.empty.shown and b.refs.picker==F.trackingDropdown and b.attributes._onclick:find('RightButton',1,true))
assert(p.buttons[1].shown and p.buttons[1].attributes.type=='spell' and p.buttons[1].attributes.spell==14318)
assert(p.buttons[2].attributes.spell==13163 and not p.buttons[3].shown)
assert(p.buttons[1].trackingIcon.texture==14328 and p.buttons[1].text=='Tracking of the Hawk')
assert(p.buttons[1].secureClose=='self:GetParent():Hide()')
shift=false;b.scripts.OnDragStart(b);assert(not b.moving,'plain drag must not move')
shift=true;b.scripts.OnDragStart(b);assert(b.moving)
b.scripts.OnDragStop(b);assert(not b.moving and settings.x==-100 and settings.y==-100)
settings.locked=true;b.scripts.OnDragStart(b);assert(not b.moving)
state.active=state.choices[1];F.UpdateTrackingButton();assert(b.icon.texture==14328 and not b.empty.shown and b.trackingName=='Tracking of the Hawk')
p:Show();p.buttons[1].scripts.PostClick();assert(not p.shown)
combat=true;local before=created
F.TrackingState=function() error('must not query tracking state in combat') end
F.UpdateTrackingButton();b.scripts.OnDragStart(b);F.ResetTrackingButton();assert(created==before and not b.moving)
combat=false;F.TrackingState=function() return state end
settings.enabled=false;p:Show();F.UpdateTrackingButton();assert(not b.shown and not p.shown)
settings.enabled=true;F.UpdateTrackingButton();assert(b.shown)
F.ResetTrackingButton();assert(settings.x==-28 and settings.y==-180)
state.choices={};F.UpdateTrackingButton();assert(not p.buttons[1].shown and p.buttons[1].attributes.spell==nil)
print('PASS: independent tracking button enable/lock, saved dragging/reset, secure right-click picker and learned casts, secure close, active/empty icon, refreshed choices and combat guards')

settings.locked=false
b.scripts.OnDragStart(b);assert(b.moving)
combat=true;b.scripts.OnDragStop(b)
assert(b.moving and F.trackingButtonDragStopPending)
F.UpdateTrackingButton();assert(b.moving, 'protected movement must wait through combat')
combat=false;settings.enabled=false;F.UpdateTrackingButton()
assert(not b.moving and not F.trackingButtonDragging and not F.trackingButtonDragStopPending)
assert(settings.x==-100 and settings.y==-100, 'deferred stop saves position even when disabled')
print('PASS: combat-interrupted drag finishes and saves on the first safe update')

-- Discover spell-backed tracking from the native list, including professions.
local rows={
 {spellID=1494,name='Track Beasts',texture=1,active=false},
 {spellID=2383,name='Find Herbs',texture=2,active=true},
 {spellID=2580,name='Find Minerals',texture=3,active=false},
 {name='Repair',active=true},
 {spellID=9999,name='Not learned',active=false},
 {spellID=2383,name='Find Herbs',active=true},
}
local known={[1494]=true,[2383]=true,[2580]=true}
C_SpellBook={IsSpellKnown=function(id) return known[id] or false end}
C_Minimap={GetNumTrackingTypes=function() return #rows end,GetTrackingInfo=function(i) return rows[i] end}
local actual=readTrackingState();assert(#actual.choices==3 and actual.active.id==2383)
rows[3].spellID=nil
C_Minimap.GetTrackingFilter=function(i) if i==3 then return {spellID=2580} end end
assert(readTrackingState().choices[3].id==2580)
F.TrackingState=readTrackingState;settings.enabled=true;settings.reminder=true
F.UpdateTrackingButton();assert(b.trackingName=='Find Herbs' and p.buttons[2].text:find('* ',1,true))
rows[2].active=false;rows[6].active=false
local now=100;GetTime=function() return now end
UnitIsDeadOrGhost=function() return false end
F.UpdateTrackingButton();assert(not p.shown)
now=104;F.UpdateTrackingButton();assert(p.shown and p.autoPrompt)
p.keep.scripts.OnClick();F.UpdateTrackingButton();assert(not p.shown and settings.intentionalNone)
rows[1].active=true;F.UpdateTrackingButton();assert(not settings.intentionalNone)
rows[1].active=false;now=110;F.UpdateTrackingButton();now=114;F.UpdateTrackingButton();assert(p.shown)
p.later.scripts.OnClick();F.UpdateTrackingButton();assert(not p.shown)
now=415;F.UpdateTrackingButton();assert(p.shown)
F.AspectMenuOpen=function(exclude) assert(exclude=='trackingPicker');return true end
F.UpdateTrackingButton();assert(not p.shown,'other settings pause the reminder')
F.AspectMenuOpen=function() return false end
settings.enabled=false;now=420;F.UpdateTrackingButton();now=424;F.UpdateTrackingButton();assert(not b.shown and p.shown,'reminder is independent of movable button')
settings.reminder=false;F.UpdateTrackingButton();assert(not p.shown)
combat=true;assert(readTrackingState()==nil);combat=false
print('PASS: native hunter/profession discovery, active markers, no service/unlearned/duplicate entries, no-tracking grace, deliberate none, reset, snooze, menu suppression and independent button/reminder')

combat=false
F.MenuText=function() return widget() end
F.HideConfigPages=function() end
F.Print=function() end
F.OpenConfig=function() end
F.OpenTrackingSettings();local panel=F.trackingSettingsPanel
assert(panel.shown and panel.enabled.checked==settings.enabled and panel.reminder.checked==settings.reminder)
panel.reminder:SetChecked(true);panel.reminder.scripts.OnClick();assert(settings.reminder)
panel.enabled:SetChecked(true);panel.enabled.scripts.OnClick();assert(settings.enabled)
panel.locked:SetChecked(true);panel.locked.scripts.OnClick();assert(settings.locked)
combat=true;panel.enabled:SetChecked(false);panel.enabled.scripts.OnClick();assert(settings.enabled and panel.enabled.checked)
combat=false
rows[1].active='secret';issecretvalue=function(v) return v=='secret' end
assert(readTrackingState().uncertain)
F.UpdateTrackingButton();now=500;F.UpdateTrackingButton();assert(not p.shown,'unknown active tracking cannot create a missing-tracking reminder')
print('PASS: settings controls, combat setting protection and unknown tracking suppression')

-- Hover uses the assigned spell, hides on exit/close, and works in combat.
local tooltip={}
GameTooltip={
    SetOwner=function(_,owner) tooltip.owner=owner end,
    SetSpellByID=function(_,id) tooltip.id=id end,
    AddLine=function() end,
    Show=function() tooltip.shown=true end,
    Hide=function() tooltip.shown=false end,
}
local option=p.buttons[1]
function option:GetAttribute(key) return self.attributes[key] end
option:SetAttribute('spell',14318)
combat=true
option.scripts.OnEnter(option)
assert(tooltip.id==14318 and tooltip.owner==option and tooltip.shown)
option.scripts.OnLeave(option);assert(not tooltip.shown)
option.scripts.OnEnter(option);option.scripts.OnHide(option);assert(not tooltip.shown)
option:SetAttribute('spell',nil);tooltip.id=nil
option.scripts.OnEnter(option);assert(tooltip.id==nil and not tooltip.shown)
b.activeSpellID=13163;b.scripts.OnEnter(b)
assert(tooltip.id==13163 and tooltip.owner==b and tooltip.shown)
b.scripts.OnLeave(b);assert(not tooltip.shown)
print('PASS: spell tooltips on picker choices and active button, combat hover and cleanup')

combat=false
local favorites={}
local menuState={choices={{id=10,key='hawk',name='Hawk'},{id=20,key='monkey',name='Monkey'}},active={id=20}}
local menu
local function refresh() F.UpdateSpellDropdown(menu,menuState,favorites,'Test') end
menu=F.BuildSpellDropdown(nil,b,8,function() return favorites end,refresh)
refresh()
assert(menu.buttons[2].text=='|cff86d59c* |rMonkey','active marker follows active spell')
menu.buttons[2].favorite.scripts.OnClick()
assert(favorites.favorites.monkey and menu.buttons[1].attributes.spell==20 and menu.buttons[2].attributes.spell==10)
assert(menu.buttons[1].favorite.text=='|cffffd100*|r' and menu.shown)
menuState.choices[2].id=21;menuState.active.id=21;refresh()
assert(menu.buttons[1].attributes.spell==21,'favorite survives a new spell rank')
combat=true;menu.buttons[1].favorite.scripts.OnClick()
assert(favorites.favorites.monkey and menu.buttons[1].attributes.spell==21,'combat cannot change favorite or cast mapping')
combat=false;menu.buttons[1].favorite.scripts.OnClick()
assert(not favorites.favorites.monkey and menu.buttons[1].attributes.spell==10)
menuState.choices={};refresh()
assert(not menu.buttons[1].shown and not menu.buttons[1].favorite.shown and menu.buttons[1].attributes.spell==nil)
print('PASS: active marker, favorite toggle/order, rank upgrades, combat guard and stale choice cleanup')

-- The second-built button wires both secure handlers, regardless of build order.
combat=false
F.trackingButton=nil
F.aspectButton=widget();F.aspectPicker=widget()
F.BuildTrackingButton()
local current=F.trackingButton
local own=current.refs.picker
local other=F.aspectPicker
assert(current.refs.otherPicker==other and F.aspectButton.refs.otherPicker==own)
function current:GetFrameRef(key) return self.refs[key] end
local click=assert(loadstring('return function(self,button) '..current.attributes._onclick..' end'))()
other:Show();own:Hide();combat=true
click(current,'RightButton');assert(own.shown and not other.shown)
other:Show();click(current,'RightButton');assert(not own.shown and not other.shown)
click(current,'LeftButton');assert(not own.shown)
current.refs.otherPicker=nil;click(current,'RightButton');assert(own.shown)
print('PASS: secure mutual menu exclusion, same-button toggle, missing peer, and both construction orders')
