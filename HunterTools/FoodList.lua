local _, F = ...
function F.CatalogMatches(id, count, filters, cached)
    if filters.inBags and count <= 0 then return false end
    if filters.blocked and not F.FoodLists().blacklist[id] and not ((F.FoodProtectionReason and F.FoodProtectionReason(id)) or (F.QuestFoodReason and F.QuestFoodReason(id))) then return false end
    if filters.edible then
        if InCombatLockdown() or not UnitExists('pet') or not cached then return false end
        local edible=C_PetInfo.CanPetEatItem(id)
        if not F.IsPublic(edible) or edible ~= true then return false end
    end
    return true
end

function F.CatalogEdibility(id, cached)
    if InCombatLockdown() then return 'Unknown',0.6,0.6,0.6 end
    if not UnitExists('pet') then return 'No pet',0.6,0.6,0.6 end
    if not cached then return 'Loading',0.6,0.6,0.6 end
    local canEat=C_PetInfo.CanPetEatItem(id)
    if not F.IsPublic(canEat) or canEat==nil then return 'Unknown',0.6,0.6,0.6 end
    if canEat then return 'Can eat',0.3,1,0.3 end
    return 'Cannot eat',0.75,0.75,0.75
end

function F.UpdateFoodCatalog()
    if InCombatLockdown() then return end
    if F.ScanQuestFood then F.ScanQuestFood() end
    F.bagFoodCounts = {}
    for _,list in ipairs({F.FoodLists().blacklist,F.FoodLists().whitelist,F.db.discoveredFoods or {}}) do
        for id in pairs(list) do
            if not F.foodCatalog[id] then
                F.foodCatalog[id]={name=C_Item.GetItemInfo(id) or ('Item '..id)}
            end
        end
    end
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        for slot=1,C_Container.GetContainerNumSlots(bag) do
            local item=C_Container.GetContainerItemInfo(bag,slot)
            if item and F.IsPublic(item.itemID) and item.itemID and F.IsPublic(item.stackCount) then
                F.bagFoodCounts[item.itemID]=(F.bagFoodCounts[item.itemID] or 0)+(item.stackCount or 0)
            end
            if item and F.IsPublic(item.itemID) and item.itemID and C_PetInfo.CanPetEatItem(item.itemID) then
                local name=C_Item.GetItemInfo(item.itemID)
                if name then
                    F.foodCatalog[item.itemID]={name=name}
                    F.db.discoveredFoods=F.db.discoveredFoods or {}
                    F.db.discoveredFoods[item.itemID]=true
                end
            end
        end
    end
end
function F.OpenFoodList()
    if InCombatLockdown() then F.Print('Open the food list after combat.'); return end
    if F.HideConfigPages then F.HideConfigPages() end
    F.UpdateFoodCatalog()
    if F.foodPanel then F.foodPanel.page=1; F.foodPanel:Show(); F.foodPanel:Refresh(); return end
    local p=CreateFrame('Frame','GFWForeverFoodList',UIParent,'BackdropTemplate')
    F.foodPanel=p
    p:SetSize(680,590); p:SetPoint('CENTER'); p:SetFrameStrata('DIALOG')
    p:SetMovable(true); p:EnableMouse(true); p:RegisterForDrag('LeftButton')
    p:SetScript('OnDragStart',function(self) if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end end); p:SetScript('OnDragStop',p.StopMovingOrSizing)
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    local title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    title:SetPoint('TOP',0,-18); title:SetText('HunterTools food list')
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
    -- Keep the searchable catalog separate from feeding preferences.
    p.catalogPage=CreateFrame('Frame',nil,p);p.catalogPage:SetAllPoints(p)
    p.feedingPage=CreateFrame('Frame',nil,p);p.feedingPage:SetAllPoints(p)
    p.catalogList=CreateFrame('Frame',nil,p.catalogPage);p.catalogList:SetSize(680,590);p.catalogList:SetPoint('TOPLEFT',0,252)
    p.tabs={}
    function p:SelectTab(key)
        self.activeTab=key;self.catalogPage:SetShown(key=='catalog');self.feedingPage:SetShown(key=='feeding')
        for name,tab in pairs(self.tabs) do
            tab:SetText((name==key and '|cffffd16a> ' or '')..tab.caption..(name==key and '|r' or ''))
            tab:SetEnabled(true)
        end
    end
    for i,spec in ipairs({{'catalog','Food catalog'},{'feeding','Feeding & alerts'}}) do
        local key=spec[1];local tab=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
        tab:SetSize(304,30);tab:SetPoint('TOPLEFT',25+(i-1)*326,-58);tab.caption=spec[2];p.tabs[key]=tab
        tab:SetScript('OnClick',function() p:SelectTab(key) end)
    end
    p:SelectTab('catalog')
    p.editList='blacklist'
    local editMode=CreateFrame('Button',nil,p.catalogPage,'UIPanelButtonTemplate')
    editMode:SetSize(280,25); editMode:SetPoint('TOPLEFT',25,-140)
    editMode:SetScript('OnClick',function()
        p.editList=p.editList=='blacklist' and 'whitelist' or 'blacklist'; p:Refresh()
    end)
    local ammo=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
    ammo:SetSize(140,24); ammo:SetPoint('BOTTOMLEFT',25,16); ammo:SetText('Back to tools')
    ammo:SetScript('OnClick',function() p:Hide(); F.OpenConfig() end)
    local manage=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
    manage:SetSize(130,24); manage:SetPoint('BOTTOMRIGHT',-25,16)
    manage:SetText('Saved pet lists'); manage:SetScript('OnClick',function() F.OpenPetLists() end)
    local search=CreateFrame('EditBox',nil,p.catalogPage,'InputBoxTemplate'); p.search=search
    search:SetSize(440,25); search:SetPoint('TOPLEFT',30,-102); search:SetAutoFocus(false)
    local protection=CreateFrame('Button',nil,p.catalogPage,'UIPanelButtonTemplate')
    protection:SetSize(145,25); protection:SetPoint('TOPLEFT',495,-102); protection:SetText('Food protection')
    protection:SetScript('OnClick',function() F.OpenFoodProtection() end)
    search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    local help=p.catalogPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    help:SetPoint('TOPLEFT',25,-174); help:SetText('Search foods, then check the boxes to edit the selected list. Changes save immediately.')
    local order=CreateFrame('Button',nil,p.feedingPage,'UIPanelButtonTemplate')
    order:SetSize(280,25); order:SetPoint('TOPLEFT',25,-110)
    order:SetScript('OnClick',function()
        F.db.foodOrder=F.db.foodOrder=='low' and 'high' or 'low'
        F.bagsDirty=true; F.Refresh(true); p:Refresh()
    end)
    local explanation=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    explanation:SetPoint('TOPLEFT',25,-145); explanation:SetWidth(630)
    explanation:SetJustifyH('LEFT')
    explanation:SetText('Chooses unlocked food in your bags that your pet can eat. Blacklist wins; a nonempty whitelist limits choices. Ranks by item level (not vendor price or measured happiness), then uses the smaller stack on ties. Low to high saves higher-level food. Changes affect the next feeding.')
    local checkParent=p.feedingPage
    local function checkbox(label,x,y,checked,change)
        local c=CreateFrame('CheckButton',nil,checkParent,'UICheckButtonTemplate')
        c:SetPoint('TOPLEFT',x,y); c:SetChecked(checked)
        local text=c:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        text:SetPoint('LEFT',c,'RIGHT',2,0); text:SetText(label)
        c:SetScript('OnClick',function(self) change(self:GetChecked() and true or false) end)
        return c
    end
    checkbox('Use default wolf sound',22,-205,F.db.wolfSound,function(value) F.db.wolfSound=value end)
    checkbox('Mute hunger sounds',250,-205,F.db.mute,function(value) F.db.mute=value end)
    local testSound=CreateFrame('Button',nil,p.feedingPage,'UIPanelButtonTemplate')
    testSound:SetSize(100,24); testSound:SetPoint('TOPLEFT',530,-209); testSound:SetText('Test sound')
    testSound:SetScript('OnClick',function() F.PlayHungerSound(true) end)
    local soundHelp=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    soundHelp:SetPoint('TOPLEFT',25,-241)
    soundHelp:SetText('Unchecked: pet-family sound, with wolf fallback. Mute overrides both. Uses Master volume.')
    local reminderMode=CreateFrame('Button',nil,p.feedingPage,'UIPanelButtonTemplate')
    reminderMode:SetSize(280,25); reminderMode:SetPoint('TOPLEFT',25,-265)
    local modes={'off','chat','screen','both'}
    local modeLabels={off='Off',chat='Chat',screen='On-screen',both='Both'}
    local function updateReminderLabel()
        reminderMode:SetText('Text reminders: '..modeLabels[F.db.textReminder])
    end
    updateReminderLabel()
    reminderMode:SetScript('OnClick',function()
        for i,mode in ipairs(modes) do
            if F.db.textReminder==mode then F.db.textReminder=modes[i % #modes + 1]; break end
        end
        updateReminderLabel()
    end)
    local testReminder=CreateFrame('Button',nil,p.feedingPage,'UIPanelButtonTemplate')
    testReminder:SetSize(125,25); testReminder:SetPoint('TOPLEFT',505,-265)
    testReminder:SetText('Test reminder')
    testReminder:SetScript('OnClick',function() F.ShowTextReminder(true) end)
    local repeatLabel=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    repeatLabel:SetPoint('TOPLEFT',25,-308); repeatLabel:SetText('Repeat every (minutes):')
    local minutes=CreateFrame('EditBox',nil,p.feedingPage,'InputBoxTemplate')
    minutes:SetSize(55,25); minutes:SetPoint('TOPLEFT',190,-300); minutes:SetAutoFocus(false)
    minutes:SetMaxLetters(6); minutes:SetText(tostring(F.db.reminderMinutes))
    local function saveInterval(self)
        local value=tonumber(self:GetText())
        if value and value==value and value>=0 and value<=120 then
            F.db.reminderMinutes=value
        else
            F.Print('Reminder time must be 0 to 120 minutes. 0 means once per hunger episode.')
        end
        self:SetText(tostring(F.db.reminderMinutes)); self:ClearFocus()
    end
    minutes:SetScript('OnEnterPressed',saveInterval)
    minutes:SetScript('OnEditFocusLost',function(self)
        if self:GetText()~=tostring(F.db.reminderMinutes) then saveInterval(self) end
    end)
    minutes:SetScript('OnEscapePressed',function(self)
        self:SetText(tostring(F.db.reminderMinutes)); self:ClearFocus()
    end)
    local repeatHelp=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    repeatHelp:SetPoint('TOPLEFT',260,-308); repeatHelp:SetText('0 = once. Range: 0-120. Press Enter to save.')
    local reminderHelp=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    reminderHelp:SetPoint('TOPLEFT',25,-334)
    reminderHelp:SetText('Private reminders only. First alert when hungry; repeats pause during combat or feeding.')
    checkbox('Food count on button',22,-353,F.db.showFoodCount,function(value)
        F.db.showFoodCount=value; F.Refresh()
    end)
    checkbox('Low-food warning (chat)',250,-353,F.db.lowFoodWarning,function(value)
        F.db.lowFoodWarning=value; F.lowFoodAlerted=nil; F.Refresh()
    end)
    local supplyLabel=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    supplyLabel:SetPoint('TOPLEFT',25,-395); supplyLabel:SetText('Warn at or below:')
    local threshold=CreateFrame('EditBox',nil,p.feedingPage,'InputBoxTemplate')
    threshold:SetSize(45,25); threshold:SetPoint('TOPLEFT',135,-387)
    threshold:SetAutoFocus(false); threshold:SetMaxLetters(3)
    threshold:SetText(tostring(F.db.lowFoodThreshold))
    local function saveThreshold(self)
        local value=tonumber(self:GetText())
        if value and value==math.floor(value) and value>=0 and value<=999 then
            F.db.lowFoodThreshold=value; F.Refresh()
        else F.Print('Low-food threshold must be a whole number from 0 to 999.') end
        self:SetText(tostring(F.db.lowFoodThreshold)); self:ClearFocus()
    end
    threshold:SetScript('OnEnterPressed',saveThreshold)
    threshold:SetScript('OnEditFocusLost',function(self)
        if self:GetText()~=tostring(F.db.lowFoodThreshold) then saveThreshold(self) end
    end)
    threshold:SetScript('OnEscapePressed',function(self)
        self:SetText(tostring(F.db.lowFoodThreshold)); self:ClearFocus()
    end)
    local supplyHelp=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    supplyHelp:SetPoint('TOPLEFT',195,-395)
    supplyHelp:SetText('Allowed food items. Warn once; restocking resets. + = incomplete count.')
    checkbox('Protect food for active quests',22,-410,F.db.protectQuestFood,function(value)
        F.db.protectQuestFood=value
        F.bagsDirty=true; F.Refresh(true); F.UpdateFoodCatalog(); p:Refresh()
    end)
    local questHelp=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    questHelp:SetPoint('TOPLEFT',310,-421)
    questHelp:SetText('All stacks, until turn-in or abandonment.')
    local alertStatus=p.feedingPage:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    alertStatus:SetPoint('TOPLEFT',25,-465);alertStatus:SetWidth(630);alertStatus:SetJustifyH('LEFT')
    local elapsed=0
    p.feedingPage:SetScript('OnUpdate',function(_,delta)
        elapsed=elapsed+delta
        if elapsed>=0.5 then elapsed=0;if F.HungerAlertStatus then alertStatus:SetText(F.HungerAlertStatus()) end end
    end)
    checkParent=p.catalogList
    p.filters={}
    for _,spec in ipairs({{'In bags','inBags',22},{'Edible by current pet','edible',175},{'Blocked','blocked',415}}) do
        local key=spec[2]
        checkbox(spec[1],spec[3],-442,false,function(value)
            p.filters[key]=value; p.page=1; p:Refresh()
        end)
    end
    local blockHelp=p.catalogList:CreateFontString(nil,'OVERLAY','GameFontNormal')
    blockHelp:SetPoint('TOPLEFT',25,-479)
    p.blockHelp=blockHelp
    p.rows={}; p.page=1
    for i=1,9 do
        local row=CreateFrame('CheckButton',nil,p.catalogList,'UICheckButtonTemplate')
        row:SetPoint('TOPLEFT',22,-501-(i-1)*25)
        row.text=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        row.icon=row:CreateTexture(nil,'ARTWORK')
        row.icon:SetSize(22,22); row.icon:SetPoint('LEFT',row,'RIGHT',3,0)
        row.text:SetPoint('LEFT',row.icon,'RIGHT',6,0)
        row.text:SetWidth(440); row.text:SetJustifyH('LEFT')
        row.diet=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        row.diet:SetPoint('LEFT',row.text,'RIGHT',8,0)
        row:SetScript('OnEnter',function(self)
            if not self.id then return end
            GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
            GameTooltip:SetHyperlink('item:'..self.id)
            local quest=F.FoodProtectionReason(self.id)
            if quest then
                GameTooltip:AddLine('Protected for quest: '..quest,1,0.8,0.2,true)
                GameTooltip:AddLine('Automatic protection is separate from manual checkboxes.',1,1,1,true)
            end
            GameTooltip:Show()
        end)
        row:SetScript('OnLeave',function() GameTooltip:Hide() end)
        row.header=p.catalogList:CreateFontString(nil,'OVERLAY','GameFontNormal')
        row.header:SetPoint('TOPLEFT',25,-506-(i-1)*25)
        row:SetScript('OnClick',function(self)
            if not self.id then return end
            F.FoodLists(true)[p.editList][self.id]=self:GetChecked() and true or nil
            F.bagsDirty=true; F.Refresh(true); p:Refresh()
        end)
        p.rows[i]=row
    end
    local status=p.catalogPage:CreateFontString(nil,'OVERLAY','GameFontNormalSmall'); p.status=status
    status:SetPoint('BOTTOM',0,80)
    for _,spec in ipairs({{'Previous',-1,-100},{'Next',1,100}}) do
        local b=CreateFrame('Button',nil,p.catalogPage,'UIPanelButtonTemplate')
        b:SetSize(85,24); b:SetPoint('BOTTOM',spec[3],48); b:SetText(spec[1])
        local step=spec[2]
        b:SetScript('OnClick',function() p.page=p.page+step; p:Refresh() end)
    end
    function p:Refresh()
        local lists=F.FoodLists()
        title:SetText('Food lists: '..(lists.name or 'Default (no pet)'))
        editMode:SetText(self.editList=='blacklist' and 'Editing: blocked foods' or 'Editing: allowed foods')
        self.blockHelp:SetText(self.editList=='blacklist' and 'CHECK TO BLOCK a food. Uncheck to remove its block.' or 'CHECK TO ALLOW. An empty allowed list permits all foods; blocks always win.')
        order:SetText('Food item level: '..(F.db.foodOrder=='low' and 'Low to high' or 'High to low'))
        local carried,other={},{}; local query=(search:GetText() or ''):lower()
        for id,entry in pairs(F.foodCatalog) do
            local cached=C_Item.GetItemInfo(id)
            local name=cached or entry.name
            local label=name..' ['..id..']'
            local count=(F.bagFoodCounts or {})[id] or 0
            if label:lower():find(query,1,true) and F.CatalogMatches(id,count,self.filters,cached) then
                table.insert(count>0 and carried or other,{id=id,label=label,count=count})
            end
        end
        local function byName(a,b) return a.label<b.label end
        table.sort(carried,byName); table.sort(other,byName)
        local list={{header='In bags ('..#carried..' matching types)'}}
        for _,e in ipairs(carried) do table.insert(list,e) end
        table.insert(list,{header='Other catalog foods ('..#other..')'})
        for _,e in ipairs(other) do table.insert(list,e) end
        local pages=math.max(1,math.ceil(#list/#self.rows)); self.page=math.max(1,math.min(pages,self.page))
        for i,row in ipairs(self.rows) do
            local e=list[(self.page-1)*#self.rows+i]
            row.id=nil
            row:SetShown(e~=nil and not e.header)
            row.header:SetShown(e~=nil and e.header~=nil)
            if e and e.header then row.header:SetText(e.header) end
            if e and not e.header then
                local cached,_,_,_,_,_,_,_,_,icon=C_Item.GetItemInfo(e.id)
                row.icon:SetTexture(icon or 'Interface\\Icons\\INV_Misc_QuestionMark')
                local diet,r,g,b=F.CatalogEdibility(e.id,cached)
                if F.FoodProtectionReason(e.id) then diet,r,g,b=F.FoodProtectionReason(e.id)..' protected',1,0.8,0.2 end
                row.diet:SetText(diet); row.diet:SetTextColor(r,g,b)
                row.id=e.id; row:SetChecked(lists[self.editList][e.id]==true)
                local restricted=next(F.FoodLists().whitelist) and not F.FoodLists().whitelist[e.id]
                row.text:SetText(e.label..(e.count>0 and (' x'..e.count) or '')..(restricted and ' (outside whitelist)' or ''))
            end
        end
        local note=self.filters.edible and (InCombatLockdown() and ' | Edibility unavailable in combat' or
            (not UnitExists('pet') and ' | Summon a pet to filter by diet' or '')) or ''
        status:SetText(('%d matching foods | Page %d/%d%s'):format(#carried+#other,self.page,pages,note))
    end
    search:SetScript('OnTextChanged',function() p.page=1; p:Refresh() end)
    for _,event in ipairs({'BAG_UPDATE_DELAYED','GET_ITEM_INFO_RECEIVED','PLAYER_REGEN_ENABLED','UNIT_PET','QUEST_LOG_UPDATE','QUEST_ACCEPTED','QUEST_REMOVED','QUEST_TURNED_IN'}) do p:RegisterEvent(event) end
    p:SetScript('OnEvent',function()
        if p:IsShown() and not InCombatLockdown() then F.UpdateFoodCatalog(); p:Refresh() end
    end)
    table.insert(UISpecialFrames,'GFWForeverFoodList')
    if F.FinishMenu then F.FinishMenu(p,680,590) end
    p:Refresh()
end

function F.OpenPetLists()
    if InCombatLockdown() then F.Print('Manage pet lists after combat.'); return end
    F.FoodLists()
    if F.petListPanel then F.petListPanel:Show(); F.petListPanel:Refresh(); return end
    local p=CreateFrame('Frame','HunterToolsPetLists',UIParent,'BackdropTemplate'); F.petListPanel=p
    p:SetSize(600,350); p:SetPoint('CENTER'); p:SetFrameStrata('FULLSCREEN_DIALOG');p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    p:SetBackdropColor(0.055,0.055,0.055,1)
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
    local title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge'); title:SetPoint('TOP',0,-25); title:SetText('Saved pet food lists')
    local info=p:CreateFontString(nil,'OVERLAY','GameFontHighlight'); info:SetPoint('TOPLEFT',25,-65); info:SetWidth(550)
    local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); help:SetPoint('TOPLEFT',25,-155); help:SetWidth(550)
    help:SetText('Lists follow pet name + family. Matching names in different families stay separate. Legacy records without a family are grouped for cleanup, not mixed into another pet\'s rules. Summoning creates a default list: all edible foods are allowed unless restricted by your rules or food protections. Deleting lists does not delete pets.')
    local result=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');result:SetPoint('TOPLEFT',25,-220);result:SetWidth(550);p.result=result
    local prev=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');prev:SetSize(140,25);prev:SetPoint('BOTTOMLEFT',25,65);prev:SetText('Previous saved pet')
    local nextPet=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); nextPet:SetSize(140,25); nextPet:SetPoint('BOTTOMLEFT',175,65); nextPet:SetText('Next saved pet')
    local delete=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); delete:SetSize(230,25); delete:SetPoint('BOTTOMRIGHT',-25,65)
    local deleteAll=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');deleteAll:SetSize(280,25);deleteAll:SetPoint('BOTTOMRIGHT',-25,25)
    function p:Refresh()
        self.groups=F.SavedPetListGroups();self.index=math.min(self.index or 1,math.max(1,#self.groups));self.group=self.groups[self.index];self.key=self.group and self.group.id
        local g=self.group
        info:SetText(g and (('Saved group %d of %d%s\n%s — %s\n%d saved record(s); %d whitelist / %d blocked entries'):format(self.index,#self.groups,g.active and ' • Current pet / protected' or '',g.name,g.family,#g.keys,g.allowed,g.blocked)) or 'No saved pet lists.')
        self.confirm=nil;self.confirmAll=nil; delete:SetText('Delete selected lists');deleteAll:SetText('Delete all inactive lists');result:SetText('')
    end
    nextPet:SetScript('OnClick',function() p.index=(p.index or 1)%math.max(1,#p.groups)+1; p:Refresh() end)
    prev:SetScript('OnClick',function() p.index=((p.index or 1)-2)%math.max(1,#p.groups)+1;p:Refresh() end)
    delete:SetScript('OnClick',function()
        if InCombatLockdown() then F.Print('Delete lists after combat.');return end
        if not p.group then return end
        local group
        for _,candidate in ipairs(F.SavedPetListGroups()) do if candidate.id==p.key then group=candidate end end
        if not group then p:Refresh();return end
        if group.active then result:SetText('Dismiss or switch pets first. Unknown-family legacy lists sharing your pet\'s name are protected too.');return end
        p.confirmAll=nil;deleteAll:SetText('Delete all inactive lists')
        local signature=table.concat(group.keys,'\n')
        if p.confirm~=signature then p.confirm=signature;delete:SetText(('Confirm delete %d record(s)'):format(#group.keys));return end
        local ok,message=F.DeleteSavedPetLists(group.keys);F.Print(message);p:Refresh()
        result:SetText(ok and (group.name..' — '..group.family..' deleted. '..#p.groups..' group(s) remain.') or message)
    end)
    deleteAll:SetScript('OnClick',function()
        if InCombatLockdown() then F.Print('Delete lists after combat.');return end
        local keys=F.InactivePetListKeys();if #keys==0 then result:SetText('No inactive saved lists to delete.');return end
        local signature=table.concat(keys,'\n');p.confirm=nil;delete:SetText('Delete selected lists')
        if p.confirmAll~=signature then p.confirmAll=signature;deleteAll:SetText(('Confirm delete %d inactive records'):format(#keys));return end
        local ok,message=F.DeleteSavedPetLists(keys);F.Print(message);p:Refresh();result:SetText(message)
    end)
    local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(180,25);back:SetPoint('BOTTOMLEFT',25,25);back:SetText('Back to food')
    back:SetScript('OnClick',function() p:Hide();F.OpenFoodList() end)
    table.insert(UISpecialFrames,'HunterToolsPetLists')
    if F.FinishMenu then F.FinishMenu(p,600,350) end
    p:Refresh()
end
