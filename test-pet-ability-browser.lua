local F={db={},Print=function(msg) Fmessage=msg end}
local all={}
local function widget()
 local w={scripts={},shown=false,text=''}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' or k=='CreateTexture' then return widget end;if k:match('^[A-Z]') then return function() end end end})
 function w:SetScript(e,f) self.scripts[e]=f end
 function w:SetText(v) self.text=v end
 function w:SetChecked(v) self.checked=v end
 function w:GetChecked() return self.checked end
 function w:SetCreature(id) self.loadedID=id;self.loadCalls=(self.loadCalls or 0)+1 end
 function w:GetText() return self.text end
 function w:GetStringHeight() return 100 end
 function w:GetFrameLevel() return self.frameLevel or 1 end
 function w:SetFrameLevel(v) self.frameLevel=v end
 function w:SetAlpha(v) self.alpha=v end
 function w:SetColorTexture(r,g,b,a) self.color={r,g,b,a} end
 function w:SetEnabled(v) self.enabled=v end
 function w:Show() local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
 function w:Hide() local was=self.shown;self.shown=false;if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
 function w:SetFocus() self.focused=true end
 function w:ClearFocus() self.focused=false end
 function w:HighlightText() self.selected=true end
 function w:IsShown() return self.shown end
 all[#all+1]=w;return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={}
local combat=false;InCombatLockdown=function() return combat end
F.HideConfigPages=function() if F.petAbilityBrowser then F.petAbilityBrowser:Hide() end end
F.OpenConfig=function() F.HideConfigPages() end
local scans=0;F.ScanKnownPetAbilities=function() scans=scans+1 end
assert(loadfile('HunterTools/PetBrowserData.lua'))('test',F)
assert(loadfile('HunterTools/PetAbilityBrowser.lua'))('test',F)
local bite,trainer,custom,creatures,links,ranks=nil,nil,nil,{},0,0
for _,a in ipairs(F.petBrowserAbilities) do
 if a.key=='bite' then bite=a end
 if a.key=='arcane resistance' then trainer=a end
 if a.key=='swipe' then custom=a end
 for _,r in ipairs(a.ranks) do
  ranks=ranks+1
  for _,animal in ipairs(r.animals) do
   links=links+1;creatures[animal.id]=true
   assert(animal.zone and animal.zone~='' and animal.levels:match('%d') and animal.family)
   assert(animal.reference=='Classic')
  end
 end
end
assert(#F.petBrowserAbilities==32 and ranks==152 and links==351)
local n=0;for _ in pairs(creatures) do n=n+1 end;assert(n==297)
assert(bite and trainer and custom)
local highest,scanned,nextRank=F.PetBrowserProgress(bite)
assert(highest==0 and not scanned and nextRank.rank==1)
assert(F.PetBrowserRankStatus(bite,1)=='Learned status unknown')
F.db.knownPetAbilities={bite=2}
highest,scanned,nextRank=F.PetBrowserProgress(bite);assert(highest==2 and scanned and nextRank.rank==3)
assert(F.PetBrowserRankStatus(bite,1)=='Learned (cached)' and F.PetBrowserRankStatus(bite,3)=='Not learned (cached)')
F.db.knownPetAbilities.bite=99;assert(select(3,F.PetBrowserProgress(bite))==nil)
F.db.knownPetAbilities={};F.db.petTrainingScanned=true
assert(F.PetBrowserRankStatus(bite,1)=='Not learned (cached)')
F.db.petTrainingScanned=nil;F.db.petAbilityScanNames={bite=true};assert(select(2,F.PetBrowserProgress(bite)))
F.db.petAbilityScanNames=nil
F.OpenPetAbilityBrowser();local p=F.petAbilityBrowser;assert(p:IsShown() and scans==1)
p.selectedKey='bite';p.selectedRank=nil;F.RefreshPetAbilityBrowser()
assert(p.summary.text:find('unknown',1,true) and p.selectedRank==1)
assert(p.animalRows[1].text:find('Level ',1,true) and p.sourceNote.text:find('Classic-linked',1,true))
assert(p.animalNext.enabled,'Bite 1 should paginate many teachers')
local first=p.animalRows[1].text;p.animalNext.scripts.OnClick();assert(p.animalPage==2 and p.animalRows[1].text~=first)
p.rankButtons[2].scripts.OnClick();assert(p.selectedRank==2 and p.animalPage==1)
F.db.knownPetAbilities={bite=2};F.OpenPetAbilityBrowser();assert(p.selectedRank==3,'reopen defaults to next needed rank')
F.db.knownPetAbilities.bite=3;p.scripts.OnUpdate(nil,1.1);assert(p.summary.text:find('Next needed: 4',1,true),'learning updates visible progress')
p.search.text='swipe';p.search.scripts.OnTextChanged();assert(p.selectedKey=='swipe' and p.sourceNote.text:find('No verified',1,true))
p.search.text='arcane resistance';p.search.scripts.OnTextChanged();assert(p.sourceNote.text:find('pet trainer',1,true))
p.search.text='[no match]';p.search.scripts.OnTextChanged();assert(p.summary.text=='No matching abilities.' and p.animalRows[1].text=='' and not p.rankButtons[1].shown)
p.search.text='';p.search.scripts.OnTextChanged();p.abilityNext.scripts.OnClick();assert(p.abilityPage==2)
p.abilityButtons[1].scripts.OnClick();assert(p.selectedKey==F.petBrowserAbilities[13].key)
p.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED');assert(not p.shown)
combat=true;local before=scans;F.OpenPetAbilityBrowser();assert(scans==before and not p.shown and Fmessage:find('after combat',1,true))
combat=false;F.PetBrowserSettings().enabled=false;F.OpenPetAbilityBrowser();assert(not p.shown and Fmessage:find('Enable',1,true))
F.db.petBrowser='bad';assert(F.PetBrowserSettings().enabled)
print('PASS: 32 abilities / 152 ranks / 297 teaching animals, cache confidence, next rank, all learned, search, ability/rank/source pagination, teacher levels/zones, trainer/unknown sources, live refresh, saved enable preference and combat guard')

-- Per-row links always open only a selected copy dialog.
F.OpenPetAbilityBrowser();p.search.text='bite';p.search.scripts.OnTextChanged();p.selectedRank=1;F.RefreshPetAbilityBrowser()
local b=p.wowheadButtons[1];assert(b.shown and b.animal)
local firstID=b.animal.id
assert(F.PetAnimalWowheadURL(b.animal)=='https://www.wowhead.com/forever/npc='..firstID)
assert(not F.PetAnimalWowheadURL(nil) and not F.PetAnimalWowheadURL({id='123'}) and not F.PetAnimalWowheadURL({id=1.5}) and not F.PetAnimalWowheadURL({id=0/0}))
LaunchURL=function() error('Direct opening must never be attempted') end
b.scripts.OnClick();local d=F.wowheadLinkPanel
assert(d.shown and d.url.selected and d.url.focused and d.url.text:find('npc='..firstID,1,true))
assert(d.status.text:find('Copy this address',1,true))
F.RefreshPetAbilityBrowser()
p.animalNext.scripts.OnClick();b=p.wowheadButtons[1];assert(b.animal.id~=firstID)
b.scripts.OnClick();assert(d.url.text==F.PetAnimalWowheadURL(b.animal),'paged buttons must point to current animals')
p.search.text='no matching ability';p.search.scripts.OnTextChanged()
for _,rowButton in ipairs(p.wowheadButtons) do assert(not rowButton.shown and rowButton.animal==nil) end
local before=d.url.text;combat=true;F.OpenPetAnimalWowhead({id=117,name='Test'});assert(d.url.text==before)
combat=false;p.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED');assert(not d.shown and not d.url.focused)
print('PASS: copy-only Wowhead dialog, selected URL, correct paged NPC links, row clearing, no direct opening and combat closure')

-- Portraits track pagination and clear absent teachers without reloading every tick.
combat=false;F.OpenPetAbilityBrowser();p.search.text='bite';p.search.scripts.OnTextChanged();p.selectedRank=1;F.RefreshPetAbilityBrowser()
local portrait=p.animalPortraits[1];assert(portrait.shown and portrait.animalID==p.wowheadButtons[1].animal.id)
local loads=0;portrait.model.SetCreature=function(self,id) loads=loads+1;self.loadedID=id end
F.RefreshPetAbilityBrowser();assert(loads==0,'unchanged rows must not reload their models')
p.animalNext.scripts.OnClick();assert(portrait.model.loadedID==p.wowheadButtons[1].animal.id)
portrait.model.scripts.OnModelLoaded(portrait.model);assert(portrait.fallback.text=='')
p.search.text='no matching ability';p.search.scripts.OnTextChanged();assert(not portrait.shown and portrait.animalID==nil and not portrait.model.shown)
p.search.text='bite';p.search.scripts.OnTextChanged()
local original=portrait.model;local originalID=portrait.animalID
p.animalNext.scripts.OnClick();p.animalPrev.scripts.OnClick()
assert(portrait.model==original and portrait.animalID==originalID,'returning to a page reuses its model')
assert(loads==0,'returning to a cached model must not call SetCreature again')
for id=900001,900010 do F.SetPetBrowserPortrait(portrait,{id=id}) end
assert(#portrait.cacheOrder==4,'model cache must stay bounded')
local count=0;for _ in pairs(portrait.models) do count=count+1 end;assert(count==4)
local failed=portrait.model;failed.SetCreature=function() error('Unavailable model') end
-- FIFO eviction recycles the oldest frame after four new IDs.
for id=900011,900014 do F.SetPetBrowserPortrait(portrait,{id=id}) end
assert(portrait.model==failed and portrait.shown and portrait.fallback.text=='?' and not portrait.model.shown)
print('PASS: creature portrait IDs, pagination, no repeated model loads, model-ready placeholder, empty rows and unavailable model fallback')

print('PASS: bounded portrait cache, revisited pages avoid creature reloads, recycled frames and loading/failure indicators')

-- Turning pictures off cancels/clears all cached models and prevents new requests.
local savedModels={}
for _,row in ipairs(p.animalPortraits) do
 for _,model in pairs(row.models or {}) do
  savedModels[#savedModels+1]=model
  model.ClearModel=function(self) self.cleared=true end
 end
end
p.pictureCheck:SetChecked(false);p.pictureCheck.scripts.OnClick(p.pictureCheck)
assert(F.db.petBrowser.showPictures==false)
for _,model in ipairs(savedModels) do assert(model.cleared and not model.shown) end
for _,row in ipairs(p.animalPortraits) do assert(not row.shown and not row.models and not row.model) end
p.animalNext.scripts.OnClick();p.animalPrev.scripts.OnClick();F.OpenPetAbilityBrowser()
assert(not p.pictureCheck.checked and F.db.petBrowser.showPictures==false)
for _,row in ipairs(p.animalPortraits) do assert(not row.models) end
p.pictureCheck:SetChecked(true);p.pictureCheck.scripts.OnClick(p.pictureCheck)
assert(F.db.petBrowser.showPictures and p.animalPortraits[1].model and p.animalPortraits[1].shown)
print('PASS: saved picture checkbox, cache clearing, no loading while disabled, paging/reopen persistence and re-enable')

combat=false
F.PetBrowserSettings().enabled=true
F.OpenPetAbilityBrowser()
local browser=F.petAbilityBrowser
local beastQuery
F.OpenBeastSearch=function() error('browser search must not open the standalone window') end
F.OpenBeastRecord=function() error('browser details must stay embedded') end
F.SearchBeasts=function(text)
 beastQuery=text
 if text=='none' or text=='' then return {} end
 local matches={}
 for i=1,8 do matches[i]={id=9000+i,record={name='Test Beast '..i,family='Wolf',zone='Test Zone',minLevel=10,sources={name='Petopia Forever'}}} end
 return matches
end
F.BeastRecordDetails=function(id) return 'Test Beast '..id,'Diet and abilities' end
browser.beastSearch:SetText('Vuldren')
browser.beastSearch.scripts.OnEnterPressed(browser.beastSearch)
assert(beastQuery=='Vuldren' and browser.shown and browser.beastSearchMode)
assert(browser.wowheadButtons[1].text=='Details' and browser.wowheadButtons[1].animal.id==9001)
browser.animalNext.scripts.OnClick()
assert(browser.animalPage==2 and browser.wowheadButtons[1].animal.id==9007 and not browser.wowheadButtons[3].shown)
browser.wowheadButtons[1].scripts.OnClick()
assert(browser.shown and browser.beastDetails.shown and browser.beastDetails.text.text=='Diet and abilities')
assert(browser.beastDetails.frameLevel>browser:GetFrameLevel() and browser.beastDetails.alpha==1 and browser.beastDetails.background.color[4]==1)
browser.beastSearch:SetText('none');browser.beastSearchButton.scripts.OnClick()
assert(browser.shown and not browser.beastDetails.shown and not browser.wowheadButtons[1].shown and not browser.animalNext.enabled)
browser.beastSearch:SetText('wolf');browser.beastSearchButton.scripts.OnClick()
assert(beastQuery=='wolf' and browser.shown)
browser.abilityButtons[1].scripts.OnClick()
assert(not browser.beastSearchMode and browser.wowheadButtons[1].text=='Wowhead')
browser.beastSearch:SetText('');browser.beastSearchButton.scripts.OnClick()
assert(not browser.beastSearchMode and browser.shown)
browser.beastSearch:SetText('cat');combat=true
browser.beastSearchButton.scripts.OnClick()
assert(beastQuery=='' and browser.shown and Fmessage=='Search beasts after combat.')
print('PASS: embedded beast search/results/details, pagination, no standalone window, empty cleanup, ability navigation, clear search and combat guard')
