-- Test live atlas quad dispatch and fallback without a graphical LÖVE installation.
package.path='./?.lua;./?/init.lua;'..package.path
local Art=require('src.art')
local Catalog=require('src.atlas_catalog')
local dimensions={}
for _,entry in pairs(Catalog) do
  local w,h=entry.atlas:match('_(%d+)x(%d+)%.png$')
  if w and h then dimensions[entry.atlas]={tonumber(w),tonumber(h)} end
end
local calls,loaded,quads={}, {}, {}
local missing={}
love={
  filesystem={getInfo=function(path)
    if missing[path] or path:find('assets/animations/',1,true) then return nil end
    return {}
  end},
  graphics={
    newImage=function(path)
      loaded[path]=(loaded[path] or 0)+1
      local name=path:match('/([^/]+)$')
      local dim=dimensions[name]
      if not dim then
        local entry=Catalog[name:gsub('%.png$','')]
        dim=entry and {entry.w,entry.h} or {16,16}
      end
      return {getDimensions=function()return dim[1],dim[2]end,setFilter=function()end,
        path=path}
    end,
    newQuad=function(x,y,w,h,iw,ih)
      assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
      local quad={x=x,y=y,w=w,h=h}
      quads[#quads+1]=quad
      return quad
    end,
    draw=function(...)
      calls[#calls+1]={...}
    end,
    setColor=function()end,
    rectangle=function()end,
  }
}
Art.load()
assert(#quads==21,'exactly 21 atlas quads must be built')
local unique=0
for _,n in pairs(loaded) do assert(n==1,'a texture was loaded twice');unique=unique+1 end
assert(unique>21,'standalone fallback and source textures should load without duplication')
local entry=Catalog.blue_hq
Art.drawEntity('blue_hq',100,100,48,48,0,1,'idle',0)
local c=calls[#calls]
assert(c[1].path=='assets/original/'..entry.atlas,'draw did not use the original atlas')
assert(c[2].x==entry.x and c[2].y==entry.y,'wrong atlas crop')
local width,height=Art.fitSize('blue_hq',48,48)
assert(width<48 and height==48,'sprite aspect ratio broken')
Art.draw('grass',0,0,16,16)
c=calls[#calls]
assert(c[1].path:find('assets/original/',1,true),'terrain not using atlas')
Art.drawEntity('red_tank',64,64,32,32,math.pi,0.5,'idle',.1)
c=calls[#calls]
assert(c[2] and c[2].x==Catalog.red_tank.x,'rotated quad lost original coordinates')
-- A damaged/partial source asset must leave the standalone image fallback intact.
missing['assets/original/'..Catalog.blue_hq.atlas]=true
Art.load()
assert(not Art.atlasFrames.blue_hq,'missing atlas should not create a Quad')
Art.drawEntity('blue_hq',100,100,48,48)
c=calls[#calls]
assert(c[1].path=='assets/sprites/blue_hq.png','missing atlas fallback did not render')
print('ATLAS QUAD REGRESSIONS PASSED')
