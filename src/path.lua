-- A* in grid cells. Adjacent endpoint is chosen for blocked building targets.
local P = {}
local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
local function key(x,y,w) return y*w+x end
function P.search(map,sx,sy,tx,ty,limit)
  local w,h = map.w,map.h
  sx=math.floor(sx);sy=math.floor(sy);tx=math.floor(tx);ty=math.floor(ty)
  local function walk(x,y) return x>=1 and x<=w and y>=1 and y<=h and not map.blocked[key(x,y,w)] end
  if not walk(sx,sy) then return {} end
  local goals={}
  if walk(tx,ty) then goals[key(tx,ty,w)]=true
  else
    for r=1,4 do
      for y=ty-r,ty+r do for x=tx-r,tx+r do
        if math.abs(x-tx)+math.abs(y-ty)==r and walk(x,y) then goals[key(x,y,w)]=true end
      end end
      if next(goals) then break end
    end
  end
  if not next(goals) then return {} end
  local open={{x=sx,y=sy,k=key(sx,sy,w),f=0}}
  local g={[key(sx,sy,w)]=0};local prev={};local closed={}
  local visits=0
  while #open>0 and visits<(limit or 2500) do
    visits=visits+1
    local best=1
    for i=2,#open do if open[i].f<open[best].f then best=i end end
    local n=table.remove(open,best)
    if not closed[n.k] then
      closed[n.k]=true
      if goals[n.k] then
        local rev={};local cur=n.k
        while prev[cur] do
          local cx=(cur-1)%w+1;local cy=math.floor((cur-1)/w)
          table.insert(rev,1,{x=cx,y=cy})
          cur=prev[cur]
        end
        return rev
      end
      for _,d in ipairs(dirs) do
        local x,y=n.x+d[1],n.y+d[2];local k=key(x,y,w)
        if walk(x,y) and not closed[k] then
          local nextg=g[n.k]+1
          if not g[k] or nextg<g[k] then
            g[k]=nextg;prev[k]=n.k
            open[#open+1]={x=x,y=y,k=k,f=nextg+math.abs(x-tx)+math.abs(y-ty)}
          end
        end
      end
    end
  end
  return {}
end
return P
