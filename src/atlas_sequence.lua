-- Validated QUAD animation data. No evaluation of CSV or external Lua files.
-- The game accepts only hand-reviewed 'verified' manifests shipped in source.
local Regions=require('src.atlas_regions')
local Sequence={}
local VALID_SPRITES={blue_infantry=true,red_infantry=true,blue_tank=true,red_tank=true,
  blue_turret=true,red_turret=true,explosion=true}
local VALID_STATES={idle=true,walk=true,attack=true,death=true}
local function integer(n) return type(n)=='number' and n==math.floor(n) end
function Sequence.validate(entry,dimensions)
  if type(entry)~='table' or entry.verification~='verified' then return false,'verification required' end
  if type(entry.frames)~='table' or #entry.frames<1 or #entry.frames>64 then return false,'frames' end
  if type(entry.fps)~='number' or entry.fps~=entry.fps or entry.fps<1 or entry.fps>30 then return false,'fps' end
  if entry.loop~=nil and type(entry.loop)~='boolean' then return false,'loop' end
  -- Once original frame durations are recovered from the JAR, exact
  -- millisecond timing can override a constant FPS without changing rules.
  if entry.durations_ms~=nil then
    if type(entry.durations_ms)~='table' or #entry.durations_ms~=#entry.frames then
      return false,'durations length'
    end
    local total=0
    for i=1,#entry.frames do
      local ms=entry.durations_ms[i]
      if not integer(ms) or ms<1 or ms>5000 then return false,'duration' end
      total=total+ms
    end
    if total>60000 then return false,'timeline too long' end
  end
  for _,frame in ipairs(entry.frames) do
    if type(frame)~='table' then return false,'frame' end
    local dim=dimensions[frame.atlas]
    if not dim or not Regions.validate(frame.atlas,frame,dim[1],dim[2]) then
      return false,'out of bounds or missing atlas'
    end
    if not (integer(frame.x) and integer(frame.y) and integer(frame.w) and integer(frame.h)) then
      return false,'noninteger frame'
    end
  end
  return true
end
function Sequence.build(catalog,dimensions,loadTexture,newQuad)
  local output,errors={},{}
  for name,states in pairs(catalog or {}) do
    if not VALID_SPRITES[name] or type(states)~='table' then
      errors[#errors+1]='invalid sprite: '..tostring(name)
    else
      for state,entry in pairs(states) do
        if not VALID_STATES[state] then
          errors[#errors+1]=name..'.'..tostring(state)..': invalid state'
        else
          local valid,why=Sequence.validate(entry,dimensions)
          if valid then
            local frames={}
            for _,region in ipairs(entry.frames) do
              local image=loadTexture(region.atlas)
              if image then
                local ok,quad=pcall(newQuad,region.x,region.y,region.w,region.h,
                  dimensions[region.atlas][1],dimensions[region.atlas][2])
                if ok and quad then
                  frames[#frames+1]={image=image,quad=quad,w=region.w,h=region.h}
                end
              end
            end
            -- Atomic: an incomplete sequence must not play partially.
            if #frames==#entry.frames then
              output[name]=output[name] or {}
              output[name][state]={frames=frames,fps=entry.fps,loop=entry.loop~=false,
                durations_ms=entry.durations_ms}
            else errors[#errors+1]=name..'.'..state..': texture/quad unavailable' end
          else errors[#errors+1]=name..'.'..state..': '..why end
        end
      end
    end
  end
  return output,errors
end
-- Pure frame selection: time is local to the current visual state, not
-- elapsed mission time. Non-looping actions hold their last frame.
function Sequence.frameIndex(sequence,time)
  if not sequence or not sequence.frames or #sequence.frames==0 then return nil end
  local t=tonumber(time) or 0
  if t~=t or t==math.huge or t==-math.huge then t=0 end
  t=math.max(0,t)
  local count=#sequence.frames
  if sequence.durations_ms then
    local durations=sequence.durations_ms
    local total=0
    for i=1,count do total=total+durations[i] end
    if total<=0 then return 1 end
    local elapsed=t*1000
    if sequence.loop then elapsed=elapsed%total
    elseif elapsed>=total then return count end
    local cumulative=0
    for i=1,count do
      cumulative=cumulative+durations[i]
      if elapsed<cumulative then return i end
    end
    return count
  end
  local idx=math.floor(t*(sequence.fps or 1))
  if sequence.loop then return idx%count+1 end
  return math.min(count,idx+1)
end
return Sequence
