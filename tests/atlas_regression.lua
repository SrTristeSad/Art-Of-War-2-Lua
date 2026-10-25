-- Validate the developer-only source atlas browser without running LÖVE.
package.path='./?.lua;./?/init.lua;'..package.path
local seen={}
local lastDraw
local font={getWidth=function(_,s)return #tostring(s)*6 end,
            getHeight=function()return 10 end}
local graphics={
  newImage=function(name)
    assert(name:find('assets/original/',1,true),'atlas browser opened a derived sprite')
    return {getDimensions=function()return 100,80 end,setFilter=function()end}
  end,
  getFont=function()return font end,
  draw=function(_,x,y,r,sx,sy)lastDraw={x=x,y=y,sx=sx,sy=sy} end,
  stencil=function(fn)fn()end,
}
setmetatable(graphics,{__index=function()return function()end end})
love={graphics=graphics,filesystem={
  getDirectoryItems=function()
    return {'i0_10_107x152.png','i0_2_206x131.png','readme.txt','i0_0_240x320.png'}
  end,
  getInfo=function(path) return path:find('%.png$') and {} or nil end
}}
local Inspector=require('src.atlas_inspector')
Inspector.initialize()
assert(#Inspector.files==3,'non-PNG file was included')
assert(Inspector.files[1]=='i0_0_240x320.png')
assert(Inspector.files[2]=='i0_2_206x131.png','atlas was sorted alphabetically, not numerically')
assert(Inspector.files[3]=='i0_10_107x152.png')
Inspector.toggle();assert(Inspector.active)
Inspector.draw();assert(lastDraw and lastDraw.sx>0,'atlas image not drawn')
Inspector.keypressed('right')
assert(Inspector.selectedFile()=='i0_2_206x131.png')
Inspector.keypressed('end');assert(Inspector.index==3)
Inspector.keypressed('right');assert(Inspector.index==1,'atlas paging must wrap')
Inspector.changeZoom(1);assert(Inspector.zoom>1)
Inspector.draw()
local previous=Inspector.index
Inspector.wheelmoved(-1)
assert(Inspector.index==previous,'zoom changed selected image')
Inspector.mousepressed(210,290,1)
assert(Inspector.index==2,'next-screen button failed')
Inspector.mousepressed(10,290,1)
assert(Inspector.index==1,'previous-screen button failed')
Inspector.keypressed('escape');assert(not Inspector.active,'inspector cannot be closed')
print('ATLAS REGRESSIONS PASSED')
