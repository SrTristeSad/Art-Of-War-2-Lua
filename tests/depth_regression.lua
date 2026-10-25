-- A soldier's ground-Y determines whether a tree is in front or behind him.
package.path='./?.lua;./?/init.lua;'..package.path
local graphics={stencil=function(fn)fn()end}
setmetatable(graphics,{__index=function() return function() end end})
love={graphics=graphics}
local World=require('src.world')
local Art=require('src.art')
local world=World.new('scenario',1,252)
world.entities={}
world.obstacles={{x=10,y=9,typeName='forest'}, {x=10,y=19,typeName='rocks'}}
world.blocked={};world:refreshBlocked()
world:add('infantry',1,10*16,14*16)
local calls={}
local draw=Art.draw
local drawEntity=Art.drawEntity
Art.draw=function(name,...)
  if name=='forest' or name=='rocks' then calls[#calls+1]=name end
end
Art.drawEntity=function(name,...)
  if name=='blue_infantry' then calls[#calls+1]=name end
end
world:draw(0,8*16,230)
Art.draw=draw;Art.drawEntity=drawEntity
assert(#calls==3,'expected 2 obstacles and 1 unit; got '..#calls)
assert(table.concat(calls,',')=='forest,blue_infantry,rocks',
  'terrain/units rendered in incorrect depth order: '..table.concat(calls,','))
print('DEPTH REGRESSIONS PASSED')
