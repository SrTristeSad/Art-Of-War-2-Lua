-- Provisional grid pathfinding. No diagonal corner clipping and no fallback
-- that lets a unit walk straight through an obstacle when no route exists.
local Path = {}
local dirs = {{1,0},{0,1},{-1,0},{0,-1}}
local function key(x,y,w) return y*w+x end
local function unpackKey(k,w) return (k-1)%w+1, math.floor((k-1)/w) end

function Path.search(map,sx,sy,tx,ty,limit)
  local w,h=map.w,map.h
  sx,sy,tx,ty=math.floor(sx),math.floor(sy),math.floor(tx),math.floor(ty)
  local function walk(x,y)
    return x>=1 and y>=1 and x<=w and y<=h and not map.blocked[key(x,y,w)]
  end
  if not walk(sx,sy) then return nil end
  -- Explore reachable cells, selecting the one nearest to the destination.
  -- For a building or inaccessible target, stop at a reachable adjacent cell.
  -- If a clear target is disconnected, return nil instead of walking through walls.
  local targetWalkable=walk(tx,ty)
  local startKey=key(sx,sy,w)
  if targetWalkable and sx==tx and sy==ty then return {} end
  local head,tail=1,1
  local queue={{x=sx,y=sy,k=startKey}}
  local visited={[startKey]=true};local previous={}
  local bestKey=nil;local bestDist=math.huge
  local total=0
  while head<=tail and total<(limit or w*h) do
    local cell=queue[head];head=head+1;total=total+1
    local dx,dy=cell.x-tx,cell.y-ty
    local dist=dx*dx+dy*dy
    if dist<bestDist then bestDist=dist;bestKey=cell.k end
    if targetWalkable and cell.x==tx and cell.y==ty then
      bestKey=cell.k;bestDist=0;break
    end
    for _,step in ipairs(dirs) do
      local nx,ny=cell.x+step[1],cell.y+step[2]
      local k=key(nx,ny,w)
      if not visited[k] and walk(nx,ny) then
        visited[k]=true;previous[k]=cell.k
        tail=tail+1;queue[tail]={x=nx,y=ny,k=k}
      end
    end
  end
  if not bestKey or (targetWalkable and bestDist>0) then return nil end
  if bestKey==startKey then return {} end
  local reverse={};local current=bestKey
  while current and current~=startKey do
    local x,y=unpackKey(current,w)
    reverse[#reverse+1]={x=x,y=y}
    current=previous[current]
  end
  local path={}
  for i=#reverse,1,-1 do path[#path+1]=reverse[i] end
  return path
end
return Path
