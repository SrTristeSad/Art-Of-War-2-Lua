local Save={}
local function encode(v,depth)
  depth=depth or 0
  assert(depth<60,'Estrutura de save excedeu profundidade permitida')
  if type(v)=='number' then return tostring(v) end
  if type(v)=='boolean' then return tostring(v) end
  if type(v)=='string' then return string.format('%q',v) end
  if type(v)~='table' then return 'nil' end
  local result={'{'}
  for k,val in pairs(v) do
    if type(k)=='string' or type(k)=='number' then
      result[#result+1]='['..encode(k,depth+1)..']='..encode(val,depth+1)..','
    end
  end
  result[#result+1]='}'
  return table.concat(result)
end
function Save.write(world)
  local copy={}
  for _,key in ipairs({'seed','mode','level','elapsed','money','income','entities',
    'nextId','obstacles','terrain','camera','result','incomeTime','aiTime'}) do
    copy[key]=world[key]
  end
  for _,e in ipairs(copy.entities) do
    -- The serializer retains current data; transient path cache is ignored at restore.
  end
  local ok,err=love.filesystem.write('save.lua','return '..encode(copy))
  return ok,err
end
function Save.read(World)
  if not love.filesystem.getInfo('save.lua') then return nil,'Nao existe jogo salvo' end
  local chunk,err=love.filesystem.load('save.lua')
  if not chunk then return nil,err end
  local ok,data=pcall(chunk)
  if not ok or type(data)~='table' then return nil,'Save invalido' end
  if type(data.seed)~='number' or type(data.entities)~='table' or type(data.money)~='table' then return nil,'Save incompleto' end
  local world=World.new(data.mode,data.level,data.seed)
  for k,v in pairs(data) do world[k]=v end
  world.selected={};world.buildMode=nil;world.noticeTimer=0
  for _,e in ipairs(world.entities) do
    e.path=nil;e.pathTime=0
  end
  world:refreshBlocked();world:toast('Partida carregada.')
  return world
end
return Save
