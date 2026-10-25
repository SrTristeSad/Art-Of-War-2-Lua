-- Visual timeline for the prototype. This does not modify the RTS simulation.
-- True J2ME frame orders and durations remain unverified without the original JAR.
local Animation={}

function Animation.state(entity)
  if entity.building then return 'idle' end
  if (entity.firePulse or 0)>0 then return 'attack' end
  if entity.order then return 'walk' end
  return 'idle'
end

function Animation.frame(time,frames,fps)
  frames=math.max(1,math.floor(tonumber(frames) or 1))
  fps=math.max(0.01,tonumber(fps) or 1)
  return math.floor(math.max(0,time or 0)*fps)%frames+1
end

function Animation.offset(state,time)
  -- Subpixel displacement is only a temporary placeholder for unprovided frames.
  if state=='walk' then return math.sin((time or 0)*15)*0.85 end
  if state=='attack' then return -0.65 end
  return math.sin((time or 0)*2)*0.15
end

return Animation
