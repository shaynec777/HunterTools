local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
function F.RangeSettings()
    if type(F.db.range)~='table' then F.db.range={} end
    local s=F.db.range
    if type(s.enabled)~='boolean' then s.enabled=true end
    for _,key in ipairs({'showPetAbilities','showPetDiet'}) do if type(s[key])~='boolean' then s[key]=true end end
    if type(s.showPetHealRange)~='boolean' then s.showPetHealRange=true end
    for key,default in pairs({x=0,y=-230}) do
        if type(s[key])~='number' or s[key]~=s[key] or math.abs(s[key])>10000 then s[key]=default end
    end
    return s
end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,value=pcall(fn,...)
    if ok and safe(value) then return value end
end
-- Actual Forever hunter Mend Pet ranks; native range checks include applicable modifiers.
local mendRanks={136,3111,3661,3662,13542,13543,13544}
function F.PetHealRangeWarning(ignoreDisplaySetting)
    if not ignoreDisplaySetting and not F.RangeSettings().showPetHealRange then return end
    if query(UnitExists,'pet')~=true then return end
    local dead=query(UnitIsDeadOrGhost,'pet')
    if dead~=false then return end
    if not InCombatLockdown() then
        F.mendPetRangeSpell=nil
        for _,id in ipairs(mendRanks) do
            if query(C_SpellBook and C_SpellBook.IsSpellKnown,id)==true then F.mendPetRangeSpell=id end
        end
    end
    local id=F.mendPetRangeSpell
    if not id then return end
    local inRange
    if C_Spell and C_Spell.IsSpellInRange then inRange=query(C_Spell.IsSpellInRange,id,'pet')
    elseif IsSpellInRange then
        local name=query(C_Spell and C_Spell.GetSpellName,id)
        if type(name)=='string' then inRange=query(IsSpellInRange,name,'pet') end
    end
    if inRange==false or inRange==0 then return 'Pet too far to heal (Mend Pet)' end
    -- Missing/secret range results do not establish that the pet is too far away.
end
function F.TargetRangeStatus()
    F.rangeNonEnemy=false
    if not UnitExists('target') then return 'No target',0.7,0.7,0.7 end
    local enemy=UnitCanAttack('player','target')
    local dead=UnitIsDeadOrGhost('target')
    if not safe(enemy) or not safe(dead) then return 'Range unavailable',0.7,0.7,0.7 end
    F.rangeNonEnemy=not enemy or dead
    local ranged
    if C_Spell and C_Spell.IsSpellInRange then ranged=C_Spell.IsSpellInRange(75,'target')
    elseif IsSpellInRange and C_Spell and C_Spell.GetSpellName then ranged=IsSpellInRange(C_Spell.GetSpellName(75),'target') end
    if not safe(ranged) then return 'Range unavailable',0.7,0.7,0.7 end
    if ranged==true or ranged==1 then return 'In range',0.2,1,0.3 end
    if ranged~=false and ranged~=0 then
        if F.rangeNonEnemy then
            local low,high=F.NonEnemyDistanceBand()
            local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(75)
            local minimum=info and info.minRange
            local maximum=info and info.maxRange
            if safe(minimum) and safe(maximum) and type(minimum)=='number' and type(maximum)=='number' then
                if high and high<minimum then return 'Too close',1,0.3,0.15 end
                if low and low>maximum then return 'Too far',1,0.8,0.2 end
                if low and high and low>=minimum and high<=maximum then return 'In range',0.2,1,0.3 end
            end
            return 'Range uncertain',0.7,0.7,0.7
        end
        return 'Range unavailable',0.7,0.7,0.7
    end
    -- Follow-distance is inside Auto Shot's normal maximum range, so a failed
    -- ranged check inside that distance means the target is too close.
    local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(75)
    local maximum=info and info.maxRange
    local near=CheckInteractDistance and CheckInteractDistance('target',4)
    if not safe(near) or not safe(maximum) or type(maximum)~='number' or maximum<28 then
        return 'Range unavailable',0.7,0.7,0.7
    end
    if near==true or near==1 then return 'Too close',1,0.3,0.15 end
    if near==false or near==0 then return 'Too far',1,0.8,0.2 end
    return 'Range unavailable',0.7,0.7,0.7
end
function F.NonEnemyDistanceBand()
    if not CheckInteractDistance then return nil end
    local close=CheckInteractDistance('target',3)
    local near=CheckInteractDistance('target',4)
    if not safe(close) or not safe(near) then return nil end
    if close==true or close==1 then return 0,10 end
    if near==true or near==1 then return (close==false or close==0) and 10 or 0,28 end
    if near==false or near==0 then return 28,nil end
end
function F.TargetDistanceEstimate(status)
    if F.rangeNonEnemy and status~='No target' and status~='Range unavailable' then
        local low,high=F.NonEnemyDistanceBand()
        if low and high then return ('Est. %g-%g yd'):format(low,high) end
        if low then return ('Est. > %g yd'):format(low) end
        return 'Distance unavailable'
    end
    if status~='In range' and status~='Too close' and status~='Too far' then
        return 'Distance unavailable'
    end
    local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(75)
    if not safe(info) or type(info)~='table' then return 'Distance unavailable' end
    local minimum,maximum=info.minRange,info.maxRange
    if not safe(minimum) or not safe(maximum) or type(minimum)~='number'
        or type(maximum)~='number' or minimum<0 or maximum<=minimum then
        return 'Distance unavailable'
    end
    if status=='Too close' then
        if minimum==0 then return 'Distance unavailable' end
        return ('Est. < %g yd'):format(minimum)
    elseif status=='Too far' then
        return ('Est. > %g yd'):format(maximum)
    end
    return ('Est. %g-%g yd'):format(minimum,maximum)
end

function F.UpdateRangeWindow()
    local s=F.RangeSettings()
    local _,class=UnitClass('player')
    if class~='HUNTER' or not s.enabled then
        if F.rangeWindow then F.rangeWindow:Hide() end
        return
    end
    if not F.rangeWindow then
        if InCombatLockdown() then return end
        local p=CreateFrame('Frame','HunterToolsRange',UIParent,'BackdropTemplate'); F.rangeWindow=p
        p:SetSize(245,94); p:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y)
        p:SetMovable(true); p:EnableMouse(true); p:SetClampedToScreen(true); p:RegisterForDrag('LeftButton')
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12})
        p.portrait=p:CreateTexture(nil,'ARTWORK')
        p.portrait:SetSize(42,42); p.portrait:SetPoint('TOPLEFT',10,-10)
        p.targetName=p:CreateFontString(nil,'OVERLAY','GameFontNormal')
        p.targetName:SetPoint('TOPLEFT',p,'TOPLEFT',60,-15); p.targetName:SetWidth(175)
        p.targetName:SetJustifyH('LEFT'); p.targetName:SetWordWrap(false)
        p.text=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge'); p.text:SetPoint('TOPLEFT',60,-37)
        p.distance=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); p.distance:SetPoint('TOP',0,-69)
        p.petHeal=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');p.petHeal:SetPoint('TOPLEFT',12,-91);p.petHeal:SetWidth(221);p.petHeal:SetJustifyH('LEFT');p.petHeal:SetTextColor(1,0.2,0.15)
        p.petDetails=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); p.petDetails:SetPoint('TOPLEFT',12,-96); p.petDetails:SetWidth(221); p.petDetails:SetJustifyH('LEFT')
        p:SetScript('OnDragStart',function() if IsShiftKeyDown() and not InCombatLockdown() then p:StartMoving() end end)
        p:SetScript('OnDragStop',function()
            p:StopMovingOrSizing()
            local x,y=p:GetCenter(); local px,py=UIParent:GetCenter()
            s.x,s.y=x-px,y-py
        end)
        p:SetScript('OnMouseUp',function(_,button)
            if button=='RightButton' then F.OpenConfig() end
        end)
        p:SetScript('OnEnter',function()
            GameTooltip:SetOwner(p,'ANCHOR_RIGHT'); GameTooltip:SetText('Hunter range')
            GameTooltip:AddLine('Right-click: settings. Shift + left-drag to move outside combat. /ht range toggles this window.',1,1,1,true)
            GameTooltip:AddLine('Checks Auto Shot range; does not check line of sight, ammunition, or cooldowns.',0.7,0.7,0.7,true)
            GameTooltip:AddLine('Pet warning uses Mend Pet range. Line of sight and healing resources are not checked.',0.7,0.7,0.7,true);GameTooltip:Show()
        end)
        p:SetScript('OnLeave',function() GameTooltip:Hide() end)
    end
    local exists=UnitExists('target')
    local name=exists and UnitName('target')
    if not safe(name) or type(name)~='string' then name=exists and 'Target' or 'No target' end
    F.rangeWindow.targetName:SetText(name)
    if exists and SetPortraitTexture then
        SetPortraitTexture(F.rangeWindow.portrait,'target')
        F.rangeWindow.portrait:Show()
    else F.rangeWindow.portrait:Hide() end
    local details=F.TargetPetDetails and F.TargetPetDetails()
    local heal=F.PetHealRangeWarning()
    F.rangeWindow.petHeal:SetText(heal or '');F.rangeWindow.petHeal:SetShown(heal~=nil)
    local healSpace=heal and (F.rangeWindow.petHeal:GetStringHeight()+8) or 0
    F.rangeWindow.petDetails:ClearAllPoints();F.rangeWindow.petDetails:SetPoint('TOPLEFT',12,-96-healSpace)
    F.rangeWindow.petDetails:SetText(details or '')
    F.rangeWindow.petDetails:SetShown(details~=nil)
    F.rangeWindow:SetHeight((details and (110+F.rangeWindow.petDetails:GetStringHeight()) or 94)+healSpace)
    local text,r,g,b=F.TargetRangeStatus()
    F.rangeWindow.portrait:SetDesaturated(F.rangeNonEnemy and true or false)
    F.rangeWindow.targetName:SetTextColor(F.rangeNonEnemy and 0.7 or 1,F.rangeNonEnemy and 0.7 or 0.82,F.rangeNonEnemy and 0.7 or 0)
    F.rangeWindow:SetAlpha((F.rangeNonEnemy and not heal) and 0.65 or 1); F.rangeWindow.distance:SetTextColor(F.rangeNonEnemy and 0.65 or 1,F.rangeNonEnemy and 0.65 or 1,F.rangeNonEnemy and 0.65 or 1); F.rangeWindow.distance:SetText(F.TargetDistanceEstimate(text)); F.rangeWindow.text:SetText(text); F.rangeWindow.text:SetTextColor(F.rangeNonEnemy and 0.7 or r,F.rangeNonEnemy and 0.7 or g,F.rangeNonEnemy and 0.7 or b); F.rangeWindow:Show()
end
