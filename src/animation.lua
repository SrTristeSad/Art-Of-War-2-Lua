-- Visual-only animation state. No movement/attack rule may depend on this module.
-- State time restarts when a unit begins moving or attacks; global lifetime
-- must not be used to select the first frame of a new animation.
local Animation={}

function Animation.state(entity)
  if entity.building then return 'idle' end
  if (entity.firePulse or 0)>0 then return 'attack' end
  -- Orders do not prove movement: a blocked unit may be stationary forever.
  if entity.moving then return 'walk' end
  return 'idle'
end

function Animation.advance(entity,dt,attackStarted)
  local state=Animation.state(entity)
  if entity.animationState~=state or attackStarted then
    entity.animationState=state
    entity.animationTime=0
  else
    entity.animationTime=(entity.animationTime or 0)+math.max(0,dt or 0)
  end
  return state,entity.animationTime
end

function Animation.frame(time,frames,fps)
  frames=math.max(1,math.floor(tonumber(frames) or 1))
  fps=math.max(0.01,tonumber(fps) or 1)
  return math.floor(math.max(0,time or 0)*fps)%frames+1
end

function Animation.offset(state,time)
  -- Placeholder displacement, not an animation recovered from J2ME.
  if state=='walk' then return math.sin((time or 0)*15)*0.85 end
  if state=='attack' then return -0.65 end
  return math.sin((time or 0)*2)*0.15
end
return Animation
