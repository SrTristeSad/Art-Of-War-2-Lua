-- v0.15: radius-aware formation slots and measurable steering progress.
-- Provisional RTS behavior, not a claim of equivalence to J2ME.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local Movement=require('src.movement')
local function check(value,message) assert(value,message) end
local function dist(a,b)
  return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
local function blank(seed)
  local w=World.new('scenario',1,seed or 3251)
  w.entities={};w.obstacles={};w.selected={};w:refreshBlocked()
  return w
end

local w=blank()
w.obstacles={{x=20,y=20,typeName='rocks'},{x=20,y=19,typeName='rocks'}}
w:refreshBlocked()
local t=w:add('tank',1,286,310)
local s=w:add('infantry',1,280,284)
local s2=w:add('infantry',1,280,340)
local parked=w:add('tank',1,320,320)
w:select(t);w:select(s,true);w:select(s2,true)
w:moveSelected(320,320)
local selected={t,s,s2}
for i,a in ipairs(selected) do
  check(a.order and not a.order.target,'valid slot missing')
  check(Movement.solidClear(w,a.order.x,a.order.y,Movement.radius(a)),
    'formation slot overlaps static terrain at member '..i)
  local circle={x=a.order.x,y=a.order.y}
  check(dist(circle,parked)>=Movement.radius(a)+Movement.radius(parked)+0.34,
    'formation slot overlaps unselected defender')
  for j=1,i-1 do
    local b=selected[j]
    check(dist(circle,b.order)>=Movement.radius(a)+Movement.radius(b)+0.34,
      'formation slots overlap')
  end
end
local previous={}
for _,a in ipairs(selected) do previous[a.id]={x=a.order.x,y=a.order.y} end
w:moveSelected(320,320)
for _,a in ipairs(selected) do
  check(a.order.x==previous[a.id].x and a.order.y==previous[a.id].y,
    'formation orders are not deterministic')
end
-- Corner orders must never reserve slots that clip map edges.
w:moveSelected(0,0)
for _,a in ipairs(selected) do
  check(a.order and Movement.solidClear(w,a.order.x,a.order.y,Movement.radius(a)),
    'map-edge formation rejected unit footprint')
end

-- A sideways-steered unit that approaches its waypoint must keep its path.
local pathWorld=blank(3252)
local u=pathWorld:add('infantry',1,64,160)
local originalAdvance=Movement.advance
Movement.advance=function(world,unit,tx,ty,step)
  local dx,dy=tx-unit.x,ty-unit.y
  local d=math.sqrt(dx*dx+dy*dy)
  if d>0.01 then
    unit.x=unit.x+dx/d*math.min(.25,d)
    unit.y=unit.y+dy/d*math.min(.25,d)
  end
  return true,true
end
for i=1,20 do
  check(pathWorld:navigate(u,320,160,1/30),'steered movement failed')
  check((u.steerTime or 0)<.06,'useful sidestep triggered congestion timer')
end
Movement.advance=originalAdvance
print('SQUAD FORMATION REGRESSIONS PASSED')
