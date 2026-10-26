-- v0.16: two opposite-moving units in a narrow corridor with a side bay.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local Movement=require('src.movement')
local Save=require('src.save')
local function check(ok,what) assert(ok,what) end
local function blank(seed)
  local w=World.new('scenario',1,seed or 1616)
  w.entities={};w.obstacles={};w.selected={};w:refreshBlocked()
  return w
end
local w=blank()
-- Two parallel solid walls, exactly one tile of walking space between them.
-- Create a side bay wide enough for one infantry unit between x=192 and 224.
for x=7,19 do
  w.obstacles[#w.obstacles+1]={x=x,y=9,typeName='rocks'}
  if x<12 or x>14 then
    w.obstacles[#w.obstacles+1]={x=x,y=11,typeName='rocks'}
  end
end
w:refreshBlocked()
local left=w:add('infantry',1,160,160)
local right=w:add('infantry',1,224,160)
left.order={x=256,y=160};right.order={x=128,y=160}
local observedYield=false
local gap=Movement.radius(left)+Movement.radius(right)
for frame=1,500 do
  w:navigate(left,left.order.x,left.order.y,1/30)
  w:navigate(right,right.order.x,right.order.y,1/30)
  if right.trafficYield then observedYield=true end
  local d=math.sqrt((left.x-right.x)^2+(left.y-right.y)^2)
  check(d>=gap-1e-6,'intersecting soldiers at tick '..frame)
  check(Movement.solidClear(w,left.x,left.y,Movement.radius(left)),'left soldier clipped wall '..frame)
  check(Movement.solidClear(w,right.x,right.y,Movement.radius(right)),'right soldier clipped wall '..frame)
end
print(('final: left(%.1f,%.1f) right(%.1f,%.1f), yield=%s'):format(left.x,left.y,right.x,right.y,tostring(observedYield)))
check(observedYield,'head-on pair never yielded')
check(left.x>=246 and right.x<=138,'passing bay failed to unblock both orders')
check(not right.trafficYield,'yield state did not clear after right of way')

-- No bay: deterministic blockage, not teleportation or overlapping.
local closed=blank(1717)
for x=7,19 do
 for _,y in ipairs({9,11}) do closed.obstacles[#closed.obstacles+1]={x=x,y=y,typeName='rocks'} end
end
closed:refreshBlocked()
local a=closed:add('infantry',1,160,160)
local b=closed:add('infantry',1,224,160)
a.order={x=256,y=160};b.order={x=128,y=160}
for tick=1,250 do
  closed:navigate(a,256,160,1/30)
  closed:navigate(b,128,160,1/30)
  check(not b.trafficYield,'illegal passing bay inside solid wall')
  check(math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)>=gap-1e-6,'head-on units phased through each other')
end
-- A deadlock with no legal passing space is a valid physical limitation.
check(a.x<b.x,'units illegally passed in a wall-to-wall corridor')

-- New orders cancel a transient yield; its state must not persist in saves.
local changed=blank(1818)
local first=changed:add('infantry',1,160,160)
local second=changed:add('infantry',1,192,160)
second.trafficYield={x=192,y=176,priorityId=first.id}
changed:select(second)
changed:moveSelected(240,240)
check(not second.trafficYield,'new order retained a stale yield')
second.trafficYield={x=192,y=176,priorityId=first.id}
local content
love={filesystem={write=function(_,s) content=s;return true end,
 getInfo=function() return {} end,read=function() return content end}}
check(Save.write(changed),'save failed')
check(not content:find('trafficYield',1,true),'temporary right-of-way serialized')
local loaded,err=Save.read(World)
check(loaded,err)
for _,e in ipairs(loaded.entities) do
  check(e.trafficYield==nil,'yield persisted after loading a save')
end
print('CHOKEPOINT YIELD REGRESSIONS PASSED')
