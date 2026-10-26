package.path='./?.lua;./?/init.lua;'..package.path
local content={}
local font={getWidth=function(_,s)return #tostring(s)*6 end,
  getHeight=function()return 10 end}
local g={
  newImage=function(name)
    local dims={77,152}
    if name:find('i0_2',1,true) then dims={206,131} end
    return {getDimensions=function()return dims[1],dims[2]end,setFilter=function()end}
  end,
  newQuad=function(x,y,w,h,tw,th)
    assert(x>=0 and y>=0 and x+w<=tw and y+h<=th)
    return {x=x,y=y,w=w,h=h}
  end,
  getFont=function()return font end,draw=function()end,stencil=function(fn)fn()end
}
setmetatable(g,{__index=function() return function()end end})
love={graphics=g,filesystem={
  getDirectoryItems=function()return {'i0_8_77x152.png','i0_2_206x131.png'}end,
  getInfo=function(path)
    if path=='atlas_sequences_candidates.csv' then return content[path] and {} or nil end
    return path:find('%.png$') and {} or nil
  end,
  read=function(path)return content[path]end,
  write=function(path,v)content[path]=v;return true end,
}}
local I=require('src.atlas_inspector')
I.initialize();I.toggle()
assert(I.active)
assert(I.selectedFile()=='i0_2_206x131.png')
I.selection={x=0,y=0,w=12,h=14}
assert(I.addFrame())
I.keypressed('right')
I.selection={x=5,y=10,w=15,h=17}
I.keypressed('g')
assert(#I.previewFrames==2,'candidate frames did not accumulate across atlases')
I.keypressed('p'); assert(I.previewPlaying)
I.update(.25);I.draw()
assert(I.previewTime>0)
I.keypressed('f');assert(I.previewFPS==9)
I.keypressed('e')
local csv=assert(content["atlas_sequences_candidates.csv"])
assert(csv:sub(1,#require('src.sequence_draft').HEADER)==require('src.sequence_draft').HEADER)
assert(csv:find('draft_0001,1,i0_2_206x131.png,0,0,12,14,9,unverified',1,true))
assert(csv:find('draft_0001,2,i0_8_77x152.png,5,10,15,17,9,unverified',1,true))
I.keypressed('e');csv=content["atlas_sequences_candidates.csv"]
assert(csv:find('draft_0002,1',1,true),'second export overwrote first')
I.keypressed('x');assert(#I.previewFrames==0)
I.keypressed('e');assert(I.message=='Quantidade de quadros invalida')
I.keypressed('escape');assert(not I.active)
print('INSPECTOR DRAFT REGRESSIONS PASSED')
