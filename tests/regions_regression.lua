package.path='./?.lua;./?/init.lua;'..package.path
local R=require('src.atlas_regions')
local eq=function(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local x,y=R.imagePoint(27,36,10,20,2,100,80,false)
eq(x,8);eq(y,8)
assert(R.imagePoint(2,2,10,20,2,100,80,false)==nil)
local cx,cy=R.imagePoint(-1,99,10,20,2,100,80,true)
eq(cx,0);eq(cy,39)
local r=R.rectangle(18,7,8,9)
eq(r.x,8);eq(r.y,7);eq(r.w,11);eq(r.h,3)
local single=R.rectangle(0,0,0,0)
eq(single.w,1);eq(single.h,1)
local row=R.csvRow('i0_5_274x147.png',r,100,80)
eq(row,'i0_5_274x147.png,8,7,11,3,unverified\n')
assert(R.csvRow('../bad.png',r,100,80)==nil,'file traversal accepted')
assert(R.csvRow('a.png',{x=98,y=0,w=3,h=1},100,80)==nil,'out-of-bounds accepted')
assert(R.csvRow('a.png',{x=0.5,y=0,w=1,h=1},100,80)==nil,'fractional accepted')
assert(R.csvRow('a.png',{x=0,y=0,w=0,h=1},100,80)==nil,'empty accepted')
assert(R.csvRow('a.png',{x=0,y=0,w=1,h=1},100,80))
-- Simulate LÖVE storage and a 100x80 atlas; regression also checks screenshots do not affect crop coordinates.
package.loaded['src.atlas_inspector']=nil
local saved={}
local fs={
  getDirectoryItems=function()return {'i0_5_274x147.png'}end,
  getInfo=function(path)
    if path=='atlas_regions.csv' then return saved[path] and {type='file'} or nil end
    return path:match('%.png$') and {type='file'} or nil
  end,
  read=function(path)return saved[path] end,
  write=function(path,data)saved[path]=data;return true end,
}
local graphics={
  newImage=function()return {getDimensions=function()return 100,80 end,setFilter=function()end} end,
  stencil=function(fn)fn()end,
}
setmetatable(graphics,{__index=function()return function()end end})
love={graphics=graphics,filesystem=fs}
local I=require('src.atlas_inspector')
I.initialize();I.toggle();I.draw()
-- Image 100x80 fits in 220x222 at 2.2x, centered vertically (43+(222-176)/2=66).
I.mousepressed(32,88,1) -- atlas pixel (10,10)
I.mousemoved(54,110) -- atlas pixel (20,20)
I.mousereleased(54,110,1)
eq(I.selection.x,10);eq(I.selection.y,10);eq(I.selection.w,11);eq(I.selection.h,11)
I.keypressed('s')
eq(saved['atlas_regions.csv'],R.HEADER..'i0_5_274x147.png,10,10,11,11,unverified\n')
I.changeZoom(1)
local previous=saved['atlas_regions.csv']
I.keypressed('s');eq(saved['atlas_regions.csv'],previous..'i0_5_274x147.png,10,10,11,11,unverified\n')
I.keypressed('c');assert(I.selection==nil)
I.close()
print('REGION REGRESSIONS PASSED')
