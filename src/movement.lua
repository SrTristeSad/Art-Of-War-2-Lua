-- Collision and local crowd avoidance for the provisional RTS engine.
-- A deliberately separate module: these measurements are NOT extracted
-- from the original J2ME game and must be calibrated if the JAR is recovered.
local Movement = {}
local TILE = 16
local function radius(entity)
  if entity.kind == 'tank' then return 7.3 end
  return 4.5 -- infantry
end
Movement.radius = radius

local function blockedTile(world, gx, gy)
  return gx < 1 or gy < 1 or gx > world.w or gy > world.h
      or world.blocked[gy * world.w + gx]
end

-- Circle/AABB test: the unit's *footprint*, not only its center, must
-- clear blocked map cells. Tile coordinate N has center at N*16.
local function solidClear(world, x, y, r)
  local minx = math.floor((x-r)/TILE+0.5)
  local maxx = math.floor((x+r)/TILE+0.5)
  local miny = math.floor((y-r)/TILE+0.5)
  local maxy = math.floor((y+r)/TILE+0.5)
  for gy=miny,maxy do for gx=minx,maxx do
    if blockedTile(world,gx,gy) then
      local left,right=(gx-.5)*TILE,(gx+.5)*TILE
      local top,bottom=(gy-.5)*TILE,(gy+.5)*TILE
      local px=math.max(left,math.min(x,right))
      local py=math.max(top,math.min(y,bottom))
      if (x-px)^2+(y-py)^2 < r*r-1e-7 then return false end
    end
  end end
  return true
end
Movement.solidClear=solidClear

function Movement.canOccupy(world,entity,x,y)
  local r=radius(entity)
  if not solidClear(world,x,y,r) then return false end
  for _,other in ipairs(world.entities) do
    if other~=entity and other.alive and not other.building then
      local sum=r+radius(other)
      if (x-other.x)^2+(y-other.y)^2 < sum*sum-1e-7 then
        return false
      end
    end
  end
  return true
end

-- Follow the planned waypoint, then probe deterministic side angles if
-- another unit is occupying the direct route. Never teleport or phase
-- through blocked terrain. Opposite ID parity prefers opposite sides.
function Movement.advance(world,entity,tx,ty,step)
  local dx,dy=tx-entity.x,ty-entity.y
  local d=math.sqrt(dx*dx+dy*dy)
  if d<1e-6 or step<=0 then return false end
  step=math.min(step,d)
  local vx,vy=dx/d,dy/d
  local preference=(entity.id%2==0) and 1 or -1
  for _,angle in ipairs({0,.38,-.38,.78,-.78,1.18,-1.18,1.53,-1.53}) do
    local a=angle*preference
    local ca,sa=math.cos(a),math.sin(a)
    local ux,uy=vx*ca-vy*sa,vx*sa+vy*ca
    local nx,ny=entity.x+ux*step,entity.y+uy*step
    if Movement.canOccupy(world,entity,nx,ny) then
      entity.angle=(math.atan2 and math.atan2(uy,ux)) or math.atan(uy,ux)
      entity.x,entity.y=nx,ny
      return true, angle~=0
    end
  end
  return false, false
end

-- Congestion-aware replanning only when local avoidance has been blocked
-- repeatedly. Do not change the permanent blocked grid or the saves.
function Movement.trafficMap(world,entity)
  local blocked={}
  for k,v in pairs(world.blocked) do blocked[k]=v end
  local sx=math.floor(entity.x/TILE+.5)
  local sy=math.floor(entity.y/TILE+.5)
  for _,other in ipairs(world.entities) do
    if other~=entity and other.alive and not other.building then
      local gx=math.floor(other.x/TILE+.5)
      local gy=math.floor(other.y/TILE+.5)
      if gx>=1 and gy>=1 and gx<=world.w and gy<=world.h
         and not (gx==sx and gy==sy) then
        -- Never block the start tile: nearby units can share a grid
        -- coordinate without physically overlapping.
        blocked[gy*world.w+gx]=true
      end
    end
  end
  return {w=world.w,h=world.h,blocked=blocked}
end
return Movement
