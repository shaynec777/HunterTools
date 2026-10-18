local _, F = ...

function F.OpenAmmoSettings()
    if InCombatLockdown() then F.Print('Open ammo settings after combat.'); return end
    if F.HideConfigPages then F.HideConfigPages() end
    if F.ammoPanel then F.ammoPanel:Show(); F.ammoPanel:Refresh(); return end
    local p=CreateFrame('Frame','HunterToolsAmmoSettings',UIParent,'BackdropTemplate')
    F.ammoPanel=p; p.page=1
    p:SetSize(660,590); p:SetPoint('CENTER'); p:SetFrameStrata('DIALOG')
    p:SetMovable(true); p:EnableMouse(true); p:RegisterForDrag('LeftButton')
    p:SetScript('OnDragStart',function(self) if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end end); p:SetScript('OnDragStop',p.StopMovingOrSizing)
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
    p.stockPage=CreateFrame('Frame',nil,p);p.stockPage:SetSize(660,590);p.stockPage:SetPoint('TOPLEFT',0,100)
    p.alertPage=CreateFrame('Frame',nil,p);p.alertPage:SetSize(660,590);p.alertPage:SetPoint('TOPLEFT',0,-50)
    p.tabs={}
    function p:SelectTab(key)
        self.activeTab=key;self.stockPage:SetShown(key=='stock');self.alertPage:SetShown(key=='alerts')
        for name,tab in pairs(self.tabs) do
            tab:SetText((name==key and '|cffffd16a> ' or '')..tab.caption..(name==key and '|r' or ''))
            tab:SetEnabled(true)
        end
    end
    for i,spec in ipairs({{'stock','Tracked ammo'},{'alerts','Alert settings'},{'upgrades','Upgrade advice >'}}) do
        local key=spec[1];local tab=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');tab:SetSize(194,30);tab:SetPoint('TOPLEFT',25+(i-1)*208,-58)
        tab.caption=spec[2];p.tabs[key]=tab
        tab:SetScript('OnClick',function() if key=='upgrades' then F.OpenAmmoUpgradeSettings() else p:SelectTab(key) end end)
    end
    p:SelectTab('stock')
    local content=p
    local function label(text,x,y,width,style)
        local t=content:CreateFontString(nil,'OVERLAY',style or 'GameFontHighlightSmall')
        t:SetPoint('TOPLEFT',x,-y); t:SetWidth(width); t:SetJustifyH('LEFT'); t:SetText(text)
        return t
    end
    local function button(text,x,y,w,click)
        local b=CreateFrame('Button',nil,content,'UIPanelButtonTemplate')
        b:SetSize(w,24); b:SetPoint('TOPLEFT',x,-y); b:SetText(text); b:SetScript('OnClick',function()
            for _,r in ipairs(p.rows or {}) do if r.minimum:HasFocus() then r.minimum:ClearFocus() end end
            click()
        end)
        return b
    end
    local function check(text,x,y,key)
        local b=CreateFrame('CheckButton',nil,content,'UICheckButtonTemplate'); b:SetSize(26,26); b:SetPoint('TOPLEFT',x,-y)
        local t=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); t:SetPoint('LEFT',b,'RIGHT',3,0); t:SetText(text)
        b:SetChecked(F.db.ammo[key]); b:SetScript('OnClick',function(self)
            F.db.ammo[key]=self:GetChecked()==true; F.ResetAmmoReminder(); p:Refresh()
        end)
        return b
    end
    label('Ammunition',25,22,590,'GameFontNormalLarge')
    content=p.alertPage
    check('Enable ammo reminders',25,53,'enabled')
    check('Play warning sound (Master)',310,53,'sound')
    label('Default minimum:',25,96,130)
    label('Repeat (minutes):',310,96,135)
    local function numeric(x,key,max,integer)
        local e=CreateFrame('EditBox',nil,p.alertPage,'InputBoxTemplate'); e:SetSize(75,24); e:SetPoint('TOPLEFT',x,-89); e:SetAutoFocus(false)
        e:SetText(tostring(F.db.ammo[key])); e:SetMaxLetters(8)
        local function save(self)
            local n=tonumber(self:GetText())
            if not n or n~=n or n<0 or n>max then
                F.Print('Enter a number from 0 to '..max..'.'); self:SetText(tostring(F.db.ammo[key])); return
            end
            if integer then n=math.floor(n) end
            if F.db.ammo[key]~=n then F.db.ammo[key]=n; F.ResetAmmoReminder() end
            self:SetText(tostring(n))
        end
        e:SetScript('OnEnterPressed',function(self) save(self); self:ClearFocus(); p:Refresh() end)
        e:SetScript('OnEditFocusLost',save)
        e:SetScript('OnEscapePressed',function(self) self:SetText(tostring(F.db.ammo[key])); self:ClearFocus() end)
        return e
    end
    numeric(167,'minimum',99999,true); numeric(455,'minutes',120,false)
    label('Alert below minimum; zero always alerts. Enter saves. 0 minutes = once until restocked.\nA further alert fires if you run out. Reminders wait until combat ends.',25,122,605)
    local modes={'screen','chat','both','off'}
    local modeNames={screen='On-screen',chat='Chat',both='Chat + on-screen',off='No text (sound only)'}
    local mode=button('',25,159,285,function()
        for i,value in ipairs(modes) do
            if value==F.db.ammo.mode then F.db.ammo.mode=modes[i%#modes+1]; break end
        end
        F.ResetAmmoReminder(); p:Refresh()
    end)
    button('Test reminder',450,159,180,function()
        F.ScanAmmo(); local id=next(F.db.ammo.selected); F.ShowAmmoReminder(id,id and (F.ammoCounts or {})[id] or 0,true)
    end)
    content=p.stockPage
    button('Monitor equipped ammo',25,198,285,function()
        local id=F.AmmoTarget(); if id then F.db.ammo.selected[id]=true; F.db.ammo.minimums[id]=F.AmmoMinimum(id); F.ResetAmmoReminder(id) end; p:Refresh()
    end)
    button('Clear monitored ammo',450,198,180,function() F.db.ammo.selected={}; F.ResetAmmoReminder(); p:Refresh() end)
    local target=label('',25,233,605,'GameFontNormal')
    label('Check each ammo type to monitor; uncheck to stop. Set its minimum on the right.\nEnter saves. Counts include carried bags and quivers/pouches, not banks.',25,274,605)
    local search=CreateFrame('EditBox',nil,p.stockPage,'InputBoxTemplate'); search:SetSize(350,24); search:SetPoint('TOPLEFT',30,-313); search:SetAutoFocus(false)
    search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    label('Carried',440,329,65); label('Minimum',550,329,80)
    p.rows={}
    for i=1,10 do
        local r=CreateFrame('CheckButton',nil,p.stockPage,'UICheckButtonTemplate'); r:SetSize(25,25); r:SetPoint('TOPLEFT',25,-349-(i-1)*26)
        r.icon=r:CreateTexture(nil,'ARTWORK'); r.icon:SetSize(22,22); r.icon:SetPoint('LEFT',r,'RIGHT',5,0)
        r.text=r:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); r.text:SetPoint('LEFT',r.icon,'RIGHT',7,0); r.text:SetWidth(330); r.text:SetJustifyH('LEFT')
        r.count=r:CreateFontString(nil,'OVERLAY','GameFontNormalSmall'); r.count:SetPoint('LEFT',r,'RIGHT',370,0); r.count:SetWidth(65); r.count:SetJustifyH('RIGHT')
        r.minimum=CreateFrame('EditBox',nil,p.stockPage,'InputBoxTemplate'); r.minimum:SetSize(70,23)
        r.minimum:SetPoint('TOPLEFT',550,-349-(i-1)*26); r.minimum:SetAutoFocus(false); r.minimum:SetMaxLetters(5)
        local function saveMinimum(self)
            if not self.id then return end
            local n=tonumber(self:GetText())
            if not n or n~=n or n<0 or n>99999 then F.Print('Enter a minimum from 0 to 99999.'); self:SetText(tostring(F.AmmoMinimum(self.id))); return end
            n=math.floor(n)
            if n~=F.AmmoMinimum(self.id) then F.ResetAmmoReminder(self.id) end
            F.db.ammo.minimums[self.id]=n
            self:SetText(tostring(n))
        end
        r.minimum:SetScript('OnEditFocusLost',saveMinimum)
        r.minimum:SetScript('OnEnterPressed',function(self) saveMinimum(self); self:ClearFocus() end)
        r.minimum:SetScript('OnEscapePressed',function(self) self:SetText(tostring(F.AmmoMinimum(self.id))); self:ClearFocus() end)
        r:SetScript('OnClick',function(self)
            if self.id then
                F.db.ammo.selected[self.id]=self:GetChecked() and true or nil
                F.db.ammo.minimums[self.id]=F.AmmoMinimum(self.id)
                F.ResetAmmoReminder(self.id); p:Refresh()
            end
        end)
        r:SetScript('OnEnter',function(self)
            if self.id and not InCombatLockdown() then GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetHyperlink('item:'..self.id); GameTooltip:Show() end
        end)
        r:SetScript('OnLeave',function() GameTooltip:Hide() end)
        p.rows[i]=r
    end
    local status=label('',25,617,605)
    content=p
    button('Back to tools',25,544,175,function() p:Hide(); F.OpenConfig() end)
    content=p.stockPage
    button('Previous',340,644,110,function() p.page=p.page-1; p:Refresh() end)
    button('Next',465,644,110,function() p.page=p.page+1; p:Refresh() end)
    function p:Refresh()
        if InCombatLockdown() then target:SetText('Updates resume after combat.'); return end
        for _,r in ipairs(self.rows) do if r.minimum:HasFocus() then return end end
        local ok=F.ScanAmmo()
        local counts=F.ammoCounts or {}
        local upgradeContext=F.AmmoUpgradeContext and F.AmmoUpgradeContext(ok)
        local bestUpgrade
        if upgradeContext then local _;_,bestUpgrade=F.AmmoUpgradeBest(upgradeContext) end
        mode:SetText('Reminder: '..modeNames[F.db.ammo.mode])
        local watched=0; for _,v in pairs(F.db.ammo.selected) do if v then watched=watched+1 end end
        target:SetText(watched..' ammo types checked'..(watched==0 and ' - no ammo monitored.' or '.')
            ..(not F.db.ammo.enabled and '\nReminders disabled.' or ''))
        local list={}; local query=(search:GetText() or ''):lower()
        for itemID,entry in pairs(F.ammoCatalog) do
            local name,icon=F.AmmoInfo(itemID)
            local text=name..' ['..itemID..']'
            if text:lower():find(query,1,true) then table.insert(list,{id=itemID,text=text,icon=icon,count=counts[itemID] or 0}) end
        end
        table.sort(list,function(a,b)
            if (a.count>0)~=(b.count>0) then return a.count>0 end
            return a.text<b.text
        end)
        local pages=math.max(1,math.ceil(#list/#self.rows)); self.page=math.max(1,math.min(pages,self.page))
        for i,r in ipairs(self.rows) do
            local e=list[(self.page-1)*#self.rows+i]; r.id=e and e.id; r:SetShown(e~=nil); r.minimum:SetShown(e~=nil); r.minimum.id=e and e.id
            if e then
                r.minimum:SetText(tostring(F.AmmoMinimum(e.id))); r:SetChecked(F.db.ammo.selected[e.id]==true); r.text:SetText(e.text..(F.AmmoIsObsolete and F.AmmoIsObsolete(e.id,upgradeContext,bestUpgrade) and ' |cffff3333[Obsolete]|r' or ''))
                r.icon:SetTexture(e.icon or 'Interface\\Icons\\INV_Misc_QuestionMark'); r.count:SetText(ok and tostring(e.count) or '?')
            end
        end
        status:SetText(#list..' ammo types | Page '..self.page..'/'..pages..' | In bags first; includes legacy records.')
    end
    search:SetScript('OnTextChanged',function() p.page=1; p:Refresh() end)
    for _,event in ipairs({'BAG_UPDATE_DELAYED','PLAYER_EQUIPMENT_CHANGED','PLAYER_REGEN_ENABLED','GET_ITEM_INFO_RECEIVED','PLAYER_LEVEL_UP','SKILL_LINES_CHANGED','PLAYER_ENTERING_WORLD'}) do p:RegisterEvent(event) end
    p:SetScript('OnEvent',function() if p:IsShown() then p:Refresh() end end)
    local elapsed=0;p:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=2 then elapsed=0;if F.AmmoUpgradeSettings and F.AmmoUpgradeSettings().enabled then p:Refresh() end end end)
    table.insert(UISpecialFrames,'HunterToolsAmmoSettings')
    if F.FinishMenu then F.FinishMenu(p,660,590) end
    p:Refresh()
end
