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
              output[name][state]={frames=frames,fps=entry.fps,loop=entry.loop~=false}
            else errors[#errors+1]=name..'.'..state..': texture/quad unavailable' end
          else errors[#errors+1]=name..'.'..state..': '..why end
        end
      end
    end
  end
  return output,errors
end
return Sequence
