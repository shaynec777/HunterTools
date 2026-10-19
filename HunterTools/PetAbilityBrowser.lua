local _,F=...
function F.PetBrowserSettings()
    if type(F.db.petBrowser)~='table' then F.db.petBrowser={} end
    local s=F.db.petBrowser
    if type(s.enabled)~='boolean' then s.enabled=true end
    if type(s.showPictures)~='boolean' then s.showPictures=true end
    return s
end
local function public(v) return not issecretvalue or not issecretvalue(v) end
function F.PetBrowserProgress(ability)
    local known=F.db.knownPetAbilities
    local highest=type(known)=='table' and known[ability.key] or 0
    if not public(highest) or type(highest)~='number' or highest~=highest or highest<0 or highest>1000 then highest=0 end
    local seen=F.db.petAbilityScanNames
    local scanned=F.db.petTrainingScanned or (type(seen)=='table' and seen[ability.key]) or highest>0
    local nextRank
    for _,r in ipairs(ability.ranks) do if r.rank>highest then nextRank=r;break end end
    return highest,scanned and true or false,nextRank
end
function F.PetBrowserRankStatus(ability,rank)
    local highest,scanned=F.PetBrowserProgress(ability)
    if highest>=rank then return 'Learned (cached)' end
    return scanned and 'Not learned (cached)' or 'Learned status unknown'
end
function F.PetBrowserAnimalText(animal)
    -- Never combine Classic pet skills with a same-ID Forever identity as if verified.
    local tags={['Observed fresh tame']='Your tame',['Petopia Forever']='Petopia',
        ['Petopia Forever (Classic-linked)']='Classic-linked',['Petopia community report (unverified)']='Report'}
    local tag=tags[animal.reference] or 'Classic'
    return animal.name..' - '..animal.family..' ['..tag..']\nLevel '..animal.levels..' | '..animal.zone
end
local function label(parent,text,x,y,width,font)
    local t=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
    t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');t:SetText(text);return t
end
local function button(parent,text,x,y,width,action)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(width,24);b:SetPoint('TOPLEFT',x,y);b:SetText(text);b:SetScript('OnClick',action);return b
end
function F.PetAnimalWowheadURL(animal)
    local id=type(animal)=='table' and animal.id
    if not public(id) or type(id)~='number' or id<1 or id>100000000 or id~=math.floor(id) then return nil end
    return 'https://www.wowhead.com/forever/npc='..string.format('%d',id)
end
function F.OpenPetAnimalWowhead(animal)
    if InCombatLockdown() then F.Print('Open animal links after combat.');return end
    local url=F.PetAnimalWowheadURL(animal)
    if not url then F.Print('No valid Wowhead NPC link is available for this animal.');return end
    if not F.wowheadLinkPanel then
        local d=CreateFrame('Frame','HunterToolsWowheadLink',UIParent,'BackdropTemplate');F.wowheadLinkPanel=d
        d:SetSize(640,300);d:SetPoint('CENTER');d:SetFrameStrata('FULLSCREEN_DIALOG');d:SetClampedToScreen(true);d:EnableMouse(true)
        d:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        local close=CreateFrame('Button',nil,d,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        table.insert(UISpecialFrames,'HunterToolsWowheadLink')
        d.title=label(d,'Wowhead animal page',28,-25,570,'GameFontNormalLarge')
        d.status=label(d,'',28,-62,580);d.status:SetHeight(32)
        d.url=CreateFrame('EditBox',nil,d,'InputBoxTemplate');d.url:SetPoint('TOPLEFT',32,-102);d.url:SetSize(572,28);d.url:SetAutoFocus(false);d.url:SetMaxLetters(256)
        d.url:SetScript('OnEscapePressed',function() d:Hide() end)
        d.url:SetScript('OnEnterPressed',function(self) self:HighlightText() end)
        label(d,'Press Ctrl+C to copy this address. Open your browser, paste it into the address bar, and press Enter.',28,-146,580)
        button(d,'Select address',28,-250,150,function() d.url:SetFocus();d.url:HighlightText() end)
        button(d,'Close',462,-250,145,function() d:Hide() end)
        local function sourceButton(caption,x,index)
            local b=button(d,caption,x,-208,180,function()
                local links=d.sourceLinks or {};local address=links[index]
                if address then d.url:SetText(address);d.url:SetFocus();d.url:HighlightText();d.status:SetText('Press Ctrl+C to copy. Source: '..caption) end
            end)
            return b
        end
        -- Explicit choices: the game cannot test websites or open external browsers.
        d.petopiaButton=sourceButton('Petopia Forever',28,1)
        d.foreverButton=sourceButton('Wowhead Forever',220,2)
        d.classicButton=sourceButton('Wowhead Classic',412,3)
        d:SetScript('OnHide',function() d.url:ClearFocus() end)
    end
    local d=F.wowheadLinkPanel
    if F.FinishMenu then F.FinishMenu(d,640,300) end
    d.title:SetText('Wowhead: '..(animal.name or 'Animal'))
    d.status:SetText("Copy this address to open the animal's Wowhead Forever page.")
    local petopia,forever,classic
    if F.BeastSourceURLs then petopia,forever,classic=F.BeastSourceURLs(animal.id) end
    d.sourceLinks={[1]=petopia,[2]=forever or url,[3]=classic or ('https://www.wowhead.com/classic/npc='..animal.id)}
    d.petopiaButton:SetEnabled(petopia~=nil)
    if petopia then url=petopia;d.status:SetText('Petopia Forever first; use Wowhead Forever, then Classic if needed.') end
    d.url:SetText(url);d:Show();d.url:SetFocus();d.url:HighlightText()

end
-- Retain a small model cache per row so paging back does not request it again.
local function petBrowserModel(portrait)
    local model=CreateFrame('PlayerModel',nil,portrait)
    model:SetAllPoints(portrait);model:EnableMouse(false)
    if model.SetKeepModelOnHide then model:SetKeepModelOnHide(true) end
    model:SetScript('OnModelLoaded',function(self)
        self.loaded=true
        if portrait.model==self and portrait.animalID==self.animalID then portrait.fallback:SetText('') end
        if self.SetPortraitZoom then self:SetPortraitZoom(0) end
        if self.SetRotation then self:SetRotation(0.5) end
    end)
    return model
end
function F.SetPetBrowserPortrait(portrait,animal)
    if not F.PetBrowserSettings().showPictures then
        for _,model in pairs(portrait.models or {}) do
            model:Hide();if model.ClearModel then model:ClearModel() end
        end
        portrait.models=nil;portrait.cacheOrder=nil;portrait.model=nil
        portrait.animalID=nil;portrait.initialized=false
        portrait.fallback:SetText('');portrait:Hide();return
    end
    local id=F.PetAnimalWowheadURL(animal) and animal.id or nil
    if portrait.initialized and portrait.animalID==id then return end
    portrait.initialized=true;portrait.animalID=id
    if portrait.model then portrait.model:Hide() end
    portrait.fallback:SetText(id and '...' or '')
    if not id then portrait:Hide();return end
    portrait:Show()
    portrait.models=portrait.models or {}
    portrait.cacheOrder=portrait.cacheOrder or {}
    local model=portrait.models[id]
    if model then
        portrait.model=model;model:Show()
        portrait.fallback:SetText(model.failed and '?' or model.loaded and '' or '...')
        return
    end
    if #portrait.cacheOrder>=4 then
        local old=table.remove(portrait.cacheOrder,1)
        model=portrait.models[old];portrait.models[old]=nil
        model:Hide();if model.ClearModel then model:ClearModel() end
    else model=petBrowserModel(portrait) end
    model.loaded=false;model.failed=false;model.animalID=id
    portrait.models[id]=model;portrait.cacheOrder[#portrait.cacheOrder+1]=id;portrait.model=model
    model:Show()
    if not model.SetCreature or not pcall(model.SetCreature,model,id) then
        model.failed=true;model:Hide();portrait.fallback:SetText('?')
    end
end
function F.ShowPetBrowserBeastDetails(id)
    if InCombatLockdown() then return end
    local name,details=F.BeastRecordDetails(id)
    if not details then return end
    local p=F.petAbilityBrowser
    if not p.beastDetails then
        local d=CreateFrame('Frame',nil,p,'BackdropTemplate');p.beastDetails=d
        d:SetPoint('TOPLEFT',p,'TOPLEFT',306,-160);d:SetSize(610,360);d:EnableMouse(true)
        d:SetFrameLevel(p:GetFrameLevel()+20);d:SetAlpha(1)
        d.background=d:CreateTexture(nil,'BACKGROUND');d.background:SetAllPoints();d.background:SetColorTexture(0.025,0.035,0.03,1)
        d:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});d:SetBackdropColor(0.035,0.047,0.044,1)
        d.title=label(d,'',14,-14,410,'GameFontNormal')
        local scroll=CreateFrame('ScrollFrame',nil,d,'UIPanelScrollFrameTemplate');d.scroll=scroll
        scroll:SetPoint('TOPLEFT',14,-48);scroll:SetPoint('BOTTOMRIGHT',-34,16)
        local content=CreateFrame('Frame',nil,scroll);content:SetWidth(550);scroll:SetScrollChild(content);d.content=content
        d.text=label(content,'',0,0,550,'GameFontHighlight')
        button(d,'Watch mob',436,-10,85,function() if F.WatchMob and F.WatchMob(d.mobName,d.npcID) then F.OpenMobFinder() end end)
        button(d,'Back',530,-10,65,function() d:Hide() end)
    end
    local d=p.beastDetails;d.mobName=name;d.npcID=id;d.title:SetText(name);d.text:SetText(details)
    d.content:SetHeight(math.max(1,d.text:GetStringHeight()+10));d.scroll:SetVerticalScroll(0);d:Show()
end
local function refreshBeastSearch(p,showPictures)
    local matches=p.beastMatches or {};local pages=math.max(1,math.ceil(#matches/6))
    p.animalPage=math.min(p.animalPage or 1,pages)
    p.sourceTitle:SetText('Beast name search')
    p.sourceNote:SetText(#matches>0 and 'All beast references and your journal.\nClick Details to inspect a result here.' or 'No matching beasts. Try another name.\nClear the beast name and Search to return to ability teachers.')
    for i,t in ipairs(p.animalRows) do
        local match=matches[(p.animalPage-1)*6+i];local a
        if match then
            local r=match.record
            a={id=match.id,name=r.name,family=r.family or 'Unknown',zone=r.zone or 'Location unknown',levels=tostring(r.minLevel or '?'),reference=r.sources and r.sources.name}
            if r.maxLevel and r.maxLevel~=r.minLevel then a.levels=a.levels..'-'..r.maxLevel end
        end
        t:ClearAllPoints();t:SetPoint('TOPLEFT',showPictures and 576 or 510,-242-(i-1)*46);t:SetWidth(showPictures and 239 or 305)
        t:SetText(a and F.PetBrowserAnimalText(a) or '')
        F.SetPetBrowserPortrait(p.animalPortraits[i],a)
        local b=p.wowheadButtons[i];b.animal=a;b.beastResult=match~=nil;b:SetText('Details');if match then b:Show() else b:Hide() end
    end
    p.animalPages:SetText(('%d beasts | Page %d/%d'):format(#matches,p.animalPage,pages))
    p.animalPrev:SetEnabled(p.animalPage>1);p.animalNext:SetEnabled(p.animalPage<pages)
end
function F.RefreshPetAbilityBrowser()
    local p=F.petAbilityBrowser
    if not p or not p:IsShown() or InCombatLockdown() then return end
    local showPictures=F.PetBrowserSettings().showPictures
    p.pictureCheck:SetChecked(showPictures)
    if p.beastSearchMode then refreshBeastSearch(p,showPictures);return end
    local query=(p.search:GetText() or ''):lower()
    local filtered={}
    for _,a in ipairs(F.petBrowserAbilities) do if query=='' or a.name:lower():find(query,1,true) then filtered[#filtered+1]=a end end
    local pages=math.max(1,math.ceil(#filtered/12));p.abilityPage=math.min(p.abilityPage or 1,pages)
    local selected
    for _,a in ipairs(filtered) do if a.key==p.selectedKey then selected=a;break end end
    if not selected and #filtered>0 then selected=filtered[1];p.selectedKey=selected.key;p.selectedRank=nil;p.animalPage=1 end
    for i,b in ipairs(p.abilityButtons) do
        local a=filtered[(p.abilityPage-1)*12+i];b.ability=a
        if a then
            local highest,scanned,nextRank=F.PetBrowserProgress(a)
            local status=nextRank and ((scanned and 'Next ' or 'Check ')..nextRank.rank) or 'Complete*'
            b:SetText((a.key==p.selectedKey and '> ' or '')..a.name..' | '..status);b:Show()
        else b:Hide() end
    end
    p.abilityPages:SetText(('Page %d/%d | %d abilities'):format(p.abilityPage,pages,#filtered))
    p.abilityPrev:SetEnabled(p.abilityPage>1);p.abilityNext:SetEnabled(p.abilityPage<pages)
    if not selected then
        p.summary:SetText('No matching abilities.');p.rankTitle:SetText('Ranks');p.sourceTitle:SetText('Teaching animals');p.sourceNote:SetText('Change the ability search to see results.')
        for _,b in ipairs(p.rankButtons) do b:Hide() end
        for _,t in ipairs(p.animalRows) do t:SetText('') end
        for _,portrait in ipairs(p.animalPortraits) do F.SetPetBrowserPortrait(portrait,nil) end
        for _,b in ipairs(p.wowheadButtons) do b.animal=nil;b:Hide() end
        p.animalPages:SetText('');p.animalPrev:SetEnabled(false);p.animalNext:SetEnabled(false);return
    end
    local highest,scanned,nextRank=F.PetBrowserProgress(selected)
    if not p.selectedRank then p.selectedRank=nextRank and nextRank.rank or selected.ranks[#selected.ranks].rank end
    local chosen
    for _,r in ipairs(selected.ranks) do if r.rank==p.selectedRank then chosen=r;break end end
    chosen=chosen or selected.ranks[1];p.selectedRank=chosen.rank
    p.rankTitle:SetText(selected.name..' ranks')
    local summary='Learned through rank '..highest..' (cached). '
    if not scanned then summary='Learned ranks unknown. Open Beast Training to update the cache. ' end
    summary=summary..(nextRank and ((scanned and 'Next needed: ' or 'Next unconfirmed: ')..nextRank.rank) or 'All listed ranks learned (cached).')
    p.summary:SetText(summary)
    for i,b in ipairs(p.rankButtons) do
        local r=selected.ranks[i];b.rank=r
        if r then
            local state=F.PetBrowserRankStatus(selected,r.rank)
            local color=state=='Learned (cached)' and '|cff33ff66' or state=='Not learned (cached)' and '|cffff8888' or '|cffffff88'
            b:SetText(color..(r.rank==p.selectedRank and '> ' or '')..'Rank '..r.rank..(nextRank and r.rank==nextRank.rank and ' (next)' or '')..'|r');b:Show()
        else b:Hide() end
    end
    p.sourceTitle:SetText(('Rank %d | pet level %s'):format(chosen.rank,tostring(chosen.petLevel or '?')))
    local animals=F.BeastTeachers and F.BeastTeachers(selected.key,chosen.rank,chosen.animals) or chosen.animals or {};local animalPages=math.max(1,math.ceil(#animals/6))
    p.animalPage=math.min(p.animalPage or 1,animalPages)
    for i,t in ipairs(p.animalRows) do
        local a=animals[(p.animalPage-1)*6+i]
        t:ClearAllPoints();t:SetPoint('TOPLEFT',showPictures and 576 or 510,-242-(i-1)*46);t:SetWidth(showPictures and 239 or 305)
        t:SetText(a and F.PetBrowserAnimalText(a) or '')
        F.SetPetBrowserPortrait(p.animalPortraits[i],a)
        local b=p.wowheadButtons[i];b.animal=a;b.beastResult=false;b:SetText('Wowhead')
        if F.PetAnimalWowheadURL(a) then b:Show() else b:Hide() end
    end
    local state=F.PetBrowserRankStatus(selected,chosen.rank)
    if #animals>0 then p.sourceNote:SetText(state..'\nYour tame = observed; Report = unverified.\nClassic / Classic-linked: verify in Forever.')
    elseif (chosen.classicSource=='t' or chosen.classicSource=='tw') then p.sourceNote:SetText(state..'\nClassic reference: pet trainer. No verified Forever teacher bundled.')
    else p.sourceNote:SetText(state..'\nNo verified teaching animal or trainer source bundled for this rank.') end
    p.animalPages:SetText(('%d animals | Page %d/%d'):format(#animals,p.animalPage,animalPages))
    p.animalPrev:SetEnabled(p.animalPage>1);p.animalNext:SetEnabled(p.animalPage<animalPages)
end
function F.OpenPetAbilityBrowser()
    if InCombatLockdown() then F.Print('Open the pet ability browser after combat.');return end
    if not F.PetBrowserSettings().enabled then F.Print('Enable Pet abilities in /ht settings first.');return end
    if F.ScanKnownPetAbilities then F.ScanKnownPetAbilities() end
    F.HideConfigPages()
    if not F.petAbilityBrowser then
        local p=CreateFrame('Frame','HunterToolsPetAbilityBrowser',UIParent,'BackdropTemplate');F.petAbilityBrowser=p
        p:SetSize(940,610);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        local width=UIParent.GetWidth and UIParent:GetWidth();local height=UIParent.GetHeight and UIParent:GetHeight()
        if type(width)=='number' and type(height)=='number' then p:SetScale(math.min(1,width/970,height/640)) end
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        p:SetMovable(true);p:EnableMouse(true);p:RegisterForDrag('LeftButton')
        p:SetScript('OnDragStart',function() if IsShiftKeyDown() and not InCombatLockdown() then p:StartMoving() end end)
        p:SetScript('OnDragStop',function() p:StopMovingOrSizing() end)
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        table.insert(UISpecialFrames,'HunterToolsPetAbilityBrowser')
        label(p,'Pet ability browser',24,-22,800,'GameFontNormalLarge')
        label(p,'Choose an ability, then a rank. Green = cached learned; red = cached missing; yellow = unknown.',24,-52,885)
        p.search=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.search:SetSize(240,25);p.search:SetPoint('TOPLEFT',28,-80);p.search:SetAutoFocus(false);p.search:SetMaxLetters(60)
        p.search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        p.search:SetScript('OnTextChanged',function() p.beastSearchMode=false;if p.beastDetails then p.beastDetails:Hide() end;p.abilityPage=1;p.selectedKey=nil;p.selectedRank=nil;p.animalPage=1;F.RefreshPetAbilityBrowser() end)
        label(p,'Search abilities',290,-86,190)
        p.pictureCheck=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.pictureCheck:SetPoint('TOPLEFT',510,-78)
        label(p,'Show pet pictures',546,-86,300)
        p.pictureCheck:SetScript('OnClick',function(self)
            F.PetBrowserSettings().showPictures=self:GetChecked() and true or false
            F.RefreshPetAbilityBrowser()
        end)
        label(p,'Beast name',510,-119,78)
        p.beastSearch=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.beastSearch:SetSize(200,25);p.beastSearch:SetPoint('TOPLEFT',594,-112);p.beastSearch:SetAutoFocus(false);p.beastSearch:SetMaxLetters(100);p.beastSearch:SetText('')
        local function searchBeasts()
            if InCombatLockdown() then F.Print('Search beasts after combat.');return end
            local text=p.beastSearch:GetText() or ''
            p.beastSearch:ClearFocus();p.beastSearchMode=text:match('%S')~=nil;p.beastMatches=F.SearchBeasts(text);p.animalPage=1
            if p.beastDetails then p.beastDetails:Hide() end
            F.RefreshPetAbilityBrowser()
        end
        p.beastSearch:SetScript('OnEnterPressed',searchBeasts)
        p.beastSearch:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        p.beastSearchButton=button(p,'Search beasts',806,-112,105,searchBeasts)
        p.summary=label(p,'',24,-117,470);p.summary:SetHeight(42)
        label(p,'Abilities',24,-164,270,'GameFontNormal')
        p.rankTitle=label(p,'Ranks',310,-164,180,'GameFontNormal')
        p.sourceTitle=label(p,'Teaching animals',510,-164,400,'GameFontNormal')
        p.sourceNote=label(p,'',510,-190,400);p.sourceNote:SetHeight(48)
        p.abilityButtons={};p.rankButtons={};p.animalRows={};p.wowheadButtons={};p.animalPortraits={}
        for i=1,12 do
            local b=button(p,'',24,-190-(i-1)*27,270,function() end);p.abilityButtons[i]=b
            b:SetScript('OnClick',function() if InCombatLockdown() or not b.ability then return end;p.beastSearchMode=false;if p.beastDetails then p.beastDetails:Hide() end;p.selectedKey=b.ability.key;p.selectedRank=nil;p.animalPage=1;F.RefreshPetAbilityBrowser() end)
        end
        local maxRanks=0;for _,a in ipairs(F.petBrowserAbilities) do maxRanks=math.max(maxRanks,#a.ranks) end
        for i=1,maxRanks do
            local b=button(p,'',310,-190-(i-1)*27,180,function() end);p.rankButtons[i]=b
            b:SetScript('OnClick',function() if InCombatLockdown() or not b.rank then return end;p.beastSearchMode=false;if p.beastDetails then p.beastDetails:Hide() end;p.selectedRank=b.rank.rank;p.animalPage=1;F.RefreshPetAbilityBrowser() end)
        end
        for i=1,6 do
            local y=-242-(i-1)*46
            local portrait=CreateFrame('Frame',nil,p);portrait:SetSize(60,44);portrait:SetPoint('TOPLEFT',510,y)
            portrait.fallback=label(portrait,'',22,-12,20,'GameFontNormalLarge')
            p.animalPortraits[i]=portrait
            local t=label(p,'',576,y,239);t:SetHeight(44);p.animalRows[i]=t
            local b=button(p,'Wowhead',824,y-6,86,function() end);p.wowheadButtons[i]=b
            b:SetScript('OnClick',function() if b.animal then if b.beastResult then F.ShowPetBrowserBeastDetails(b.animal.id) else F.OpenPetAnimalWowhead(b.animal) end end end)
        end
        p.abilityPages=label(p,'',24,-522,270);p.animalPages=label(p,'',510,-522,400)
        p.abilityPrev=button(p,'Previous',24,-546,125,function() p.abilityPage=math.max(1,p.abilityPage-1);F.RefreshPetAbilityBrowser() end)
        p.abilityNext=button(p,'Next',163,-546,131,function() p.abilityPage=p.abilityPage+1;F.RefreshPetAbilityBrowser() end)
        p.animalPrev=button(p,'Previous',510,-546,120,function() p.animalPage=math.max(1,p.animalPage-1);F.RefreshPetAbilityBrowser() end)
        p.animalNext=button(p,'Next',640,-546,120,function() p.animalPage=p.animalPage+1;F.RefreshPetAbilityBrowser() end)
        button(p,'Refresh',310,-546,180,function() if not InCombatLockdown() then F.ScanKnownPetAbilities();F.RefreshPetAbilityBrowser() end end)
        button(p,'Back to tools',776,-546,135,F.OpenConfig)
        label(p,'Ranks/levels: Forever client reference. Availability may vary in beta. Lower ranks are inferred from the highest learned rank.',24,-582,888)
        p:SetScript('OnShow',F.RefreshPetAbilityBrowser)
        p:SetScript('OnHide',function() p.search:ClearFocus();p.beastSearch:ClearFocus();if F.wowheadLinkPanel then F.wowheadLinkPanel:Hide() end end)
        local elapsed=0
        p:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;F.RefreshPetAbilityBrowser() end end)
        p:SetScript('OnEvent',function(_,event) if event=='PLAYER_REGEN_DISABLED' then p:Hide() end end)
        p:RegisterEvent('PLAYER_REGEN_DISABLED')
        p.abilityPage=1;p.animalPage=1
    end
    if F.FinishMenu then F.FinishMenu(F.petAbilityBrowser,940,610) end
    F.petAbilityBrowser.selectedRank=nil
    F.petAbilityBrowser:Show();F.RefreshPetAbilityBrowser()
end
