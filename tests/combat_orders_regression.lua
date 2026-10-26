-- Regression coverage for explicit orders, dead buildings, and terminal result.
-- Runs with texlua or Lua 5.3. Tests provisional RTS mechanics, not J2ME parity.
package.path='./?.lua;./?/init.lua;'..package.path
local World=require('src.world')
local function check(condition,message) assert(condition,message) end
local function find(world,team,kind)
  for _,e in ipairs(world.entities) do
    if e.alive and e.team==team and e.kind==kind then return e end
  end
end
local game=World.new('scenario',1,994)
local barracks=find(game,1,'barracks')
local prior=game.money[1]
local oldQueue=barracks.queue
barracks.alive=false
check(not game:train(barracks,'infantry'),'destroyed barracks can still train')
check(game.money[1]==prior and barracks.queue==oldQueue,'rejected training mutated economy')
barracks.alive=true
local counterfeit={kind='barracks',team=1,building=true,alive=true,queue=0}
check(not game:train(counterfeit,'infantry'),'unregistered barracks can train')
check(game.money[1]==prior,'unregistered building charged player')

-- A manually clicked farther enemy must take priority over a closer enemy.
local soldier=find(game,1,'infantry')
local nearEnemy=game:add('infantry',2,soldier.x+10,soldier.y)
local orderedEnemy=game:add('infantry',2,soldier.x+30,soldier.y)
game:select(soldier)
game:moveSelected(orderedEnemy.x,orderedEnemy.y)
check(soldier.order and soldier.order.manualAttack and soldier.order.target==orderedEnemy.id,
 'click-to-attack did not record an explicit order')
local nearHP,orderedHP=nearEnemy.hp,orderedEnemy.hp
for _,e in ipairs(game.entities) do e.cooldown=10 end
soldier.cooldown=0
game:_tick(1/30)
check(orderedEnemy.hp<orderedHP,'explicit enemy was not attacked')
check(nearEnemy.hp==nearHP,'nearby enemy displaced explicit attack order')
-- A destroyed target must not leave an endless order to its former coordinates.
orderedEnemy.alive=false
soldier.cooldown=10
game:_tick(1/30)
check(soldier.order==nil,'dead explicit target order was not cleared')

-- On simultaneous possible HQ eliminations, only the first resolution wins.
local race=World.new('scenario',1,995)
local playerHQ=find(race,1,'hq')
local hostileHQ=find(race,2,'hq')
playerHQ.hp=1
hostileHQ.hp=1
local friendlyTurret=race:add('turret',1,hostileHQ.x-16,hostileHQ.y)
local hostileTurret=race:add('turret',2,playerHQ.x+16,playerHQ.y)
for _,e in ipairs(race.entities) do e.cooldown=10 end
friendlyTurret.cooldown=0
hostileTurret.cooldown=0
race:_tick(1/30)
check(race.result=='VITORIA','first HQ destruction did not decide match')
check(playerHQ.alive and playerHQ.hp>0,'simulation continued after match ended')
check(hostileHQ.alive==false,'enemy HQ was not destroyed')
print('COMBAT ORDER REGRESSIONS PASSED')
