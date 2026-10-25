-- Deterministic visual-pipeline tests, independent of a graphical LÖVE build.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local Art=require('src.art')
local Anim=require('src.animation')
local Save=require('src.save')
local function close(a,b) return math.abs(a-b)<0.00001 end
local draws={}
local originalDimensions={blue_hq={92,103},blue_factory={96,49},
  blue_infantry={15,17},explosion={25,23}}
local function image(name)
  local dim=originalDimensions[name] or {16,16}
  return {getDimensions=function() return dim[1],dim[2] end,
    setFilter=function() end}
end
local graphics={
  newImage=function(path)
    local name=path:match('/([^/]+)%.png$')
    return image(name)
  end,
  draw=function(_,x,y,angle,sx,sy)
    draws[#draws+1]={x=x,y=y,angle=angle,sx=sx,sy=sy}
  end,
}
setmetatable(graphics,{__index=function()return function()end end})
love={graphics=graphics,filesystem={getInfo=function(p)
  if p:find('assets/animations/',1,true) then return nil end
  return {}
end}}
Art.load()
local w,h=Art.fitSize('blue_factory',48,48,'idle',0)
assert(close(w,48) and close(h,24.5),'factory aspect ratio was squashed')
local a,b=Art.fitSize('blue_hq',55,55)
assert(a<55 and close(b,55),'HQ aspect ratio was squashed')
Art.drawEntity('blue_factory',100,100,48,48,0,1,'idle',0)
assert(#draws==1 and close(draws[1].x,76) and close(draws[1].y,100-12.25),
  'sprite is not centered on the tile')
assert(Anim.frame(0,4,10)==1 and Anim.frame(.1,4,10)==2 and
 Anim.frame(.4,4,10)==1,'animation timeline has incorrect frame order')
assert(Anim.state({building=true})=='idle')
assert(Anim.state({building=false,firePulse=.1})=='attack')
assert(Anim.state({building=false,order={x=1,y=1}})=='walk')

local world=World.new('scenario',1,2468)
world:effect('order',100,100,.5)
world:update(1/30)
assert(#world.effects==1,'feedback effect missing')
for _=1,30 do world:update(1/30) end
assert(#world.effects==0,'expired effects were not removed')
-- A killed target must produce an explosion without consuming extra RNG.
local first,second
for _,e in ipairs(world.entities) do
  if e.kind=='infantry' and e.team==1 and not first then first=e end
  if e.kind=='infantry' and e.team==2 and not second then second=e end
end
assert(first and second)
first.x=100;first.y=100;first.cooldown=0
second.x=106;second.y=100;second.hp=1
world:_tick(1/30)
assert(not second.alive,'combat failed in visual event test')
local exploded=false
for _,e in ipairs(world.effects) do if e.kind=='explosion' then exploded=true end end
assert(exploded,'missing destruction visual')
-- Test the rendering path including the ghost building overlay.
world.buildMode='turret'
world.preview={x=16*20,y=16*20}
world:draw(0,0,230)

local saved
love.filesystem.write=function(_,value) saved=value;return true end
love.filesystem.read=function() return saved end
love.filesystem.getInfo=function(path) if path=='save.lua' then return saved and {} or nil end end
assert(Save.write(world))
assert(not saved:find('firePulse',1,true) and not saved:find('animTime',1,true),
  'transient animation state was persisted')
local restored=assert(Save.read(World))
assert(#restored.effects==0 and restored.preview==nil,'visual state restored from save')
restored:draw(0,0,230)
print('VISUAL REGRESSIONS PASSED')
