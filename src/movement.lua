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

-- Test the entire movement segment, not just its endpoint. This prevents
-- tunneling through small units and walls when a mod introduces faster units
-- or a caller requests a longer-than-normal simulation step.
function Movement.sweepClear(world,entity,x1,y1)
  local dx,dy=x1-entity.x,y1-entity.y
  local length=math.sqrt(dx*dx+dy*dy)
  local slices=math.max(1,math.ceil(length/math.min(3,radius(entity)*0.5)))
  for i=1,slices do
    local t=i/slices
    if not Movement.canOccupy(world,entity,entity.x+dx*t,entity.y+dy*t) then
      return false
    end
  end
  return true
end

-- Inflate the static route grid by the physical unit footprint. The blocked
-- grid remains unmodified, so different-sized units and saves are independent.
function Movement.clearanceMap(world,entity)
  local blocked={}
  for gy=1,world.h do for gx=1,world.w do
    local key=gy*world.w+gx
    if not solidClear(world,gx*TILE,gy*TILE,radius(entity)) then
      blocked[key]=true
    end
  end end
  return {w=world.w,h=world.h,blocked=blocked}
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
    if Movement.sweepClear(world,entity,nx,ny) then
      entity.angle=(math.atan2 and math.atan2(uy,ux)) or math.atan(uy,ux)
      entity.x,entity.y=nx,ny
      return true, angle~=0
    end
  end
  return false, false
end

-- Reserve distinct, physically walkable squad destinations. A grid tile that is
-- free for infantry is not necessarily free for a tank next to a wall. Reserve
-- larger bodies first; all ties are deterministic (unit id / grid position).
-- This changes ONLY provisional formation placement, never J2ME reference data.
function Movement.formationSlots(world,units,x,y,selected)
  local available={}
  for gy=1,world.h do for gx=1,world.w do
    if not blockedTile(world,gx,gy) then
      local px,py=gx*TILE,gy*TILE
      available[#available+1]={x=px,y=py,
        clickDistance=(px-x)^2+(py-y)^2}
    end
  end end
  table.sort(available,function(a,b)
    if a.clickDistance~=b.clickDistance then return a.clickDistance<b.clickDistance end
    if a.y~=b.y then return a.y<b.y end
    return a.x<b.x
  end)
  local largestFirst={}
  for i,unit in ipairs(units) do largestFirst[i]=unit end
  table.sort(largestFirst,function(a,b)
    if radius(a)~=radius(b) then return radius(a)>radius(b) end
    return a.id<b.id
  end)
  local reserved,goals={},{}
  for _,unit in ipairs(largestFirst) do
    local r=radius(unit)
    local chosen,bestDistance=nil,math.huge
    for _,spot in ipairs(available) do
      if solidClear(world,spot.x,spot.y,r) then
        local free=true
        for _,other in ipairs(world.entities) do
          if other.alive and not other.building and not selected[other.id] then
            local combined=r+radius(other)+0.35
            if (spot.x-other.x)^2+(spot.y-other.y)^2<combined*combined then
              free=false;break
            end
          end
        end
        if free then for _,taken in ipairs(reserved) do
          local combined=r+taken.radius+0.35
          if (spot.x-taken.x)^2+(spot.y-taken.y)^2<combined*combined then
            free=false;break
          end
        end end
        if free then
          -- Prioritize proximity to the order, then travel distance from
          -- this particular unit; never change results with frame timing.
          local score=spot.clickDistance*0.75+
            (spot.x-unit.x)^2+(spot.y-unit.y)^2
          if score<bestDistance then chosen=spot;bestDistance=score end
        end
      end
    end
    if chosen then
      goals[unit.id]={x=chosen.x,y=chosen.y}
      reserved[#reserved+1]={x=chosen.x,y=chosen.y,radius=r}
    end
  end
  return goals
end

-- Congestion-aware replanning only when local avoidance has been blocked
-- repeatedly. Do not change the permanent blocked grid or the saves.
function Movement.trafficMap(world,entity)
  local map=Movement.clearanceMap(world,entity)
  local sx=math.floor(entity.x/TILE+.5)
  local sy=math.floor(entity.y/TILE+.5)
  -- An occupied grid cell can belong to a unit whose center is between
  -- tiles. Mark every grid CENTER which would overlap its actual footprint,
  -- not just the tile containing the other center.
  for _,other in ipairs(world.entities) do
    if other~=entity and other.alive and not other.building then
      local clearance=radius(entity)+radius(other)+0.5
      local x0=math.max(1,math.ceil((other.x-clearance)/TILE))
      local x1=math.min(world.w,math.floor((other.x+clearance)/TILE))
      local y0=math.max(1,math.ceil((other.y-clearance)/TILE))
      local y1=math.min(world.h,math.floor((other.y+clearance)/TILE))
      for gy=y0,y1 do for gx=x0,x1 do
        if not (gx==sx and gy==sy) then
          local dx,dy=gx*TILE-other.x,gy*TILE-other.y
          if dx*dx+dy*dy<clearance*clearance then
            map.blocked[gy*world.w+gx]=true
          end
        end
      end end
    end
  end
  return map
end
return Movement
