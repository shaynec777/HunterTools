local shift=true
IsShiftKeyDown=function() return shift end
local settings={button={enabled=true,locked=false,x=-80,y=-180}}
local state={choices={{id=14318,name='Aspect of the Hawk'},{id=13163,name='Aspect of the Monkey'}}}
local F={db={},AspectSettings=function() return settings end,AspectState=function() return state end}
local combat=false;InCombatLockdown=function() return combat end
UnitClass=function() return 'Hunter','HUNTER' end;GetTime=function() return 100 end
C_Spell={GetSpellTexture=function(id) return id+10 end}
local created=0
local function widget()
    created=created+1
    local w={scripts={},attributes={},refs={},shown=false,moving=false}
    setmetatable(w,{__index=function(_,key)
        if key=='spellID' or key=='favoriteKey' then return nil end
        if key=='SetFrameRef' then return nil end -- Click template does not supply base-template methods.
        if key=='CreateTexture' or key=='CreateFontString' then return widget end
        return function() end
    end})
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
assert(loadfile('HunterTools/SpellDropdown.lua'))('test',F)
assert(loadfile('HunterTools/AspectButton.lua'))('test',F)
F.UpdateAspectButton();local b,p=F.aspectButton,F.aspectPicker
assert(b.shown and b.empty.shown and b.refs.picker==p and b.attributes._onclick:find('RightButton',1,true))
assert(p.buttons[1].shown and p.buttons[1].attributes.type=='spell' and p.buttons[1].attributes.spell==14318)
assert(p.buttons[2].attributes.spell==13163 and not p.buttons[3].shown)
assert(p.buttons[1].aspectIcon.texture==14328 and p.buttons[1].text=='Aspect of the Hawk')
assert(p.buttons[1].secureClose=='self:GetParent():Hide()')
shift=false;b.scripts.OnDragStart(b);assert(not b.moving,'plain drag must not move')
shift=true;b.scripts.OnDragStart(b);assert(b.moving)
b.scripts.OnDragStop(b);assert(not b.moving and settings.button.x==-100 and settings.button.y==-100)
settings.button.locked=true;b.scripts.OnDragStart(b);assert(not b.moving)
state.active=state.choices[1];F.UpdateAspectButton();assert(b.icon.texture==14328 and not b.empty.shown and b.aspectName=='Aspect of the Hawk')
p:Show();p.buttons[1].scripts.PostClick();assert(not p.shown)
combat=true;local before=created
F.AspectState=function() error('must not query aspect state in combat') end
F.UpdateAspectButton();b.scripts.OnDragStart(b);F.ResetAspectButton();assert(created==before and not b.moving)
combat=false;F.AspectState=function() return state end
settings.button.enabled=false;p:Show();F.UpdateAspectButton();assert(not b.shown and not p.shown)
settings.button.enabled=true;F.UpdateAspectButton();assert(b.shown)
F.ResetAspectButton();assert(settings.button.x==-80 and settings.button.y==-180)
state.choices={};F.UpdateAspectButton();assert(not p.buttons[1].shown and p.buttons[1].attributes.spell==nil)
print('PASS: independent aspect button enable/lock, saved dragging/reset, secure right-click picker and learned casts, secure close, active/empty icon, refreshed choices and combat guards')

settings.button.locked=false
b.scripts.OnDragStart(b);assert(b.moving)
combat=true;b.scripts.OnDragStop(b)
assert(b.moving and F.aspectButtonDragStopPending)
F.UpdateAspectButton();assert(b.moving, 'protected movement must wait through combat')
combat=false;settings.button.enabled=false;F.UpdateAspectButton()
assert(not b.moving and not F.aspectButtonDragging and not F.aspectButtonDragStopPending)
assert(settings.button.x==-100 and settings.button.y==-100, 'deferred stop saves position even when disabled')
print('PASS: combat-interrupted drag finishes and saves on the first safe update')

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
option.spellID=14318
option:SetAttribute('spell',14318)
combat=true
option.scripts.OnEnter(option)
assert(tooltip.id==14318 and tooltip.owner==option and tooltip.shown)
option.scripts.OnLeave(option);assert(not tooltip.shown)
option.scripts.OnEnter(option);option.scripts.OnHide(option);assert(not tooltip.shown)
option:SetAttribute('spell',nil);option.spellID=nil;tooltip.id=nil
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
F.aspectButton=nil
F.trackingButton=widget();F.trackingDropdown=widget()
F.BuildAspectButton()
local current=F.aspectButton
local own=current.refs.picker
local other=F.trackingDropdown
assert(current.refs.otherPicker==other and F.trackingButton.refs.otherPicker==own)
function current:GetFrameRef(key) return self.refs[key] end
local click=assert(loadstring('return function(self,button) '..current.attributes._onclick..' end'))()
other:Show();own:Hide();combat=true
click(current,'RightButton');assert(own.shown and not other.shown)
other:Show();click(current,'RightButton');assert(not own.shown and not other.shown)
click(current,'LeftButton');assert(not own.shown)
current.refs.otherPicker=nil;click(current,'RightButton');assert(own.shown)
print('PASS: secure mutual menu exclusion, same-button toggle, missing peer, and both construction orders')
