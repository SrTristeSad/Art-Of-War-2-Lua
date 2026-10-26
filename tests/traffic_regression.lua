-- Provisional collision/traffic tests. No J2ME parity claim.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local Movement=require('src.movement')
local Save=require('src.save')
local function check(ok,msg) assert(ok,msg) end
local function d(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
local function blank(seed)
  local w=World.new('scenario',1,seed or 1234)
  w.entities={};w.obstacles={};w.selected={};w:refreshBlocked()
  return w
end

-- Two bodies may not share a destination or overlap while passing.
local w=blank()
local a=w:add('infantry',1,120,160)
local b=w:add('tank',1,152,160)
check(not Movement.canOccupy(w,a,b.x,b.y),'collision checker permits overlap')
for i=1,240 do
  w:navigate(a,184,160,1/30)
  if i%2==0 then w:navigate(b,100,160,1/30) end
  check(d(a,b)+1e-6>=Movement.radius(a)+Movement.radius(b),'units overlapped at tick '..i)
end
check(d(a,b)>=Movement.radius(a)+Movement.radius(b),'final unit overlap')
check(a.x>180 and b.x<105,'units failed to pass one another')

-- A stationary tank must be detoured, not merely avoided forever.
local avoid=blank(1237)
local moving=avoid:add('infantry',1,100,160)
local stationary=avoid:add('tank',1,130,160)
for i=1,240 do
  avoid:navigate(moving,180,160,1/30)
  check(d(moving,stationary)>=Movement.radius(moving)+Movement.radius(stationary),
    'stationary tank overlap at tick '..i)
end
check(moving.x>170,'traffic reroute did not pass stationary tank')

-- Fixed obstacle corners block the *footprint* and cannot be clipped.
local rocks=blank(1235)
rocks.obstacles={{x=12,y=12,typeName='rocks'}}
rocks:refreshBlocked()
local scout=rocks:add('infantry',1,12*16-8-5,12*16)
check(not Movement.canOccupy(rocks,scout,12*16-8-2,12*16),'edge collision missed')
check(Movement.canOccupy(rocks,scout,12*16-8-5,12*16),'walkable point rejected')
for i=1,160 do
  rocks:navigate(scout,15*16,12*16,1/30)
  check(Movement.solidClear(rocks,scout.x,scout.y,Movement.radius(scout)),
    'unit clipped a blocked rock at tick '..i)
end

-- A group should avoid an occupied destination cell where feasible.
local formation=blank(1236)
local blocker=formation:add('infantry',1,320,320)
local p=formation:add('infantry',1,260,300)
local q=formation:add('infantry',1,260,320)
formation:select(p)
formation:select(q,true)
formation:moveSelected(320,320)
check(p.order and q.order,'missing move goals')
check(p.order.x~=q.order.x or p.order.y~=q.order.y,'duplicated formation cell')
for _,unit in ipairs({p,q}) do
  local goal={x=unit.order.x,y=unit.order.y}
  check(d(goal,blocker)>=Movement.radius(blocker)+7.3,
    'formation reserved occupied ground')
end

-- Transient traffic caches must not be persisted in a save.
local saved
love={filesystem={write=function(_,data) saved=data;return true end,
  getInfo=function() return saved and {} or nil end,
  read=function() return saved end}}
a.blockedTime=.4;a.avoidCongestion=true
check(Save.write(w),'cannot save traffic state')
check(not saved:find('blockedTime',1,true),'blocked timer serialized')
check(not saved:find('avoidCongestion',1,true),'traffic flag serialized')
check(not saved:find('steerTime',1,true),'steering clock serialized')
local restored,err=Save.read(World)
check(restored,err)
for _,entity in ipairs(restored.entities) do
  check(entity.blockedTime==0 and entity.steerTime==0 and entity.avoidCongestion==false,
    'stale traffic state after restore')
end
print('TRAFFIC REGRESSIONS PASSED')
