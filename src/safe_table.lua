-- Restricted parser for the table literals written by src/save.lua.
-- Unlike load(), this does not execute code from an edited save file.
local M={}
function M.decode(source)
  if type(source)~='string' or #source>4*1024*1024 then
    return nil,'Tamanho de save invalido'
  end
  local pos,steps=1,0
  local function skip()
    local _,last=source:find('^%s*',pos)
    if last then pos=last+1 end
  end
  local function consume(token)
    skip()
    if source:sub(pos,pos+#token-1)~=token then error('Token esperado: '..token) end
    pos=pos+#token
  end
  local function stringValue()
    consume('"')
    local parts={}
    while pos<=#source do
      local c=source:sub(pos,pos);pos=pos+1
      if c=='"' then return table.concat(parts) end
      if c=='\\' then
        local escaped=source:sub(pos,pos);pos=pos+1
        if escaped=='n' then c='\n'
        elseif escaped=='r' then c='\r'
        elseif escaped=='t' then c='\t'
        elseif escaped=='\\' then c='\\'
        elseif escaped=='"' then c='"'
        elseif escaped=='a' then c='\a'
        elseif escaped=='b' then c='\b'
        elseif escaped=='f' then c='\f'
        elseif escaped=='v' then c='\v'
        elseif escaped:match('%d') then
          local digits=escaped
          for _=1,2 do
            local d=source:sub(pos,pos)
            if not d:match('%d') then break end
            digits=digits..d;pos=pos+1
          end
          local number=tonumber(digits)
          if number>255 then error('Escape numerico invalido') end
          c=string.char(number)
        else error('Escape nao permitido') end
      end
      parts[#parts+1]=c
    end
    error('String inacabada')
  end
  local parse
  parse=function(depth)
    steps=steps+1
    if depth>60 or steps>300000 then error('Save excede limite de estrutura') end
    skip()
    local c=source:sub(pos,pos)
    if c=='"' then return stringValue() end
    if c=='{' then
      pos=pos+1
      local out={}
      skip()
      while source:sub(pos,pos)~='}' do
        consume('[')
        local k=parse(depth+1)
        if type(k)~='number' and type(k)~='string' then error('Chave invalida') end
        consume(']');consume('=')
        local v=parse(depth+1)
        out[k]=v
        skip()
        if source:sub(pos,pos)==',' then pos=pos+1
        else
          skip()
          if source:sub(pos,pos)~='}' then error('Separador ausente') end
        end
        skip()
        if pos>#source then error('Tabela inacabada') end
      end
      pos=pos+1
      return out
    end
    for _,word in ipairs({'true','false','nil'}) do
      if source:sub(pos,pos+#word-1)==word then
        pos=pos+#word
        if word=='true' then return true end
        if word=='false' then return false end
        return nil
      end
    end
    local fragment=source:sub(pos):match('^[-+]?%d+%.?%d*[eE]?[-+]?%d*')
    if fragment and #fragment>0 then
      local number=tonumber(fragment)
      if not number then error('Numero invalido') end
      pos=pos+#fragment
      return number
    end
    error('Valor invalido na posicao '..pos)
  end
  local ok,value=pcall(function()
    consume('return')
    local result=parse(0)
    skip()
    if pos<=#source then error('Conteudo extra nao permitido') end
    if type(result)~='table' then error('Save nao e uma tabela') end
    return result
  end)
  if not ok then return nil,tostring(value) end
  return value
end
return M
