package.path='./?.lua;./?/init.lua;'..package.path
local boxes=require('src.atlas_candidates')
local Regions=require('src.atlas_regions')
assert(boxes['i0_8_77x152.png'] and #boxes['i0_8_77x152.png']>0)
for atlas,list in pairs(boxes) do
  local w,h=atlas:match('_(%d+)x(%d+)%.png$')
  -- Every suggestion must be bounded by the untouched source atlas.
  assert(w and h)
  for _,box in ipairs(list) do
    assert(Regions.validate(atlas,box,tonumber(w),tonumber(h)))
  end
end
local fs={getDirectoryItems=function()return {'i0_8_77x152.png'}end,
 getInfo=function()return {}end}
local g={newImage=function()return {getDimensions=function()return 77,152 end,
 setFilter=function()end}end}
setmetatable(g,{__index=function()return function()end end})
love={filesystem=fs,graphics=g}
local I=require('src.atlas_inspector')
I.initialize();I.toggle()
assert(I.nextCandidate(1))
assert(I.candidateIndex==2)
local a=boxes['i0_8_77x152.png'][2]
assert(I.selection.x==a.x and I.selection.y==a.y)
assert(I.selection.w==a.w and I.selection.h==a.h)
I.keypressed('g')
assert(#I.previewFrames==1)
assert(I.previewFrames[1].x==a.x)
I.keypressed('m')
assert(I.candidateIndex==#boxes['i0_8_77x152.png'])
I.keypressed('j')
assert(not I.reviewOnly)
I.keypressed('n')
assert(I.candidateIndex==1)
assert(I.selection.w==boxes['i0_8_77x152.png'][1].w)
I.keypressed('j')
assert(I.reviewOnly)
assert(#I.visibleCandidateIndices()==5)
I.keypressed('b')
assert(I.showCandidates)
I.keypressed('escape')
assert(not I.active)
print('CANDIDATE INSPECTOR REGRESSIONS PASSED')
