-- Experimental map loading must preserve dimensions and never execute input.
package.path='./?.lua;./?/init.lua;'..package.path
local Mission=require('src.mission')
local World=require('src.world')
local Save=require('src.save')
local Movement=require('src.movement')
local function check(ok,why) assert(ok,why) end
local definition,err=Mission.load('training_crossroads')
check(definition,err)
check(definition.width==36 and definition.height==26,'wrong mission geometry')
check(definition.provenance=='experimental','misleading provenance')
local scene,reason=World.new('scenario',2,1517,definition)
check(scene,reason)
check(scene.w==36 and scene.h==26,'map dimensions ignored')
check(scene.mapId==definition.id,'map identifier lost')
check(scene.terrain[11][18]=='dirt' or scene.terrain[11][18]=='dirt2','terrain codes ignored')
check(#scene.entities==#definition.entities,'starting roster mismatch')
check(#scene.obstacles==#definition.obstacles,'missing obstacles')
for _,unit in ipairs(scene.entities) do
  if not unit.building then
    check(Movement.canOccupy(scene,unit,unit.x,unit.y),
      'mission spawned unit in obstruction')
  end
end
local saved
love={filesystem={write=function(_,s) saved=s;return true end,
 getInfo=function() return true end,read=function() return saved end}}
check(Save.write(scene),'failed to save experimental map')
local restored,restoreErr=Save.read(World)
check(restored,restoreErr)
check(restored.w==36 and restored.h==26,'save altered map geometry')
check(restored.mapId==definition.id,'save dropped map id')
check(#restored.entities==#scene.entities,'save dropped units')
restored:update(1/30)
local before=World.new('scenario',1,1517)
check(before.w==46 and before.h==38,'legacy/procedural mode changed')
-- Untrusted data parsing is a data-only operation, never Lua execution.
local injected='return (function() _G.SHOULD_NOT_EXECUTE=true end)()'
local malicious=Mission.decode(injected)
check(malicious==nil and _G.SHOULD_NOT_EXECUTE==nil,'unsafe Lua mission evaluation')
local invalid=Mission.load('../save.lua')
check(invalid==nil,'unrestricted arbitrary mission file paths')
local missing={}
for k,v in pairs(definition) do missing[k]=v end
missing.rows={[1]='g'}
local notValid=Mission.validate(missing)
check(notValid==nil,'accepted truncated terrain')
local broken={}
for k,v in pairs(definition) do broken[k]=v end
broken.width=97
check(Mission.validate(broken)==nil,'accepted map too large')
local brokenWorld,invalidReason=World.new('scenario',2,1517,broken)
check(brokenWorld==nil and invalidReason,'World.new silently accepted invalid scenario')
print('MISSION LOADER REGRESSIONS PASSED')
