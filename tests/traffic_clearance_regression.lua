-- v0.14: high-speed swept collision, unit-sized route grids and safe spawning.
-- These are provisional Lua engine invariants, not J2ME parity tests.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local Movement=require('src.movement')
local function check(ok,msg) assert(ok,msg) end
local function distance(a,b)
  return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
local function blank()
  local w=World.new('scenario',1,1407)
  w.entities={};w.obstacles={};w.selected={};w:refreshBlocked()
  return w
end

-- Endpoint-only testing used to allow a fast unit to phase through a tank.
local crossing=blank()
local scout=crossing:add('infantry',1,100,160)
local tank=crossing:add('tank',2,130,160)
check(Movement.canOccupy(crossing,scout,160,160),'test endpoint must be clear')
check(not Movement.sweepClear(crossing,scout,160,160),
  'movement segment tunneled through a stationary tank')
local x0,y0=scout.x,scout.y
local moved=Movement.advance(crossing,scout,160,160,60)
if moved then
  -- Reconstruct the traversed segment from the original start position.
  local x1,y1=scout.x,scout.y
  scout.x,scout.y=x0,y0
  check(Movement.sweepClear(crossing,scout,x1,y1),
    'local steering permitted a segment crossing another troop')
  scout.x,scout.y=x1,y1
end
check(distance(scout,tank)+1e-7 >= Movement.radius(scout)+Movement.radius(tank),
  'swept movement ended inside a tank')

-- Terrain collision must also test intermediate points, not just the end.
local terrain=blank()
terrain.obstacles={{x=8,y=10,typeName='rocks'}}
terrain:refreshBlocked()
local runner=terrain:add('infantry',1,92,160)
check(Movement.canOccupy(terrain,runner,164,160),'terrain test endpoint blocked')
check(not Movement.sweepClear(terrain,runner,164,160),
  'fast movement crossed solid terrain')

-- A static path map is a *derived* view: source obstruction data is untouched.
local paths=blank()
paths.obstacles={{x=12,y=12,typeName='rocks'}}
paths:refreshBlocked()
local vehicle=paths:add('tank',1,70,96)
local map=Movement.clearanceMap(paths,vehicle)
check(map.w==paths.w and map.h==paths.h,'invalid clearance map size')
check(map.blocked[12*paths.w+12],'solid rock missing from footprint grid')
check(not paths.blocked[10*paths.w+10], 'static map mutated by path preparation')

-- A between-cell unit occupies more than just its rounded map tile.
local traffic=blank()
local mover=traffic:add('infantry',1,64,160)
local guard=traffic:add('tank',1,136,160)
local dynamic=Movement.trafficMap(traffic,mover)
check(dynamic.blocked[10*traffic.w+8],'first half-tile is not reserved')
check(dynamic.blocked[10*traffic.w+9],'second half-tile is not reserved')
check(not traffic.blocked[10*traffic.w+8], 'dynamic traffic polluted static terrain')
check(not traffic.blocked[10*traffic.w+9], 'dynamic traffic polluted static terrain')
check(not dynamic.blocked[10*traffic.w+4], 'own start tile was blocked')

-- Factory output must respect the full footprint, not the center-point picker.
local production=blank()
local factory=production:add('factory',1,160,160)
local parked=production:add('tank',1,204,160)
local created=production:spawn(factory,'tank')
check(created and created.alive, 'spawn failed to find an available location')
check(distance(created,parked)+1e-7 >= Movement.radius(created)+Movement.radius(parked),
  'new tank overlaps a parked tank')
check(Movement.solidClear(production,created.x,created.y,Movement.radius(created)),
  'new tank overlaps a structure or a solid tile')
print('TRAFFIC CLEARANCE REGRESSIONS PASSED')
