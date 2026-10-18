local F={db={}}
assert(loadfile('HunterTools/Range.lua'))('test',F)
local combat,pet,dead,target=false,true,false,false
InCombatLockdown=function() return combat end
UnitClass=function() return 'Hunter','HUNTER' end
UnitExists=function(unit) return unit=='pet' and pet or unit=='target' and target end
UnitIsDeadOrGhost=function(unit) return unit=='pet' and dead or false end
UnitCanAttack=function() return false end
UnitName=function() return 'Friendly target' end
CheckInteractDistance=function() return false end
local known={[136]=true,[3111]=true};local ranged=false;local checks=0
C_SpellBook={IsSpellKnown=function(id) assert(not combat);return known[id] or false end}
C_Spell={IsSpellInRange=function(id,unit)
 if unit=='pet' then assert(id==3111);checks=checks+1;return ranged end
 return nil
end,GetSpellInfo=function() return {minRange=8,maxRange=35} end}
assert(F.PetHealRangeWarning()=='Pet too far to heal (Mend Pet)')
ranged=true;assert(not F.PetHealRangeWarning())
ranged=0;assert(F.PetHealRangeWarning())
ranged=1;assert(not F.PetHealRangeWarning())
ranged=nil;assert(not F.PetHealRangeWarning())
ranged='secret';issecretvalue=function(v) return v=='secret' end;assert(not F.PetHealRangeWarning());issecretvalue=nil
ranged=false;combat=true;assert(F.PetHealRangeWarning(),'public native range can warn in combat without querying spell knowledge')
combat=false;pet=false;assert(not F.PetHealRangeWarning());pet=true
dead=true;assert(not F.PetHealRangeWarning());dead=false
F.RangeSettings().showPetHealRange=false;local before=checks;assert(not F.PetHealRangeWarning() and checks==before)
F.RangeSettings().showPetHealRange=true;known={};assert(not F.PetHealRangeWarning() and checks==before)
known={[3111]=true}
-- Exercise warning layout independently of the target.
local function widget()
 local w={shown=false,scripts={}}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' or k=='CreateTexture' then return widget end;return function() end end})
 function w:SetScript(k,v) self.scripts[k]=v end
 function w:SetText(v) self.text=v end
 function w:SetPoint(...) self.point={...} end
 function w:SetHeight(v) self.height=v end
 function w:GetStringHeight() return 14 end
 function w:SetAlpha(v) self.alpha=v end
 function w:SetShown(v) self.shown=v end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 return w
end
CreateFrame=widget;UIParent={}
F.UpdateRangeWindow();local p=F.rangeWindow
assert(p.petHeal.shown and p.petHeal.text:find('too far',1,true) and p.height==116 and p.targetName.text=='No target')
F.TargetPetDetails=function() return 'Animal details' end
target=true;F.UpdateRangeWindow();assert(p.petDetails.point[3]==-118 and p.height==146 and p.alpha==1)
ranged=true;F.UpdateRangeWindow();assert(not p.petHeal.shown and p.height==124 and p.alpha==0.65)
F.TargetPetDetails=nil;pet=false;F.UpdateRangeWindow();assert(p.height==94 and not p.petHeal.shown)
print('PASS: highest learned Mend Pet rank, native range, combat/public/secret results, absent/dead pets, unlearned spell, toggle, no-target warning and nonoverlapping window layout')
