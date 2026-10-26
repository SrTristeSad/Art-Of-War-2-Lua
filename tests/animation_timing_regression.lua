-- V0.8: verified atlas timeline and visual phase are independent of gameplay.
package.path='./?.lua;./?/init.lua;'..package.path
local Animation=require('src.animation')
local Sequence=require('src.atlas_sequence')
local World=require('src.world')
local Save=require('src.save')
local dims={['i0_8_77x152.png']={77,152}}
local a={atlas='i0_8_77x152.png',x=0,y=0,w=15,h=17}
local b={atlas='i0_8_77x152.png',x=16,y=0,w=15,h=17}
local c={atlas='i0_8_77x152.png',x=32,y=0,w=15,h=17}
local entry={verification='verified',fps=8,loop=true,
  frames={a,b,c},durations_ms={80,220,100}}
assert(Sequence.validate(entry,dims))
local function invalid(d)
  local v={verification='verified',fps=8,loop=true,frames={a,b,c},durations_ms=d}
  assert(not Sequence.validate(v,dims))
end
invalid({80,220});invalid({80,0,100});invalid({80,1.5,100});invalid({80,math.huge,100})
local q=Sequence.build({blue_infantry={walk=entry}},dims,
  function() return {name='texture'} end, function()return {} end)
local t=q.blue_infantry.walk
assert(Sequence.frameIndex(t,0)==1)
assert(Sequence.frameIndex(t,.079)==1)
assert(Sequence.frameIndex(t,.08)==2)
assert(Sequence.frameIndex(t,.299)==2)
assert(Sequence.frameIndex(t,.30)==3)
assert(Sequence.frameIndex(t,.4)==1,'loop should reset at 400 ms')
t.loop=false
assert(Sequence.frameIndex(t,.4)==3)
assert(Sequence.frameIndex(t,5)==3,'nonloop should hold final frame')
local uniform={frames={a,b,c},fps=10,loop=true}
assert(Sequence.frameIndex(uniform,.11)==2)
assert(Sequence.frameIndex(uniform,.31)==1)
uniform.loop=false
assert(Sequence.frameIndex(uniform,20)==3)
assert(Sequence.frameIndex(uniform,0/0)==1,'nan should not crash timeline')
local e={building=false,order={x=100,y=100},firePulse=0,moving=false}
assert(Animation.advance(e,.033)=='idle')
e.moving=true
local state,time=Animation.advance(e,.033)
assert(state=='walk' and time==0,'first walk frame must start at zero')
state,time=Animation.advance(e,.033)
assert(state=='walk' and time>.03)
e.firePulse=.15
state,time=Animation.advance(e,.033,true)
assert(state=='attack' and time==0,'attack resets timeline')
state,time=Animation.advance(e,.033,true)
assert(state=='attack' and time==0,'new attack event must retrigger animation')
e.firePulse=0;e.moving=false
state,time=Animation.advance(e,.033)
assert(state=='attack', 'visual attack retains short flash timing')
for i=1,4 do state,time=Animation.advance(e,.033) end
assert(state=='idle' and time==0)
local world=World.new('scenario',1,553)
local first
for _,unit in ipairs(world.entities) do
  if unit.kind=='infantry' and unit.team==1 then first=unit;break end
end
world:refreshBlocked()
first.order={x=first.x+16,y=first.y};first.path=nil
for i=1,10 do world:_tick(1/30) end
assert(first.animationState=='walk' or first.order==nil,'moving entity should animate walk')
local saved
love={filesystem={write=function(_,content) saved=content;return true end,
  getInfo=function()return {}end,read=function()return saved end}}
assert(Save.write(world))
assert(not saved:find('animationState',1,true))
local loaded=assert(Save.read(World))
for _,unit in ipairs(loaded.entities) do
  assert(unit.animationTime==0 and unit.animationState=='idle' and not unit.moving)
end
-- Attack's visual lifespan follows verified clip length, not a short flash.
local firing={kind='infantry',building=false,moving=false,firePulse=.15}
assert(Animation.advance(firing,.033,true,.45)=='attack')
firing.firePulse=0
for i=1,10 do assert(Animation.advance(firing,.033,false)=='attack') end
assert(Animation.advance(firing,.15,false)=='idle')
-- Turrets are buildings that can visibly fire; headquarters remain idle.
local turret={kind='turret',building=true,firePulse=.15}
assert(Animation.state(turret)=='attack')
assert(Animation.state({kind='hq',building=true,firePulse=.15})=='idle')
-- The duration calculator works for verified in-memory sequences.
local Art=require('src.art')
Art.atlasAnimations={blue_infantry={attack={frames={a,b,c},fps=10,durations_ms={80,220,100}}}}
assert(math.abs(Art.sequenceDuration('blue_infantry','attack')-.4)<1e-7)
assert(Art.sequenceDuration('red_infantry','attack')==nil)
print('ANIMATION TIMING REGRESSIONS PASSED')
