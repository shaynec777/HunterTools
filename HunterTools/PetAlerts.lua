local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...);if not ok or not safe(a) then return end
    if not safe(b) then b=nil end
    return a,b
end
local function number(v) return type(v)=='number' and v==v and v>=0 and v<1e12 end
function F.PetAlertSettings()
    if type(F.db.petAlerts)~='table' then F.db.petAlerts={} end
    local s=F.db.petAlerts
    if type(s.enabled)~='boolean' then s.enabled=true end
    for _,kind in ipairs({'low','dead'}) do
        if type(s[kind])~='table' then s[kind]={} end
        local row=s[kind]
        for key,default in pairs({enabled=true,banner=true,chat=false,sound=true}) do
            if type(row[key])~='boolean' then row[key]=default end
        end
        if not number(row.repeatSeconds) or row.repeatSeconds>600 then row.repeatSeconds=kind=='low' and 15 or 0 end
    end
    if not number(s.threshold) or s.threshold<1 or s.threshold>95 then s.threshold=35 end
    return s
end
local function hideNativeWarning()
    if F.petLowHealthVisual then F.petLowHealthVisual:Hide() end
end
function F.ResetPetAlerts() F.petAlertRuntime={};hideNativeWarning() end
function F.UpdateNativePetHealthWarning(settings)
    if not settings.low.banner then return end
    if not (C_CurveUtil and C_CurveUtil.CreateCurve and UnitHealthPercent) then return end
    local ok=pcall(function()
        if not F.petLowHealthVisual then
            local p=CreateFrame('Frame',nil,UIParent)
            p:SetSize(760,80);p:SetPoint('TOP',UIParent,'TOP',0,-170)
            p:SetFrameStrata('HIGH');p:EnableMouse(false)
            p.text=p:CreateFontString(nil,'OVERLAY','GameFontNormalHuge')
            p.text:SetAllPoints();p.text:SetText('PET HEALTH LOW - MEND PET!')
            p.text:SetTextColor(1,0.18,0.12);p:Hide()
            F.petLowHealthVisual=p
        end
        local p=F.petLowHealthVisual
        if p.threshold~=settings.threshold then
            local curve=C_CurveUtil.CreateCurve()
            if Enum and Enum.LuaCurveType then curve:SetType(Enum.LuaCurveType.Linear) end
            local threshold=settings.threshold/100
            curve:AddPoint(0,1);curve:AddPoint(threshold,1)
            -- A tiny linear transition avoids ambiguous step-curve boundaries.
            curve:AddPoint(threshold+0.000001,0);curve:AddPoint(1,0)
            p.curve=curve;p.threshold=settings.threshold
        end
        local alpha=UnitHealthPercent('pet',true,p.curve)
        -- Only the native renderer consumes this result. Do not branch on secrets.
        if safe(alpha) and (not number(alpha) or alpha>1) then return end
        local tooFar=F.PetHealRangeWarning and F.PetHealRangeWarning(true)
        p.text:SetText(tooFar and 'PET HEALTH LOW - OUT OF RANGE TO MEND PET!' or 'PET HEALTH LOW - MEND PET!')
        p.text:SetAlpha(alpha);p:Show()
    end)
    F.petAlertDiagnostics=F.petAlertDiagnostics or {publicReads=0,unavailableReads=0}
    F.petAlertDiagnostics.nativeVisualStatus=ok and 'Native visual requested (visibility evaluated by client)' or 'Native visual API failed'
    if not ok then hideNativeWarning() end
end
function F.ShowPetAlert(kind,percent,test)
    local s=F.PetAlertSettings()[kind]
    local name=query(UnitName,'pet')
    if type(name)~='string' or name=='' then name='Your pet' end
    local message=kind=='dead' and (name..' is dead!') or (name..(' has low health (%d%%)!'):format(math.floor(percent or 25)))
    if test then message=message..' (Test)' end
    local chat=s.chat
    if s.banner then
        if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame,message,{r=1,g=0.2,b=0.1},5)
        else chat=true end
    end
    if chat then F.Print(message) end
    if s.sound then
        local ok,played=false,false
        if PlaySound then ok,played=pcall(PlaySound,(SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959,'Master') end
        if test and (not ok or played==false) then F.Print('The client could not play the pet warning sound.') end
    end
    if test and not s.banner and not s.chat and not s.sound then F.Print('All outputs for this pet warning are disabled.') end
end
local function healthValue(fn,...)
    if type(fn)~='function' then return nil,'API missing' end
    local ok,value=pcall(fn,...)
    if not ok then return nil,'API error' end
    if not safe(value) then return nil,'restricted' end
    if not number(value) then return nil,'not a valid number' end
    return value,'readable'
end
local function petHealthPercent()
    -- Native percentage can be public even when raw health cannot be inspected.
    -- Never compare, calculate with, or stringify a restricted return value.
    local curve=CurveConstants and CurveConstants.ScaleTo100
    local percent,percentStatus=healthValue(UnitHealthPercent,'pet',true,curve)
    if percent and not curve then percent=percent*100 end
    if percent and percent>0 and percent<=100 then return percent,'native percentage' end
    local health,healthStatus=healthValue(UnitHealth,'pet')
    local maximum,maximumStatus=healthValue(UnitHealthMax,'pet')
    if health and maximum and maximum>0 and health>0 and health<=maximum then
        return health/maximum*100,'raw health calculation'
    end
    return nil,('Percentage: %s; current health: %s; maximum health: %s.'):format(percentStatus,healthStatus,maximumStatus)
end
function F.CheckPetAlerts()
    hideNativeWarning()
    if not F.db then return end
    local s=F.PetAlertSettings()
    if not s.enabled then F.ResetPetAlerts();return end
    local _,class=query(UnitClass,'player');if class~='HUNTER' then return end
    local exists=query(UnitExists,'pet')
    if exists==false then F.ResetPetAlerts();return end
    if exists~=true then return end
    local r=F.petAlertRuntime or {};F.petAlertRuntime=r
    local guid=query(UnitGUID,'pet')
    if type(guid)=='string' and guid~=r.guid then F.ResetPetAlerts();r=F.petAlertRuntime;r.guid=guid end
    local now=GetTime()
    local function notify(kind,percent)
        local settings=s[kind]
        if not settings.enabled then r[kind]=nil;return end
        local last=r[kind]
        if not last or (settings.repeatSeconds>0 and now-last>=settings.repeatSeconds) then
            F.ShowPetAlert(kind,percent);r[kind]=now
            F.petAlertDiagnostics=F.petAlertDiagnostics or {publicReads=0,unavailableReads=0}
            F.petAlertDiagnostics.lastAlert=kind
        end
    end
    local dead=query(UnitIsDeadOrGhost,'pet')
    if dead==true then r.low=nil;notify('dead');return end
    if dead~=false then return end
    r.dead=nil
    if not s.low.enabled then r.low=nil;return end
    local percent,source=petHealthPercent()
    F.petAlertDiagnostics=F.petAlertDiagnostics or {publicReads=0,unavailableReads=0}
    local diagnostics=F.petAlertDiagnostics
    if not percent then
        diagnostics.unavailableReads=diagnostics.unavailableReads+1
        diagnostics.lastHealthStatus=source
        F.UpdateNativePetHealthWarning(s)
        return
    end
    diagnostics.publicReads=diagnostics.publicReads+1
    diagnostics.lastHealthStatus=('Readable health: %.1f%% (%s)'):format(percent,source)
    diagnostics.minimumPercent=math.min(diagnostics.minimumPercent or 100,percent)
    if percent<=s.threshold then notify('low',percent)
    elseif percent>=math.min(100,s.threshold+5) then r.low=nil end
end
function F.DebugPetAlerts()
    F.CheckPetAlerts()
    local s=F.PetAlertSettings();local d=F.petAlertDiagnostics or {}
    F.Print(('Pet alerts: master=%s; low=%s; threshold=%g%%; banner=%s; chat=%s; sound=%s; repeat=%gs.'):format(tostring(s.enabled),tostring(s.low.enabled),s.threshold,tostring(s.low.banner),tostring(s.low.chat),tostring(s.low.sound),s.low.repeatSeconds))
    F.Print(('Since reload: readable health checks=%d; unavailable checks=%d; lowest readable health=%s; last alert=%s.'):format(d.publicReads or 0,d.unavailableReads or 0,d.minimumPercent and ('%.1f%%'):format(d.minimumPercent) or 'none',d.lastAlert or 'none'))
    F.Print(d.lastHealthStatus or 'No living-pet health reading recorded yet.')
    F.Print(d.nativeVisualStatus or 'Native visual has not been requested.')
end
function F.OpenPetAlertSettings()
    if InCombatLockdown() then F.Print('Open pet warning settings after combat.');return end
    F.HideConfigPages()
    local settings=F.PetAlertSettings()
    if not F.petAlertPanel then
        local p=CreateFrame('Frame','HunterToolsPetAlerts',UIParent,'BackdropTemplate');F.petAlertPanel=p
        p:SetSize(660,570);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        table.insert(UISpecialFrames,'HunterToolsPetAlerts')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        local function label(message,x,y,width,font)
            local t=p:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall');t:SetPoint('TOPLEFT',x,y);t:SetWidth(width or 590);t:SetJustifyH('LEFT');t:SetText(message);return t
        end
        label('Pet health and death warnings',28,-26,590,'GameFontNormalLarge')
        p.checks={}
        local function check(key,message,x,y,get,set)
            local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',x,y);p.checks[key]={button=c,get=get}
            local t=c:CreateFontString(nil,'OVERLAY','GameFontHighlight');t:SetPoint('LEFT',c,'RIGHT',2,0);t:SetText(message)
            c:SetScript('OnClick',function() set(c:GetChecked() and true or false);F.ResetPetAlerts() end)
        end
        check('enabled','Enable pet health / death warnings',24,-65,function() return F.PetAlertSettings().enabled end,function(v) F.PetAlertSettings().enabled=v end)
        local function edit(x,y,get,set,minimum,maximum)
            local e=CreateFrame('EditBox',nil,p,'InputBoxTemplate');e:SetPoint('TOPLEFT',x,y);e:SetSize(70,25);e:SetAutoFocus(false);e:SetMaxLetters(6)
            local function save()
                local value=tonumber(e:GetText())
                if value and value==value and value>=minimum and value<=maximum then set(value);F.ResetPetAlerts()
                else F.Print(('Enter a value from %g to %g.'):format(minimum,maximum)) end
                e:SetText(tostring(get()));e:ClearFocus()
            end
            e:SetScript('OnEnterPressed',save)
            e:SetScript('OnEditFocusLost',function() if e:GetText()~=tostring(get()) then save() end end)
            e:SetScript('OnEscapePressed',function() e:SetText(tostring(get()));e:ClearFocus() end)
            return e
        end
        for _,kind in ipairs({'low','dead'}) do
            local key=kind;local y=key=='low' and -115 or -285
            check(key..'Enabled',key=='low' and 'Low-health warning' or 'Pet-dead warning',24,y,function() return F.PetAlertSettings()[key].enabled end,function(v) F.PetAlertSettings()[key].enabled=v end)
            for i,spec in ipairs({{'banner','Banner'},{'chat','Chat'},{'sound','Sound'}}) do
                local field=spec[1]
                check(key..field,spec[2],36+(i-1)*190,y-40,function() return F.PetAlertSettings()[key][field] end,function(v) F.PetAlertSettings()[key][field]=v end)
            end
            label('Repeat every (seconds):',40,y-90,190)
            local input=edit(220,y-82,function() return F.PetAlertSettings()[key].repeatSeconds end,function(v) F.PetAlertSettings()[key].repeatSeconds=v end,0,600)
            p[key..'Repeat']=input
            label('0 = once per episode. Enter saves.',310,y-90,290)
        end
        label('Warn at or below (% health):',40,-247,220)
        p.threshold=edit(265,-239,function() return F.PetAlertSettings().threshold end,function(v) F.PetAlertSettings().threshold=v end,1,95)
        for i,kind in ipairs({'low','dead'}) do
            local key=kind;local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(265,27);b:SetPoint('TOPLEFT',35+(i-1)*300,-415);b:SetText(key=='low' and 'Test low-health warning' or 'Test pet-dead warning')
            b:SetScript('OnClick',function() F.ShowPetAlert(key,25,true) end)
        end
        label('Low-health Banner stays visible below your threshold when health is restricted; the client controls its visibility. Sound, chat and timed repeats require readable health. Test buttons preview outputs only. Death alerts work separately. Sound uses Master volume.',30,-460,600)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(200,27);back:SetPoint('BOTTOM',0,24);back:SetText('Back to pet settings');back:SetScript('OnClick',F.OpenPetStatusSettings)
    end
    local p=F.petAlertPanel
    for _,row in pairs(p.checks) do row.button:SetChecked(row.get()) end
    p.lowRepeat:SetText(tostring(settings.low.repeatSeconds));p.deadRepeat:SetText(tostring(settings.dead.repeatSeconds));p.threshold:SetText(tostring(settings.threshold))
    if F.FinishMenu then F.FinishMenu(p,660,570) end;p:Show()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'UNIT_HEALTH','UNIT_MAXHEALTH','UNIT_FLAGS','UNIT_PET','PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event,unit)
    if event=='PLAYER_ENTERING_WORLD' then F.ResetPetAlerts() end
    if event=='PLAYER_ENTERING_WORLD' or event=='PLAYER_REGEN_ENABLED' or (safe(unit) and (unit=='pet' or (event=='UNIT_PET' and unit=='player'))) then F.CheckPetAlerts() end
end)
