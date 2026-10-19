local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c,d=pcall(fn,...)
    if not ok or not safe(a) then return end
    if not safe(b) then b=nil end
    if not safe(c) then c=nil end
    if not safe(d) then d=nil end
    return a,b,c,d
end
F.animalFields={{'info','Potential pet information'},{'role','Pet role'},
    {'abilities','Abilities / learned ranks'},{'diet','Diet'},{'food','Inventory food counts'}}
function F.AnimalSettings()
    if type(F.db.animals)~='table' then F.db.animals={} end
    local s=F.db.animals
    for _,surface in ipairs({'mouseover','target'}) do
        if type(s[surface])~='table' then s[surface]={} end
        local fields=s[surface]
        if type(fields.enabled)~='boolean' then fields.enabled=true end
        for _,field in ipairs(F.animalFields) do
            local key=field[1]
            if type(fields[key])~='boolean' then
                local old=F.RangeSettings()
                if surface=='target' and key=='abilities' then fields[key]=old.showPetAbilities~=false
                elseif surface=='target' and key=='diet' then fields[key]=old.showPetDiet~=false
                else fields[key]=true end
            end
        end
    end
    return s
end
-- Traditional Classic roles; not a claim about Forever's modified family stats.
local roles={Bat='Offensive',Bear='Defensive',Boar='Defensive',Cat='Offensive',
    ['Carrion Bird']='General (balanced)',Crab='Defensive',Crocolisk='Defensive',
    Gorilla='Defensive',Hyena='General (balanced)',Owl='Offensive',Raptor='Offensive',
    Scorpid='Defensive',Spider='Offensive',Tallstrider='Defensive',Turtle='Defensive',
    ['Wind Serpent']='Offensive',Wolf='General (balanced)'}
function F.PetRole(family)
    local current=F.petopiaForeverFamilies and F.petopiaForeverFamilies[family]
    if current and current.role then return current.role..' (Petopia Forever)' end
    return family and roles[family] and (roles[family]..' (Classic baseline)') or 'Unknown'
end
local foodCache={}
function F.AnimalFoodCounts(diet,level)
    if type(diet)~='string' then return 'Diet unknown; counts unavailable.' end
    local cacheKey=diet..':'..tostring(level)
    local now=GetTime and GetTime() or 0
    local cached=foodCache[cacheKey]
    if cached and now-cached.at<2 then return cached.text end
    local counts,usable={},0
    for kind in diet:gmatch('[^,]+') do counts[kind:match('^%s*(.-)%s*$')]=0 end
    local pending,unclassified=false,false
    if not C_Container or not C_Item then return 'Inventory information unavailable.' end
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        local slots=query(C_Container.GetContainerNumSlots,bag)
        if type(slots)~='number' or (bag==0 and slots==0) then pending=true;slots=0 end
        for slot=1,slots do
            local item=query(C_Container.GetContainerItemInfo,bag,slot)
            if type(item)=='table' then
                local id,count=item.itemID,item.stackCount
                if safe(id) and safe(count) and type(id)=='number' and type(count)=='number' and count>0 then
                    local kind=F.petFoodTypes and F.petFoodTypes[id]
                    if kind and counts[kind] then
                        counts[kind]=counts[kind]+count
                        local name,_,_,foodLevel=query(C_Item.GetItemInfo,id)
                        if not safe(name) or not name or not safe(foodLevel) or type(foodLevel)~='number' then pending=true
                        elseif type(level)=='number' and level>0 and foodLevel>=level-30 then usable=usable+count end
                    elseif not kind and F.foodCatalog and F.foodCatalog[id] then unclassified=true end
                else pending=true end
            end
        end
    end
    local parts={}
    for token in diet:gmatch('[^,]+') do local kind=token:match('^%s*(.-)%s*$');parts[#parts+1]=kind..' ('..(counts[kind] or 0)..')' end
    local result=table.concat(parts,', ')
    if type(level)=='number' and level>0 then result=result..'\nUsable food (Classic estimate): '..usable end
    if pending or unclassified then result=result..'\nPartial count: '..(pending and 'item data loading; ' or '')..(unclassified and 'unclassified food in bags.' or 'retry after inventory settles.') end
    foodCache[cacheKey]={at=now,text=result}
    return result
end
function F.AnimalDetails(unit,s)
    if not s.enabled then return nil end
    local any=false;for _,field in ipairs(F.animalFields) do if s[field[1]] then any=true end end
    if not any or InCombatLockdown() then return nil end
    if not query(UnitExists,unit) then return nil end
    local family=query(UnitCreatureFamily,unit)
    -- Other hunters' pets are not potential tames. Your own pet has its status tooltip.
    if query(UnitIsPlayer,unit) or query(UnitPlayerControlled,unit) then return nil end
    local guid=query(UnitGUID,unit)
    local npcID=type(guid)=='string' and guid:match('^Creature%-.*%-(%d+)%-%x+$')
    npcID=tonumber(npcID)
    local forever=npcID and F.foreverPetCreatureDB and F.foreverPetCreatureDB[npcID]
    if F.ObserveBeast then F.ObserveBeast(unit) end
    local record=F.BeastRecord and F.BeastRecord(npcID) or forever or (npcID and F.petCreatureDB and F.petCreatureDB[npcID])
    local hasFamily=type(family)=='string' and family~=''
    if not hasFamily and record and record.family then family=record.family;hasFamily=true end
    -- Missing family is normal for new Forever beasts. Still show available info.
    -- Unknown non-beasts must not receive animal details.
    if not hasFamily and not record then
        local creatureType=query(UnitCreatureType,unit)
        if creatureType~='Beast' then return nil end
    end
    family=hasFamily and family or 'Family unknown'
    -- Creature families alone do not establish tameability; never promise a tame.
    local lines={}
    local level=query(UnitLevel,unit)
    if type(level)~='number' or level<1 then level=forever and forever.minLevel end
    if s.info then
        lines[#lines+1]=family..(type(level)=='number' and level>0 and (' - level '..level) or '')
            ..(record and record.tameable==true and ' (tameable: '..(record.sources and record.sources.tameable or 'Wowhead Forever')..')'
                or record and record.tameable==false and ' (reference: not tameable)' or ' (tameability unconfirmed)')
        if record and record.zone then lines[#lines+1]='Location: '..record.zone end
    end
    if s.role then lines[#lines+1]='Role: '..F.PetRole(family) end
    local diet,abilities
    local tip=query(C_TooltipInfo and C_TooltipInfo.GetUnit,unit)
    if safe(tip) and tip and safe(tip.lines) and tip.lines then
        for _,line in ipairs(tip.lines) do
            local text=line.leftText
            if safe(text) and type(text)=='string' then
                local clean=text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
                local foods=clean:match('^[Dd]iet:%s*(.+)') or clean:match('^[Ff]ood [Tt]ypes?:%s*(.+)')
                if foods then diet=foods end
                local skills=clean:match('^[Aa]bilities:%s*(.+)') or clean:match('^[Pp]et [Aa]bilities:%s*(.+)')
                if skills then abilities=skills end
                if clean:match('[Rr]ank%s+%d+') and not skills then
                    abilities=abilities and (abilities..'; '..clean) or clean
                end
            end
        end
    end
    local baseline=false
    if not abilities and record then
        abilities=record.abilities
        if abilities and record.sources and s.abilities then lines[#lines+1]='Ability reference: '..record.sources.abilities..'.' end
        baseline=(not record.sources and not forever) and s.abilities and abilities~=nil
    end
    local wowheadDiet=false
    local dietSource
    if not diet and record and record.diet then diet=record.diet;dietSource=record.sources and record.sources.diet end
    if not diet and F.BeastDiet then diet,dietSource=F.BeastDiet(family) end
    if not diet and forever then diet=forever.diet;wowheadDiet=diet~=nil end
    if not diet and F.foreverPetFamilyDiets then diet=F.foreverPetFamilyDiets[family];wowheadDiet=diet~=nil end
    if not diet and F.petFamilyDiets then diet=F.petFamilyDiets[family];baseline=baseline or ((s.diet or s.food) and diet~=nil) end
    if abilities and F.MarkTargetAbilities and s.abilities and s.learned~=false then abilities=F.MarkTargetAbilities(abilities) end
    if s.abilities then lines[#lines+1]='Abilities: '..(abilities or 'no database record; inspect with Beast Lore.') end
    local familyInfo=F.petopiaForeverFamilies and F.petopiaForeverFamilies[family]
    if s.abilities and not abilities and familyInfo and familyInfo.learnable and #familyInfo.learnable>0 then
        lines[#lines+1]='Family training options: '..table.concat(familyInfo.learnable,', ')..' (Petopia Forever; innate ranks unknown).'
    end
    if s.diet then lines[#lines+1]='Eats: '..(diet or 'not revealed; inspect with Beast Lore.') end
    if s.food then lines[#lines+1]='In bags: '..F.AnimalFoodCounts(diet,level) end
    if wowheadDiet and (s.diet or s.food) then lines[#lines+1]='Diet reference: Wowhead Forever.' end
    if dietSource and (s.diet or s.food) then lines[#lines+1]='Diet reference: '..dietSource..'.' end
    if record and record.sources and s.info then lines[#lines+1]='Beast reference: '..(record.sources.name or record.sources.family or 'Unknown')..'.' end
    if baseline then lines[#lines+1]='Classic baseline - Forever may differ.' end
    return #lines>0 and table.concat(lines,'\n') or nil
end
function F.TargetPetDetails()
    return F.AnimalDetails('target',F.AnimalSettings().target)
end
local building=false
function F.AddAnimalTip(tooltip)
    if building or not F.db or InCombatLockdown() or tooltip.HunterToolsAnimalTipAdded then return end
    local _,class=query(UnitClass,'player');if class~='HUNTER' then return end
    local _,unit=query(tooltip.GetUnit,tooltip)
    if type(unit)~='string' or query(UnitIsUnit,unit,'pet') then return end
    -- GetUnit returns the hovered unit, independent of the current target.
    building=true
    local ok,details=pcall(F.AnimalDetails,unit,F.AnimalSettings().mouseover)
    building=false
    if not ok or not details then return end
    tooltip.HunterToolsAnimalTipAdded=true
    tooltip:AddLine(' ');tooltip:AddLine('HunterTools animal information',1,0.82,0)
    for line in details:gmatch('[^\n]+') do tooltip:AddLine(line,0.9,0.9,0.9,true) end
end
if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript('OnTooltipCleared',function(t) t.HunterToolsAnimalTipAdded=nil end)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,F.AddAnimalTip)
    elseif GameTooltip.HasScript and GameTooltip:HasScript('OnTooltipSetUnit') then
        GameTooltip:HookScript('OnTooltipSetUnit',F.AddAnimalTip)
    end
end

local inventory=CreateFrame('Frame')
for _,event in ipairs({'BAG_UPDATE_DELAYED','GET_ITEM_INFO_RECEIVED','PLAYER_ENTERING_WORLD'}) do inventory:RegisterEvent(event) end
inventory:SetScript('OnEvent',function() foodCache={} end)

-- An explicit lookup is available to every class, independent of hunter UI toggles.
function F.OpenBeastDetail()
    if InCombatLockdown() then F.Print('View beast details after combat.');return end
    if not query(UnitExists,'target') then F.OpenBeastSearch('');return end
    local _,class=query(UnitClass,'player')
    local fields={enabled=true,info=true,role=true,abilities=true,diet=true,food=true,learned=class=='HUNTER'}
    local details=F.AnimalDetails('target',fields)
    if not details then F.OpenBeastSearch('');return end
    local name=query(UnitName,'target') or 'Beast'
    if class~='HUNTER' then details=details..'\nHunter learned-ability status does not apply to this character.' end
    F.ShowBeastDetail(name,details)
end
function F.ShowBeastDetail(name,details)
    if not F.beastDetailPanel then
        local p=CreateFrame('Frame','HunterToolsBeastDetail',UIParent,'BackdropTemplate');F.beastDetailPanel=p
        p:SetSize(500,460);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        table.insert(UISpecialFrames,'HunterToolsBeastDetail')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        p.search=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.search:SetSize(315,24);p.search:SetPoint('BOTTOMLEFT',30,12);p.search:SetAutoFocus(false);p.search:SetMaxLetters(100);p.search:SetText('')
        local function searchBeasts() p.search:ClearFocus();F.OpenBeastSearch(p.search:GetText() or '') end
        p.search:SetScript('OnEnterPressed',searchBeasts)
        p.search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        p.searchButton=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.searchButton:SetSize(110,24);p.searchButton:SetPoint('BOTTOMLEFT',360,12);p.searchButton:SetText('Search beasts');p.searchButton:SetScript('OnClick',searchBeasts)
        p:SetScript('OnHide',function() p.search:ClearFocus() end)
        p.title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');p.title:SetPoint('TOPLEFT',24,-24);p.title:SetWidth(440);p.title:SetJustifyH('LEFT')
        local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate');p.scroll=scroll
        scroll:SetPoint('TOPLEFT',24,-65);scroll:SetPoint('BOTTOMRIGHT',-45,48)
        local content=CreateFrame('Frame',nil,scroll);content:SetWidth(420);scroll:SetScrollChild(content)
        p.text=content:CreateFontString(nil,'OVERLAY','GameFontHighlight');p.text:SetPoint('TOPLEFT');p.text:SetWidth(420);p.text:SetJustifyH('LEFT');p.text:SetJustifyV('TOP')
        p.content=content
    end
    if F.beastSearchPanel then F.beastSearchPanel:Hide() end
    local p=F.beastDetailPanel;p.title:SetText(name..' - Beast details');p.text:SetText(details)
    p.content:SetHeight(math.max(1,p.text:GetStringHeight()+10));p.scroll:SetVerticalScroll(0);p:Show()
end

-- Search all available sources by literal, case-insensitive partial name.
function F.SearchBeasts(text)
    local needle=(text or ''):match('^%s*(.-)%s*$'):lower()
    if needle=='' then return {} end
    local ids={}
    local function add(rows) for id in pairs(rows or {}) do ids[id]=true end end
    add(F.petCreatureDB);add(F.foreverPetCreatureDB);add(F.petopiaForeverCreatures);add(F.petopiaCommunityCreatures)
    add(F.db and F.db.beastJournal and F.db.beastJournal.records)
    local matches={}
    for id in pairs(ids) do
        local row=F.BeastRecord(id)
        if row and type(row.name)=='string' and row.name:lower():find(needle,1,true) then
            matches[#matches+1]={id=id,record=row}
        end
    end
    table.sort(matches,function(a,b)
        local an,bn=a.record.name:lower(),b.record.name:lower()
        if (an==needle)~=(bn==needle) then return an==needle end
        if an~=bn then return an<bn end
        return a.id<b.id
    end)
    return matches
end
function F.OpenBeastRecord(id)
    if InCombatLockdown() then F.Print('View beast details after combat.');return end
    local name,details=F.BeastRecordDetails(id)
    if not details then F.Print('No beast record available.');return end
    F.ShowBeastDetail(name,details)
end
function F.BeastRecordDetails(id)
    local row=F.BeastRecord(id)
    if not row then return end
    local family=row.family or 'Family unknown'
    local levels=row.minLevel and tostring(row.minLevel) or 'unknown'
    if row.maxLevel and row.maxLevel~=row.minLevel then levels=levels..'-'..row.maxLevel end
    local lines={'Database lookup (NPC '..id..')',family..' - level '..levels,
        'Tameability: '..(row.tameable==true and 'reference says tameable' or row.tameable==false and 'reference says not tameable' or 'unconfirmed'),
        'Location: '..(row.zone or 'unknown'),'Role: '..F.PetRole(row.family)}
    local abilities=row.abilities
    local _,class=query(UnitClass,'player')
    if abilities and class=='HUNTER' and F.MarkTargetAbilities then abilities=F.MarkTargetAbilities(abilities) end
    lines[#lines+1]='Abilities: '..(abilities or 'unknown; no recorded abilities')
    local diet,dietSource=row.diet,row.sources and row.sources.diet
    if not diet and F.BeastDiet then diet,dietSource=F.BeastDiet(row.family) end
    lines[#lines+1]='Eats: '..(diet or 'unknown')
    lines[#lines+1]='In bags: '..F.AnimalFoodCounts(diet,row.minLevel)
    for _,field in ipairs({'name','family','minLevel','tameable','zone','abilities'}) do
        local source=row.sources and row.sources[field]
        if source then lines[#lines+1]=field..' reference: '..source end
    end
    if dietSource then lines[#lines+1]='Diet reference: '..dietSource end
    lines[#lines+1]='Reference data may be incomplete. This lookup does not inspect a live beast.'
    return row.name or 'Beast',table.concat(lines,'\n')
end
function F.OpenBeastSearch(text)
    if InCombatLockdown() then F.Print('Search beasts after combat.');return end
    if not F.beastSearchPanel then
        local p=CreateFrame('Frame','HunterToolsBeastSearch',UIParent,'BackdropTemplate');F.beastSearchPanel=p
        p:SetSize(620,470);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        table.insert(UISpecialFrames,'HunterToolsBeastSearch')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        local title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');title:SetPoint('TOPLEFT',24,-24);title:SetText('Search beasts by name')
        p.input=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.input:SetSize(425,26);p.input:SetPoint('TOPLEFT',30,-60);p.input:SetAutoFocus(false);p.input:SetMaxLetters(100);p.input:SetText('')
        p.status=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');p.status:SetPoint('TOPLEFT',24,-100);p.status:SetText('Enter all or part of a beast name, then press Search.')
        p.rows={};p.matches={};p.page=1
        local function render()
            local count=#p.matches;local pages=math.max(1,math.ceil(count/10))
            p.status:SetText(count..' matches | Page '..p.page..' / '..pages..' | Click a beast for details')
            for i,b in ipairs(p.rows) do
                local match=p.matches[(p.page-1)*10+i];b:SetShown(match~=nil)
                if match then
                    local r=match.record;b.npcID=match.id
                    b:SetText(r.name..' - '..(r.family or '?')..' - '..(r.zone or 'Location unknown')..' [ID '..match.id..']')
                else b.npcID=nil end
            end
        end
        local function search()
            if InCombatLockdown() then F.Print('Search beasts after combat.');return end
            p.input:ClearFocus();p.matches=F.SearchBeasts(p.input:GetText());p.page=1;render()
        end
        p.search=search
        local go=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');go:SetSize(110,26);go:SetPoint('LEFT',p.input,'RIGHT',12,0);go:SetText('Search');go:SetScript('OnClick',search)
        p.input:SetScript('OnEnterPressed',search);p.input:SetScript('OnEscapePressed',function(self) self:ClearFocus();p:Hide() end)
        for i=1,10 do
            local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.rows[i]=b
            b:SetSize(565,26);b:SetPoint('TOPLEFT',24,-123-(i-1)*28)
            local caption=b:GetFontString();if caption then caption:SetWidth(545);caption:SetWordWrap(false) end
            b:SetScript('OnClick',function() if b.npcID then F.OpenBeastRecord(b.npcID) end end)
        end
        local prev=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.previous=prev;prev:SetSize(120,26);prev:SetPoint('BOTTOMLEFT',24,24);prev:SetText('Previous')
        prev:SetScript('OnClick',function() p.page=math.max(1,p.page-1);render() end)
        local nextPage=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.nextPage=nextPage;nextPage:SetSize(120,26);nextPage:SetPoint('BOTTOMRIGHT',-24,24);nextPage:SetText('Next')
        nextPage:SetScript('OnClick',function() p.page=math.min(math.max(1,math.ceil(#p.matches/10)),p.page+1);render() end)
    end
    local p=F.beastSearchPanel
    if text then p.input:SetText(text);p.search() end
    if F.beastDetailPanel then F.beastDetailPanel:Hide() end
    p:Show()
end
