local _,F=...
-- Secure spell rows are prepared outside combat; favorites never cast a spell.
function F.BuildSpellDropdown(name,anchor,limit,settings,refresh)
    local p=CreateFrame('Frame',name,anchor,'SecureHandlerStateTemplate,BackdropTemplate')
    p:SetPoint('TOPLEFT',anchor,'BOTTOMLEFT',0,-2);p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12})
    p:SetBackdropColor(0.035,0.047,0.044,1)
    p.title=p:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');p.title:SetPoint('TOPLEFT',12,-10)
    p.help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');p.help:SetPoint('BOTTOMLEFT',12,10);p.help:SetText('Click to choose. Star to favorite.')
    p.buttons={}
    for i=1,limit do
        local row=CreateFrame('Button',nil,p,'SecureActionButtonTemplate,UIPanelButtonTemplate');p.buttons[i]=row
        row:SetSize(240,24);row:RegisterForClicks('LeftButtonUp');row:SetAttribute('useOnKeyDown',false);row:SetAttribute('type','spell')
        row.icon=row:CreateTexture(nil,'OVERLAY');row.icon:SetSize(18,18);row.icon:SetPoint('LEFT',5,0)
        row.aspectIcon=row.icon;row.trackingIcon=row.icon
        local caption=row:GetFontString()
        if caption then caption:ClearAllPoints();caption:SetPoint('LEFT',29,0);caption:SetPoint('RIGHT',-5,0);caption:SetJustifyH('LEFT') end
        row:SetScript('OnEnter',function(self)
            if not GameTooltip or not self.spellID then return end
            GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetSpellByID(self.spellID);GameTooltip:Show()
        end)
        local function hideTooltip() if GameTooltip then GameTooltip:Hide() end end
        row:SetScript('OnLeave',hideTooltip);row:SetScript('OnHide',hideTooltip)
        row:SetScript('PostClick',function() if not InCombatLockdown() then p:Hide() end end)
        if SecureHandlerWrapScript then SecureHandlerWrapScript(row,'OnClick',p,[[return nil, true]],[[self:GetParent():Hide()]]) end
        local star=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');row.favorite=star;star:SetSize(24,24)
        star:SetScript('OnClick',function()
            if InCombatLockdown() or not row.favoriteKey then return end
            local s=settings();if type(s.favorites)~='table' then s.favorites={} end
            s.favorites[row.favoriteKey]=not s.favorites[row.favoriteKey] or nil
            refresh();p:Show()
        end)
        star:SetScript('OnEnter',function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:AddLine(InCombatLockdown() and 'Change favorites after combat.' or 'Toggle favorite (shown first).',1,1,1);GameTooltip:Show()
        end)
        star:SetScript('OnLeave',hideTooltip);star:SetScript('OnHide',hideTooltip)
    end
    p:Hide();return p
end
function F.UpdateSpellDropdown(p,state,settings,title)
    if InCombatLockdown() then return end
    local favorites=type(settings.favorites)=='table' and settings.favorites or {}
    local choices={}
    for i,spell in ipairs(state.choices) do choices[i]=spell end
    local function key(spell) return spell.key or spell.name end
    -- Stable partition keeps the native order within each group; names/family keys survive rank upgrades.
    table.sort(choices,function(a,b)
        local af,bf=favorites[key(a)]==true,favorites[key(b)]==true
        if af~=bf then return af end
        local ai,bi=0,0
        for i,v in ipairs(state.choices) do if v==a then ai=i end;if v==b then bi=i end end
        return ai<bi
    end)
    local signature={}
    for _,spell in ipairs(choices) do signature[#signature+1]=tostring(spell.id) end
    signature=table.concat(signature,':')
    if p.signature~=signature then p:Hide();p.signature=signature end
    local rows=math.max(1,math.min(16,#choices));local columns=math.max(1,math.ceil(#choices/16))
    p:SetSize(292*columns,54+rows*26)
    p.title:SetText(#choices>0 and title or 'No learned abilities available')
    for i,row in ipairs(p.buttons) do
        local spell=choices[i];local id=spell and spell.id or nil;row.spellID=id;row.favoriteKey=spell and key(spell) or nil
        row:SetAttribute('spell',id);row:SetShown(spell~=nil);row.favorite:SetShown(spell~=nil)
        if spell then
            row:ClearAllPoints();row:SetPoint('TOPLEFT',12+math.floor((i-1)/16)*292,-28-((i-1)%16)*26)
            row.favorite:ClearAllPoints();row.favorite:SetPoint('LEFT',row,'RIGHT',3,0)
            local active=spell.active or (state.active and state.active.id==spell.id)
            row:SetText((active and '|cff86d59c* |r' or '')..spell.name)
            row.favorite:SetText(favorites[key(spell)] and '|cffffd100*|r' or '*')
            local texture=spell.texture
            if not texture and C_Spell and C_Spell.GetSpellTexture then local ok,value=pcall(C_Spell.GetSpellTexture,spell.id);if ok then texture=value end end
            row.icon:SetTexture(texture or 136076)
        end
    end
end
