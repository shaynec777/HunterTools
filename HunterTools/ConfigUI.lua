local _,F=...
function F.InstanceSettings()
    if type(F.db.instanceChecks)~='table' then F.db.instanceChecks={} end
    for _,key in ipairs({'growl','pack'}) do
        if type(F.db.instanceChecks[key])~='boolean' then F.db.instanceChecks[key]=true end
    end
    return F.db.instanceChecks
end
local function panel(name,title,w,h)
    local p=CreateFrame('Frame',name,UIParent,'BackdropTemplate')
    p:SetSize(w,h); p:SetPoint('CENTER'); p:SetFrameStrata('DIALOG'); p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    local t=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge'); t:SetPoint('TOP',0,-22); t:SetText(title)
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
    table.insert(UISpecialFrames,name)
    return p
end
function F.HideConfigPages()
    for _,key in ipairs({'configPanel','foodPanel','ammoPanel','instanceSettingsPanel','rangeSettingsPanel','petStatusSettingsPanel','petListPanel','animalSettingsPanel','petAbilityBrowser','ammoUpgradePanel','protectionPanel','weaponSettingsPanel','beastJournalPanel','aspectSettingsPanel','aspectPrompt','aspectPicker','petAlertPanel'}) do
        if F[key] then F[key]:Hide() end
    end
end
function F.ToolEnabled(key)
    if key=='abilities' then return F.PetBrowserSettings().enabled end
    if key=='food' then return F.db.enabled end
    if key=='instance' then return F.InstanceSettings().enabled~=false end
    if key=='ammo' then return F.db.ammo.enabled end
    if key=='pet' then return F.PetStatusSettings().enabled end
    return F.RangeSettings().enabled
end
function F.SetToolEnabled(key,value)
    if InCombatLockdown() then F.Print('Change tool settings after combat.'); return end
    if key=='abilities' then F.PetBrowserSettings().enabled=value;if not value and F.petAbilityBrowser then F.petAbilityBrowser:Hide() end
    elseif key=='food' then F.db.enabled=value; F.Refresh()
    elseif key=='instance' then
        F.InstanceSettings().enabled=value
        if not value then F.instanceCheckPending=false; if F.instancePrompt then F.instancePrompt:Hide() end end
    elseif key=='ammo' then F.db.ammo.enabled=value; F.ResetAmmoReminder()
    elseif key=='pet' then F.PetStatusSettings().enabled=value; F.UpdatePetStatusWindow()
    else F.RangeSettings().enabled=value; F.UpdateRangeWindow() end
end
function F.RefreshToolMenu()
    if not F.configPanel then return end
    if F.configPanel.versionLabel then F.configPanel.versionLabel:SetText('Version '..(F.VERSION or 'unknown')) end
    for key,c in pairs(F.configPanel.checks) do
        local enabled=F.ToolEnabled(key);c:SetChecked(enabled)
        F.configPanel.statusLabels[key]:SetText(enabled and '|cff86d59cEnabled|r' or '|cffaaaaaaDisabled|r')
    end
end
function F.OpenConfig()
    if InCombatLockdown() then F.Print('Open settings after combat.'); return end
    F.HideConfigPages()
    if not F.configPanel then
        local p=panel('HunterToolsConfig','',760,572);F.configPanel=p
        p.checks={};p.actions={};p.statusLabels={}
        local emblem=p:CreateTexture(nil,'ARTWORK');emblem:SetSize(90,90);emblem:SetPoint('TOPLEFT',24,-12)
        emblem:SetTexture('Interface\\AddOns\\HunterTools\\Artwork\\HunterToolsLogo')
        F.MenuText(p,'HunterTools',128,-29,550,'GameFontNormalHuge')
        F.MenuText(p,'Your field kit for the hunt',130,-62,550,'GameFontHighlight')
        p.versionLabel=F.MenuText(p,'',130,-85,550,'GameFontHighlightSmall')
        F.MenuText(p,'Enable the tools you want. Open a card to adjust its details.',28,-108,700)
        local tools={
            {'food','Pet feeding','Food rules, supplies and hunger alerts.','OpenFoodList','Food & alerts','Ability_Hunter_BeastTraining'},
            {'instance','Dungeon checks','Growl and Aspect of the Pack reminders.','OpenInstanceSettings','Configure','INV_Misc_Key_03'},
            {'ammo','Ammunition','Stock warnings and usable ammo upgrades.','OpenAmmoSettings','Ammo & upgrades','INV_Ammo_Arrow_02'},
            {'range','Range & animal tips','Target distance and wild-animal details.','OpenRangeSettings','Configure','Ability_Hunter_SniperShot'},
            {'pet','Pet status','Your pet window and mouseover details.','OpenPetStatusSettings','Configure','Ability_Hunter_BeastCall'},
            {'abilities','Pet abilities','Learned ranks and where to find teachers.','OpenPetAbilityBrowser','Browse abilities','Ability_Hunter_Pet_Bear'},
        }
        for i,spec in ipairs(tools) do
            local key,method=spec[1],spec[4]
            local x=26+((i-1)%2)*360;local y=-140-math.floor((i-1)/2)*126
            local card=F.MenuSection(p,x,y,348,114)
            local icon=card:CreateTexture(nil,'ARTWORK');icon:SetSize(36,36);icon:SetPoint('TOPLEFT',14,-14)
            icon:SetTexture('Interface\\Icons\\'..spec[6])
            F.MenuText(card,spec[2],62,-16,270,'GameFontNormalLarge')
            local description=F.MenuText(card,spec[3],62,-42,270);description:SetHeight(28)
            local c=CreateFrame('CheckButton',nil,card,'UICheckButtonTemplate');c:SetPoint('BOTTOMLEFT',10,8);p.checks[key]=c
            local status=F.MenuText(card,'',46,-82,120);p.statusLabels[key]=status
            c:SetScript('OnClick',function()
                F.SetToolEnabled(key,c:GetChecked() and true or false);F.RefreshToolMenu()
            end)
            local b=CreateFrame('Button',nil,card,'UIPanelButtonTemplate');b:SetSize(154,27);b:SetPoint('BOTTOMRIGHT',-12,12);b:SetText(spec[5]);p.actions[key]=b
            b:SetScript('OnClick',function() if not InCombatLockdown() then F.HideConfigPages();F[method]() end end)
        end
        local aspect=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');aspect:SetSize(206,27);aspect:SetPoint('TOPLEFT',28,-531);aspect:SetText('Aspect reminders >')
        aspect:SetScript('OnClick',function() F.OpenAspectSettings() end);p.actions.aspects=aspect
        local weapons=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');weapons:SetSize(206,27);weapons:SetPoint('TOPLEFT',526,-531);weapons:SetText('Weapon comparisons >')
        weapons:SetScript('OnClick',function() F.OpenWeaponComparisonSettings() end);p.actions.weapons=weapons
        F.FinishMenu(p,760,572)
    end
    F.RefreshToolMenu()
    F.configPanel:Show()
end
function F.OpenPetStatusSettings()
    if InCombatLockdown() then F.Print('Open settings after combat.');return end
    F.HideConfigPages()
    if not F.petStatusSettingsPanel then
        local p=panel('HunterToolsPetStatusSettings','Pet status and mouseover tips',590,660);F.petStatusSettingsPanel=p
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');help:SetPoint('TOPLEFT',28,-54);help:SetWidth(530)
        help:SetText('Window and tips have independent fields. Tips show your own pet. Drag the window outside combat; right-click it for the tool menu. Unit details pause during combat.')
        p.tips=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.tips:SetPoint('TOPLEFT',25,-98)
        local tipLabel=p.tips:CreateFontString(nil,'OVERLAY','GameFontHighlight');tipLabel:SetPoint('LEFT',p.tips,'RIGHT',2,0);tipLabel:SetText('Enable mouseover pet tips')
        p.tips:SetScript('OnClick',function() F.PetStatusSettings().tooltipEnabled=p.tips:GetChecked() and true or false end)
        p.lock=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.lock:SetPoint('TOPLEFT',335,-98)
        local lockLabel=p.lock:CreateFontString(nil,'OVERLAY','GameFontHighlight');lockLabel:SetPoint('LEFT',p.lock,'RIGHT',2,0);lockLabel:SetText('Lock window position')
        p.lock:SetScript('OnClick',function() F.PetStatusSettings().locked=p.lock:GetChecked() and true or false end)
        for _,spec in ipairs({{365,'Window'},{465,'Mouseover'}}) do
            local h=p:CreateFontString(nil,'OVERLAY','GameFontNormal');h:SetPoint('TOPLEFT',spec[1],-140);h:SetText(spec[2])
        end
        p.fields={windowFields={},tooltipFields={}}
        for i,field in ipairs(F.petStatusFields) do
            local key=field[1];local y=-166-(i-1)*29
            local label=p:CreateFontString(nil,'OVERLAY','GameFontHighlight');label:SetPoint('TOPLEFT',30,y-6);label:SetText(field[2])
            for _,spec in ipairs({{'windowFields',365},{'tooltipFields',465}}) do
                local surface=spec[1];local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',spec[2],y);p.fields[surface][key]=c
                c:SetScript('OnClick',function() F.PetStatusSettings()[surface][key]=c:GetChecked() and true or false;F.UpdatePetStatusWindow() end)
            end
        end
        local reset=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');reset:SetSize(180,26);reset:SetPoint('BOTTOM',0,73);reset:SetText('Reset window position');reset:SetScript('OnClick',F.ResetPetStatusPosition)
        local alerts=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');alerts:SetSize(260,26);alerts:SetPoint('BOTTOM',0,108);alerts:SetText('Pet low-health / death warnings');alerts:SetScript('OnClick',function() F.OpenPetAlertSettings() end)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(160,26);back:SetPoint('BOTTOM',0,30);back:SetText('Back to tools');back:SetScript('OnClick',F.OpenConfig)
    end
    local p=F.petStatusSettingsPanel;local s=F.PetStatusSettings();p.tips:SetChecked(s.tooltipEnabled);p.lock:SetChecked(s.locked)
    for surface,fields in pairs(p.fields) do for key,c in pairs(fields) do c:SetChecked(s[surface][key]) end end
    if F.FinishMenu then F.FinishMenu(p,590,660) end;p:Show()
end
function F.OpenRangeSettings()
    if InCombatLockdown() then F.Print('Open settings after combat.'); return end
    F.HideConfigPages()
    if not F.rangeSettingsPanel then
        local p=panel('HunterToolsRangeSettings','Range settings',460,330); F.rangeSettingsPanel=p
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlight')
        help:SetPoint('TOPLEFT',30,-60); help:SetWidth(400)
        help:SetText('Shows your target name, portrait, ranged-attack status and estimated distance. Non-enemies are gray. Drag the range window outside combat to move it.')
        p.checks={}
        local animal=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');animal:SetSize(330,30);animal:SetPoint('TOP',0,-155);animal:SetText('Animal mouseover / target information')
        animal:SetScript('OnClick',F.OpenAnimalSettings)
        local heal=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');heal:SetPoint('TOPLEFT',25,-193);p.checks.showPetHealRange=heal
        local healLabel=heal:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');healLabel:SetPoint('LEFT',heal,'RIGHT',2,0);healLabel:SetText('Warn when pet is out of Mend Pet range')
        heal:SetScript('OnClick',function()
            if InCombatLockdown() then heal:SetChecked(F.RangeSettings().showPetHealRange);return end
            F.RangeSettings().showPetHealRange=heal:GetChecked() and true or false;F.UpdateRangeWindow()
        end)
        local reset=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); reset:SetSize(180,26); reset:SetPoint('BOTTOM',0,65); reset:SetText('Reset window position')
        reset:SetScript('OnClick',function()
            if InCombatLockdown() then return end
            local s=F.RangeSettings(); s.x=0; s.y=-230
            if F.rangeWindow then F.rangeWindow:ClearAllPoints(); F.rangeWindow:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y) end
        end)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); back:SetSize(160,26); back:SetPoint('BOTTOM',0,25); back:SetText('Back to tools'); back:SetScript('OnClick',F.OpenConfig)
    end
    for key,c in pairs(F.rangeSettingsPanel.checks) do c:SetChecked(F.RangeSettings()[key]) end
    if F.FinishMenu then F.FinishMenu(F.rangeSettingsPanel,460,330) end
    F.rangeSettingsPanel:Show()
end
function F.OpenInstanceSettings()
    if InCombatLockdown() then F.Print('Open settings after combat.'); return end
    F.InstanceSettings()
    F.HideConfigPages()
    if not F.instanceSettingsPanel then
        local p=panel('HunterToolsInstanceSettings','Instance settings',480,320); F.instanceSettingsPanel=p
        p.checks={}
        for i,spec in ipairs({{'growl','Check Growl autocast'},{'pack','Suggest an alternative to Pack'}}) do
            local b=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate')
            b:SetPoint('TOPLEFT',25,-55-(i-1)*38)
            local text=b:CreateFontString(nil,'OVERLAY','GameFontHighlight'); text:SetPoint('LEFT',b,'RIGHT',2,0); text:SetText(spec[2])
            local key=spec[1]; p.checks[key]=b
            b:SetScript('OnClick',function() F.InstanceSettings()[key]=b:GetChecked() and true or false end)
        end
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        help:SetPoint('TOPLEFT',30,-145); help:SetWidth(420)
        help:SetText('At dungeon or raid entry, offer to turn off Growl and choose another learned aspect if your Pack is on. Choices require a click and wait until combat ends. Keeping Pack dismisses that entry reminder.')
        local aspects=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');aspects:SetSize(230,26);aspects:SetPoint('BOTTOM',0,65);aspects:SetText('No-aspect reminder settings');aspects:SetScript('OnClick',function() F.OpenAspectSettings() end)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); back:SetSize(160,26); back:SetPoint('BOTTOM',0,25); back:SetText('Back to tools')
        back:SetScript('OnClick',F.OpenConfig)
    end
    for key,b in pairs(F.instanceSettingsPanel.checks) do b:SetChecked(F.InstanceSettings()[key]) end
    if F.FinishMenu then F.FinishMenu(F.instanceSettingsPanel,480,320) end
    F.instanceSettingsPanel:Show()
end

function F.OpenAnimalSettings()
    if InCombatLockdown() then F.Print('Open settings after combat.');return end
    F.HideConfigPages()
    if not F.animalSettingsPanel then
        local p=panel('HunterToolsAnimalSettings','Animal information',650,460);F.animalSettingsPanel=p
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');help:SetPoint('TOPLEFT',28,-52);help:SetWidth(594);help:SetText('Choose details independently for hovered wild animals and the targeted animal in the range window. Mouseover works even with Range disabled. Own-pet tips use Pet status settings. Changes take effect on the next hover; detailed reads pause in combat.')
        p.fields={mouseover={},target={}}
        for _,spec in ipairs({{'mouseover',390,'Mouseover'},{'target',510,'Range target'}}) do
            local surface,x=spec[1],spec[2]
            local h=p:CreateFontString(nil,'OVERLAY','GameFontNormal');h:SetPoint('TOPLEFT',x,-120);h:SetText(spec[3])
            local fields={{'enabled','Enable this view'}}
            for _,field in ipairs(F.animalFields) do fields[#fields+1]=field end
            for i,field in ipairs(fields) do
                local key=field[1];local y=-148-(i-1)*34
                if surface=='mouseover' then local label=p:CreateFontString(nil,'OVERLAY','GameFontHighlight');label:SetPoint('TOPLEFT',30,y-6);label:SetText(field[2]) end
                local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',x,y);p.fields[surface][key]=c
                c:SetScript('OnClick',function()
                    if InCombatLockdown() then c:SetChecked(F.AnimalSettings()[surface][key]);return end
                    F.AnimalSettings()[surface][key]=c:GetChecked() and true or false;F.UpdateRangeWindow()
                end)
            end
        end
        local journal=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');journal:SetSize(240,26);journal:SetPoint('BOTTOM',0,66);journal:SetText('Beast journal / data collection');journal:SetScript('OnClick',function() F.OpenBeastJournal() end)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(180,26);back:SetPoint('BOTTOM',0,28);back:SetText('Back to range settings');back:SetScript('OnClick',F.OpenRangeSettings)
    end
    local s=F.AnimalSettings();for surface,fields in pairs(F.animalSettingsPanel.fields) do for key,c in pairs(fields) do c:SetChecked(s[surface][key]) end end
    if F.FinishMenu then F.FinishMenu(F.animalSettingsPanel,650,460) end
    F.animalSettingsPanel:Show()
end
