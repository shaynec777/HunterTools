local settings={button={enabled=true,locked=false,x=-80,y=-180}}
local state={choices={{id=14318,name='Aspect of the Hawk'},{id=13163,name='Aspect of the Monkey'}}}
local F={db={},AspectSettings=function() return settings end,AspectState=function() return state end}
local combat=false;InCombatLockdown=function() return combat end
UnitClass=function() return 'Hunter','HUNTER' end;GetTime=function() return 100 end
C_Spell={GetSpellTexture=function(id) return id+10 end}
local created=0
local function widget()
    created=created+1
    local w={scripts={},attributes={},refs={},shown=false}
    setmetatable(w,{__index=function(_,key)
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
assert(loadfile('HunterTools/AspectButton.lua'))('test',F)
F.UpdateAspectButton();local b,p=F.aspectButton,F.aspectPicker
assert(b.shown and b.empty.shown and b.refs.picker==p and b.attributes._onclick:find('RightButton',1,true))
assert(p.buttons[1].shown and p.buttons[1].attributes.type=='spell' and p.buttons[1].attributes.spell==14318)
assert(p.buttons[2].attributes.spell==13163 and not p.buttons[3].shown)
assert(p.buttons[1].aspectIcon.texture==14328 and p.buttons[1].text=='Aspect of the Hawk')
assert(p.buttons[1].secureClose=='self:GetParent():Hide()')
b.scripts.OnDragStart(b);assert(b.moving)
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
