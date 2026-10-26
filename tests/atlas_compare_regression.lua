package.path='./?.lua;./?/init.lua;'..package.path
local Compare=require('src.atlas_compare')
local input={x=4,y=10,w=12,h=22}
local f=assert(Compare.capture('i0_8_77x152.png',input,77,152))
input.x=90 -- pinned frame is a copy
assert(f.x==4 and f.verified==false)
assert(Compare.identicalRegion(f,{atlas=f.atlas,x=4,y=10,w=12,h=22}))
assert(not Compare.identicalRegion(f,{atlas=f.atlas,x=5,y=10,w=12,h=22}))
assert(Compare.scale(f,60,55)==2.5)
assert(Compare.fits(f,{getDimensions=function()return 77,152 end}))
assert(not Compare.fits(f,{getDimensions=function()return 10,10 end}))
assert(not Compare.capture('foo/../../../wrong.png',f,77,152))
assert(not Compare.capture('i0_8_77x152.png',{x=74,y=0,w=5,h=5},77,152))
local I
love={
  filesystem={getDirectoryItems=function()return {'i0_8_77x152.png','i0_2_206x131.png'}end,
    getInfo=function()return {}end},
  graphics={newImage=function(path)
    local w,h=path:find('i0_2_',1,true) and 206 or 77,path:find('i0_2_',1,true) and 131 or 152
    return {getDimensions=function()return w,h end,setFilter=function()end}
  end}
}
setmetatable(love.graphics,{__index=function()return function()end end})
I=require('src.atlas_inspector')
I.initialize();I.toggle()
assert(I.nextCandidate(1))
assert(I.pinSelection());local before=I.pinnedFrame;local sourceName=I.selectedFile()
I.step(1)
assert(I.pinnedFrame==before and I.pinnedFrame.atlas==sourceName)
assert(I.pinSelection()==false)
assert(I.keypressed('l') and I.pinnedFrame==nil)
assert(I.keypressed('n'))
assert(I.keypressed('h') and I.pinnedFrame)
assert(I.pinnedFrame.atlas==I.selectedFile())
I.draw() -- pinned crop and current crop both load with mocked graphics
print('ATLAS COMPARE REGRESSIONS PASSED')
