local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c,d=pcall(fn,...);if not ok then return end
    if not safe(a) then a=nil end;if not safe(b) then b=nil end
    if not safe(c) then c=nil end;if not safe(d) then d=nil end
    return a,b,c,d
end
local function num(v) return safe(v) and type(v)=='number' and v==v and math.abs(v)<1e8 end
local function text(v) return safe(v) and type(v)=='string' and #v<=100 and not v:find('[\r\n|]') and v:match('%S') and v or nil end
local function now() local n=query(GetTime);return num(n) and n or 0 end
function F.MobFinderSettings()
    if type(F.db.mobFinder)~='table' then F.db.mobFinder={} end
    local s=F.db.mobFinder
    for k,v in pairs({enabled=true,sound=true,banner=true,navigation=true,markers=true,partial=false,locked=false}) do if type(s[k])~='boolean' then s[k]=v end end
    for k,v in pairs({x=290,y=80,radius=100}) do if not num(s[k]) or math.abs(s[k])>10000 then s[k]=v end end
    s.radius=math.max(10,math.min(200,s.radius))
    if type(s.watches)~='table' then s.watches={} end
    return s
end
function F.WatchMob(name,id)
    if InCombatLockdown() then F.Print('Change Mob Finder watches after combat.');return end
    name=text(name);name=name and name:match('^%s*(.-)%s*$')
    if not name then F.Print('Enter a mob name (up to 100 characters).');return end
    local s=F.MobFinderSettings()
    for _,row in ipairs(s.watches) do if row.name:lower()==name:lower() then F.Print('Already watching '..name..'.');return end end
    if #s.watches>=8 then F.Print('Mob Finder supports eight watches; remove one first.');return end
    local row={name=name,ids={}}
    if num(id) and id>0 then row.ids[1]=id
    elseif F.SearchBeasts then
        for _,match in ipairs(F.SearchBeasts(name)) do
            if match.record.name:lower()==name:lower() and #row.ids<16 then row.ids[#row.ids+1]=match.id end
        end
    end
    s.watches[#s.watches+1]=row;s.enabled=true
    F.Print('Watching '..name..'. Detection depends on units exposed by the game.')
    F.UpdateMobFinderUI()
    return true
end
local function matches(w,name,id,s)
    if id then for _,v in ipairs(w.ids or {}) do if v==id then return true end end end
    if not name then return false end
    if s.partial then return name:lower():find(w.name:lower(),1,true)~=nil end
    return name:lower()==w.name:lower()
end
function F.MobFinderWorldPoint(mapID,x,y)
    if not num(mapID) or not num(x) or not num(y) or x<0 or x>1 or y<0 or y>1 or not CreateVector2D then return end
    local instance,pos=query(C_Map and C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(x,y))
    if not num(instance) or not pos then return end
    local wx,wy=query(pos.GetXY,pos)
    if num(wx) and num(wy) then return wx,wy,instance end
end
local function playerPosition()
    local x,y,_,instance=query(UnitPosition,'player')
    if num(x) and num(y) and num(instance) then return x,y,instance end
    local map=query(C_Map and C_Map.GetBestMapForUnit,'player')
    if not num(map) then return end
    local pos=query(C_Map and C_Map.GetPlayerMapPosition,map,'player')
    if not pos then return end
    local mx,my=query(pos.GetXY,pos)
    return F.MobFinderWorldPoint(map,mx,my)
end
function F.MobFinderRelative(x,y,instance)
    local px,py,pi=playerPosition()
    if not (num(x) and num(y) and num(px) and num(py) and num(instance) and pi==instance) then return end
    local north,west=x-px,y-py
    return north,west,math.sqrt(north*north+west*west)
end
function F.MobFinderMapPoint(found,uiMapID)
    if not found or not num(found.x) or not num(found.y) or not num(found.instance) or not num(uiMapID) or not CreateVector2D then return end
    if found.mapID==uiMapID and num(found.mapX) and num(found.mapY) then return found.mapX,found.mapY end
    local map,pos=query(C_Map and C_Map.GetMapPosFromWorldPos,found.instance,CreateVector2D(found.x,found.y),uiMapID)
    if map~=uiMapID or not pos then return end
    local x,y=query(pos.GetXY,pos)
    if num(x) and num(y) and x>=0 and x<=1 and y>=0 and y<=1 then return x,y end
end
function F.MobFinderVignettes()
    local results={};local api=C_VignetteInfo
    local map=query(C_Map and C_Map.GetBestMapForUnit,'player')
    local guids=query(api and api.GetVignettes)
    if not num(map) or type(guids)~='table' then return results end
    local s=F.MobFinderSettings()
    for _,guid in ipairs(guids) do
        if safe(guid) and type(guid)=='string' then
            local info=query(api and api.GetVignetteInfo,guid)
            if type(info)=='table' and safe(info.isDead) and info.isDead==false then
                local name=text(info.name);local object=safe(info.objectGUID) and info.objectGUID
                local id=type(object)=='string' and tonumber(object:match('^Creature%-.*%-(%d+)%-%x+$'))
                if name and id then
                    for _,watch in ipairs(s.watches) do if matches(watch,name,id,s) then
                        local pos=query(api.GetVignettePosition,guid,map)
                        if pos then
                            local mx,my=query(pos.GetXY,pos)
                            local x,y,instance=F.MobFinderWorldPoint(map,mx,my)
                            local _,_,distance=F.MobFinderRelative(x,y,instance)
                            if x and (distance and distance<=s.radius or not distance and safe(info.onMinimap) and info.onMinimap==true) then
                                results[#results+1]={name=name,id=id,guid=object,x=x,y=y,instance=instance,distance=distance,source='Live map marker',mapID=map,mapX=mx,mapY=my}
                            end
                        end
                        break
                    end end
                end
            end
        end
    end
    return results
end
local function hideNavigation()
    if F.mobFinderMiniPin then F.mobFinderMiniPin:Hide() end
    if F.mobFinderMapPin then F.mobFinderMapPin:Hide() end
    if F.mobFinderPanel then F.mobFinderPanel.arrow:Hide() end
end
function F.UpdateMobFinderNavigation(found)
    hideNavigation()
    if InCombatLockdown() or not found then return end
    local s=F.MobFinderSettings()
    local north,west,distance=F.MobFinderRelative(found.x,found.y,found.instance)
    if not distance then F.mobFinderLocationStatus='Location unavailable - alerts only';return end
    F.mobFinderLocationStatus=found.source=='Live map marker' and 'Live map marker coordinates' or 'Live coordinates available'
    local facing=query(GetPlayerFacing)
    if s.navigation and not num(facing) then F.mobFinderLocationStatus='Facing unavailable - no direction arrow' end
    if s.navigation and num(facing) and F.mobFinderPanel then
        -- World X points north and world Y west; facing increases towards west.
        local angle=math.atan2(west,north)-facing
        local p=F.mobFinderPanel;p.arrow:Show();p.arrow:SetRotation(angle)
    end
    if not s.markers then return end
    local radius=query(C_Minimap and C_Minimap.GetViewRadius)
    if Minimap and num(radius) and radius>0 and distance<=radius then
        local east,up=-west,north
        local rotate=query(GetCVar,'rotateMinimap')
        if rotate=='1' then
            if not num(facing) then return end
            east=-west*math.cos(facing)+north*math.sin(facing)
            up=north*math.cos(facing)+west*math.sin(facing)
        end
        local w,h=query(Minimap.GetWidth,Minimap),query(Minimap.GetHeight,Minimap)
        if num(w) and num(h) then
            if not F.mobFinderMiniPin then
                local p=CreateFrame('Frame',nil,Minimap);F.mobFinderMiniPin=p;p:SetSize(18,18);p:SetFrameLevel(Minimap:GetFrameLevel()+20)
                p.texture=p:CreateTexture(nil,'OVERLAY');p.texture:SetAllPoints();p.texture:SetColorTexture(1,0.7,0.05,1)
                p:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:AddLine('Mob Finder: '..(F.mobFinderNavigation and F.mobFinderNavigation.source or 'location'),1,0.8,0);GameTooltip:Show() end end)
                p:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end);p:EnableMouse(true)
            end
            local pin=F.mobFinderMiniPin;pin:ClearAllPoints();pin:SetPoint('CENTER',Minimap,'CENTER',east/radius*w/2,up/radius*h/2);pin:Show()
            -- Local visual pulse only: do not broadcast minimap pings to the group.
            pin:SetAlpha(0.6+0.4*math.abs(math.sin(now()*3)))
        end
    end
    local map=WorldMapFrame
    if map and query(map.IsShown,map) and map.GetCanvas and map.GetMapID then
        local canvas=query(map.GetCanvas,map);local mapID=query(map.GetMapID,map)
        local x,y=F.MobFinderMapPoint(found,mapID)
        if canvas and x then
            local w,h=query(canvas.GetWidth,canvas),query(canvas.GetHeight,canvas)
            if num(w) and num(h) then
                if not F.mobFinderMapPin then
                    local p=CreateFrame('Frame',nil,canvas);F.mobFinderMapPin=p;p:SetSize(18,18);p:SetFrameLevel(canvas:GetFrameLevel()+20)
                    p.texture=p:CreateTexture(nil,'OVERLAY');p.texture:SetAllPoints();p.texture:SetColorTexture(1,0.7,0.05,1)
                end
                local pin=F.mobFinderMapPin;pin:SetParent(canvas);pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',x*w,-y*h);pin:SetAlpha(0.6+0.4*math.abs(math.sin(now()*3)));pin:Show()
            end
        end
    end
end
local pendingTargetPing
function F.RequestMobFinderTargetPing(name,isPlayer)
    if InCombatLockdown() or not text(name) then return end
    pendingTargetPing={name=name,isPlayer=isPlayer,expires=now()+1.5}
    F.UpdateMobFinderTargetPing()
end
function F.UpdateMobFinderTargetPing()
    local ping=F.mobFinderTargetPing
    if InCombatLockdown() then pendingTargetPing=nil;if ping then ping:Hide() end;return end
    if ping and ping:IsShown() then
        local guid=query(UnitGUID,'target')
        if guid~=ping.targetGUID or now()>=ping.expires or not query(ping.plate.IsShown,ping.plate) then ping:Hide()
        else ping:SetAlpha(0.35+0.65*math.abs(math.sin(now()*8))) end
    end
    if not pendingTargetPing then return end
    local pending=pendingTargetPing
    if now()>pending.expires then
        pendingTargetPing=nil
        F.Print('Target ping: matching target or visible nameplate unavailable. Enable nameplates to see the on-screen ping.')
        return
    end
    local name=query(UnitName,'target');local guid=query(UnitGUID,'target')
    if pending.isPlayer and F.PlayerFinderName then name=F.PlayerFinderName('target') end
    local full,realm=query(UnitFullName,'target')
    if type(full)=='string' and type(realm)=='string' and realm~='' then full=full..'-'..realm:gsub('%s','') end
    local wanted=pending.name:gsub('%s',''):lower()
    local nameMatch=(type(name)=='string' and name:gsub('%s',''):lower()==wanted) or (type(full)=='string' and full:gsub('%s',''):lower()==wanted)
    local eligible=pending.isPlayer and query(UnitIsPlayer,'target')==true or not pending.isPlayer and query(UnitPlayerControlled,'target')==false
    if not nameMatch or not eligible or type(guid)~='string' or query(UnitIsDeadOrGhost,'target')~=false then return end
    local plate=query(C_NamePlate and C_NamePlate.GetNamePlateForUnit,'target')
    if not plate or query(plate.IsForbidden,plate)==true or query(plate.IsShown,plate)~=true then return end
    if not ping then
        ping=CreateFrame('Frame',nil,UIParent,'BackdropTemplate');F.mobFinderTargetPing=ping
        ping:SetFrameStrata('TOOLTIP');ping:SetSize(100,42);ping:EnableMouse(false)
        ping:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=3})
        ping:SetBackdropColor(1,0.7,0,0.12);ping:SetBackdropBorderColor(1,0.8,0.05,1)
        ping.label=ping:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');ping.label:SetPoint('BOTTOM',ping,'TOP',0,4);ping.label:SetText('FOUND')
    end
    ping:Hide();ping:ClearAllPoints()
    local ok=pcall(ping.SetPoint,ping,'CENTER',plate,'CENTER',0,0)
    if not ok then return end
    ping.plate=plate;ping.targetGUID=guid;ping.expires=now()+3;ping:SetAlpha(1);ping:Show();pendingTargetPing=nil
end
function F.ResolveFinderPlayerUnit(popup)
    if InCombatLockdown() or type(popup.detectedGUID)~='string' then return end
    local units={popup.detectedUnit or 'target'}
    for i=1,40 do units[#units+1]='nameplate'..i end
    units[#units+1]='target';units[#units+1]='mouseover'
    for _,unit in ipairs(units) do
        if query(UnitGUID,unit)==popup.detectedGUID and query(UnitExists,unit)==true and query(UnitIsPlayer,unit)==true and query(UnitIsDeadOrGhost,unit)==false then return unit end
    end
end
function F.PrepareFinderPlayerTarget(popup)
    if InCombatLockdown() then return end
    local unit=F.ResolveFinderPlayerUnit(popup)
    local b=popup.target
    if unit then
        b:SetAttribute('type','target');b:SetAttribute('unit',unit);b:SetAttribute('macrotext',nil)
    elseif popup.mobName:find(' ',1,true) then
        -- A valid captured full name remains usable after a mouseover token disappears.
        b:SetAttribute('type','macro');b:SetAttribute('unit',nil);b:SetAttribute('macrotext','/targetexact '..popup.mobName)
    else
        b:SetAttribute('type',nil);b:SetAttribute('unit',nil);b:SetAttribute('macrotext',nil)
    end
    popup.targetUnavailable=not unit and not popup.mobName:find(' ',1,true)
end
function F.ShowFinderTargetPopup(found,isPlayer)
    if InCombatLockdown() or not found or not text(found.name) or found.name:find('[%[%]]') then return end
    local key=isPlayer and 'playerFinderTargetPopup' or 'mobFinderTargetPopup'
    if not F[key] then
        local p=CreateFrame('Frame',isPlayer and 'HunterToolsPlayerFinderTarget' or 'HunterToolsMobFinderTarget',UIParent,'SecureHandlerStateTemplate,BackdropTemplate');F[key]=p
        p:SetSize(350,145);p:SetPoint('CENTER',UIParent,'CENTER',0,140);p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=18});p:SetBackdropColor(0.025,0.035,0.03,1)
        p.title=F.MenuText(p,isPlayer and 'Player detected' or 'Mob detected',20,-20,310,'GameFontNormalLarge')
        p.message=F.MenuText(p,'',20,-49,310);p.message:SetHeight(36)
        local b=CreateFrame('Button',nil,p,'SecureActionButtonTemplate,UIPanelButtonTemplate');p.target=b
        b:SetSize(145,27);b:SetPoint('BOTTOMLEFT',20,18);b:SetText('Target');b:RegisterForClicks('LeftButtonUp');b:SetAttribute('useOnKeyDown',false);b:SetAttribute('type','macro')
        b:SetScript('PreClick',function(self)
            if InCombatLockdown() or not p.isPlayer then return end
            -- Revalidate the GUID at click time: nameplate tokens can be recycled.
            F.PrepareFinderPlayerTarget(p)
        end)
        b:SetScript('PostClick',function()
            if InCombatLockdown() then return end
            p:Hide()
            if p.targetUnavailable then F.Print('Player Finder: no current unit reference or captured surname is available for this player. Try their full name in /targetexact.');return end
            F.RequestMobFinderTargetPing(p.mobName,p.isPlayer)
        end)
        if SecureHandlerWrapScript then SecureHandlerWrapScript(b,'OnClick',p,[[return nil, true]],[[self:GetParent():Hide()]]) end
        local close=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.dismiss=close;close:SetSize(145,27);close:SetPoint('BOTTOMRIGHT',-20,18);close:SetText('Dismiss')
        close:SetScript('OnClick',function() if not InCombatLockdown() then p:Hide() end end)
        p:SetAttribute('_onstate-combat',[[if newstate == 'combat' then self:Hide() end]])
        if RegisterStateDriver then RegisterStateDriver(p,'combat','[combat] combat; peace') end
        p:Hide()
    end
    local p=F[key]
    p.isPlayer=isPlayer;p.mobName=found.name;p.detectedGUID=found.guid;p.detectedUnit=found.unit;p.targetUnavailable=false
    p.message:SetText(found.name..'\nClick Target to select by exact name. No attack.')
    if isPlayer then
        F.PrepareFinderPlayerTarget(p)
        p.message:SetText(found.name..'\nClick Target to select this detected player. No attack.')
    else
        p.target:SetAttribute('unit',nil);p.target:SetAttribute('type','macro');p.target:SetAttribute('macrotext','/targetexact '..found.name)
    end
    p.expires=now()+15;p:Show()
end
function F.ShowMobFinderTarget(found) F.ShowFinderTargetPopup(found,false) end
local lastSeen={};local lastByID={};local trackedUnits={}
function F.ScanMobFinder()
    if not F.db then return end
    local s=F.MobFinderSettings()
    local popup=F.mobFinderTargetPopup
    if popup and not InCombatLockdown() and (not s.enabled or #s.watches==0 or now()>=(popup.expires or 0)) then popup:Hide() end
    if InCombatLockdown() or not s.enabled or #s.watches==0 or query(UnitIsDeadOrGhost,'player')==true then
        F.mobFinderFound=nil;F.mobFinderNavigation=nil;hideNavigation();F.UpdateMobFinderUI();return
    end
    local candidates={};local units={'target','mouseover'}
    for i=1,40 do units[#units+1]='nameplate'..i end
    for unit in pairs(trackedUnits) do units[#units+1]=unit end
    local seen={}
    for _,unit in ipairs(units) do
        if not seen[unit] and query(UnitExists,unit)==true and query(UnitIsPlayer,unit)==false and query(UnitPlayerControlled,unit)==false and query(UnitIsDeadOrGhost,unit)==false then
            seen[unit]=true
            local name=text(query(UnitName,unit));local guid=query(UnitGUID,unit)
            if name and type(guid)=='string' then
                local id=tonumber(guid:match('^Creature%-.*%-(%d+)%-%x+$'))
                if id then
                    for _,watch in ipairs(s.watches) do if matches(watch,name,id,s) then
                        local x,y,_,instance=query(UnitPosition,unit)
                        local _,_,distance=F.MobFinderRelative(x,y,instance)
                        if not distance or distance<=s.radius then candidates[guid]={name=name,guid=guid,id=id,x=x,y=y,instance=instance,distance=distance,source='Detected'} end
                        break
                    end end
                end
            end
        end
    end
    for _,c in ipairs(F.MobFinderVignettes()) do if not candidates[c.guid] or not candidates[c.guid].distance then candidates[c.guid]=c end end
    -- Try location fallback for both database watches and actually detected NPC IDs.
    -- A nameplate sighting without coordinates must not suppress this lookup.
    local locationIDs={}
    for _,watch in ipairs(s.watches) do for _,id in ipairs(watch.ids or {}) do locationIDs[id]=watch.name end end
    for _,c in pairs(candidates) do if not c.distance then locationIDs[c.id]=c.name end end
    F.mobFinderLocationStatus='No readable mob coordinates'
    for id,name in pairs(locationIDs) do
        local x,y,distance=query(ClosestUnitPosition,id)
        if num(x) and num(y) and num(distance) and distance>=0 and distance<=s.radius then
            local _,_,_,instance=query(UnitPosition,'player')
            local existing=false
            for _,c in pairs(candidates) do if c.id==id and c.distance then existing=true;break end end
            if not existing then candidates['id:'..id]={name=name,id=id,guid='id:'..id,x=x,y=y,instance=instance,distance=distance,source='Client location (alive status unknown)'} end
        end
    end
    local best,popupCandidate;local clock=now()
    for key,c in pairs(candidates) do
        local prior=lastSeen[key]
        local fallbackSeen=lastSeen['id:'..c.id]
        if key=='id:'..c.id then prior=lastByID[c.id] or prior
        elseif fallbackSeen and (not prior or fallbackSeen>prior) then prior=fallbackSeen end
        if not prior or clock-prior>30 then
            local message='Mob Finder: '..c.name..' '..((c.source=='Detected' or c.source=='Live map marker') and 'detected nearby' or 'location reported nearby')..(c.distance and (' (~%d yd)'):format(c.distance) or '')
            F.Print(message)
            if s.banner and RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame,message,{r=1,g=0.8,b=0.1}) end
            if s.sound then query(PlaySound,8959,'Master') end
            if not popupCandidate or (c.distance or math.huge)<(popupCandidate.distance or math.huge) then popupCandidate=c end
        end
        lastSeen[key]=clock;lastByID[c.id]=clock
        if not best or (c.distance or math.huge)<(best.distance or math.huge) then best=c end
    end
    for key,at in pairs(lastSeen) do if clock-at>300 then lastSeen[key]=nil end end
    for id,at in pairs(lastByID) do if clock-at>300 then lastByID[id]=nil end end
    if popupCandidate then F.ShowMobFinderTarget(popupCandidate) end
    F.mobFinderFound=best
    F.mobFinderNavigation=best
    F.UpdateMobFinderNavigation(best);F.UpdateMobFinderUI()
end
function F.UpdateMobFinderUI()
    local p=F.mobFinderPanel;if not p then return end
    local s=F.MobFinderSettings();local found=F.mobFinderFound
    p.pause:SetText(s.enabled and 'Pause' or 'Resume')
    p.status:SetText(InCombatLockdown() and 'Combat: detection paused' or not s.enabled and 'Paused' or #s.watches==0 and 'Enter a mob name to start watching.' or found and (found.name..(found.distance and (' - ~%d yd'):format(found.distance) or '')..'\n'..(F.mobFinderLocationStatus or found.source)) or 'Watching - no matching mob currently detected')
    for i,b in ipairs(p.rows) do local row=s.watches[i];b:SetText(row and (row.name..'  [remove]') or '');b:SetShown(row~=nil) end
end
function F.OpenMobFinder()
    if InCombatLockdown() then F.Print('Open Mob Finder after combat.');return end
    local s=F.MobFinderSettings()
    if not F.mobFinderPanel then
        local p=CreateFrame('Frame','HunterToolsMobFinder',UIParent,'BackdropTemplate');F.mobFinderPanel=p
        p:SetSize(430,510);p:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y);p:SetClampedToScreen(true);p:SetMovable(true);p:EnableMouse(true);p:RegisterForDrag('LeftButton')
        p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=18});p:SetBackdropColor(0.035,0.047,0.044,1)
        p:SetScript('OnDragStart',function() if IsShiftKeyDown() and not InCombatLockdown() and not s.locked then p:StartMoving() end end)
        p:SetScript('OnDragStop',function() p:StopMovingOrSizing();local x,y=p:GetCenter();local px,py=UIParent:GetCenter();if num(x) and num(y) and num(px) and num(py) then s.x=x-px;s.y=y-py end end)
        table.insert(UISpecialFrames,'HunterToolsMobFinder')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        F.MenuText(p,'Mob Finder',22,-22,365,'GameFontNormalLarge')
        F.MenuText(p,'All classes. Shift-drag to move. Closing keeps watching.',22,-49,385)
        p.input=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.input:SetSize(280,25);p.input:SetPoint('TOPLEFT',28,-75);p.input:SetAutoFocus(false);p.input:SetMaxLetters(100)
        local function btn(label,x,y,w,action) local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(w,25);b:SetPoint('TOPLEFT',x,y);b:SetText(label);b:SetScript('OnClick',action);return b end
        local function add() if F.WatchMob(p.input:GetText()) then p.input:SetText('');p.input:ClearFocus() end end
        btn('Watch',320,-75,88,add);p.input:SetScript('OnEnterPressed',add);p.input:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        btn('Watch target',22,-111,125,function() if not InCombatLockdown() and query(UnitIsPlayer,'target')==false and query(UnitPlayerControlled,'target')==false then F.WatchMob(query(UnitName,'target'),F.BeastNPCID and F.BeastNPCID('target')) end end)
        p.pause=btn('Pause',157,-111,115,function() if InCombatLockdown() then return end;s.enabled=not s.enabled;F.ScanMobFinder() end)
        btn('Stop / clear',282,-111,125,function() if InCombatLockdown() then return end;s.watches={};lastSeen={};lastByID={};F.ScanMobFinder() end)
        p.status=F.MenuText(p,'',22,-150,330);p.status:SetHeight(44)
        p.arrow=p:CreateTexture(nil,'OVERLAY');p.arrow:SetSize(34,34);p.arrow:SetPoint('TOPRIGHT',-25,-153);p.arrow:SetTexture('Interface\\Minimap\\MinimapArrow');p.arrow:Hide()
        p.rows={}
        for i=1,8 do local index=i;p.rows[i]=btn('',22,-200-(i-1)*25,385,function() if InCombatLockdown() then return end;table.remove(s.watches,index);F.ScanMobFinder() end) end
        local function check(label,x,y,key)
            local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',x,y);c:SetChecked(s[key]);F.MenuText(c,label,30,-7,150)
            c:SetScript('OnClick',function(self) if InCombatLockdown() then self:SetChecked(s[key]);return end;s[key]=self:GetChecked() and true or false;F.ScanMobFinder() end)
        end
        check('Sound',20,-405,'sound');check('Screen alert',215,-405,'banner')
        check('Direction arrow',20,-435,'navigation');check('Map markers',215,-435,'markers')
        check('Partial names',20,-465,'partial');check('Lock position',215,-465,'locked')
        p:SetScript('OnHide',function() p.input:ClearFocus() end)
    end
    F.UpdateMobFinderUI();F.mobFinderPanel:Show();F.ScanMobFinder()
end
function F.DebugMobFinder()
    if InCombatLockdown() then F.Print('Check Mob Finder after combat.');return end
    F.ScanMobFinder()
    local found=F.mobFinderFound
    F.Print('Mob Finder: '..(found and found.name or 'no current detection')..'; '..(F.mobFinderLocationStatus or 'no navigation data'))
    F.Print('Location API: '..(type(ClosestUnitPosition)=='function' and 'available' or 'missing')..'; minimap radius API: '..(C_Minimap and type(C_Minimap.GetViewRadius)=='function' and 'available' or 'missing'))
    local nav=F.mobFinderNavigation
    F.Print('Navigation source: '..(nav and nav.source or 'none')..'; map markers API: '..(C_VignetteInfo and 'available' or 'missing'))
    if found and type(ClosestUnitPosition)=='function' then
        local ok,x,y,d=pcall(ClosestUnitPosition,found.id)
        local function classify(v) if not safe(v) then return 'restricted' end;if num(v) then return 'readable' end;return 'unavailable' end
        F.Print(ok and ('Mob location: X '..classify(x)..', Y '..classify(y)..', distance '..classify(d)) or 'Mob location lookup failed')
    end
end
local driver=CreateFrame('Frame')
for _,event in ipairs({'NAME_PLATE_UNIT_ADDED','NAME_PLATE_UNIT_REMOVED','PLAYER_TARGET_CHANGED','UPDATE_MOUSEOVER_UNIT','PLAYER_ENTERING_WORLD','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED'}) do pcall(driver.RegisterEvent,driver,event) end
local elapsed=0
-- Events only maintain token membership; scans are batched at two per second.
driver:SetScript('OnEvent',function(_,event,unit)
    if event=='NAME_PLATE_UNIT_ADDED' and text(unit) then trackedUnits[unit]=true
    elseif event=='NAME_PLATE_UNIT_REMOVED' and text(unit) then trackedUnits[unit]=nil
    elseif event=='PLAYER_ENTERING_WORLD' then trackedUnits={};F.mobFinderFound=nil;F.mobFinderNavigation=nil;hideNavigation()
    elseif event=='PLAYER_REGEN_DISABLED' then F.mobFinderFound=nil;F.mobFinderNavigation=nil;hideNavigation() end
    elapsed=0.5
end)
driver:SetScript('OnUpdate',function(_,dt) F.UpdateMobFinderTargetPing();elapsed=elapsed+dt;if elapsed>=0.5 then elapsed=0;if F.db then F.ScanMobFinder() end end end)
F.mobFinderDriver=driver
