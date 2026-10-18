local shift=true
IsShiftKeyDown=function() return shift end
local F={db={}}
local combat=false
InCombatLockdown=function() return combat end
UIParent={GetEffectiveScale=function() return 1 end,GetCenter=function() return 500,400 end}
assert(loadfile('HunterTools/MenuStyle.lua'))('test',F)
local function frame()
 local p={scripts={},scale=0.8,x=750,y=600,point=false,moving=false,alertDragging=false,alertStopPending=false}
 setmetatable(p,{__index=function(_,key) if key=='alertDragging' or key=='alertStopPending' then return nil end;return function() end end})
 function p:SetScript(k,v) self.scripts[k]=v end
 function p:HookScript(k,v) self.scripts[k]=v end
 function p:GetEffectiveScale() return self.scale end
 function p:GetCenter() return self.x,self.y end
 function p:StartMoving() self.moving=true end
 function p:StopMovingOrSizing() self.moving=false end
 function p:SetPoint(...) self.point={...} end
 return p
end
local p=frame();F.MakeMovableAlert(p,'tracking');assert(not p.point,'keep original button anchor before first drag')
shift=false;p.scripts.OnDragStart();assert(not p.moving,'plain drag must not move')
shift=true;p.scripts.OnDragStart();assert(p.moving and p.alertDragging)
p.scripts.OnDragStop();assert(not p.moving and not p.alertDragging)
assert(F.db.alertPositions.tracking.x==100 and F.db.alertPositions.tracking.y==80)
assert(p.point[1]=='CENTER' and p.point[4]==125 and p.point[5]==100)
local fresh=frame();fresh.scale=1;F.MakeMovableAlert(fresh,'tracking')
assert(fresh.point[4]==100 and fresh.point[5]==80,'restore normalized position at a different scale')
p.scripts.OnDragStart();combat=true;p.scripts.OnHide();assert(p.alertStopPending and p.moving)
combat=false;p.scripts.OnEvent(p,'PLAYER_REGEN_ENABLED');assert(not p.moving and not p.alertDragging)
combat=true;p.scripts.OnDragStart();assert(not p.moving)
combat=false;F.db.alertPositions.tracking={x=0/0,y=12};local invalid=frame();F.MakeMovableAlert(invalid,'tracking');assert(not invalid.point)
print('PASS: movable alert save/restore, initial button anchor, scale conversion, hide/combat interruption, combat guard and invalid saved positions')
