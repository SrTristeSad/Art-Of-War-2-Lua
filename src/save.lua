local SafeTable=require('src.safe_table')
local Rules=require('src.mission_rules')
local Save={}
local SAVE_FORMAT=2
local function encode(v,depth)
  depth=depth or 0
  assert(depth<60,'Estrutura de save excedeu profundidade permitida')
  if type(v)=='number' then return tostring(v) end
  if type(v)=='boolean' then return tostring(v) end
  if type(v)=='string' then return string.format('%q',v) end
  if type(v)~='table' then return 'nil' end
  local result={'{'}
  for k,val in pairs(v) do
    if type(k)=='string' or type(k)=='number' then
      result[#result+1]='['..encode(k,depth+1)..']='..encode(val,depth+1)..','
    end
  end
  result[#result+1]='}'
  return table.concat(result)
end
function Save.write(world)
  local copy={format=SAVE_FORMAT}
  for _,key in ipairs({'seed','mode','level','elapsed','money','income','entities',
    'nextId','obstacles','terrain','camera','result','incomeTime','aiTime',
    'rngState','tickRemainder','w','h','tile','mapId',
    'missionObjective','missionEvents','missionEventDone',
    'missionStage','missionStageSince'}) do
    copy[key]=world[key]
  end
  -- Do not serialize transient navigation caches or mutate live entities.
  copy.entities={}
  for _,e in ipairs(world.entities) do
    local entity={}
    for k,v in pairs(e) do
      if k~='path' and k~='pathTime' and k~='blockedTime' and k~='steerTime' and k~='avoidCongestion' and k~='trafficYield' and k~='yieldCooldown' and k~='firePulse' and k~='hitPulse' and k~='animTime' and k~='animationTime' and k~='animationState' and k~='moving' then entity[k]=v end
    end
    copy.entities[#copy.entities+1]=entity
  end
  local ok,err=love.filesystem.write('save.lua','return '..encode(copy))
  return ok,err
end
function Save.read(World)
  if not love.filesystem.getInfo('save.lua') then return nil,'Nao existe jogo salvo' end
  local content,readError=love.filesystem.read('save.lua')
  if not content then return nil,readError or 'Falha ao ler save' end
  local data,errorMessage=SafeTable.decode(content)
  if not data then return nil,'Save invalido: '..tostring(errorMessage) end
  if type(data.seed)~='number' or type(data.entities)~='table' or type(data.money)~='table' then return nil,'Save incompleto' end
  if data.format and data.format~=SAVE_FORMAT then return nil,'Versao de save nao suportada' end
  if (data.w and (type(data.w)~='number' or data.w<16 or data.w>96 or data.w%1~=0))
      or (data.h and (type(data.h)~='number' or data.h<16 or data.h>96 or data.h%1~=0)) then
    return nil,'Dimensoes de save invalidas'
  end
  if (data.w==nil)~=(data.h==nil) or (data.tile~=nil and data.tile~=16) then
    return nil,'Geometria de save inconsistente'
  end
  if data.mapId~=nil and (type(data.mapId)~='string' or #data.mapId>60) then
    return nil,'Identificador de mapa invalido'
  end
  if data.missionObjective~=nil or data.missionEvents~=nil then
    local valid,why=Rules.validate(data.missionObjective,data.missionEvents,data.w or 46,data.h or 38)
    if not valid then return nil,'Regras de missao invalidas: '..tostring(why) end
    if data.missionObjective==nil then return nil,'Objetivo de missao ausente' end
    if type(data.missionEventDone)~='table' then return nil,'Estado dos eventos ausente' end
    for k,v in pairs(data.missionEventDone) do
      if type(k)~='number' or k%1~=0 or k<1 or k>#(data.missionEvents or {})
        or v~=true then return nil,'Estado dos eventos invalido' end
    end
    if data.missionObjective.kind=='sequence' then
      local count=#data.missionObjective.steps
      if type(data.elapsed)~='number' or data.elapsed~=data.elapsed
        or data.elapsed<0 or data.elapsed>86400
        or type(data.missionStage)~='number' or data.missionStage%1~=0
        or data.missionStage<1 or data.missionStage>count+1
        or type(data.missionStageSince)~='number' or data.missionStageSince<0
        or data.missionStageSince>(data.elapsed or -1)+1e-7 then
        return nil,'Estado das etapas invalido'
      end
    elseif data.missionStage~=nil or data.missionStageSince~=nil then
      return nil,'Save antigo contem etapas inesperadas'
    end
  end
  local world=World.new(data.mode,data.level,data.seed)
  for k,v in pairs(data) do world[k]=v end
  world.rngState=data.rngState or world.rngState
  world.tickRemainder=data.tickRemainder or 0
  world.selected={};world.buildMode=nil;world.noticeTimer=0
  world.effects={};world.preview=nil
  for _,e in ipairs(world.entities) do
    e.path=nil;e.pathTime=0;e.blockedTime=0;e.steerTime=0;e.avoidCongestion=false;e.trafficYield=nil;e.yieldCooldown=0
    e.moving=false;e.animationState='idle';e.animationTime=0;e.animTime=0
    e.firePulse=0;e.hitPulse=0
  end
  world:refreshBlocked();world:toast('Partida carregada.')
  return world
end
return Save
