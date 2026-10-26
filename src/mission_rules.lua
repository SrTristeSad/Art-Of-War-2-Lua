-- Declarative rules for EXPERIMENTAL missions. Never execute text from mission files.
-- No assertion here implies equivalence to Art of War 2 J2ME missions.
local Movement=require('src.movement')
local Rules={}
local function integer(v,lo,hi)
  return type(v)=='number' and v==math.floor(v) and v>=lo and v<=hi
end
local function dense(t,limit)
  if type(t)~='table' then return false end
  local n=0
  for k in pairs(t) do
    if not integer(k,1,limit) then return false end
    n=n+1
  end
  if n>limit or n~=#t then return false end
  for i=1,n do if t[i]==nil then return false end end
  return true
end
function Rules.validate(objective,events,width,height)
  if objective~=nil then
    if type(objective)~='table' then return nil,'Objetivo invalido' end
    if objective.kind=='survive' then
      if not integer(objective.seconds,1,3600) then return nil,'Duracao invalida para sobreviver' end
    elseif objective.kind~='destroy_hq' and objective.kind~='eliminate_units' then
      return nil,'Tipo de objetivo desconhecido'
    end
  end
  if events~=nil then
    if not dense(events,16) then return nil,'Eventos invalidos ou excessivos' end
    for _,ev in ipairs(events) do
      if type(ev)~='table' or not integer(ev.at,1,3600)
        or not integer(ev.team,1,2) then
        return nil,'Evento com tempo ou time invalido'
      end
      if ev.action=='credits' then
        if not integer(ev.amount,1,5000) then return nil,'Valor de credito invalido' end
      elseif ev.action=='reinforce' then
        if (ev.kind~='infantry' and ev.kind~='tank')
          or not integer(ev.x,2,width-1) or not integer(ev.y,2,height-1) then
          return nil,'Reforco fora do mapa ou de tipo invalido'
        end
      else return nil,'Acao de evento desconhecida' end
    end
  end
  return true
end
local function alive(world,team,kind,combatOnly)
  for _,e in ipairs(world.entities) do
    if e.alive and e.team==team and (not kind or e.kind==kind)
      and (not combatOnly or not e.building) then return true end
  end
  return false
end
function Rules.label(world)
  local obj=world.missionObjective
  if not obj then return nil end
  if obj.kind=='survive' then
    return 'SOBREVIVA '..math.max(0,math.ceil(obj.seconds-world.elapsed-1e-9))..'s'
  elseif obj.kind=='eliminate_units' then
    return 'ELIMINE AS TROPAS INIMIGAS'
  end
  return 'DESTRUA O QG INIMIGO'
end
function Rules.tick(world)
  if world.result or not world.missionObjective then return end
  for index,ev in ipairs(world.missionEvents or {}) do
    if not world.missionEventDone[index] and world.elapsed+1e-9>=ev.at then
      -- One-shot even when the reinforcement destination becomes obstructed:
      -- no infinite retry and no duplicate rewards after loading a save.
      world.missionEventDone[index]=true
      if ev.action=='credits' then
        world.money[ev.team]=world.money[ev.team]+ev.amount
        world:toast('Evento: +'..ev.amount..' creditos, equipe '..ev.team)
      elseif ev.action=='reinforce' then
        local x,y=ev.x*world.tile,ev.y*world.tile
        if Movement.canOccupy(world,{kind=ev.kind,x=x,y=y},x,y) then
          world:add(ev.kind,ev.team,x,y)
          world:toast('Reforco recebido: '..ev.kind)
        else
          world:toast('Evento: reforco bloqueado')
        end
      end
    end
  end
  -- Player HQ is mandatory for every prototype objective.
  if not alive(world,1,'hq') then world.result='DERROTA';return end
  local obj=world.missionObjective
  if obj.kind=='survive' then
    if world.elapsed+1e-9>=obj.seconds then world.result='VITORIA' end
  elseif obj.kind=='eliminate_units' then
    if not alive(world,2,nil,true) then world.result='VITORIA' end
  elseif obj.kind=='destroy_hq' then
    if not alive(world,2,'hq') then world.result='VITORIA' end
  end
end
return Rules
