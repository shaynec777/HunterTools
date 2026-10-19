-- Exercise the real shared theme and tabbed menus with a hierarchical client mock.
local F={Print=function() end}
local all={}
local methods={}
local function widget(kind,name,parent,template)
    local w=setmetatable({kind=kind or 'FontString',name=name,parent=parent,template=template,children={},scripts={},shown=true,text='',width=32,height=32}, {__index=function(_,k) if methods[k] then return methods[k] end;if k:match('^[A-Z]') then return function() end end end})
    if parent and parent.children then table.insert(parent.children,w) end
    all[#all+1]=w;return w
end
function methods:CreateFontString() return widget('FontString',nil,self) end
function methods:CreateTexture() return widget('Texture',nil,self) end
function methods:GetChildren() local list={};for _,c in ipairs(self.children) do if c.kind~='Texture' and c.kind~='FontString' then list[#list+1]=c end end;return unpack(list) end
function methods:GetObjectType() return self.kind end
function methods:SetTexture(texture) self.texture=texture end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.point={...} end
function methods:SetAllPoints() self.width=self.parent.width;self.height=self.parent.height end
function methods:SetScale(scale) self.scale=scale end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetEnabled(v) self.enabled=v end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:SetShown(v) self.shown=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:HasFocus() return false end
function methods:SetNormalTexture() self.normal=widget('Texture') end
function methods:GetNormalTexture() return self.normal end
function methods:SetPushedTexture() self.pushed=widget('Texture') end
function methods:GetPushedTexture() return self.pushed end
function methods:SetHighlightTexture() self.highlight=widget('Texture') end
function methods:GetHighlightTexture() return self.highlight end
function methods:SetDisabledTexture() self.disabled=widget('Texture') end
function methods:GetDisabledTexture() return self.disabled end
function methods:SetBackdropColor(...) self.bg={...} end
CreateFrame=widget;UIParent=widget('Frame');UIParent:SetSize(1280,720);UISpecialFrames={}
local combat=false;InCombatLockdown=function() return combat end
assert(loadfile('HunterTools/Core.lua'))('test',F);F.LoadSettings();F.Print=function() end;F.db.ammo={enabled=false,selected={},minimums={},minimum=100,minutes=5,mode='screen',sound=true}
assert(loadfile('HunterTools/MenuStyle.lua'))('test',F)
UnitLevel=function() return 25 end;GetTime=function() return 100 end
assert(loadfile('HunterTools/WeaponCompare.lua'))('test',F)
assert(loadfile('HunterTools/WeaponCompareUI.lua'))('test',F)
assert(loadfile('HunterTools/ConfigUI.lua'))('test',F)
assert(loadfile('HunterTools/FoodList.lua'))('test',F)
assert(loadfile('HunterTools/AmmoUI.lua'))('test',F)
F.PetBrowserSettings=function() return {enabled=true,showPictures=false} end
local range={enabled=true};F.RangeSettings=function() return range end
F.PetStatusSettings=function() return {enabled=true} end
F.Refresh=function() end;F.ResetAmmoReminder=function() end;F.UpdateRangeWindow=function() end
F.foodCatalog={[1]={name='Test fish'},[2]={name='Test meat'}}
local lists={name='Test pet',blacklist={},whitelist={}}
F.FoodLists=function() return lists end
F.UpdateFoodCatalog=function() F.bagFoodCounts={[1]=4} end
F.FoodProtectionReason=function() return nil end
F.IsPublic=function() return true end
UnitExists=function() return true end
C_Item={GetItemInfo=function(id) return id==1 and 'Test fish' or 'Test meat' end}
C_PetInfo={CanPetEatItem=function() return true end}
local function find(text) for _,w in ipairs(all) do if w.text==text then return w end end;error('Missing '..text) end
F.OpenConfig();local menu=F.configPanel
assert(menu.bg[4]==1 and menu.width==760 and menu.scale<=1)
local logo=false;for _,w in ipairs(all) do if w.texture=='Interface\\AddOns\\HunterTools\\Artwork\\HunterToolsLogo' then logo=true end end;assert(logo)
menu.actions.weapons.scripts.OnClick();assert(F.weaponSettingsPanel.shown and not menu.shown)
F.weaponSettingsPanel.scopeChoices.none.scripts.OnClick();assert(F.WeaponCompareSettings().scope=='none')
F.OpenConfig();assert(not F.weaponSettingsPanel.shown and menu.shown)
for _,key in ipairs({'food','instance','ammo','range','pet','abilities'}) do assert(menu.checks[key] and menu.actions[key].menuStyled) end
menu.actions.food.scripts.OnClick();local food=F.foodPanel
assert(not menu.shown and food.activeTab=='catalog' and food.catalogPage.shown and not food.feedingPage.shown)
assert(food.height==590 and food.bg[4]==1)
food.tabs.feeding.scripts.OnClick();assert(food.feedingPage.shown and not food.catalogPage.shown)
local wolf=find('Use default wolf sound').parent;assert(wolf.parent==food.feedingPage)
wolf:SetChecked(true);wolf.scripts.OnClick(wolf);assert(F.db.wolfSound)
food.tabs.catalog.scripts.OnClick();assert(food.catalogPage.shown and not food.feedingPage.shown)
for _,row in ipairs(food.rows) do assert(row.parent==food.catalogList and row.header.parent==food.catalogList) end
food.search:SetText('fish');food.search.scripts.OnTextChanged();assert(food.status.text:find('1 matching foods',1,true))
local selected;for _,row in ipairs(food.rows) do if row.id==1 then selected=row end end
assert(selected);selected:SetChecked(true);selected.scripts.OnClick(selected);assert(lists.blacklist[1])
food:SelectTab('feeding');F.OpenConfig();menu.actions.food.scripts.OnClick();assert(food.activeTab=='feeding','reopening retains the current tab')
assert(food.tabs.feeding.enabled and food.tabs.feeding.text:find('> Feeding & alerts',1,true),'selected feeding tab must remain usable and visibly marked')
F.ammoCatalog={[2512]={},[2515]={}}
F.ScanAmmo=function() F.ammoCounts={[2512]=20};return true end
F.AmmoInfo=function(id) return 'Ammo '..id end
F.AmmoMinimum=function(id) return F.db.ammo.minimums[id] or 100 end
F.OpenConfig();menu.actions.ammo.scripts.OnClick();local ammo=F.ammoPanel
assert(ammo.activeTab=='stock' and ammo.stockPage.shown and not ammo.alertPage.shown and ammo.height==590)
ammo.tabs.alerts.scripts.OnClick();assert(ammo.alertPage.shown and not ammo.stockPage.shown)
local enable=find('Enable ammo reminders').parent;assert(enable.parent==ammo.alertPage)
enable:SetChecked(true);enable.scripts.OnClick(enable);assert(F.db.ammo.enabled)
ammo.tabs.stock.scripts.OnClick();for _,row in ipairs(ammo.rows) do assert(row.parent==ammo.stockPage and row.minimum.parent==ammo.stockPage) end
local upgraded=false;F.OpenAmmoUpgradeSettings=function() upgraded=true end
ammo.tabs.upgrades.scripts.OnClick();assert(upgraded)
F.OpenConfig();menu.checks.range:SetChecked(false);menu.checks.range.scripts.OnClick();assert(not range.enabled and menu.statusLabels.range.text:find('Disabled',1,true))
-- Fit to small displays and preserve the close button's native artwork.
UIParent:SetSize(800,600);F.FinishMenu(menu,760,668);assert(menu.scale<=1 and menu.scale>0)
for _,child in ipairs({menu:GetChildren()}) do if child.template=='UIPanelCloseButton' then assert(not child.menuStyled) end end
combat=true;menu:Hide();F.OpenConfig();assert(not menu.shown)
print('PASS: shared theme, six tool cards, navigation, opaque panels, food/ammo tabs, search/list edits, saved controls, small-screen scale and combat guard')
return {F=F,widgets=all}
