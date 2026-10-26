local Art=require('src.art')
local UI={buttons={}}
local lg=love.graphics
local function text(t,x,y,size,color)
  lg.setColor(color and color[1] or 1,color and color[2] or 1,color and color[3] or 1,1)
  lg.print(t,x,y)
  lg.setColor(1,1,1,1)
end
function UI.newFrame() UI.buttons={} end
function UI.button(id,label,x,y,w,h,disabled,accent)
  UI.buttons[#UI.buttons+1]={id=id,x=x,y=y,w=w,h=h,disabled=disabled}
  lg.setColor(disabled and .13 or (accent and .13 or .09),disabled and .17 or (accent and .37 or .21),disabled and .21 or (accent and .50 or .31),1)
  lg.rectangle('fill',x,y,w,h,3,3)
  lg.setColor(disabled and .26 or .36,disabled and .3 or .58,disabled and .34 or .72,1)
  lg.rectangle('line',x+.5,y+.5,w-1,h-1,3,3)
  local font=lg.getFont();local tw=font:getWidth(label)
  text(label,x+(w-tw)/2,y+(h-font:getHeight())/2,10,disabled and {.47,.51,.53} or {1,1,1})
end
function UI.hit(x,y)
  for i=#UI.buttons,1,-1 do
    local b=UI.buttons[i]
    if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then
      return not b.disabled and b.id or nil,true
    end
  end
  return nil,false
end
function UI.menu(game)
  UI.newFrame()
  lg.setColor(0,0,0,1);lg.rectangle('fill',0,0,240,320)
  Art.draw('background',0,0,240,320)
  lg.setColor(.00,.03,.08,.48);lg.rectangle('fill',14,117,212,186)
  lg.setColor(.18,.56,.75,.7);lg.rectangle('line',14.5,117.5,211,185)
  text('RECONSTRUCAO LUA',54,110,12,{.64,.92,1})
  UI.button('campaign','CAMPANHA',30,133,180,27,false,true)
  UI.button('scenario','BATALHA LIVRE',30,168,180,27,false)
  UI.button('load','CONTINUAR',30,203,180,27,not love.filesystem.getInfo('save.lua'))
  UI.button('help','CONTROLES',30,238,180,27,false)
  text('PROTOTIPO v0.14 | J2ME 1.12.0',31,293,10,{.77,.83,.88})
end
function UI.help()
  UI.newFrame()
  lg.clear(.025,.075,.13,1)
  text('CONTROLES',76,20)
  local items={
    'Clique na unidade para selecionar.',
    'Arraste: selecao de grupo.',
    'Botao direito: mover / atacar.',
    'WASD ou setas: mover camera.',
    'Roda do mouse: rolar mapa.',
    'Arrastar com mouse do meio: mapa.',
    'Toque: seleciona / ordena.',
    'Arrastar no celular: pan no mapa.',
    'Previa verde/vermelha: construir.',
    'Q/E/T: preparar construcao.',
    'I: treinar soldado (quartel).',
    'K: produzir tanque (fabrica).',
    'F5: salvar / F9: carregar.',
    'ESC: pausar / voltar ao menu.',
    'F2: inspecionar PNGs originais.',
  }
  for i,s in ipairs(items) do text(s,11,46+(i-1)*15) end
  UI.button('menu','VOLTAR',53,283,134,27,false,true)
end
function UI.hud(world,paused)
  UI.newFrame()
  lg.setColor(.025,.075,.12,1);lg.rectangle('fill',0,0,240,26)
  lg.setColor(.18,.44,.59,1);lg.rectangle('fill',0,24,240,2)
  text('CRED $'..math.floor(world.money[1]),5,7,10,{.79,1,.63})
  text('+'..world.income[1]..'/s',95,7,10,{.5,.85,.95})
  text(string.format('%02d:%02d',math.floor(world.elapsed/60),math.floor(world.elapsed%60)),146,7,10)
  UI.button('pause',paused and '>' or 'II',214,3,23,19,false)
  lg.setColor(.03,.08,.12,1);lg.rectangle('fill',0,256,240,64)
  lg.setColor(.22,.56,.72,1);lg.rectangle('fill',0,256,240,1)
  UI.minimap(world,4,262,54,52)
  lg.setColor(.3,.51,.65,1);lg.rectangle('line',3.5,261.5,55,53)
  local selected=world:selectedList()
  local first=#selected==1 and selected[1] or nil
  if first then
    text(first.kind:upper()..' '..math.floor(first.hp)..' HP',64,260,9,{.85,.99,1})
  elseif #selected>1 then
    text(#selected..' UNIDADES',64,260,9,{.85,.99,1})
  else
    text(world.buildMode and ('CONSTRUIR: '..world.buildMode:upper()) or 'SELECIONE UNIDADES',64,260,9,{.72,.91,1})
  end
  if first and first.kind=='barracks' then
    UI.button('train_infantry','INF $85',65,278,77,18,world.money[1]<85,true)
    UI.button('cancel','LIMPAR',148,278,85,18,false)
    text('Fila: '..first.queue,68,300,9)
  elseif first and first.kind=='factory' then
    UI.button('train_tank','TANQ $220',65,278,77,18,world.money[1]<220,true)
    UI.button('cancel','LIMPAR',148,278,85,18,false)
    text('Fila: '..first.queue,68,300,9)
  else
    UI.button('build_barracks','QRT $340',64,278,54,18,world.money[1]<340)
    UI.button('build_factory','FAB $460',122,278,54,18,world.money[1]<460)
    UI.button('build_turret','TOR $200',180,278,56,18,world.money[1]<200)
    text(world.buildMode and 'Clique para posicionar | Esc cancela' or 'Q/E/T: construir | Toque: mover',65,301,9,{.65,.81,.9})
  end
  if world.noticeTimer>0 then
    local w=math.min(236,lg.getFont():getWidth(world.notice)+12)
    lg.setColor(0,.08,.13,.86);lg.rectangle('fill',2,229,w,22,3,3)
    text(world.notice,7,235,9)
  end
  if paused then
    lg.setColor(0,.015,.03,.67);lg.rectangle('fill',0,26,240,230)
    text('PAUSADO',97,91,12)
    UI.button('resume','CONTINUAR',52,123,136,26,false,true)
    UI.button('save','SALVAR (F5)',52,155,136,26,false)
    UI.button('back_to_menu','MENU PRINCIPAL',52,187,136,26,false)
  end
  if world.result then
    lg.setColor(0,.01,.03,.78);lg.rectangle('fill',0,26,240,230)
    text(world.result,92,98,12,{.95,.91,.55})
    UI.button('restart','JOGAR NOVAMENTE',40,132,160,28,false,true)
    UI.button('back_to_menu','MENU PRINCIPAL',40,172,160,28,false)
  end
end
function UI.minimap(world,x,y,w,h)
  lg.setColor(.16,.27,.22,1);lg.rectangle('fill',x,y,w,h)
  for _,o in ipairs(world.obstacles) do
    lg.setColor(.08,.14,.11,1)
    lg.points(x+((o.x-.5)/world.w)*w,y+((o.y-.5)/world.h)*h)
  end
  for _,e in ipairs(world.entities) do
    if e.alive then
      if e.team==1 then lg.setColor(.25,.78,1,1) else lg.setColor(1,.25,.20,1) end
      local px=x+e.x/(world.w*16)*w
      local py=y+e.y/(world.h*16)*h
      if e.building then lg.rectangle('fill',px-1,py-1,3,3) else lg.points(px,py) end
    end
  end
  lg.setColor(1,1,1,.7)
  lg.rectangle('line',x+world.camera.x/(world.w*16)*w,y+world.camera.y/(world.h*16)*h,
      240/(world.w*16)*w,230/(world.h*16)*h)
  lg.setColor(1,1,1,1)
end
return UI
