local _,F=...
local function showSpellTooltip(self)
    if not GameTooltip then return end
    local id=self:GetAttribute('spell')
    if not id then return end
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
    GameTooltip:SetSpellByID(id)
    GameTooltip:Show()
end
local function hideSpellTooltip() if GameTooltip then GameTooltip:Hide() end end
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...);if not ok or not safe(a) then return end
    if not safe(b) then b=nil end
    return a,b
end
function F.BuildAspectButton()
    if F.aspectButton or InCombatLockdown() then return end
    local b=CreateFrame('Button','HunterToolsAspectButton',UIParent,'SecureHandlerClickTemplate,BackdropTemplate');F.aspectButton=b
    b:SetSize(44,44);b:SetClampedToScreen(true);b:SetMovable(true);b:EnableMouse(true)
    local s=F.AspectSettings().button;b:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y)
    b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=12})
    b:SetBackdropColor(0.04,0.06,0.05,1)
    b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',5,-5);b.icon:SetPoint('BOTTOMRIGHT',-5,5);b.icon:SetTexture(136076)
    b.empty=b:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');b.empty:SetPoint('CENTER');b.empty:SetText('?')
    b:RegisterForDrag('LeftButton');b:RegisterForClicks('RightButtonUp')
    b:SetScript('OnDragStart',function(self)
        if IsShiftKeyDown() and not InCombatLockdown() and not F.AspectSettings().button.locked then self:StartMoving();F.aspectButtonDragging=true end
    end)
    b:SetScript('OnDragStop',function()
        if not F.aspectButtonDragging then return end
        F.aspectButtonDragStopPending=true
        F.FinishAspectButtonDrag()
    end)
    b:SetScript('OnEnter',function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
        if self.activeSpellID then GameTooltip:SetSpellByID(self.activeSpellID)
        else GameTooltip:AddLine('HunterTools aspects',1,0.82,0) end
        GameTooltip:AddLine(self.aspectName or 'No active aspect confirmed',1,1,1)
        GameTooltip:AddLine('Right-click: choose a learned aspect.',0.8,0.9,0.8,true)
        GameTooltip:AddLine(F.AspectSettings().button.locked and 'Position locked. /ht aspects opens settings.' or 'Shift + left-drag to move. /ht aspects opens settings.',0.8,0.8,0.8,true)
        GameTooltip:Show()
    end)
    b:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    local p=F.BuildSpellDropdown('HunterToolsAspectPicker',b,8,function() return F.AspectSettings().button end,F.UpdateAspectButton);F.aspectPicker=p
    SecureHandlerSetFrameRef(b,'picker',p)
    if F.trackingButton then
        SecureHandlerSetFrameRef(b,'otherPicker',F.trackingDropdown)
        SecureHandlerSetFrameRef(F.trackingButton,'otherPicker',p)
    end
    b:SetAttribute('_onclick',[[
        if button == 'RightButton' then
            local other = self:GetFrameRef('otherPicker')
            if other then other:Hide() end
            local picker = self:GetFrameRef('picker')
            if picker:IsShown() then picker:Hide() else picker:Show() end
        end
    ]])
    p:Hide();b:Hide()
end
function F.FinishAspectButtonDrag()
    if InCombatLockdown() or not F.aspectButtonDragStopPending then return end
    local b=F.aspectButton
    if not b then return end
    b:StopMovingOrSizing()
    F.aspectButtonDragging=false;F.aspectButtonDragStopPending=nil
    local x,y=query(b.GetCenter,b);local px,py=query(UIParent.GetCenter,UIParent)
    if type(x)=='number' and type(y)=='number' and type(px)=='number' and type(py)=='number' then
        local settings=F.AspectSettings().button;settings.x=x-px;settings.y=y-py
        b:ClearAllPoints();b:SetPoint('CENTER',UIParent,'CENTER',settings.x,settings.y)
    end
end
function F.UpdateAspectButton()
    if not F.db or InCombatLockdown() then return end
    F.FinishAspectButtonDrag()
    local _,class=query(UnitClass,'player')
    local settings=F.AspectSettings().button
    if class~='HUNTER' or not settings.enabled then
        if F.aspectButton then F.aspectPicker:Hide();F.aspectButton:Hide() end
        return
    end
    F.BuildAspectButton();local b,p=F.aspectButton,F.aspectPicker
    local state=F.AspectState()
    if not state then p:Hide();b:Hide();return end
    local active=state.active
    b.activeSpellID=active and active.id or nil
    local texture=active and query(C_Spell and C_Spell.GetSpellTexture,active.id)
    b.icon:SetTexture(texture or 136076);b.icon:SetDesaturated(not active)
    b.empty:SetShown(active==nil);b.aspectName=active and active.name or nil
    F.UpdateSpellDropdown(p,state,settings,'Aspects')
    b:Show()
end
function F.ResetAspectButton()
    if InCombatLockdown() then return end
    local s=F.AspectSettings().button;s.x=-80;s.y=-180
    if F.aspectButton then F.aspectButton:ClearAllPoints();F.aspectButton:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y) end
end
