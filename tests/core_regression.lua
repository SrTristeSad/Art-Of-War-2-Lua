-- Run with: texlua tests/core_regression.lua
-- Pure Lua regression suite. Does not claim gameplay parity with J2ME.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local Path=require('src.path')
local Save=require('src.save')
local SafeTable=require('src.safe_table')
local function check(ok,msg) assert(ok,msg) end
local function near(a,b) return math.abs(a-b)<0.00001 end

-- Walkable grid path may route around obstacles, but never enters a blocked cell.
local grid={w=10,h=8,blocked={}}
for y=1,7 do grid.blocked[y*grid.w+5]=true end
local route=Path.search(grid,2,4,9,4)
check(route and #route>9,'detour missing')
local x,y=2,4
for _,cell in ipairs(route) do
  check(math.abs(cell.x-x)+math.abs(cell.y-y)==1,'path skips a cell')
  check(not grid.blocked[cell.y*grid.w+cell.x],'path crosses obstacle')
  x,y=cell.x,cell.y
end
check(x==9 and y==4,'path ends at wrong cell')
for y=1,8 do grid.blocked[y*grid.w+5]=true end
check(Path.search(grid,2,4,9,4)==nil,'unreachable path must be nil')
check(Path.search(grid,2,4,5,4)~=nil,'blocked building target should use reachable edge')

local one=World.new('scenario',1,9781)
local two=World.new('scenario',1,9781)
check(one.rngState==two.rngState,'seeded RNG not reproducible')
-- A squad must fan out over separate non-blocked destinations.
one.selected={}
local infantry={}
for _,e in ipairs(one.entities) do
  if e.team==1 and e.kind=='infantry' then
    infantry[#infantry+1]=e;one.selected[e.id]=true
  end
end
one:moveSelected(21*16,19*16)
local goals={}
for _,e in ipairs(infantry) do
  check(e.order and not e.order.target,'missing move order')
  local key=e.order.x..','..e.order.y
  check(not goals[key],'two units share the same formation destination')
  goals[key]=true
  local cx=math.floor(e.order.x/16+.5)
  local cy=math.floor(e.order.y/16+.5)
  check(not one.blocked[cy*one.w+cx],'formation targets an obstacle')
end
-- Structural placement must not overlap a live unit.
local soldier=infantry[1]
check(not one:canBuild(soldier.x,soldier.y,'barracks'),'building overlaps soldier')
local preMoney=one.money[1]
check(not one:placeBuilding('barracks',soldier.x,soldier.y),'overlap was accepted')
check(one.money[1]==preMoney,'invalid build charged credits')
local location
for gy=3,one.h-3 do
  for gx=3,one.w-3 do
    if one:canBuild(gx*16,gy*16,'barracks') then
      location={x=gx*16,y=gy*16};break
    end
  end
  if location then break end
end
check(location,'no buildable tile remains on map')
check(one:placeBuilding('barracks',location.x,location.y),'valid construction failed')
check(one.money[1]==preMoney-one:cost('barracks'),'valid build deducted wrong amount')

-- Unreachable orders may not walk through solid barriers.
local mover=infantry[1]
local oldX,oldY=mover.x,mover.y
one.blocked={}
for y=1,one.h do one.blocked[y*one.w+18]=true end
-- Navigation calls refreshBlocked, so use a static obstacle wall instead.
one.obstacles={}
for y=1,one.h do one.obstacles[#one.obstacles+1]={x=18,y=y,typeName='rocks'} end
one:refreshBlocked()
local sx,sy=math.floor(mover.x/16+.5),math.floor(mover.y/16+.5)
local destinationX=(sx<18 and 25 or 10)*16
mover.path=nil;mover.pathTime=0
for _=1,100 do one:navigate(mover,destinationX,mover.y,1/30) end
check(near(oldX,mover.x) and near(oldY,mover.y),'unreachable unit moved through a wall')

-- Whole-number seconds of income and production are stable under different dt.
for _=1,100 do two:update(.05) end
local three=World.new('scenario',1,9781)
for _=1,50 do three:update(.1) end
check(near(two.elapsed,three.elapsed),'fixed timestep depends on frame chunking')
check(two.money[1]==three.money[1] and two.money[2]==three.money[2],
 'economy depends on frame chunking')
check(two.rngState==three.rngState,'AI decisions depend on frame chunking')
for i,e in ipairs(two.entities) do
  local f=three.entities[i]
  check(f and f.kind==e.kind and near(e.x,f.x) and near(e.y,f.y),
    'world positions differ at '..i)
end

-- Production spends credits and deploys a new unit after its timer.
local barracks
for _,e in ipairs(two.entities) do
  if e.team==1 and e.kind=='barracks' then barracks=e;break end
end
local before=#two.entities
check(two:train(barracks,'infantry'),'could not queue an infantry unit')
for _=1,150 do two:update(1/30) end
check(barracks.queue==0,'production queue did not finish')
check(#two.entities>before,'new infantry never spawned')

-- Save must preserve RNG, simulation remainder and live unit state.
local saved
love={filesystem={
  write=function(_,data) saved=data;return true end,
  getInfo=function() return saved and {} or nil end,
  read=function() return saved end,
}}
check(Save.write(two),'save failed')
local attack=SafeTable.decode('return os.execute("echo unsafe")')
check(attack==nil,'unsafe executable save accepted')
local copy=SafeTable.decode('return {["s"]="a\\b\n",[1]=true,}')
check(copy and copy[1]==true,'safe parser lost values')
check(not saved:find('pathTime',1,true),'transient path cache stored in save')
local restored,err=Save.read(World)
check(restored,err)
check(restored.rngState==two.rngState,'save lost RNG state')
check(near(restored.tickRemainder,two.tickRemainder),'save lost tick remainder')
check(restored.money[1]==two.money[1] and #restored.entities==#two.entities,'save lost state')
print('CORE REGRESSIONS PASSED')
