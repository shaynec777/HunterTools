local F={db={enabled=true,ammo={enabled=false}},Print=function() end}
assert(loadfile('HunterTools/ConfigUI.lua'))('test',F)
local frames={}
local function widget()
    local w={scripts={}}
    setmetatable(w,{__index=function(_,key)
        if key=='CreateFontString' or key=='CreateTexture' then return widget end
        return function() end
    end})
    function w:SetScript(event,fn) self.scripts[event]=fn end
    function w:SetText(text) self.text=text end
    function w:SetChecked(value) self.checked=value end
    function w:GetChecked() return self.checked end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    table.insert(frames,w); return w
end
CreateFrame=widget; UIParent={}; UISpecialFrames={}
InCombatLockdown=function() return false end
F.OpenFoodList=function() F.foodOpened=true end
F.OpenAmmoSettings=function() F.ammoOpened=true end
local function find(text) for _,w in ipairs(frames) do if w.text==text then return w end end; error(text) end
F.RangeSettings=function() return {enabled=true} end
local petSettings={enabled=false,tooltipEnabled=true,locked=false,windowFields={health=true},tooltipFields={health=true}}
F.PetStatusSettings=function() return petSettings end
local browserSettings={enabled=true}
F.PetBrowserSettings=function() return browserSettings end
F.OpenPetAbilityBrowser=function() F.browserOpened=true end
F.petStatusFields={{'health','Health'}}
F.UpdatePetStatusWindow=function() F.petUpdated=true end
F.ResetPetStatusPosition=function() F.petReset=true end
F.MenuText=function(parent,text) local t=widget();t:SetText(text);return t end
F.MenuSection=function() return widget() end
F.FinishMenu=function() end
F.OpenConfig(); assert(F.configPanel.shown)
local settings={};for i,key in ipairs({'food','instance','ammo','range','pet','abilities'}) do settings[i]=F.configPanel.actions[key];assert(settings[i]) end; settings[1].scripts.OnClick(); assert(F.foodOpened and not F.configPanel.shown)
F.OpenConfig();settings[6].scripts.OnClick();assert(F.browserOpened)
F.SetToolEnabled('abilities',false);assert(not browserSettings.enabled)
F.OpenConfig(); settings[3].scripts.OnClick(); assert(F.ammoOpened)
F.OpenConfig(); settings[2].scripts.OnClick()
assert(F.instanceSettingsPanel.shown and not F.configPanel.shown)
local checks=F.instanceSettingsPanel.checks
assert(checks.growl.checked and checks.pack.checked,'old settings initialize both checks')
checks.growl.checked=false; checks.growl.scripts.OnClick()
F.OpenConfig(); settings[2].scripts.OnClick()
assert(not checks.growl.checked and checks.pack.checked,'reopening preserves choices')
F.db.instanceChecks=nil; settings[2].scripts.OnClick()
assert(checks.growl.checked and checks.pack.checked,'repair missing settings on reopen')
F.db.instanceChecks='bad'; settings[2].scripts.OnClick()
assert(checks.growl.checked and checks.pack.checked,'repair malformed settings')
checks.pack.checked=true; checks.pack.scripts.OnClick(); assert(F.db.instanceChecks.pack)
find('Back to tools').scripts.OnClick(); assert(F.configPanel.shown and not F.instanceSettingsPanel.shown)
settings[5].scripts.OnClick();assert(F.petStatusSettingsPanel.shown and not F.configPanel.shown)
local p=F.petStatusSettingsPanel
p.fields.windowFields.health.checked=false;p.fields.windowFields.health.scripts.OnClick()
assert(not petSettings.windowFields.health and petSettings.tooltipFields.health and F.petUpdated)
p.tips.checked=false;p.tips.scripts.OnClick();assert(not petSettings.tooltipEnabled)
F.SetToolEnabled('pet',true);assert(petSettings.enabled and F.ToolEnabled('pet'))
F.HideConfigPages();assert(not p.shown)
F.configPanel:Hide(); InCombatLockdown=function() return true end
F.OpenConfig(); assert(not F.configPanel.shown)
print('PASS: six-tool card navigation, independent pet window/tooltip checkboxes, instance toggles and combat guard')

InCombatLockdown=function() return false end
F.OpenConfig()
local mobOpened,playerOpened
F.OpenMobFinder=function() mobOpened=true end
F.OpenPlayerFinder=function() playerOpened=true end
F.configPanel.actions.mobfinder.scripts.OnClick();assert(mobOpened and not F.configPanel.shown)
F.OpenConfig();F.configPanel.actions.playerfinder.scripts.OnClick();assert(playerOpened and not F.configPanel.shown)
mobOpened=false;InCombatLockdown=function() return true end
F.configPanel.actions.mobfinder.scripts.OnClick();assert(not mobOpened)
print('PASS: separate main-menu Finders section, mob/player navigation and combat guard')
