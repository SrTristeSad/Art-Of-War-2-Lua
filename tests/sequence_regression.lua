-- Verify animation sequences are validation-gated and render via shared original atlas quads.
package.path='./?.lua;./?/init.lua;'..package.path
local S=require('src.atlas_sequence')
local Draft=require('src.sequence_draft')
local rect={atlas='i0_8_77x152.png',x=0,y=0,w=15,h=17}
local valid={verification='verified',fps=8,frames={rect,{atlas=rect.atlas,x=16,y=0,w=15,h=17}}}
local sizes={[rect.atlas]={77,152}}
assert(S.validate(valid,sizes))
local missing={verification='unverified',fps=8,frames={rect}}
assert(not S.validate(missing,sizes),'unverified frame must not become game animation')
assert(not S.validate({verification='verified',fps=500,frames={rect}},sizes))
assert(not S.validate({verification='verified',fps=8,frames={{atlas=rect.atlas,x=70,y=0,w=15,h=17}}},sizes))
assert(not S.validate({verification='verified',fps=8,frames={}},sizes))
local shared={getDimensions=function() return 77,152 end}
local textureCalls=0
local function loadTexture(atlas) assert(atlas==rect.atlas);textureCalls=textureCalls+1;return shared end
local qCalls={}
local function makeQuad(x,y,w,h,tw,th)
  local q={x=x,y=y,w=w,h=h};qCalls[#qCalls+1]=q
  return q
end
local built,errors=S.build({blue_infantry={walk=valid,attack=missing}},sizes,loadTexture,makeQuad)
assert(#errors==1,'rejected candidates must be reported')
assert(#built.blue_infantry.walk.frames==2 and built.blue_infantry.walk.fps==8)
assert(not built.blue_infantry.attack,'unverified sequence loaded')
assert(textureCalls==2 and #qCalls==2)
local broken,count=S.build({blue_infantry={walk=valid}},sizes,loadTexture,function(x,y,w,h)
  if x~=0 then error('GPU could not allocate quad') end
  return makeQuad(x,y,w,h)
end)
assert(not broken.blue_infantry and #count==1,'partial sequence must be rejected atomically')
local frames={}
assert(Draft.append(frames,rect.atlas,rect,77,152))
assert(Draft.append(frames,rect.atlas,{x=16,y=0,w=15,h=17},77,152))
assert(not Draft.append(frames,'../outside.png',rect,77,152))
assert(not Draft.append(frames,rect.atlas,{x=70,y=0,w=15,h=17},77,152))
local rows=assert(Draft.csvRows('draft_0001',frames,8))
assert(rows:find('draft_0001,1,i0_8_77x152.png,0,0,15,17,8,unverified',1,true))
assert(not Draft.csvRows('unsafe,name',frames,8))
assert(Draft.frameIndex(0,2,8)==1 and Draft.frameIndex(.125,2,8)==2 and
  Draft.frameIndex(.25,2,8)==1)
-- Inject a verified manifest into the renderer; default remains empty in production.
package.loaded['src.animation_sequences']={blue_infantry={walk=valid}}
package.loaded['src.art']=nil
local Art=require('src.art')
local Catalog=require('src.atlas_catalog')
local loaded,calls={},{}
local dimensions={}
for _,entry in pairs(Catalog) do
  local w,h=entry.atlas:match('_(%d+)x(%d+)%.png$')
  if w then dimensions[entry.atlas]={tonumber(w),tonumber(h)} end
end
love={filesystem={getInfo=function(p)
  if p:find('assets/animations/',1,true) then return nil end
  return {}
end},graphics={
  newImage=function(path)
    loaded[path]=(loaded[path] or 0)+1
    local name=path:match('/([^/]+)$')
    local dim=dimensions[name] or {16,17}
    return {path=path,getDimensions=function()return dim[1],dim[2]end,
      setFilter=function()end}
  end,
  newQuad=makeQuad,
  draw=function(...)calls[#calls+1]={...}end,
  setColor=function()end,rectangle=function()end
}}
Art.load()
assert(Art.hasSequence('blue_infantry','walk'))
assert(not Art.hasSequence('red_infantry','walk'))
local first=Art.frameFor('blue_infantry','walk',0)
local second=Art.frameFor('blue_infantry','walk',.125)
assert(first.quad.x==0 and second.quad.x==16)
local static=Art.frameFor('blue_infantry','idle',0)
assert(static.quad.x==0 and static.quad.w==15,'missing animation must use static quad')
Art.drawEntity('blue_infantry',100,100,16,16,0,1,'walk',.125)
assert(calls[#calls][2].x==16)
assert(loaded['assets/original/i0_8_77x152.png']==1,'sequence duplicated source atlas load')
print('SEQUENCE REGRESSIONS PASSED')
