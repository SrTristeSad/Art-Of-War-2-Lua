-- v0.18: data-only objectives and one-shot timed events.
-- These are prototype rules, not reconstructed canonical missions.
package.path='./?.lua;./?/init.lua;'..package.path
local Mission=require('src.mission')
local Rules=require('src.mission_rules')
local World=require('src.world')
local Save=require('src.save')
local function check(value,message) assert(value,message) end
local descriptor,err=Mission.load('training_crossroads')
check(descriptor,err)
check(descriptor.objective.kind=='survive' and descriptor.objective.seconds==90,'wrong objective')
check(#descriptor.events==3,'timed events not read')
local scene=assert(World.new('scenario',2,335,descriptor))
check(Rules.label(scene)=='SOBREVIVA 90s','initial HUD objective label wrong')
local base=scene.money[1]
local entities=#scene.entities
scene.elapsed=12
Rules.tick(scene)
check(scene.money[1]==base+175,'credits event did not fire')
check(scene.missionEventDone[1]==true,'credits event was not marked')
Rules.tick(scene)
check(scene.money[1]==base+175,'repeated event granted credits twice')
scene.elapsed=22
Rules.tick(scene)
check(scene.missionEventDone[2]==true,'reinforcement event not marked')
check(#scene.entities==entities+1,'enemy reinforcement was not spawned')
check(scene.entities[#scene.entities].team==2,'enemy reinforcement wrong team')
scene.elapsed=25
check(scene.result==nil,'survival completed prematurely')
local saved
love={filesystem={
 write=function(_,data) saved=data;return true end,
 getInfo=function() return saved and {} or nil end,
 read=function() return saved end,
}}
check(Save.write(scene),'mission could not be saved')
local loaded,readError=Save.read(World)
check(loaded,readError)
check(loaded.missionObjective.kind=='survive' and loaded.missionObjective.seconds==90,
 'objective lost on restore')
check(loaded.missionEventDone[1] and loaded.missionEventDone[2],
 'event completion lost on restore')
local moneyBefore=loaded.money[1]
local countBefore=#loaded.entities
Rules.tick(loaded)
check(loaded.money[1]==moneyBefore and #loaded.entities==countBefore,
 'restored mission duplicated events')
loaded.elapsed=45
Rules.tick(loaded)
check(loaded.missionEventDone[3],'all event completions must persist')
local finalCount=#loaded.entities
Rules.tick(loaded)
check(#loaded.entities==finalCount,'third event ran twice')
-- Enemy HQ destruction is not a survival victory condition.
for _,e in ipairs(loaded.entities) do
 if e.alive and e.team==2 and e.kind=='hq' then e.alive=false end
end
loaded.elapsed=89
Rules.tick(loaded)
check(loaded.result==nil,'enemy HQ incorrectly ended survival mission')
loaded.elapsed=90
Rules.tick(loaded)
check(loaded.result=='VITORIA','survival objective was not completed')
-- Eliminate hostile mobile units, regardless of surviving enemy structures.
local wipe=assert(World.new('scenario',2,336,descriptor))
wipe.missionObjective={kind='eliminate_units'}
wipe.missionEvents={};wipe.missionEventDone={}
for _,e in ipairs(wipe.entities) do
 if e.team==2 and not e.building then e.alive=false end
end
Rules.tick(wipe)
check(wipe.result=='VITORIA','elimination objective not recognized')
-- Player's HQ destruction always loses, even before a survival deadline.
local defend=assert(World.new('scenario',2,337,descriptor))
for _,e in ipairs(defend.entities) do
 if e.kind=='hq' and e.team==1 then e.alive=false end
end
Rules.tick(defend)
check(defend.result=='DERROTA','player HQ death not recognized')
-- Tick integration, not just direct test of the rules library.
local timer=assert(World.new('scenario',2,338,descriptor))
timer.missionObjective={kind='survive',seconds=1}
timer.missionEvents={};timer.missionEventDone={}
for _=1,30 do timer:update(1/30) end
check(timer.result=='VITORIA','World fixed update did not dispatch mission rules')
-- Validation must reject arbitrary or excessive event definitions.
local cases={
 {kind='survive',seconds=-1}, {kind='unknown'},
}
for _,objective in ipairs(cases) do
 check(not Rules.validate(objective,{},36,26),'invalid objective accepted')
end
check(not Rules.validate({kind='destroy_hq'},{{at=0,action='credits',team=1,amount=10}},36,26),
 'event at zero accepted')
check(not Rules.validate({kind='survive',seconds=50},{{at=4,action='eval',team=1}},36,26),
 'executable event accepted')
check(not Rules.validate(nil,{{at=12,action='reinforce',kind='tank',team=1,x=36,y=3}},36,26),
 'out-of-bounds spawn accepted')
local malformed={}
for k,v in pairs(descriptor) do malformed[k]=v end
malformed.events={{at=999999,action='credits',team=1,amount=10}}
check(not Mission.validate(malformed),'malformed mission event accepted')
check(not Mission.decode('return (function() os.execute("id") end)()'),
 'data parser executed injected script')
-- Blocked spawn must not become an infinite retry/duplication loop.
local jam=assert(World.new('scenario',2,339,descriptor))
local ev=jam.missionEvents[2]
jam:add('tank',1,ev.x*jam.tile,ev.y*jam.tile)
local before=#jam.entities
jam.elapsed=22
Rules.tick(jam)
check(jam.missionEventDone[2] and #jam.entities==before,
 'blocked reinforcement was spawned or left pending')
print('MISSION OBJECTIVES REGRESSIONS PASSED')
