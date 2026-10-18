local F={db={}}
local widgets={}
local function widget()
 local w={scripts={},shown=false,text=''}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' then return widget end;return function() end end})
 function w:SetScript(k,v) self.scripts[k]=v end
 function w:SetAlpha(v) self.alpha=v end
 function w:SetText(v) self.text=v end
 function w:GetText() return self.text end
 function w:SetChecked(v) self.checked=v end
 function w:GetChecked() return self.checked end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 widgets[#widgets+1]=w;return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={}
local now,hp,maximum,dead,exists,guid,combat=100,100,100,false,true,'pet-a',false
GetTime=function() return now end;InCombatLockdown=function() return combat end
UnitClass=function() return 'Hunter','HUNTER' end
UnitExists=function() return exists end;UnitGUID=function() return guid end
UnitName=function() return 'Wolf' end;UnitIsDeadOrGhost=function() return dead end
UnitHealth=function() return hp end;UnitHealthMax=function() return maximum end
local banners,chats,sounds={},{},0
RaidWarningFrame={};RaidNotice_AddMessage=function(_,message) banners[#banners+1]=message end
F.Print=function(message) chats[#chats+1]=message end
PlaySound=function(_,channel) assert(channel=='Master');sounds=sounds+1;return true end
F.HideConfigPages=function() if F.petAlertPanel then F.petAlertPanel:Hide() end end
F.OpenPetStatusSettings=function() end
assert(loadfile('HunterTools/PetAlerts.lua'))('test',F)
local settings=F.PetAlertSettings();assert(settings.enabled and settings.threshold==35 and settings.low.repeatSeconds==15 and settings.dead.repeatSeconds==0)
F.CheckPetAlerts();assert(#banners==0)
hp=30;F.CheckPetAlerts();assert(#banners==1 and sounds==1 and #chats==0 and banners[1]=='Wolf has low health (30%)!')
F.CheckPetAlerts();assert(#banners==1)
hp=37;F.CheckPetAlerts();hp=34;now=105;F.CheckPetAlerts();assert(#banners==1,'threshold jitter must not create a fresh episode')
hp=41;F.CheckPetAlerts();hp=34;F.CheckPetAlerts();assert(#banners==2)
now=120;F.CheckPetAlerts();assert(#banners==3)
dead=true;hp=0;F.CheckPetAlerts();assert(#banners==4 and banners[4]=='Wolf is dead!')
now=200;F.CheckPetAlerts();assert(#banners==4,'death defaults to once until revived')
dead=false;hp=100;F.CheckPetAlerts();dead=true;F.CheckPetAlerts();assert(#banners==5)
settings.dead.banner=false;settings.dead.sound=false;settings.dead.chat=true;F.ResetPetAlerts()
F.CheckPetAlerts();assert(#banners==5 and sounds==5 and chats[1]=='Wolf is dead!')
settings.dead.enabled=false;F.ResetPetAlerts();F.CheckPetAlerts();assert(#chats==1)
dead=false;hp=20;settings.low.enabled=false;F.CheckPetAlerts();assert(#banners==5)
settings.low.enabled=true;settings.low.repeatSeconds=0;combat=true;F.CheckPetAlerts();assert(#banners==6,'public health can alert in combat')
now=500;F.CheckPetAlerts();assert(#banners==6)
issecretvalue=function(v) return v=='secret' end
hp='secret';F.ResetPetAlerts();F.CheckPetAlerts();assert(#banners==6)
hp=20;dead='secret';F.CheckPetAlerts();assert(#banners==6)
dead=false;maximum=0;F.CheckPetAlerts();assert(#banners==6)
maximum=100;issecretvalue=nil;guid='pet-b';F.CheckPetAlerts();assert(#banners==7)
exists=false;F.CheckPetAlerts();assert(next(F.petAlertRuntime)==nil and #banners==7,'dismissal is not death')
exists=true;settings.enabled=false;F.CheckPetAlerts();assert(#banners==7)
combat=false;settings.threshold=0;settings.low.repeatSeconds=-1;settings.dead.repeatSeconds=601
assert(F.PetAlertSettings().threshold==35 and settings.low.repeatSeconds==15 and settings.dead.repeatSeconds==0)
F.OpenPetAlertSettings();local p=F.petAlertPanel;assert(p.shown and not p.checks.enabled.button.checked)
p.threshold:SetText('40');p.threshold.scripts.OnEnterPressed();assert(settings.threshold==40)
p.lowRepeat:SetText('30');p.lowRepeat.scripts.OnEnterPressed();assert(settings.low.repeatSeconds==30)
p.deadRepeat:SetText('10');p.deadRepeat.scripts.OnEnterPressed();assert(settings.dead.repeatSeconds==10)
p.threshold:SetText('invalid');p.threshold.scripts.OnEnterPressed();assert(settings.threshold==40 and p.threshold.text=='40')
p.checks.enabled.button:SetChecked(true);p.checks.enabled.button.scripts.OnClick();assert(settings.enabled)
p.checks.lowsound.button:SetChecked(false);p.checks.lowsound.button.scripts.OnClick();assert(not settings.low.sound)
print('PASS: low/death thresholds and episode resets, hysteresis/repeats, independent master/type/output toggles, pet identity, combat/public/secret/loading guards, saved settings and validation')

F.DebugPetAlerts()
assert(chats[#chats-2]:find('readable health checks=',1,true))
assert(F.petAlertDiagnostics.publicReads>0 and F.petAlertDiagnostics.unavailableReads>0)
assert(F.petAlertDiagnostics.minimumPercent<=35)
print('PASS: public/unavailable health diagnostics and debug output')

settings.enabled=true;settings.low.enabled=true;settings.low.banner=true
settings.low.repeatSeconds=0;dead=false;exists=true;hp='secret';maximum='secret'
issecretvalue=function(v) return v=='secret' end
local fraction=0.30
UnitHealthPercent=function(unit,predicted,curve)
 assert(unit=='pet' and predicted==true)
 return fraction
end
F.ResetPetAlerts();local before=#banners
F.CheckPetAlerts();assert(#banners==before+1 and banners[#banners]:find('30%%'))
assert(F.petAlertDiagnostics.lastHealthStatus:find('native percentage',1,true))
fraction=1;F.CheckPetAlerts();assert(#banners==before+1, 'full native health must not be read as 1 percent')
CurveConstants={ScaleTo100={}}
UnitHealthPercent=function(_,_,curve) assert(curve==CurveConstants.ScaleTo100);return 25 end
F.CheckPetAlerts();assert(#banners==before+2)
UnitHealthPercent=function() return 'secret' end
F.ResetPetAlerts();F.CheckPetAlerts();assert(#banners==before+2)
assert(F.petAlertDiagnostics.lastHealthStatus:find('Percentage: restricted',1,true))
UnitHealthPercent=function() error('unavailable') end
hp=20;maximum=100;F.CheckPetAlerts();assert(#banners==before+3, 'public raw health remains a fallback')
print('PASS: native percentage with restricted raw health, correct percentage scaling, restricted percentage guard and raw fallback')

-- Opaque curve output must reach the renderer untouched, with no Lua comparison.
local opaque=setmetatable({}, {__eq=function() error('secret comparison') end,__tostring=function() error('secret formatting') end})
issecretvalue=function(v) return rawequal(v,opaque) or v=='secret' end
local built=0
C_CurveUtil={CreateCurve=function()
 built=built+1
 local c={points={}}
 function c:SetType(v) self.kind=v end
 function c:AddPoint(x,y) self.points[#self.points+1]={x,y} end
 return c
end}
Enum={LuaCurveType={Linear=1}}
UnitHealthPercent=function(_,_,curve)
 if curve==CurveConstants.ScaleTo100 then return 'secret' end
 return opaque
end
hp='secret';maximum=100;dead=false;exists=true;combat=true
settings.low.banner=true;settings.low.sound=true;settings.low.chat=true
F.ResetPetAlerts();local alertCount,soundCount,chatCount=#banners,sounds,#chats
F.CheckPetAlerts();local visual=F.petLowHealthVisual
assert(visual.shown and rawequal(visual.text.alpha,opaque))
assert(#banners==alertCount and sounds==soundCount and #chats==chatCount,'secret visual must not trigger sound/chat')
assert(visual.curve.points[2][1]==settings.threshold/100 and visual.curve.points[2][2]==1)
assert(visual.curve.points[3][2]==0 and visual.curve.points[4][1]==1)
F.CheckPetAlerts();assert(built==1,'curve is reused')
settings.threshold=50;F.CheckPetAlerts();assert(built==2 and visual.threshold==50)
settings.low.banner=false;F.CheckPetAlerts();assert(not visual.shown)
settings.low.banner=true;settings.low.enabled=false;F.CheckPetAlerts();assert(not visual.shown)
settings.low.enabled=true;settings.enabled=false;F.CheckPetAlerts();assert(not visual.shown)
settings.enabled=true;dead=true;F.CheckPetAlerts();assert(not visual.shown)
dead=false;exists=false;F.CheckPetAlerts();assert(not visual.shown)
exists=true;dead='secret';F.CheckPetAlerts();assert(not visual.shown)
dead=false;UnitHealthPercent=function() error('API failed') end
F.CheckPetAlerts();assert(not visual.shown)
UnitHealthPercent=function(_,_,curve)
 if curve==CurveConstants.ScaleTo100 then return 'secret' end
 return nil
end
F.CheckPetAlerts();assert(not visual.shown,'missing native result cannot leave a stale warning')
print('PASS: opaque native alpha passthrough, cached threshold curve, no sound/chat from secrets, all toggles, death/dismissal/unknown/API failure cleanup')

UnitHealthPercent=function(_,_,curve)
 if curve==CurveConstants.ScaleTo100 then return 'secret' end
 return opaque
end
F.PetHealRangeWarning=function() return 'Pet too far to heal (Mend Pet)' end
F.CheckPetAlerts();assert(visual.text.text=='PET HEALTH LOW - OUT OF RANGE TO MEND PET!')
F.PetHealRangeWarning=function() return nil end
F.CheckPetAlerts();assert(visual.text.text=='PET HEALTH LOW - MEND PET!')
print('PASS: native low-health warning follows confirmed Mend Pet range and uses ASCII punctuation')
