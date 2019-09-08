pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

function debug(t)
  start_scene.root.text = t
  active_scene = start_scene
end

function _init()
  start_scene = scene:new()
  game_scene = scene:new()    
  
  active_scene = game_scene
  -- active_scene = start_scene

  start_scene.root = layer:new({text="start",x=20,y=20})
  game_scene.root = layer:new({text="game",x=-20,y=30})      
  start_scene.root.update = function()
    if btnp(0) then
      sfx(0)
      active_scene = game_scene
    end
  end
  game_scene.root.update = function(self)
    local hill = {}   
    local o = 0
    for i=1,34 do
      for j=1,4 do
        add(hill, i)
      end
    end
    random_shuffle(hill)
    local p1 = player:new() 
    local p2 = player:new()
    hill.i = 1
    p1:init(hill)
    p2:init(hill)
    
    p1.river.draw = function(self)
      for i=1,#self do
        local row, col = flr((i-1) / 24), (i-1) % 24 + 1
        local suit, order = parse_tile(self[i])        
        print(order,10+4*col,80-14*row,7)
        print(suit,10+4*col,80+6-14*row,7)
      end
    end
    p2.river.draw = function(self)
      for i=1,#self do
        local row, col = flr((i-1) / 24), (i-1) % 24 + 1
        local suit, order = parse_tile(self[i])
        print(order,10+4*col,30+14*row,7)
        print(suit,10+4*col,30+6+14*row,7)
      end
    end    
    p1.hand.draw = function(self) 
      for i=1,#self do
        if not(self.active and self.active_index == i and not self.flashing) then          
          suit, order = parse_tile(self[i])        
          local o = 0
          if (i==#self) and ((i+1)%3==0) then 
            o += 2
          end
          print(order,p1.hand.st+4*i+o,100,7)
          print(suit,p1.hand.st+4*i+o,100+6,7)
        end
      end      
    end    
    p2.hand.draw = function(self)          
      for i=1,#self do
        local o = 0
        if i == 14 then 
          o += 2
        end
        print('-',p2.hand.st+4*i+o,10)
      end
    end
    p1.hand.twinkle = function(self)
      self.flashing = not self.flashing
    end

    self.sub_claim = function(self)
      p1.sub_options:update()
      if btnp(4) then 
        --[[      
        sfx(0)
        local op = p1.options[p1.options.active_index]
        local opp = p1.sub_options[p1.sub_options.active_index]        
        p1:add(p1.options.target)
        sort(p1.hand)
        op.cmd(p1, opp.param)
        local t = #p1.sub_options
        for i=1,t do --!!!
          p1.sub_options[i] = nil
        end
        local t = #p1.options
        for i=1,t do --!!!
          p1.options[i] = nil
        end
        p1.hand.active = true
        p1.hand.active_index = #p1.hand
        p1.hand.flashing = true            
        game_scene.animations.twinkle = twinkle:new(nil,p1.hand,20)
        self.update = self.player_select_tile_to_discard                
        --]]
      end

      if btnp(5) then
        sfx(0)
        local t = #p1.sub_options
        for i=1,t do --!!!
          p1.sub_options[i] = nil
        end        
        self.update = self.claim
      end     
    end

    self.claim = function(self)
      p1.options:update()
      if btnp(4) then                 
        local op = p1.options[p1.options.active_index]
        if type(op.param) ~= "number" then
          for i in all(op.param) do -- better use params
            s, o = parse_tile(i)
            add(p1.sub_options, 
              {
                text=tostr(o*1111), 
                cmd=p1.kann, param=o
              }
            );
            p1.sub_options.active_index = 1
          end
          self.update = self.sub_claim
        else
          op.cmd(p1, op.param)
          local t = #p1.options
          for i=1,t do --!!!
            p1.options[i] = nil
          end
          p1.hand.active = true
          p1.hand.active_index = #p1.hand
          p1.hand.flashing = true            
          game_scene.animations.twinkle = twinkle:new(nil,p1.hand,20)
          self.update = self.player_select_tile_to_discard
        end
      end

      if btnp(5) then
        sfx(0)
        -- p1.options = {}
        local t = #p1.options
        for i=1,t do --!!!
          p1.options[i] = nil
        end
        self.update = self.player_select_tile_to_discard
      end       
    end

    self.sub_naki = function(self)
      p1.sub_options:update()
      if btnp(4) then 
        --[[
        sfx(0)
        local op = p1.options[p1.options.active_index]
        local opp = p1.sub_options[p1.sub_options.active_index]        
        p1:add(p1.options.target)
        sort(p1.hand)
        op.cmd(p1, opp.param)
        local t = #p1.sub_options
        for i=1,t do --!!!
          p1.sub_options[i] = nil
        end
        local t = #p1.options
        for i=1,t do --!!!
          p1.options[i] = nil
        end
        p1.hand.active = true
        p1.hand.active_index = #p1.hand
        p1.hand.flashing = true            
        game_scene.animations.twinkle = twinkle:new(nil,p1.hand,20)
        self.update = self.player_select_tile_to_discard        
        --]]
      end

      if btnp(5) then
        sfx(0)
        local t = #p1.sub_options
        for i=1,t do --!!!
          p1.sub_options[i] = nil
        end        
        self.update = self.naki
      end    
    end

    self.naki = function(self)      
      p1.options:update()

      if btnp(4) then         
        local op = p1.options[p1.options.active_index]
        if type(op.param) ~= "number" then
          for i in all(op.param) do -- better use params
            s, o = parse_tile(i)
            add(p1.sub_options, 
              {
                text=tostr(o*100+(o+1)*10+(o+2)), 
                cmd=p1.chii, param=o
              }
            );
            p1.sub_options.active_index = 1
          end
          self.update = self.sub_naki          
        else
          p1:add(p1.options.target)
          sort(p1.hand)
          op.cmd(p1,op.param)
          local t = #p1.options
          for i=1,t do --!!!
            p1.options[i] = nil
          end
          p1.hand.active = true
          p1.hand.active_index = #p1.hand
          p1.hand.flashing = true            
          game_scene.animations.twinkle = twinkle:new(nil,p1.hand,20)
          self.update = self.player_select_tile_to_discard
        end
        --self.update = self.player_turn
      end

      if btnp(5) then
        sfx(0)
        -- p1.options = {}
        local t = #p1.options
        for i=1,t do --!!!
          p1.options[i] = nil
        end
        self.update = self.player_turn
      end      
    end    

    self.player_turn = function(self)
      p1:draw_a_tile()
      p1.hand.active = true
      p1.hand.active_index = #p1.hand
      p1.hand.flashing = true            
      game_scene.animations.twinkle = twinkle:new(nil,p1.hand,20)
      p1.divide_results = {}
      if is_agari(p1.count, p1.divide_results) then      
      --if true then
        add(p1.options, {text="tsumo", cmd=p1.tsumo, param=p1.hand[#p1.hand]})
      end
      local kantsus = find_kantsu(p1.count)
      --if #kantsus > 0 then
      if true then 
        kantsus = {1,2,9}
        add(p1.options, {text="kan", cmd=p1.ankan, param=kantsus})
      end
      --[[ richii?
      if any_koutsu(p2.count, d) then
        --if true then
        add(p1.options, {text="pon", cmd=p1.pon, param=d})
      end
      --]]
      if #p1.options > 0 then 
        p1.options.target = d
        p1.options.active_index = 1
        self.update = self.claim
      else
        self.update = self.player_select_tile_to_discard
      end
    end

    self.player_select_tile_to_discard = function(self)            
      if btnp(0) then
        if p1.hand.active_index > 1 then 
          sfx(0)
          p1.hand.active_index -= 1
          game_scene.animations.twinkle.timer = 0
          p1.hand.flashing = true
        end
      end
      if btnp(1) then
        if p1.hand.active_index < #p1.hand then 
          sfx(0)
          p1.hand.active_index += 1
          game_scene.animations.twinkle.timer = 0
          p1.hand.flashing = true
        end
      end      

      if btnp(4) then
        sfx(0)
        game_scene.animations.twinkle = nil
        p1:discard(p1.hand.active_index)
        p1.hand.active = false
        self.update = self.cpu_turn
      end
    end
    
    self.cpu_turn = function(self)
      p2:draw_a_tile()
      self.update = self.cpu_select_tile_to_discard         
    end

    self.cpu_select_tile_to_discard = function(self)      
        sfx(0)
        local d = p2:discard(14)
        local chiis = {}
        if p1.count[d] == nil then 
          p1.count[d] = 0
        end 
        p1.count[d] += 1
        if any_shuntsu(p1.count, d, chiis) then
          --if true then
          if (#chiis == 1) chiis = chiis[1]
          add(p1.options, {text="chii", cmd=p1.chii, param=chiis})
        end
        if any_koutsu(p1.count, d) then
          --if true then
          add(p1.options, {text="pon", cmd=p1.pon, param=d})
        end
        if any_kantsu(p1.count, d) then
        --if true then
          add(p1.options, {text="kan", cmd=p1.daiminkan, param=d})
        end
        p1.count[d] -= 1
        if p1.count[d] == 0 then 
          p1.count[d] = nil
        end 
        if #p1.options > 0 then 
          p1.options.target = d
          p1.options.active_index = 1
          self.update = self.naki
        else
          self.update = self.player_turn      
        end
    end

    self.update = self.player_turn 

    self.children = {}
    add(self.children, p1.hand)
    add(self.children, p2.hand)
    add(self.children, p1.river)
    add(self.children, p2.river)
    p1.options = menu:new()
    p1.options.x0 = 90
    p1.options.y1 = 120
    p1.options.w = 32
    p1.sub_options = menu:new()
    p1.sub_options.x0 = 85
    p1.sub_options.y1 = 115
    p1.sub_options.w = 28

    add(self.children, p1.options)
    add(self.children, p1.sub_options)

    p1.fuuro.draw = function(self) 
      if #self > 0 then
        for i=1,#self do
          local f=self[i]
          if (#f == 3) then
            for j=1,3 do
              suit, order = parse_tile(f[j])        
              print(order,-5+i*15+4*j,100,7)
              print(suit,-5+i*15+4*j,100+6,7)
            end          
          else            
            local suit, order = parse_tile(f[1])
            for j=1,3 do              
              print(order,-5+i*15+4*j,100,7)
              print(suit,-5+i*15+4*j,100+6,7)
            end          
            print(order,-5+i*15+4*2,100-6,7)
          end
        end   
      end      
    end
    p2.fuuro.draw = function(self) 
      if #self > 0 then      
      end      
    end
    add(self.children, p1.fuuro)
    add(self.children, p2.fuuro)
  end    
  start_scene.active_layer = start_scene.root
  game_scene.active_layer = game_scene.root  
end
scene = {}
function scene:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.active_layer={}
  self.animations={}
  self.last_scene=nil
  return o
end
function scene:update()
  self.active_layer:update()
  if self.animations ~= nil then 
    for k,v in pairs(self.animations) do
      v:update()
    end  
  end
end
function scene:draw()
  cls()
  rect(0,0,127,127,1)
  self.root:draw()
end
layer = {}
function layer:new(o)  
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
function layer:update()
end
function layer:draw()
  print(self.text,x,y)
  if self.children then
    for c in all(self.children) do
      c:draw()      
    end
  end
end
twinkle = {}
function twinkle:new(o,target,period)
  o = o or {}
  setmetatable(o, self)
  self.__index = self    
  o.target = target
  o.period = period
  o.timer = period
  return o
end
function twinkle:update()
  self.timer -= 1
  if self.timer <= 0 then
    self.target:twinkle()
    self.timer = self.period
  end
end
-->8
function _update()
  active_scene:update()
end
player = {}
function player:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self  
  o.hand = {}
  o.river = {}
  o.fuuro = {}
  o.count = {}
  return o
end
function player:add(t)
  local h = self.hand
  local c = self.count
  add(h, t)
  if c[t] == nil then 
    c[t] = 0
  end 
  c[t] += 1
end
function player:del(i)  
  local h = self.hand
  local c = self.count
  local t = h[i]
  h[i] = h[#h]
  h[#h] = nil
  c[t] -= 1
  if c[t] == 0 then
    c[t] = nil
  end  
end
function player:dels(m)  
  local h = self.hand
  local mi = 1
  for i=1,#h do
    if h[i] == m[mi] then
      self:del(i)
      i -= 1
      mi += 1
      if mi > #m then 
        break
      end
    end
  end 
  h.st += 15  
  sort(h)
end
function player:init(hill)   
  for i=1,13 do
    local t = hill[hill.i]
    self:add(t)
    hill.i+=1
  end    
  self.hill = hill
  self.hand.st = 10
  sort(self.hand)
end
function player:draw_a_tile()
  local h = self.hill
  local t = h[h.i]
  h.i += 1
  self:add(t) 
end
function player:discard(i)
  local h = self.hand
  local t = h[i]
  add(self.river, t)
  self:del(i)
  sort(h)
  return t
end
function player.chii(self, c)
  --local shuntsu = {self.hand[1],self.hand[2],self.hand[3]}
  local shuntsu = {c,c+1,c+2}
  add(self.fuuro, shuntsu);  
  self:dels(shuntsu)
end
function player:pon(d)
  --local koutsu = {self.hand[1],self.hand[2],self.hand[3]}
  local koutsu = {d,d,d}
  add(self.fuuro, koutsu);  
  self:dels(koutsu)  
end
function player:daiminkan(d)
  local kantsu = {d,d,d,d}
  kantsu.type = daiminkan
  add(self.fuuro, kantsu);  
  self:dels(kantsu)
end
function player:shouminkan(d)  
end 
function player:ankan(d)
  local kantsu = {d,d,d,d}
  kantsu.type = ankan
  add(self.fuuro, kantsu);  
  self:dels(kantsu)
end
function player:agari()
end
function player:tsumo()
  active_scene = start_scene
end
function player:ron()
end
menu = {}
function menu:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self    
  o.x0 = 0
  o.y1 = 0
  o.w = 0
  o.active_index = 0
  return o
end
function menu:update()
  if btnp(2) then
    if self.active_index > 1 then 
      sfx(0)
      self.active_index -= 1
    end
  end

  if btnp(3) then    
    if self.active_index < #self then 
      sfx(0)
      self.active_index += 1
    end 
  end    
end
-->8
function _draw()
  active_scene:draw()  
end
function menu:draw()
  if #self > 0 then      
    local x0 = self.x0
    local y1 = self.y1
    local x1 = x0 + self.w
    local y0 = y1-6*#self-6
    palt(0, false)
    --pal(6, 1)
    rectfill(x0,y0,x1,y1,0)
    --rectfill(x0,y0,x1,y0,0)
    rect(x0,y0,x1,y1,6)
    palt(0, true)
    pal()
    x0 += 4
    y0 += 4
    for i=1,#self do
      print(self[i].text, x0+6, y0)
      if i==self.active_index then
        spr(255,x0+sin(time()),y0)
      end
      y0 += 6
    end
  end  
end
-->8
-- Agari Algorithm
function any_shuntsu_start_with(c, h)      
  if c[h] == nil or c[h+1] == nil or c[h+2] == nil then 
    return false
  end
  for i=0,2 do
    if i*9+1 <= h and h <= i*9+7 then
      return true      
    end
  end
end

function any_shuntsu(c, h, options)
  if h > 27 then
    return false
  end
  if (any_shuntsu_start_with(c, h)) then 
    add(options, h)
  end
  if (h ~= 1 and h ~= 10 and h ~= 19) then
    if (any_shuntsu_start_with(c, h-1)) then 
      add(options, h-1)      
    end 
    if (h ~= 2 and h ~= 11 and h ~= 20) then
      if (any_shuntsu_start_with(c, h-2)) then 
        add(options, h-2)
      end
    end
  end
  --add(options, h)
  return #options > 0
end
function any_koutsu(c, h)
  if c[h] == nil then 
    return false 
  end 
  return c[h] >= 3
end
function any_kantsu(c, h)
  if c[h] == nil then 
    return false 
  end 
  return c[h] >= 4
end
function find_kantsu(c)
  local z = {}
  for i,v in pairs(c) do
    if v >= 4 then
      add(z, i)
    end
  end 
  return z
end
function is_agari(c, divide_results)  
  local divide_result = {}
  function shuntsu_dfs(h)
    local ok = false

    if h == nil then 
      return false
    end
    if any_shuntsu_start_with(c, h) then
      c[h] -= 1
      c[h+1] -= 1
      c[h+2] -= 1
      add(divide_result, {h,h+1,h+2})
      mentsu_dfs()
      del(divide_result, {h,h+1,h+2})
      c[h+2] += 1
      c[h+1] += 1
      c[h] += 1
    end
  end

  function koutsu_dfs(h)
    if any_koutsu(c, h) then    
      c[h] -= 3
      add(divide_result, {h,h,h})
      mentsu_dfs()
      del(divide_result, {h,h,h})
      c[h] += 3
    end 
  end

  function mentsu_dfs()  
    for i, v in pairs(c) do     
      if v >= 1 then
        koutsu_dfs(i)
        shuntsu_dfs(i)
        return
      end
    end
    add(divide_results, divide_results)
  end

  -- jantou, 11  
  for i, v in pairs(c) do    
    if v >= 2 then
      if (not(is_jihai(i) and v > 2)) then 
        v -= 2
        add(divide_result, {v,v})
        mentsu_dfs(c, divide_results) 
        del(divide_result, {v,v})
        v += 2
      end
    end
  end
  -- return #divide_results > 0
  if #divide_results > 0 then
    return true
  end
end

-->8
-- General Library
function sort(a)
 for i=1,#a do
    local j = i
    while j > 1 and a[j-1] > a[j] do
      a[j],a[j-1]=a[j-1],a[j]
      j -= 1
    end
  end
end
function random_shuffle(a)
 for i=1,#a do
  j=flr(rnd(#a-i+1))+i
  a[i],a[j] = a[j],a[i]
 end 
end
function parse_tile(x)
  if x <= 27 then 
    x -= 1
    local s = {"m","p","s"}
    return s[1+flr(x/9)],1+x%9
  end
  x -= 27
  local s = {"e","s","w","n","w","f","z"}  
  return 'z', s[x]
end
function is_jihai(x)
  return x > 27
end
-->8
-- UI stuff
function rectfill2(_x,_y,_w,_h,_c) 
 rectfill(_x,_y,_x+max(_w-1,0),_y+max(_h-1,0),_c)
end

__gfx__
000000000000000066606660000000006660666066606660aaaaaaaa00aaa00000aaa00000000000000000000000000000aaa000a0aaa0a0a000000055555550
000000000000000000000000000000000000000000000000aaaaaaaa0a000a000a000a00066666600aaaaaa066666660a0aaa0a000000000a0aa000000000000
007007000000000060666060000000006066606060000060a000000a0a000a000a000a00060000600a0000a060000060a00000a0a0aaa0a0a0aa0aa055000000
00077000000000000000000000000000000000000000000000aa0a0000aaa000a0aaa0a0060000600a0aa0a060000060a00a00a000aaa00000aa0aa055055000
000770000000000066606660000000000000000060000060a000000a0a00aa00aa00aaa0066666600aaaaaa066666660aaa0aaa0a0aaa0a0a0000aa055055050
007007000005000000000000000000000005000000000000a0a0aa0a0aaaaa000aaaaa000000000000000000000000000000000000aaa000a0aa000055055050
000000000000000060666060000000000000000060666060a000000a00aaa00000aaa000066666600aaaaaa066666660aaaaaaa0a0aaa0a0a0aa0aa055055050
000000000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006666660666666000666666006666600666666006660666066666660000066606660000066666660000066600000666066600000
00000000000000000000000066666660666666606666666066666660666666606660666066666660000066606660000066666660000066600000666066600000
00000000000000000000000066666660666666606666666066666660666666606660066066666660000006606600000066666660000066600000066066600000
00000000000000000000000066600000000066606660000066606660000066606660000000000000000000000000000000000000000066600000000066600000
00000660666666606600000066600000000066606660666066606660666066606660066066000660660006606600066000000660660066606666666066600660
00006660666666606660000066600000000066606660666066606660666066606660666066606660666066606660666000006660666066606666666066606660
00006660666666606660000066600000000066606660666066606660666066606660666066606660666066606660666000006660666066606666666066606660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006660066666006660000066600000000066600666666066606660666666006660666066606660666066606660666066606660666000006660666066666660
00006660666666606660000066600000000066606666666066606660666666606660666066606660666066606660666066606660666000006660666066666660
00006660666666606660000066600000000066606666666066000660666666606600066066006660660006606600066066600660660000006600666066666660
00006660666066606660000066600000000066606660000000000000000066600000000000006660000000000000000066600000000000000000666000000000
00006660666666606660000066666660666666606666666066000660666666606666666066006660000006606600000066600000666666600000666066000000
00006660666666606660000066666660666666606666666066606660666666606666666066606660000066606660000066600000666666600000666066600000
00006660066666006660000006666660666666000666666066606660666666006666666066606660000066606660000066600000666666600000666066600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005000000088000088
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005055000080000008
00000660666666606600000066666660666066606660666066606660666066600000066066000000000006600000000066000660660000005055055000000000
00000000000000000000000000000000666066606660000066606660000066600000000000000000000000000000000000000000000000000055055000000000
00000000000000000000000066666660666066606666666066666660666666606600000000000660000006606600066000000000660000005000055000000000
00000000000000000000000066666660666066606666666066666660666666606660000000006660000066606660666000000000666000005055000000000000
00000000000000000000000066666660666066600666666006666600666666006660000000006660000066606660666000000000666000005055055080000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088000088
06000000000000000000060000000000505050506660666000000000000550000000000000000000000000000000000000000000000000000000000000000000
60000000060000000000006000000600000000000000000000500500000000500500005005050050005000000000005000500000000000000000000000000000
66000000660000000000066000000660505050506066606000050000055005000500005005000000000005000050055000000500000000000000000000000000
00000000000000000000000000000000000000000000000005050000555050000005000000005000000000000000000005000000000000000000000000000000
66000000660000000000066000000660505050505050505000005050000050500005050000005050000000000000000000055000000000000000000000000000
0005000000050000000500000005000000000000000000000050500000050000050505000500005000050000005500500050050000aaaaa00000000000000000
600000006000000000000060000000605050505050505050000050000005000005000000050500500000000005555000005550000aaaaaaaa000000000aaaa00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0aaaaaaaa00000aaaaaaa0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000a00aaaaaaaaaaaaaaaaaaaaa
cc7777cc7777ccccccccccccccccccccc77777777cccccccccccccccccccccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaa
ccc77cccc77ccccccccccccccccccccccc77cccc77ccccccccccccccccccccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaa0a
cccc77cc77cc77777cc7777cc7777ccccc77ccccc77cc777777c7777777cccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaa0aa
ccccc7777cc77ccc77cc77cccc77cccccc77cccccc77cc77cc7cc77ccc77ccc77ccccccc000000000000000000000000000000000aaaaaaaaaaaaaaaaaaa0aa0
ccccc7777c77ccccc77c77cccc77cccccc77cccccc77cc77ccccc77cccc77cc77ccccccc0000000000000000000000000000000000aaaaaaaaaaaaaaa0a0a0a0
cccccc77cc77ccccc77c77cccc77cccccc77cccccc77cc7777ccc77cccc77cc77ccccccc00000000000000000000000000000000a00aaa0a0a0a0a0a0a0a0a0a
cccccc77cc77ccccc77c77cccc77cccccc77cccccc77cc77ccccc77cccc77cc77ccccccc00000000000000000000000000000000a0000aaaa0a0a0a0a0aaa00a
cccccc77cc77ccccc77c77cccc77cccccc77ccccc77ccc77ccccc77cccc77cc77ccccccc00000000000000000000000000000000aa000000aaaaaaaaaaa000aa
cccccc77ccc77ccc77ccc77cc77ccccccc77cccc77cccc77cc7cc77ccc77cccccccccccc00000000000000000000000000000000aa000aa000000000000000aa
ccccc7777ccc77777ccccc7777ccccccc77777777cccc777777c7777777cccc77ccccccc000000000000000000000000000000000aa0000aaaaaaaaaa0000aa0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000a0aa00000000000000aa0a0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000a00aa0000000000aa00a00
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000aa00aaaaaaaaaa00aa000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000aa0000000000aa00000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000aaaaaaaaaa0000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cc7777cc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777ccccccccccccccccccc77ccccccc000000000000000000000000
ccc77cc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777ccc77cccccccccccccccccc77ccccccc000000000000000000000000
ccc77c77cccc7777c777777c7777ccc777777ccccc77cccccc7777cccc77ccccccccc77cccc77c777777c77777777cc77ccccccc000000000000000000000000
ccc7777cccccc77ccc77cc7cc77ccccc77cc77ccc7777cccc77c77ccc7777ccccccc77ccccccccc77cc7cccc77cc7cc77ccccccc000000000000000000000000
ccc777ccccccc77ccc77ccccc77ccccc77cc77ccc7cc7cccc77cccccc7cc7ccccccc77ccccccccc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc7777cccccc77ccc7777ccc777cccc77777ccc77cc7ccccc77cccc77cc7ccccccc77cccc7777c7777ccccc77ccccc77ccccccc000000000000000000000000
ccc77777ccccc77ccc77cccc777ccccc77cc77cc777777ccccc77ccc777777cccccc77ccccc77cc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc77c777cccc77ccc77ccccc77ccccc77cc77cc77cc77cccccc77cc77cc77ccccccc77cccc77cc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc77cc777ccc77ccc77cc7cc77cc7cc77cc77c77ccc77cc77cc77c77ccc77cccccccc77ccc77cc77cc7cccc77cccccccccccccc000000000000000000000000
cc7777cc777c7777c777777c777777c777777c7777cc777cc7777c7777cc777cccccccc77777cc777777ccc7777cccc77ccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
c0000000000000ccccccc000000000cc00000000000ccc0000000000000000000000000000000000000000000000000000000000000000cc0000000000000000
0000000000000000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000
00777777777770000c000077777770000777777777700007777777700777777077777777000077777707777777007777707777777777700c0000000000000000
0007777777777770000077777777777000777777777770007777770007777700077777700c0007777707777770007777707777777777700c0000000000000000
c00000777000777000077770000077770000777000777000007770000777000000077700ccc000777000077700007770000077700007700c0000000000000000
cc0000777000077700777000000000777000777000077700007770007770000c00077700cccc00777000077700077700000077700000700c0000000000000000
cccc007770000777007770000000007770007770000777000077700777000cccc0077700cccc00777000077700777000cc0077700000000c0000000000000000
cccc00777000077700770000000000077700777000077700007770777000ccccc0077700cccc0077700007770777000ccc007770007000cc0000000000000000
cccc0077700007700777007700077007770077700007700c00777777000cccccc0077700cccc007770000777777000cccc00777777700ccc0000000000000000
cccc0077700777700777007700077007770077700077700c0077777000ccccccc0077700cccc00777000077777000ccccc00777777700ccc0000000000000000
cccc007777777700077700770007700777007777777700cc00777777000cccccc0077700cccc007770000777777000cccc00777000700ccc0000000000000000
cccc0077777770000777000700070007770077777777000c007777777000ccccc0077700cccc0077700007777777000ccc007770000000cc0000000000000000
cccc007770000000077700000000000770007770077770000077707777000cccc0077700ccc000777000077707777000cc0077700000000c0000000000000000
cccc0077700000c000777000000000777000777000777700007770077770000cc0077700cc00007770000777007777000c0077700000700c0000000000000000
ccc000777000cccc00777000000000777000777000077770007770007777000000077700000700777000077700077770000077700007700c0000000000000000
cc00007770000ccc00077770000077770000777000007777007770000777770000077700007700777000077700007777700077700007700c0000000000000000
c0007777777000ccc0007777777777700007777700000777777777700077777700777777777707777770777777000777777777777777700c0000000000000000
c0077777777700cccc000077777770000077777770000077777777770000777707777777777707777770777777700007777777777777700c0000000000000000
c0000000000000ccccc000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000c0000000000000000
cc00000000000cccccccc000000000ccc000000000ccc000000000000cc000000000000000000000000000000000cc0000000000000000cc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
00000000000000000000000000000000000006000000000006000000000000000000000000060006000000000066006600066600000666000006660000066600
00000000006660000000000000000000006600600006600060066000006600000066006600060006006600660600060000660600006606000066060000660600
00666000060666000066600000000000006660606066600060666000006660600600060000600060060006000600060006666000066660000666606606666066
06066600060666000606660006666660066666006066006006666600600660600066606000666060006660600066606006666666066666660666660606666606
60666660066666006066666060066666600666000666660006660060066666000606660606666606066606060606060606666606006606060660660000660600
66666660066666006666666066666666606660000666600000666060006666000666060606060606060666060660660666066000066000006606600006600000
06666600006660000666660006666660006666000066660006666000066660000606666006606660066606600666666006606600006600000060660000660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666000000066000000000000000000000000000000000000000000000666000000000000666600006666000066666600666600
00666600000000000066660006600600000666600000660000000000000066000000000000066600006666660006660000066666000660660006606600066066
06600060006666660660006006000000000606000006666000006600000666600006660000666666006666060066666600666666006666660066660000666666
06660000066600000666000006660000060666660006060000066660000606000066666600666606066666660066660600060000000600000006000000060000
00666600006666000066660000666600066666060606666600060600060666660066660606666666066666000666666600006600060066000000660006006600
06066066060660660606606606066066006660000666660606066666066666060666666606666600066666660666660000006660060066600000666006006660
06060660060606600606066006060660000000000066600006666606006660000666660006666666066606060666666606666600006666000666660000666600
00000000000000000000000000000000000000000000000000666000000000000666666606660606066660000666060600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000606000000000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
00060600006666000006060000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
00666600000606660066660000060666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000
00060666000666660006066600066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
06066666006000000006666606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
66000000066066000660000066066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66066606066066000660660066066606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600600000660000060060000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010400000557514625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001d0612b161340612c20023200112000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001d6452a645236451c6451b6452f6452d6452b645136452b6452b6452a6452865534645266451c6451b6452c64532645366451e6451e6452a63531635386352963526635356352b645226452864536645
010c00000237000000023700000005370000000537000000073700000007370000000737000000073700000008370000000837000000073700000007370000000537000000053700000002370000000237000000
010c00000e073000030000000000326750000000000000000e073000000e073000003267500000000000000000000000000e07300000326750000000000000000e073000000e0730000032675000000000032645
001000003d636176163d636176163d6233d6031760600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000543539625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000543539605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001e54300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 41420304

