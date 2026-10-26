-- A reserved but not yet occupied passing bay belongs to just one unit.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local Movement=require('src.movement')
local function check(ok,msg) assert(ok,msg) end
local world=World.new('scenario',1,1719)
world.entities={};world.obstacles={};world:refreshBlocked()
local oncoming=world:add('infantry',1,160,160)
local first=world:add('infantry',2,192,160)
local second=world:add('infantry',2,192,128)
local tx,ty=112,160
local firstBay=Movement.passingBay(world,first,oncoming,tx,ty)
check(firstBay,'first soldier could not find a bay')
first.trafficYield={x=firstBay.x,y=firstBay.y,priorityId=oncoming.id}
local otherBay=Movement.passingBay(world,second,oncoming,tx,ty)
if otherBay then
  local dx,dy=firstBay.x-otherBay.x,firstBay.y-otherBay.y
  check(dx*dx+dy*dy>=(Movement.radius(first)+Movement.radius(second)+1)^2,
    'two soldiers reserved overlapping side bays')
end
-- Reserved bay is transitory and the queue may retry if no space.
first.trafficYield=nil
local again=Movement.passingBay(world,second,oncoming,tx,ty)
check(again~=nil,'reservation permanently blocked the bay')
print('SQUAD BAY RESERVATION REGRESSIONS PASSED')
