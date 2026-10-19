local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...);if not ok then return end
    if not safe(a) then a=nil end;if not safe(b) then b=nil end
    return a,b
end
local function clock() return query(GetTime) or 0 end
local function nameText(v)
    if not safe(v) or type(v)~='string' or #v>100 or v:find('[\r\n|/%[%]]') then return end
    v=v:match('^%s*(.-)%s*$');if v=='' then return end
    return v:gsub('%s+',' ')
end
function F.PlayerFinderSettings()
    if type(F.db.playerFinder)~='table' then F.db.playerFinder={} end
    local s=F.db.playerFinder
    for k,v in pairs({enabled=true,sound=true,banner=true,partial=false}) do if type(s[k])~='boolean' then s[k]=v end end
    for k,v in pairs({x=-290,y=80}) do if type(s[k])~='number' or s[k]~=s[k] or math.abs(s[k])>10000 then s[k]=v end end
    if type(s.watches)~='table' then s.watches={} end
    return s
end
function F.PlayerFinderName(unit)
    -- Forever exposes first name + surname in these two returns, not a realm suffix.
    local first,last=query(UnitNameUnmodified,unit)
    if not first then first,last=query(UnitName,unit) end
    first=nameText(first);last=nameText(last)
    if not first then return end
    if last and first:sub(-#last-1):lower()~=(' '..last):lower() then return first..' '..last end
    return first
end
function F.WatchPlayer(value)
    if InCombatLockdown() then F.Print('Change Player Finder watches after combat.');return end
    local name=nameText(value)
    if not name then F.Print('Enter an exact character name.');return end
    local s=F.PlayerFinderSettings()
    for _,v in ipairs(s.watches) do if v:lower()==name:lower() then F.Print('Already watching '..name..'.');return end end
    if #s.watches>=8 then F.Print('Player Finder supports eight names; remove one first.');return end
    s.watches[#s.watches+1]=name;s.enabled=true;F.Print('Player Finder: watching '..name..'.');F.UpdatePlayerFinderUI();return true
end
local lastSeen={}
function F.ScanPlayerFinder()
    if not F.db then return end
    local s=F.PlayerFinderSettings();local popup=F.playerFinderTargetPopup
    if not InCombatLockdown() and popup and (not s.enabled or #s.watches==0 or clock()>=(popup.expires or 0)) then popup:Hide() end
    if InCombatLockdown() or not s.enabled or #s.watches==0 then F.playerFinderFound=nil;F.UpdatePlayerFinderUI();return end
    local units={}
    for i=1,40 do units[#units+1]='nameplate'..i end
    units[#units+1]='target';units[#units+1]='mouseover'
    local found,unique={},{}
    for _,unit in ipairs(units) do
        if query(UnitExists,unit)==true and query(UnitIsPlayer,unit)==true and query(UnitIsUnit,unit,'player')~=true and query(UnitIsDeadOrGhost,unit)==false then
            local full=F.PlayerFinderName(unit);local guid=query(UnitGUID,unit)
            if full and type(guid)=='string' and not unique[guid] then
                for _,watch in ipairs(s.watches) do
                    local match=s.partial and full:lower():find(watch:lower(),1,true)~=nil or not s.partial and watch:lower()==full:lower()
                    if match then unique[guid]=true;found[#found+1]={name=full,guid=guid,unit=unit};break end
                end
            end
        end
    end
    table.sort(found,function(a,b) return a.name<b.name end)
    local popupChoice
    for _,player in ipairs(found) do
        if not lastSeen[player.guid] or clock()-lastSeen[player.guid]>30 then
            local message='Player Finder: '..player.name..' detected nearby'
            F.Print(message)
            if s.sound then query(PlaySound,8959,'Master') end
            if s.banner and RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame,message,{r=1,g=0.8,b=0.1}) end
            popupChoice=popupChoice or player
        end
        lastSeen[player.guid]=clock()
    end
    for guid,at in pairs(lastSeen) do if clock()-at>300 then lastSeen[guid]=nil end end
    F.playerFinderFound=found[1]
    if popupChoice then F.ShowFinderTargetPopup(popupChoice,true) end
    F.UpdatePlayerFinderUI()
end
function F.UpdatePlayerFinderUI()
    local p=F.playerFinderPanel;if not p then return end
    local s=F.PlayerFinderSettings();p.pause:SetText(s.enabled and 'Pause' or 'Resume')
    p.status:SetText(InCombatLockdown() and 'Combat: detection paused' or not s.enabled and 'Paused' or F.playerFinderFound and ('Detected: '..F.playerFinderFound.name) or 'Watching - no matching player currently detected')
    for i,b in ipairs(p.rows) do b:SetText(s.watches[i] and (s.watches[i]..' [remove]') or '');b:SetShown(s.watches[i]~=nil) end
end
function F.OpenPlayerFinder()
    if InCombatLockdown() then F.Print('Open Player Finder after combat.');return end
    local s=F.PlayerFinderSettings()
    if not F.playerFinderPanel then
        local p=CreateFrame('Frame','HunterToolsPlayerFinder',UIParent,'BackdropTemplate');F.playerFinderPanel=p
        p:SetSize(430,475);p:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y);p:SetClampedToScreen(true);p:SetMovable(true);p:EnableMouse(true);p:RegisterForDrag('LeftButton')
        p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=18});p:SetBackdropColor(0.035,0.047,0.044,1)
        p:SetScript('OnDragStart',function() if IsShiftKeyDown() and not InCombatLockdown() then p:StartMoving() end end)
        p:SetScript('OnDragStop',function() p:StopMovingOrSizing();local x,y=p:GetCenter();local px,py=UIParent:GetCenter();if type(x)=='number' and type(y)=='number' and type(px)=='number' and type(py)=='number' then s.x=x-px;s.y=y-py end end)
        table.insert(UISpecialFrames,'HunterToolsPlayerFinder')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        F.MenuText(p,'Player Finder',22,-22,365,'GameFontNormalLarge')
        F.MenuText(p,'Character names. Partial matching is optional. Closing keeps watching.',22,-49,385)
        local function btn(label,x,y,w,action) local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(w,25);b:SetPoint('TOPLEFT',x,y);b:SetText(label);b:SetScript('OnClick',action);return b end
        p.input=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.input:SetSize(280,25);p.input:SetPoint('TOPLEFT',28,-75);p.input:SetAutoFocus(false);p.input:SetMaxLetters(100)
        local function add() if F.WatchPlayer(p.input:GetText()) then p.input:SetText('');p.input:ClearFocus() end end
        btn('Watch',320,-75,88,add);p.input:SetScript('OnEnterPressed',add);p.input:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        btn('Watch target',22,-111,125,function() if not InCombatLockdown() and query(UnitIsPlayer,'target')==true then F.WatchPlayer(F.PlayerFinderName('target')) end end)
        p.pause=btn('Pause',157,-111,115,function() if InCombatLockdown() then return end;s.enabled=not s.enabled;F.ScanPlayerFinder() end)
        btn('Stop / clear',282,-111,125,function() if InCombatLockdown() then return end;s.watches={};lastSeen={};F.ScanPlayerFinder() end)
        p.status=F.MenuText(p,'',22,-150,385);p.status:SetHeight(36)
        p.rows={}
        for i=1,8 do local index=i;p.rows[i]=btn('',22,-192-(i-1)*25,385,function() if InCombatLockdown() then return end;table.remove(s.watches,index);F.ScanPlayerFinder() end) end
        local function check(label,x,key,y)
            local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',x,y or -402);c:SetChecked(s[key]);F.MenuText(c,label,30,-7,150)
            c:SetScript('OnClick',function(self) if InCombatLockdown() then self:SetChecked(s[key]);return end;s[key]=self:GetChecked() and true or false end)
        end
        check('Sound',20,'sound');check('Screen alert',215,'banner');check('Partial names',20,'partial',-432)
        p:SetScript('OnHide',function() p.input:ClearFocus() end)
    end
    F.playerFinderPanel:Show();F.ScanPlayerFinder()
end
local frame=CreateFrame('Frame');local elapsed=0
frame:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=0.5 then elapsed=0;F.ScanPlayerFinder() end end)
F.playerFinderDriver=frame
