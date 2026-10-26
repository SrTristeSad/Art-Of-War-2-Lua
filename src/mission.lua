-- V0.17 experimental mission format. Table literals are parsed, NOT executed.
-- This module does not claim any format or mission from the original J2ME JAR.
local SafeTable=require('src.safe_table')
local MissionRules=require('src.mission_rules')
local Mission={}
local kinds={hq=true,barracks=true,factory=true,turret=true,infantry=true,tank=true}
local scenery={rocks=true,forest=true}
local terrainCodes={g='grass',G='grass2',d='dirt',D='dirt2'}
local function integer(n,lo,hi)
  return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi
end
local function dense(t,max)
  if type(t)~='table' then return false end
  local count=0
  for k in pairs(t) do
    if not integer(k,1,max) then return false end
    count=count+1
  end
  if count~=#t then return false end
  for i=1,count do if t[i]==nil then return false end end
  return true
end
function Mission.validate(m)
  if type(m)~='table' or m.format~=1 or m.provenance~='experimental' then
    return nil,'Formato de missao nao reconhecido ou origem nao declarada'
  end
  if type(m.id)~='string' or not m.id:match('^[%w_%-]+$') or #m.id>60 then
    return nil,'Identificador de mapa invalido'
  end
  if not integer(m.width,16,96) or not integer(m.height,16,96) then
    return nil,'Dimensoes de mapa invalidas'
  end
  if not dense(m.rows,m.height) or #m.rows~=m.height then
    return nil,'Quantidade de linhas de terreno invalida'
  end
  for y=1,m.height do
    if type(m.rows[y])~='string' or #m.rows[y]~=m.width then
      return nil,'Linha de terreno com largura invalida'
    end
    for x=1,m.width do
      if not terrainCodes[m.rows[y]:sub(x,x)] then return nil,'Codigo de terreno invalido' end
    end
  end
  if not dense(m.obstacles,3000) or not dense(m.entities,150) then
    return nil,'Lista de objetos invalida'
  end
  if #m.entities>150 or #m.obstacles>3000 then return nil,'Quantidade excessiva de objetos' end
  local occupied={}
  for _,o in ipairs(m.obstacles) do
    if type(o)~='table' or not integer(o.x,1,m.width) or not integer(o.y,1,m.height)
       or not scenery[o.typeName] then return nil,'Obstaculo invalido' end
    local key=o.y*m.width+o.x
    if occupied[key] then return nil,'Obstaculos sobrepostos' end
    occupied[key]=true
  end
  local hq={[1]=0,[2]=0}
  for _,e in ipairs(m.entities) do
    if type(e)~='table' or not kinds[e.kind] or not integer(e.team,1,2)
       or not integer(e.x,2,m.width-1) or not integer(e.y,2,m.height-1) then
      return nil,'Unidade inicial invalida'
    end
    if e.kind=='hq' then hq[e.team]=hq[e.team]+1 end
    local b=e.kind=='hq' or e.kind=='barracks' or e.kind=='factory' or e.kind=='turret'
    local radius=b and (e.kind=='hq' and 2 or 1) or 0
    for yy=e.y-radius,e.y+radius do for xx=e.x-radius,e.x+radius do
      local key=yy*m.width+xx
      if xx<1 or yy<1 or xx>m.width or yy>m.height or occupied[key] then
        return nil,'Estrutura/unidade sobre obstaculo ou fora do mapa'
      end
      occupied[key]=true
    end end
  end
  if hq[1]~=1 or hq[2]~=1 then return nil,'Mapa exige exatamente um QG por time' end
  if type(m.money)~='table' or type(m.income)~='table' then
    return nil,'Economia inicial ausente'
  end
  for t=1,2 do
    if not integer(m.money[t],0,50000) or not integer(m.income[t],0,100) then
      return nil,'Economia inicial invalida'
    end
  end
  local rulesOK,rulesErr=MissionRules.validate(m.objective,m.events,m.width,m.height,m.entities)
  if not rulesOK then return nil,rulesErr end
  return true
end
function Mission.decode(source)
  local descriptor,parseError=SafeTable.decode(source)
  if not descriptor then return nil,parseError end
  local ok,err=Mission.validate(descriptor)
  if not ok then return nil,err end
  return descriptor
end
-- Only IDs in this allowlist may be read. No arbitrary filesystem paths.
local builtin={training_crossroads='missions/training_crossroads.tbl',
  training_operations='missions/training_operations.tbl'}
function Mission.load(id)
  local filename=builtin[id]
  if not filename then return nil,'Missao desconhecida' end
  local content
  if love and love.filesystem and love.filesystem.read then
    content=love.filesystem.read(filename)
  else
    local f=io.open(filename,'rb')
    if f then content=f:read('*a');f:close() end
  end
  if not content then return nil,'Arquivo de missao ausente: '..filename end
  local descriptor,err=Mission.decode(content)
  if descriptor and descriptor.id~=id then return nil,'ID do arquivo nao corresponde a missao' end
  return descriptor,err
end
function Mission.apply(world,descriptor)
  local ok,err=Mission.validate(descriptor)
  if not ok then return nil,err end
  -- Validation completes before anything in world is touched.
  world.w,world.h=descriptor.width,descriptor.height
  world.terrain={};world.obstacles={};world.entities={};world.selected={};world.nextId=0
  world.mapId=descriptor.id
  world.missionObjective=descriptor.objective or {kind='destroy_hq'}
  world.missionEvents=descriptor.events or {}
  world.missionEventDone={}
  world.missionStage=world.missionObjective.kind=='sequence' and 1 or nil
  world.missionStageSince=world.missionStage and world.elapsed or nil
  world.money={[1]=descriptor.money[1],[2]=descriptor.money[2]}
  world.income={[1]=descriptor.income[1],[2]=descriptor.income[2]}
  for y=1,world.h do
    world.terrain[y]={}
    for x=1,world.w do
      world.terrain[y][x]=terrainCodes[descriptor.rows[y]:sub(x,x)]
    end
  end
  for _,o in ipairs(descriptor.obstacles) do
    world.obstacles[#world.obstacles+1]={x=o.x,y=o.y,typeName=o.typeName}
  end
  world:refreshBlocked()
  for _,e in ipairs(descriptor.entities) do
    world:add(e.kind,e.team,e.x*world.tile,e.y*world.tile)
  end
  world:refreshBlocked()
  world.camera={x=0,y=0}
  world:toast('Mapa experimental: '..descriptor.id)
  return true
end
return Mission
