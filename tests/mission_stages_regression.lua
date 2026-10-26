-- Experimental multi-stage objectives, event triggers and save/load regressions.
package.path='./?.lua;./?/init.lua;'..package.path
local Mission=require('src.mission')
local Rules=require('src.mission_rules')
local World=require('src.world')
local Save=require('src.save')
local function check(v,msg) assert(v,msg) end
local function target(world,team,kind,cx,cy)
  for _,e in ipairs(world.entities) do
    if e.team==team and e.kind==kind and e.x==cx*world.tile and e.y==cy*world.tile then
      return e
    end
  end
  error('Expected target absent')
end
local descriptor,err=Mission.load('training_operations')
check(descriptor,err)
check(descriptor.objective.kind=='sequence' and #descriptor.objective.steps==3,
  'experimental staged mission was not loaded')
check(#descriptor.events==3 and descriptor.events[3].trigger.kind=='structure_destroyed',
  'new event triggers were not decoded')
local scene=assert(World.new('scenario',3,360,descriptor))
check(scene.missionStage==1 and scene.missionStageSince==0,'initial stage not set')
check(Rules.label(scene):find('ETAPA 1/3:',1,true),'first objective absent from HUD')
local cash=scene.money[1]
scene.elapsed=8;Rules.tick(scene)
check(scene.money[1]==cash+100 and scene.missionEventDone[1],
  'timed event failed within a staged mission')
Rules.tick(scene)
check(scene.money[1]==cash+100,'timed event duplicated')
scene.elapsed=19.9;Rules.tick(scene)
check(scene.missionStage==1,'protection prematurely completed')
scene.elapsed=20;Rules.tick(scene)
check(scene.missionStage==2 and scene.missionStageSince==20,'stage 1 did not advance')
check(scene.money[1]==cash+250 and scene.missionEventDone[2],
  'stage start credit event not applied once')
check(Rules.label(scene):find('ETAPA 2/3:',1,true),'second objective HUD missing')
Rules.tick(scene)
check(scene.money[1]==cash+250,'stage reward repeated')
local written
love={filesystem={
  write=function(_,v) written=v;return true end,
  getInfo=function() return written and {} or nil end,
  read=function() return written end,
}}
check(Save.write(scene),'staged mission save failed')
local restored,why=Save.read(World)
check(restored,why)
check(restored.missionStage==2 and restored.missionStageSince==20,
  'staged mission cursor/time lost on restore')
check(restored.missionEventDone[1] and restored.missionEventDone[2],
  'trigger event state lost in save')
local moneyBefore=restored.money[1]
Rules.tick(restored)
check(restored.money[1]==moneyBefore,'restored mission duplicated reward')
local enemyBarracks=target(restored,2,'barracks',31,13)
enemyBarracks.alive=false
restored:refreshBlocked()
local countBefore=#restored.entities
restored.elapsed=24;Rules.tick(restored)
check(restored.missionStage==3 and restored.missionStageSince==24,
  'destroying specified structure did not finish second stage')
check(restored.missionEventDone[3] and #restored.entities==countBefore+1,
  'destruction triggered reinforcement failed')
local countAfter=#restored.entities
Rules.tick(restored)
check(#restored.entities==countAfter,'destruction event duplicated')
restored.elapsed=48.99;Rules.tick(restored)
check(restored.result==nil,'third stage ended prematurely')
restored.elapsed=49;Rules.tick(restored)
check(restored.result=='VITORIA','final stage victory not recognized')
check(Rules.label(restored)=='MISSAO CONCLUIDA','completion label invalid')
-- Protecting a specific structure must fail when that structure is destroyed.
local lost=assert(World.new('scenario',3,361,descriptor))
target(lost,1,'barracks',5,13).alive=false
lost.elapsed=3;Rules.tick(lost)
check(lost.result=='DERROTA','loss of protected building was ignored')
-- Losing an unrelated building must not count as loss of the protected one.
local unrelated=assert(World.new('scenario',3,362,descriptor))
target(unrelated,1,'factory',9,7).alive=false
unrelated.elapsed=3;Rules.tick(unrelated)
check(unrelated.result==nil and unrelated.missionStage==1,
  'unrelated building incorrectly failed protection')
-- Neither target can be invented outside the validated initial map.
local unsupported={}
for k,v in pairs(descriptor) do unsupported[k]=v end
unsupported.objective={kind='sequence',steps={{kind='destroy_structure',team=2,
  structure='turret',x=21,y=21}}}
check(not Mission.validate(unsupported),'nonexistent objective target accepted')
unsupported.objective={kind='sequence',steps={{kind='protect_structure',team=1,
  structure='barracks',x=5,y=13,seconds=8}}}
unsupported.events={{trigger={kind='structure_destroyed',team=2,
  structure='factory',x=18,y=22},action='credits',team=1,amount=50}}
check(not Mission.validate(unsupported),'nonexistent destruction event target accepted')
check(not Rules.validate({kind='sequence',steps={}}, {},36,26),'empty sequence accepted')
check(not Rules.validate({kind='sequence',steps={{kind='capture_structure'}}},{},36,26),
  'unknown objective step accepted')
check(not Rules.validate({kind='survive',seconds=30},
  {{trigger={kind='stage_start',step=1},team=1,action='credits',amount=5}},36,26),
  'stage trigger on non-staged mission accepted')
check(not Rules.validate(descriptor.objective,
  {{at=10,trigger={kind='stage_start',step=2},team=1,action='credits',amount=5}},36,26),
  'ambiguous multiple event triggers accepted')
check(not Rules.validate(descriptor.objective,
  {{trigger={kind='stage_start',step=9},team=1,action='credits',amount=5}},36,26),
  'unreachable stage event accepted')
-- Bad stage cursor/relative timer must never be loaded from modified saves.
local corrupted=assert(World.new('scenario',3,363,descriptor))
corrupted.missionStage=99
check(Save.write(corrupted),'could not prepare tampered save')
local invalid,saveError=Save.read(World)
check(not invalid and saveError:find('etapas'),'invalid stage cursor accepted')
corrupted.missionStage=2;corrupted.missionStageSince=999
check(Save.write(corrupted),'could not prepare tampered stage time')
invalid,saveError=Save.read(World)
check(not invalid and saveError:find('etapas'),'future stage time accepted')
-- File contents must remain inert (no code execution or filesystem access).
check(not Mission.decode('return {format=1, os.execute("id")}'),
  'unsafe mission source accepted')
print('STAGED MISSION REGRESSIONS PASSED')
