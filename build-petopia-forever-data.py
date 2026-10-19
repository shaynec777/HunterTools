"""Import factual family/creature/rank facts from cached Petopia Forever pages.
Family-learnable skills are never assigned to individual wild creatures.
"""
from pathlib import Path
import re, html, json
root=Path(__file__).resolve().parent
cache=root/'reference-data/petopia-forever'
def plain(s): return ' '.join(html.unescape(re.sub('<[^>]*>',' ',s)).split())
def lua(v):
    if isinstance(v,bool): return str(v).lower()
    if isinstance(v,str): return json.dumps(v,ensure_ascii=False)
    if isinstance(v,(int,float)): return str(v)
    if isinstance(v,list): return '{'+','.join(map(lua,v))+'}'
    return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
names=dict(bat='Bat',bear='Bear',birdofprey='Bird of Prey',boar='Boar',carrionbird='Carrion Bird',cat='Cat',corehound='Core Hound',crab='Crab',crocolisk='Crocolisk',fox='Fox',gorilla='Gorilla',hyena='Hyena',raptor='Raptor',scorpid='Scorpid',spider='Spider',tallstrider='Tallstrider',turtle='Turtle',windserpent='Wind Serpent',wolf='Wolf')
families={}; creatures={}; teachers={}; conflicts=[]
for slug,name in names.items():
    page=(cache/('family.php_id_'+slug)).read_text(encoding='utf-8')
    diet=re.search(r"class='familydetailsdata[^']* diet'>(.*?)</div>",page,re.S)
    role=re.search(r"class='familydetailsrole[^']*'>(.*?)</div>",page,re.S)
    row={'source':'https://www.wow-petopia.com/forever/family.php?id='+slug}
    if diet: row['diet']=', '.join(plain(diet[1]).split(' - '))
    if role: row['role']=plain(role[1])
    active=re.search(r"class='familydetailsabilities[^']* active'>(.*?)</div></div>",page,re.S)
    if active: row['learnable']=[plain(s) for s in re.findall(r"class='familyabilityitem[^']*'>(.*?)</div>",active[1],re.S)]
    # Blizzard confirmed Sonic Blast for bats; cached Petopia family list omits it.
    if name=='Bat':
        row.setdefault('learnable',[])
        if 'Sonic Blast' not in row['learnable']: row['learnable'].append('Sonic Blast')
        row['trainingReference']='Petopia Forever / Blizzard beta notes'
    families[name]=row
    for look in sorted(set(re.findall(r"href='look.php\?id=([\w-]+)'",page))):
        source='https://www.wow-petopia.com/forever/look.php?id='+look
        text=(cache/('look.php_id_'+look)).read_text(encoding='utf-8')
        for tr in re.findall(r'<tr\b[^>]*>(.*?)</tr>',text,re.S):
            npc=re.search(r'(?:wowhead.com/(?:forever/)?npc=)(\d+)',tr)
            nm=re.search(r"class='pettablename'>(.*?)</div>",tr,re.S)
            lv=re.search(r"<td class='level'>(.*?)</td>",tr,re.S)
            zone=re.search(r"<td class='zone'>(.*?)</td>",tr,re.S)
            if not (npc and nm): continue
            entry={'name':plain(nm[1]),'family':name,'source':source}
            if zone: entry['zone']=plain(zone[1])
            if lv:
                levels=re.match(r'(\d+)(?:\s*-\s*(\d+))?',plain(lv[1]))
                if levels: entry.update(minLevel=int(levels[1]),maxLevel=int(levels[2] or levels[1]))
            if "alt='Can Be Tamed'" in tr: entry['tameable']=True
            elif "alt='Cannot Be Tamed'" in tr: entry['tameable']=False
            id=int(npc[1])
            if id in creatures and creatures[id]['family']!=name: conflicts.append(id); continue
            creatures[id]=entry
page=(cache/'abilities.php').read_text(encoding='utf-8')
heads=list(re.finditer(r"class='abilityrankname[^']*'>(.*?)</span>: Pet Level (\d+)",page,re.S))
aliases={'screech':'demoralizing screech'}
for i,h in enumerate(heads):
    match=re.fullmatch(r'(.*?) (\d+)',plain(h[1]))
    if not match: continue
    name,rank=match[1],int(match[2]);key=aliases.get(name.lower(),name.lower())
    block=page[h.end():heads[i+1].start() if i+1<len(heads) else len(page)]
    for m in re.finditer(r"class='npclink[^']*' href='(https://[^']*wowhead.com/(?:forever/)?npc=(\d+))'>(.*?)</a>\s*\((.*?)\)</li>",block,re.S):
        bits=plain(m[4]).split(', ',2)
        if len(bits)!=3: continue
        family,levels,zone=bits; family='Bird of Prey' if family=='Owl' else family
        id=int(m[2]); entry=creatures.setdefault(id,{'name':plain(m[3]),'family':family,'zone':zone,'source':'https://www.wow-petopia.com/forever/abilities.php'})
        # Preserve the fact this Forever page still links Classic teaching sources.
        reference='Petopia Forever (Classic-linked)' if 'classic.wowhead' in m[1] else 'Petopia Forever'
        teachers.setdefault(key,{}).setdefault(rank,[]).append(dict(id=id,name=plain(m[3]),family=family,levels=levels,zone=zone,reference=reference))
        abilities=entry.setdefault('abilityRanks',{})
        abilities[key]={'name':name,'rank':rank,'petLevel':int(h[2]),'reference':reference}
for entry in creatures.values():
    if 'abilityRanks' in entry:
        entry['abilities']='; '.join(f"{r['name']} {r['rank']} (pet level {r['petLevel']})" for _,r in sorted(entry['abilityRanks'].items()))
        entry['abilityReference']='Petopia Forever (Classic-linked)'
community={};communityTeachers={};communityAbilityNames={};skipped=[]
communitySource='https://docs.google.com/spreadsheets/d/e/2PACX-1vQ9XgOGgdQ_Jpo6GaGOuSQRC7w8WNlNAs5Yb5XhglYCSyaksJ_Qw6QmUZq05ObeOJhBsPyeK1abupXl/pubhtml'
sheet=cache/'community-tames-sheet.html'
wowhead=json.loads((root/'reference-data/wowhead-forever-pets.json').read_text(encoding='utf-8'))
# NPC identities are joined by explicit numeric IDs, never by appearance links.
def find_records(v):
    if isinstance(v,list):
        for x in v: yield from find_records(x)
    elif isinstance(v,dict):
        if 'id' in v and 'name' in v: yield v
        for x in v.values():
            if isinstance(x,(dict,list)): yield from find_records(x)
canonical={int(r['id']):r['name'] for r in find_records(wowhead)}
if sheet.exists():
    for tr in re.findall(r'<tr\b[^>]*>(.*?)</tr>',sheet.read_text(encoding='utf-8'),re.S):
        cells=[plain(c) for c in re.findall(r'<td\b[^>]*>(.*?)</td>',tr,re.S)]
        if len(cells)<7 or not cells[0] or cells[0]=='Creature Name': continue
        ids=re.findall(r'\b(\d{6})\b',cells[6])
        if len(ids)!=1: skipped.append(cells[0]);continue
        id=int(ids[0]);entry=dict(name=canonical.get(id,cells[0]),family=cells[4],zone=cells[3],source=communitySource)
        if entry['family']=='Owl': entry['family']='Bird of Prey'
        levels=re.fullmatch(r'(\d+)(?:-(\d+))?',cells[2])
        if levels: entry.update(minLevel=int(levels[1]),maxLevel=int(levels[2] or levels[1]))
        ability=re.fullmatch(r'(.+?)\s+(\d+)',cells[1])
        if ability:
            name,rank=ability[1],int(ability[2]);key=aliases.get(name.lower(),name.lower())
            communityAbilityNames[key]=name
            entry.update(abilities=f'{name} {rank}',abilityReference='Petopia community report (unverified)')
            communityTeachers.setdefault(key,{}).setdefault(rank,[]).append(dict(id=id,name=entry['name'],family=entry['family'],zone=entry['zone'],levels=cells[2],reference='Petopia community report (unverified)'))
        elif cells[1].lower()=='no ability': entry['reportedNoAbilities']=True
        community[id]=entry
lines=['local _,F=...','-- Generated factual Petopia Forever reference; incomplete, not in-game confirmation.',
       'F.petopiaForeverCreatures='+lua(creatures),'F.petopiaForeverFamilies='+lua(families),
       'F.petopiaCommunityCreatures='+lua(community),'F.petopiaCommunityTeachers='+lua(communityTeachers),
       'F.petopiaCommunityAbilityNames='+lua(communityAbilityNames),
       'F.petopiaForeverTeachers='+lua(teachers),'F.petopiaForeverFamilies.Owl=F.petopiaForeverFamilies["Bird of Prey"]','F.petopiaForeverDate="2026-10-17"']
(root/'release-source/HunterTools/PetopiaForeverData.lua').write_text('\n'.join(lines)+'\n',encoding='utf-8')
report=dict(creatures=len(creatures),families=len(families),teachingLinks=sum(len(v) for ranks in teachers.values() for v in ranks.values()),communityCreatures=len(community),communityTeachingLinks=sum(len(v) for ranks in communityTeachers.values() for v in ranks.values()),communityRowsWithoutIDs=skipped,creaturesWithAbilityReferences=sum('abilities' in r for r in creatures.values()),newNPCIDs=sum(id>=250000 for id in creatures),familyConflicts=conflicts,source='https://www.wow-petopia.com/forever/',retrieved='2026-10-17')
(cache/'facts.json').write_text(json.dumps({'creatures':creatures,'families':families,'teachers':teachers,'communityCreatures':community,'communityTeachers':communityTeachers},indent=2,ensure_ascii=False),encoding='utf-8')
(root/'reference-data/petopia-forever/coverage.json').write_text(json.dumps(report,indent=2))
print(report)
