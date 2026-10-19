local _,F=...
function F.OpenWeaponComparisonSettings()
    if InCombatLockdown() then F.Print('Open weapon comparisons after combat.');return end
    F.HideConfigPages()
    if not F.weaponSettingsPanel then
        local p=CreateFrame('Frame','HunterToolsWeaponComparisons',UIParent,'BackdropTemplate');F.weaponSettingsPanel=p
        p:SetSize(650,610);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:EnableMouse(true)
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        table.insert(UISpecialFrames,'HunterToolsWeaponComparisons')
        local function text(value,x,y,width,font) return F.MenuText(p,value,x,y,width,font) end
        text('Ranged weapon comparisons (experimental)',28,-25,580,'GameFontNormalLarge')
        local intro=text('Hover a bow, gun or crossbow to compare estimated Auto Shot damage with your equipped weapon.',28,-60,590)
        intro:SetHeight(35)
        p.enabled=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.enabled:SetPoint('TOPLEFT',24,-98)
        text('Show weapon comparisons in tooltips',60,-107,550,'GameFontHighlight')
        p.enabled:SetScript('OnClick',function(self) F.WeaponCompareSettings().enabled=self:GetChecked() and true or false end)
        text('Scope on the hovered weapon',28,-150,590,'GameFontNormal')
        text('Preview only. Your equipped weapon keeps its actual attached scope.',28,-176,590)
        p.scopeChoices={}
        local choices={{'actual','As attached on the hovered weapon'},{'none','No scope'},{'equipped','Match my equipped scope'}}
        for _,scope in ipairs(F.weaponScopes) do choices[#choices+1]={scope.id,scope.name..'  (+'..scope.damage..' damage; level '..scope.level..')',scope} end
        for i,spec in ipairs(choices) do
            local key=spec[1];local y=-204-(i-1)*31
            local b=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');b:SetPoint('TOPLEFT',24,y);b.scope=spec[3];p.scopeChoices[key]=b
            local t=b:CreateFontString(nil,'OVERLAY','GameFontHighlight');t:SetPoint('LEFT',b,'RIGHT',3,0);t:SetText(spec[2]);b.caption=t
            b:SetScript('OnClick',function()
                if InCombatLockdown() then p:Refresh();return end
                F.WeaponCompareSettings().scope=key;p:Refresh()
            end)
        end
        local scopeHelp=text('Scope choices filter by your level. Each hovered weapon is also checked against the scope\'s minimum item level. These weapon-level rules use a Classic baseline; confirm application in Forever. Scopes can be obtained from an engineer; crafting skill is not a requirement to preview them.',28,-466,590)
        scopeHelp:SetHeight(55)
        local limits=text('Stationary Auto Shot only; requires 0.5 seconds standing still. Before armor, misses and crit. Uses live buffs and weapon stat changes; does not simulate a rotation, procs, stat multipliers or weapon-specific talent changes.',28,-525,590)
        limits:SetHeight(35)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(180,27);back:SetPoint('BOTTOM',0,22);back:SetText('Back to tools');back:SetScript('OnClick',F.OpenConfig)
        function p:Refresh()
            local s=F.WeaponCompareSettings();self.enabled:SetChecked(s.enabled)
            local level=UnitLevel('player')
            if issecretvalue and issecretvalue(level) then level=nil end
            for key,b in pairs(self.scopeChoices) do
                b:SetChecked(s.scope==key)
                local allowed=not b.scope or (type(level)=='number' and level>=b.scope.level)
                b:SetEnabled(allowed);b.caption:SetTextColor(allowed and 0.9 or 0.45,allowed and 0.9 or 0.45,allowed and 0.9 or 0.45)
            end
        end
        p:RegisterEvent('PLAYER_LEVEL_UP');p:RegisterEvent('PLAYER_REGEN_ENABLED')
        p:SetScript('OnEvent',function() if p:IsShown() then p:Refresh() end end)
        F.FinishMenu(p,650,610)
    end
    F.weaponSettingsPanel:Show();F.weaponSettingsPanel:Refresh()
end
