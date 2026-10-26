-- Declarative EXPERIMENTAL mission rules. Never execute external mission text.
-- No rule or timing in this file is claimed to be part of the original J2ME game.
local Movement=require('src.movement')
local Rules={}
local structures={hq=true,barracks=true,factory=true,turret=true}
local function integer(v,lo,hi)
  return type(v)=='number' and v==math.floor(v) and v>=lo and v<=hi
end
local function dense(t,limit)
  if type(t)~='table' then return false end
  local n=0
  for k in pairs(t) do if not integer(k,1,limit) then return false end;n=n+1 end
  if n>limit or n~=#t then return false end
  for i=1,n do if t[i]==nil then return false end end
  return true
end
local function reference(ref,width,height)
  return type(ref)=='table' and structures[ref.structure]
    and integer(ref.team,1,2)
    and integer(ref.x,2,width-1) and integer(ref.y,2,height-1)
end
local function stepValid(step,width,height)
  if type(step)~='table' then return false end
  if step.kind=='survive' then
    return integer(step.seconds,1,3600)
  elseif step.kind=='protect_structure' then
    return reference(step,width,height) and step.team==1
      and integer(step.seconds,1,3600)
  elseif step.kind=='destroy_structure' then
    return reference(step,width,height) and step.team==2
  end
  return false
end
local function validateReferences(objective,events,entities)
  if not entities then return true end -- Saves contain pixel coordinates; validated at mission import.
  local function exists(ref)
    for _,e in ipairs(entities) do
      if e.kind==ref.structure and e.team==ref.team and e.x==ref.x and e.y==ref.y then
        return true
      end
    end
    return false
  end
  if objective and objective.kind=='sequence' then
    for _,step in ipairs(objective.steps) do
      if step.structure and not exists(step) then return nil,'Alvo da etapa nao existe no mapa' end
    end
  end
  for _,ev in ipairs(events or {}) do
    if ev.trigger and ev.trigger.kind=='structure_destroyed' and not exists(ev.trigger) then
      return nil,'Gatilho de destruicao sem estrutura inicial'
    end
  end
  return true
end
function Rules.validate(objective,events,width,height,entities)
  if objective~=nil then
    if type(objective)~='table' then return nil,'Objetivo invalido' end
    if objective.kind=='survive' then
      if not integer(objective.seconds,1,3600) then return nil,'Duracao invalida para sobreviver' end
    elseif objective.kind=='sequence' then
      if not dense(objective.steps,8) or #objective.steps==0 then
        return nil,'Etapas de objetivo invalidas ou excessivas'
      end
      for _,step in ipairs(objective.steps) do
        if not stepValid(step,width,height) then return nil,'Etapa invalida' end
      end
    elseif objective.kind~='destroy_hq' and objective.kind~='eliminate_units' then
      return nil,'Tipo de objetivo desconhecido'
    end
  end
  if events~=nil then
    if not dense(events,16) then return nil,'Eventos invalidos ou excessivos' end
    for _,ev in ipairs(events) do
      if type(ev)~='table' or not integer(ev.team,1,2) then
        return nil,'Evento com time invalido'
      end
      if (ev.at==nil)==(ev.trigger==nil) then
        return nil,'Evento exige exatamente um gatilho'
      end
      if ev.at~=nil and not integer(ev.at,1,3600) then
        return nil,'Tempo de evento invalido'
      end
      if ev.trigger~=nil then
        local tr=ev.trigger
        if type(tr)~='table' then return nil,'Gatilho invalido' end
        if tr.kind=='stage_start' then
          if not objective or objective.kind~='sequence'
            or not integer(tr.step,1,#objective.steps) then
            return nil,'Etapa de evento invalida'
          end
        elseif tr.kind=='structure_destroyed' then
          if not reference(tr,width,height) then return nil,'Alvo de gatilho invalido' end
        else return nil,'Gatilho desconhecido' end
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
  return validateReferences(objective,events,entities)
end
local function alive(world,team,kind,combatOnly)
  for _,e in ipairs(world.entities) do
    if e.alive and e.team==team and (not kind or e.kind==kind)
      and (not combatOnly or not e.building) then return true end
  end
  return false
end
local function structureAlive(world,ref)
  for _,e in ipairs(world.entities) do
    if e.team==ref.team and e.kind==ref.structure
      and math.abs(e.x-ref.x*world.tile)<0.01
      and math.abs(e.y-ref.y*world.tile)<0.01 then
      return e.alive
    end
  end
  return false
end
local function stageDescription(world,step)
  if step.kind=='survive' then
    return 'RESISTA '..math.max(0,math.ceil(step.seconds-(world.elapsed-world.missionStageSince)-1e-9))..'s'
  elseif step.kind=='protect_structure' then
    return 'PROTEJA '..step.structure:upper()..' '..math.max(0,math.ceil(step.seconds-(world.elapsed-world.missionStageSince)-1e-9))..'s'
  end
  return 'DESTRUA '..step.structure:upper()..' INIMIGO'
end
function Rules.label(world)
  local obj=world.missionObjective
  if not obj then return nil end
  if obj.kind=='sequence' then
    local i=world.missionStage or 1
    local step=obj.steps[i]
    if not step then return 'MISSAO CONCLUIDA' end
    return 'ETAPA '..i..'/'..#obj.steps..': '..stageDescription(world,step)
  elseif obj.kind=='survive' then
    return 'SOBREVIVA '..math.max(0,math.ceil(obj.seconds-world.elapsed-1e-9))..'s'
  elseif obj.kind=='eliminate_units' then
    return 'ELIMINE AS TROPAS INIMIGAS'
  end
  return 'DESTRUA O QG INIMIGO'
end
local function eventTriggered(world,ev)
  if ev.at then return world.elapsed+1e-9>=ev.at end
  local tr=ev.trigger
  if tr.kind=='stage_start' then
    return (world.missionStage or 1)==tr.step
  elseif tr.kind=='structure_destroyed' then
    return not structureAlive(world,tr)
  end
  return false
end
local function fireEvents(world)
  world.missionEventDone=world.missionEventDone or {}
  for index,ev in ipairs(world.missionEvents or {}) do
    if not world.missionEventDone[index] and eventTriggered(world,ev) then
      -- One-shot even when the reinforcement destination becomes obstructed:
      -- no infinite retry and no duplicate rewards after a save/load.
      world.missionEventDone[index]=true
      if ev.action=='credits' then
        world.money[ev.team]=world.money[ev.team]+ev.amount
        world:toast('Evento: +'..ev.amount..' creditos, equipe '..ev.team)
      elseif ev.action=='reinforce' then
        local x,y=ev.x*world.tile,ev.y*world.tile
        if Movement.canOccupy(world,{kind=ev.kind,x=x,y=y},x,y) then
          world:add(ev.kind,ev.team,x,y)
          world:toast('Reforco recebido: '..ev.kind)
        else world:toast('Evento: reforco bloqueado') end
      end
    end
  end
end
function Rules.tick(world)
  if world.result or not world.missionObjective then return end
  -- Player HQ is mandatory for all provisional objectives.
  if not alive(world,1,'hq') then world.result='DERROTA';return end
  local obj=world.missionObjective
  if obj.kind=='sequence' then
    local index=world.missionStage or 1
    local step=obj.steps[index]
    if not step then world.result='VITORIA';return end
    local age=world.elapsed-(world.missionStageSince or 0)
    if step.kind=='protect_structure' and not structureAlive(world,step) then
      world.result='DERROTA';return
    end
    local completed=(step.kind=='survive' and age+1e-9>=step.seconds)
      or (step.kind=='protect_structure' and age+1e-9>=step.seconds)
      or (step.kind=='destroy_structure' and not structureAlive(world,step))
    if completed then
      world.missionStage=index+1
      world.missionStageSince=world.elapsed
      if world.missionStage>#obj.steps then
        world.result='VITORIA';return
      end
      world:toast('Etapa '..index..' concluida!')
    end
  elseif obj.kind=='survive' then
    if world.elapsed+1e-9>=obj.seconds then world.result='VITORIA';return end
  elseif obj.kind=='eliminate_units' then
    if not alive(world,2,nil,true) then world.result='VITORIA';return end
  elseif obj.kind=='destroy_hq' then
    if not alive(world,2,'hq') then world.result='VITORIA';return end
  end
  fireEvents(world)
end
return Rules
