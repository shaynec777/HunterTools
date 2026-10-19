local F={db={}}
local function widget()
 local w={scripts={},shown=false,text=''}
 setmetatable(w,{__index=function(_,key)
  if key=='npcID' then return nil end
  if key=='CreateFontString' or key=='GetFontString' then return widget end
  return function() end
 end})
 function w:SetScript(key,fn) self.scripts[key]=fn end
 function w:SetText(text) self.text=text end
 function w:GetText() return self.text end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 function w:SetShown(value) self.shown=value end
 function w:GetStringHeight() return 100 end
 return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={};GameTooltip=nil
local combat=false;InCombatLockdown=function() return combat end
UnitClass=function() return 'Druid','DRUID' end
F.Print=function(text) F.message=text end
for _,file in ipairs({'PetDatabase.lua','ForeverPetData.lua','PetopiaForeverData.lua','BeastKnowledge.lua','TargetPetInfo.lua'}) do
 assert(loadfile('HunterTools/'..file))('test',F)
end
local rows=F.SearchBeasts('  VULDREN  ')
assert(#rows>=3 and rows[1].record.name=='Vuldren')
local seen={};for _,row in ipairs(rows) do assert(not seen[row.id]);seen[row.id]=true end
assert(#F.SearchBeasts('')==0 and #F.SearchBeasts('   ')==0 and #F.SearchBeasts('no-such-beast-123')==0)
assert(#F.SearchBeasts('[')==0,'query must use literal matching, not Lua patterns')
F.db.beastJournal={records={[999998]={name='Test Beast',family='Boar',minLevel=6},[999999]={name='Test Beast',family='Cat',minLevel=7}}}
rows=F.SearchBeasts('test beast');assert(#rows==2 and rows[1].id==999998 and rows[2].id==999999)
F.db.beastJournal.records[250868]={name='Observed Vuldren',family='Wolf'}
rows=F.SearchBeasts('Observed Vuldren');assert(#rows==1 and rows[1].record.sources.name=='Observed in Forever')
local originalShow=F.ShowBeastDetail
local name,details
F.ShowBeastDetail=function(n,d) name=n;details=d end
F.MarkTargetAbilities=function() error('druid must not use hunter learned labels') end
F.AnimalFoodCounts=function() return 'Food counts' end
F.OpenBeastRecord(999998)
assert(name=='Test Beast' and details:find('NPC 999998',1,true) and details:find('unknown; no recorded abilities',1,true))
assert(details:find('Observed in Forever',1,true) and not details:find('reference says tameable',1,true))
F.ShowBeastDetail=originalShow
F.OpenBeastSearch('Test Beast')
local p=F.beastSearchPanel
assert(p.shown and #p.matches==2 and p.rows[1].npcID==999998 and not p.rows[3].shown)
p.rows[1].scripts.OnClick()
assert(F.beastDetailPanel.shown and not p.shown,'result opens real scrollable detail UI')
assert(F.beastDetailPanel.title.text=='Test Beast - Beast details')
F.OpenBeastSearch('wolf');assert(p.shown and not F.beastDetailPanel.shown and #p.matches>10)
assert(p.rows[10].shown and p.rows[10].npcID)
local firstID=p.rows[1].npcID;p.nextPage.scripts.OnClick();assert(p.page==2 and p.rows[1].npcID==p.matches[11].id and p.rows[1].npcID~=firstID)
p.previous.scripts.OnClick();assert(p.page==1 and p.rows[1].npcID==firstID)
F.OpenBeastSearch('does-not-exist-123');assert(#p.matches==0 and not p.rows[1].shown and p.rows[1].npcID==nil)
F.beastDetailPanel.search:SetText('Vuldren')
F.beastDetailPanel.search.scripts.OnEnterPressed()
assert(p.shown and p.input:GetText()=='Vuldren' and #p.matches>=3)
F.OpenBeastRecord(999998);F.beastDetailPanel.search:SetText('wolf');F.beastDetailPanel.searchButton.scripts.OnClick()
assert(p.shown and p.input:GetText()=='wolf')
combat=true;F.OpenBeastSearch('wolf');assert(F.message=='Search beasts after combat.')
F.OpenBeastRecord(999998);assert(F.message=='View beast details after combat.')
print('PASS: real-source name search, partial/case/whitespace/literal matching, exact-name priority, NPC deduplication, same-name identities, local precedence, unknown fields, druid behavior, search/result UI, empty result cleanup and combat guards')

-- Exercise the actual slash-command registration and routing.
local loader
CreateFrame=function() loader=widget();return loader end
SlashCmdList={};F.LoadSettings=function() end;F.ReplayPetAbilityLearning=function() end
F.CheckAPIs=function() return false end
assert(loadfile('HunterTools/HunterTools.lua'))('test',F)
loader.scripts.OnEvent(loader,'ADDON_LOADED','test')
local queryText,targetLookup
F.OpenBeastSearch=function(text) queryText=text end
F.OpenBeastDetail=function() targetLookup=true end
SlashCmdList.FEEDOMATICTOO('beastdetail Vuldren Alpha');assert(queryText=='Vuldren Alpha')
SlashCmdList.FEEDOMATICTOO(' BEASTDETAIL wolf ');assert(queryText=='wolf ')
SlashCmdList.FEEDOMATICTOO('beastsearch');assert(queryText=='')
SlashCmdList.FEEDOMATICTOO('beastdetail');assert(targetLookup)
targetLookup=false;SlashCmdList.FEEDOMATICTOO('beastdetails');assert(targetLookup)
SlashCmdList.FEEDOMATICTOO('beastdetails Vuldren');assert(queryText=='Vuldren')
print('PASS: next/previous pages and actual slash-command routing preserve targeted lookup')
