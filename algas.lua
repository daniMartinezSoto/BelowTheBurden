-- ============================================
-- variables del juego - submarine with sphere
-- ============================================


-- === submarino ===
sub_x = 32
sub_y = 150
sub_vx = 0
sub_vy = 0
sub_flip = false

-- === física del submarino ===
accel = 1
max_speed = 1.5
friction = 0.80

-- === esfera que sigue al submarino ===
sphere_offset_y = 80
sphere_x = 0
sphere_y = 0
sphere_vx = 0
sphere_vy = 0
sphere_radius = 3

-- === control de distancia de la esfera ===
sphere_offset_speed = 1
sphere_offset_min = 10
sphere_offset_max = 100

-- === control de burbujas de la esfera ===
sphere_bubble_timer = 0
sphere_last_collision = false

-- === sistema de algas con vaivén ===
seaweeds = {}  -- tabla de algas detectadas

-- === detección de colisión con pinchos ===
spike_collision_detected = false

-- === sistema de checkpoint y muerte ===
checkpoint_x = 32
checkpoint_y = 16
checkpoint_sphere_dist = 80
is_dead = false
death_timer = 0
death_shake = 0
death_sound_played = false
transition_bubbles = {}
transition_active = false
transition_timer = 0

-- === sistema de checkpoints (banderas) ===
checkpoints = {
 {x=4, y=2, sphere_dist=10},
 {x=32, y=5, sphere_dist=5},
 {x=47, y=5, sphere_dist=5},
 {x=76, y=7, sphere_dist=5},
}
current_checkpoint = 0
checkpoints_activated = {}

-- === sistema de minas ===
mines = {}

-- === sistema de pinchos cayentes ===
falling_spikes = {}
spike_trigger_range = 1
spike_gravity = 0.3
spike_max_fall_speed = 3


turret_defs = {
 -- clave = "x,y" en coordenadas de mapa
 ["110,13"] = {range=120, fire_rate=60, proj_speed=2},
 ["121,15"] = {range=80,  fire_rate=50, proj_speed=2},

 ["110,13"]  = {range=80, fire_rate=50, proj_speed=2},
 ["88,7"]  = {range=80, fire_rate=100, proj_speed=5}
}

-- === sistema de torretas ===
turrets = {}
projectiles = {}
proj_length = 8


puzzles = {
 {
  buttons = {
   {x=15, y=14, type="floor"},
   {x=15, y=9, type="ceiling"}
  },
  door = {x=20, y=13, type="vertical"}
 },
 {
  buttons = {
   {x=25, y=8, type="floor"},
  },
  door = {x=19, y=6, type="vertical"}
 },
 {
  buttons = {
   {x=42, y=14, type="floor"},
   {x=43, y=14, type="floor"},
   {x=42, y=11, type="wall_left"}
  },
  door = {x=45, y=4, type="vertical"}
 },
 {
  buttons = {
   {x=63, y=13, type="floor"},
   {x=64, y=10, type="ceiling"}
  },
  door = {x=68, y=5, type="vertical"}
 },
 {
  buttons = {
   {x=94, y=15, type="floor"},
   {x=100, y=10, type="floor"},
   {x=116, y=15, type="floor"},
   {x=118, y=10, type="ceiling"}
  },
  door = {x=127, y=10, type="vertical"}
 }
}

buttons_state = {}
doors_open = {}

-- === partículas (burbujas) ===
particles = {}

-- === control de sonido ===
sfx_playing = false
sfx_in_playing = false


-- ============================================
-- main game code
-- ============================================

function _init()
 sphere_x = sub_x
 sphere_y = sub_y + sphere_offset_y
 
 for i=1,#puzzles do
  buttons_state[i] = {}
  for j=1,#puzzles[i].buttons do
   buttons_state[i][j] = false
  end
  doors_open[i] = false
 end
 
 for i=1,#checkpoints do
  checkpoints_activated[i] = false
 end
 
 for y=0,63 do
  for x=0,127 do
   if mget(x, y) == 53 then
    add(mines, {
     x = x,
     y = y,
     offset = rnd(1)
    })
   end
  end
 end
 
 for y=0,63 do
  for x=0,127 do
   if mget(x, y) == 23 then
    add(falling_spikes, {
     x = x * 8 + 4,
     y = y * 8,
     original_y = y * 8,
     vy = 0,
     falling = false
    })
    mset(x, y, 0)
   end
  end
 end
end


--------------------------------------------------------------
-- detectar algas en el mapa
for y=0,63 do
  for x=0,127 do
    if mget(x, y) == 64 then
      add(seaweeds, {
        x = x * 8 + 4,
        top_y = y * 8 - 40,         
        bottom_y = y * 8 + 8,       -- empieza 1 tile MÁS ABAJO
        max_segments = 3 + flr(rnd(5))
      })
      
      mset(x, y, 0)
    end
  end
end


-- === detectar torretas en el mapa ===
for y=0,63 do
 for x=0,127 do
  if mget(x,y) == 54 then
   local key = x..","..y
   local def = turret_defs[key]

add(turrets,{
 x = x*8 + 4,
 y = y*8 + 4,
 range = def and def.range or 100,
 fire_rate = def and def.fire_rate or 60,
 proj_speed = def and def.proj_speed or 3,
 cooldown = 0,
 sound_cooldown = 0,
 sound_range = 50
})


   -- limpiar el mapa
   mset(x,y,0)
  end
 end
end


function _update()
 if btn(0) then
  sub_vx-=accel
  sub_flip=true
 end
 if btn(1) then
  sub_vx+=accel
  sub_flip=false
 end
 if btn(2) then
  sub_vy-=accel
 end
 if btn(3) then
  sub_vy+=accel
 end

 sub_vx=mid(-max_speed,sub_vx,max_speed)
 sub_vy=mid(-max_speed,sub_vy,max_speed)
 sub_vx*=friction
 sub_vy*=friction

 local old_sub_x = sub_x
 local old_sub_y = sub_y

 sub_x += sub_vx
 sub_y += sub_vy

 if is_solid(sub_x - 6, sub_y - 3) or
    is_solid(sub_x + 5, sub_y - 3) or
    is_solid(sub_x - 6, sub_y + 2) or
    is_solid(sub_x + 5, sub_y + 2) then
  sub_x = old_sub_x
  sub_y = old_sub_y
  sub_vx = 0
  sub_vy = 0
 end
 
 if not is_dead and death_timer <= 0 then
  if is_damage_zone(sub_x - 6, sub_y - 3) or
     is_damage_zone(sub_x + 5, sub_y - 3) or
     is_damage_zone(sub_x - 6, sub_y + 2) or
     is_damage_zone(sub_x + 5, sub_y + 2) or
     is_damage_zone(sub_x, sub_y - 3) or
     is_damage_zone(sub_x, sub_y + 2) then
   is_dead = true
   death_timer = 60
   death_shake = 10
   death_sound_played = true
   sfx(-1, 0)
   sfx(-1, 1)
   sfx(7, 2)
  end
 end
 
 spike_collision_detected = false
 
 local target_x = sub_x
 local target_y = sub_y + sphere_offset_y
 local dx = target_x - sphere_x
 local dy = target_y - sphere_y
 
 local sphere_accel = 0.15
 local sphere_friction = 0.88
 
 sphere_vx += dx * sphere_accel
 sphere_vy += dy * sphere_accel
 sphere_vx *= sphere_friction
 sphere_vy *= sphere_friction
 
 local sphere_max_speed = 1.2
 if abs(sphere_vx) > sphere_max_speed then
  sphere_vx = sgn(sphere_vx) * sphere_max_speed
 end
 if abs(sphere_vy) > sphere_max_speed then
  sphere_vy = sgn(sphere_vy) * sphere_max_speed
 end
 
 local old_sphere_x = sphere_x
 local old_sphere_y = sphere_y
 
 local function check_spike_collision()
  for angle=0,1,0.125 do
   local check_x = sphere_x + cos(angle) * sphere_radius
   local check_y = sphere_y + sin(angle) * sphere_radius
   if is_spike(check_x, check_y) then
    return true
   end
  end
  if is_spike(sphere_x, sphere_y) then
   return true
  end
  return false
 end
 
 local new_x = sphere_x + sphere_vx
 local collision_x = false
 if not (is_solid(new_x - sphere_radius, sphere_y - sphere_radius) or
         is_solid(new_x + sphere_radius, sphere_y - sphere_radius) or
         is_solid(new_x - sphere_radius, sphere_y + sphere_radius) or
         is_solid(new_x + sphere_radius, sphere_y + sphere_radius)) then
  sphere_x = new_x
 else
  sphere_vx = 0
  collision_x = true
 end
 
 local new_y = sphere_y + sphere_vy
 local collision_y = false
 if not (is_solid(sphere_x - sphere_radius, new_y - sphere_radius) or
         is_solid(sphere_x + sphere_radius, new_y - sphere_radius) or
         is_solid(sphere_x - sphere_radius, new_y + sphere_radius) or
         is_solid(sphere_x + sphere_radius, new_y + sphere_radius)) then
  sphere_y = new_y
 else
  sphere_vy = 0
  collision_y = true
 end
 
 if not is_dead and death_timer <= 0 then
  local hit_spike = check_spike_collision()
  
  local hit_damage = false
  for angle=0,1,0.125 do
   local check_x = sphere_x + cos(angle) * sphere_radius
   local check_y = sphere_y + sin(angle) * sphere_radius
   if is_damage_zone(check_x, check_y) then
    hit_damage = true
    break
   end
  end
  if is_damage_zone(sphere_x, sphere_y) then
   hit_damage = true
  end
  
  if hit_spike or hit_damage then
   spike_collision_detected = true
   is_dead = true
   death_timer = 60
   death_shake = 10
   death_sound_played = true
   sfx(-1, 0)
   sfx(-1, 1)
   if hit_damage then
    sfx(7, 2)
   else
    sfx(2, 2)
   end
  end
 end
 
 local sphere_collision = collision_x or collision_y
 if sphere_collision and not sphere_last_collision then
  for i=1,3 do
   add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
  end
 end
 sphere_last_collision = sphere_collision
 
 -- ============================================
 -- SISTEMA DE PUZZLES
 -- ============================================
 for i=1,#puzzles do
  local puzzle = puzzles[i]
  
  for j=1,#puzzle.buttons do
   local btn_data = puzzle.buttons[j]
   
   if not buttons_state[i][j] then
    if is_button_pressed(sphere_x, sphere_y, btn_data) then
     buttons_state[i][j] = true
     -- cambiar sprite según tipo
     if btn_data.type == "floor" then
      mset(btn_data.x, btn_data.y, 22)
     elseif btn_data.type == "ceiling" then
      mset(btn_data.x, btn_data.y, 24)
     elseif btn_data.type == "wall_left" then
      mset(btn_data.x, btn_data.y, 55)
     elseif btn_data.type == "wall_right" then
      mset(btn_data.x, btn_data.y, 56)
     end
     sfx(3, 3)
    end
   end
  end
  
  local all_pressed = true
  for j=1,#puzzle.buttons do
   if not buttons_state[i][j] then
    all_pressed = false
    break
   end
  end
  
  -- abrir puerta según su tipo
  if all_pressed and not doors_open[i] then
   doors_open[i] = true
   local door = puzzle.door
   local door_type = door.type or "vertical"

   if door_type == "vertical" then
    -- puerta vertical: ocupa (x,y) y (x, y+1)
    mset(door.x, door.y, 37)
    mset(door.x, door.y + 1, 52)
    fset(mget(door.x, door.y), 0, false)
    fset(mget(door.x, door.y + 1), 0, false)
   elseif door_type == "horizontal" then
    -- puerta horizontal: ocupa (x,y) y (x+1, y)
    mset(door.x, door.y, 57)
    mset(door.x + 1, door.y, 58)
    fset(mget(door.x, door.y), 0, false)
    fset(mget(door.x + 1, door.y), 0, false)
   end
   sfx(5, 3)
  end
 end
 
 for i=1,#checkpoints do
  local cp = checkpoints[i]
  local sphere_cell_x = flr(sphere_x / 8)
  local sphere_cell_y = flr(sphere_y / 8)
  
  if sphere_cell_x == cp.x and sphere_cell_y == cp.y and not checkpoints_activated[i] then
   checkpoints_activated[i] = true
   current_checkpoint = i
   checkpoint_x = cp.x * 8 + 4
   checkpoint_y = cp.y * 8 - 8
   checkpoint_sphere_dist = cp.sphere_dist
   sfx(6, 3)
  end
 end
 
 for spike in all(falling_spikes) do
  if not spike.falling then
   local horizontal_dist = abs(sub_x - spike.x)
   if sub_y > spike.y and horizontal_dist < spike_trigger_range then
    spike.falling = true
    sfx(8, 3)
   end
   if not spike.falling then
   local horizontal_dist_sub = abs(sub_x - spike.x)
   local horizontal_dist_sph = abs(sphere_x - spike.x)
   if (sub_y > spike.y and horizontal_dist_sub < spike_trigger_range) or
      (sphere_y > spike.y and horizontal_dist_sph < spike_trigger_range) then
    spike.falling = true
    sfx(8, 3)
   end
  end
  end
  
  if spike.falling then
   spike.vy += spike_gravity
   if spike.vy > spike_max_fall_speed then
    spike.vy = spike_max_fall_speed
   end
   spike.y += spike.vy
   
   if not is_dead and death_timer <= 0 then
    local spike_left = spike.x - 4
    local spike_right = spike.x + 3
    local spike_top = spike.y
    local spike_bottom = spike.y + 7
    
    local sub_points = {
     {x = sub_x - 6, y = sub_y - 3},
     {x = sub_x + 5, y = sub_y - 3},
     {x = sub_x - 6, y = sub_y + 2},
     {x = sub_x + 5, y = sub_y + 2},
     {x = sub_x, y = sub_y - 3},
     {x = sub_x, y = sub_y + 2}
    }
    
    for p in all(sub_points) do
     if p.x >= spike_left and p.x <= spike_right and
        p.y >= spike_top and p.y <= spike_bottom then
      is_dead = true
      death_timer = 60
      death_shake = 10
      sfx(-1, 0)
      sfx(-1, 1)
      sfx(2, 2)
      break
     end
    end
   end
   
   if not is_dead and death_timer <= 0 then
    local spike_left = spike.x - 4
    local spike_right = spike.x + 3
    local spike_top = spike.y
    local spike_bottom = spike.y + 7
    
    if sphere_x + sphere_radius >= spike_left and
       sphere_x - sphere_radius <= spike_right and
       sphere_y + sphere_radius >= spike_top and
       sphere_y - sphere_radius <= spike_bottom then
     is_dead = true
     death_timer = 60
     death_shake = 10
     sfx(-1, 0)
     sfx(-1, 1)
     sfx(2, 2)
    end
   end
  end
 end
 
 for turret in all(turrets) do
  if turret.cooldown > 0 then
    turret.cooldown -= 1
  end

  if turret.sound_cooldown > 0 then
    turret.sound_cooldown -= 1
  end

  local dx = sphere_x - turret.x
  local dy = sphere_y - turret.y
  local dist = sqrt(dx*dx + dy*dy)

  if dist <= turret.range and turret.cooldown == 0 then
    local angle = atan2(dx, dy)
    add(projectiles, {
      x = turret.x,
      y = turret.y,
      vx = cos(angle) * turret.proj_speed,
      vy = sin(angle) * turret.proj_speed,
      max_dist = turret.range*1.2,
      traveled = 0
    })
    turret.cooldown = turret.fire_rate

    local cam_x = sub_x - 64
    local cam_y = sub_y - 20
    if turret.x >= cam_x and turret.x <= cam_x + 128 and
       turret.y >= cam_y and turret.y <= cam_y + 128 and
       turret.sound_cooldown == 0 then
      sfx(9, 3)
      turret.sound_cooldown = 10
    end
  end
end

for proj in all(projectiles) do
  proj.x += proj.vx
  proj.y += proj.vy
  proj.traveled += sqrt(proj.vx * proj.vx + proj.vy * proj.vy)
  
  if is_solid(proj.x, proj.y) then
   del(projectiles, proj)
  elseif proj.traveled > proj.max_dist then
   del(projectiles, proj)
  elseif not is_dead and death_timer <= 0 then
   local speed = sqrt(proj.vx * proj.vx + proj.vy * proj.vy)
   local px2 = proj.x + (proj.vx / speed) * proj_length
   local py2 = proj.y + (proj.vy / speed) * proj_length
   
   local dist_to_line = abs((py2-proj.y)*sphere_x - (px2-proj.x)*sphere_y + px2*proj.y - py2*proj.x) / 
                        sqrt((py2-proj.y)^2 + (px2-proj.x)^2)
   if dist_to_line < sphere_radius + 1 then
    local dot = (sphere_x - proj.x)*(px2 - proj.x) + (sphere_y - proj.y)*(py2 - proj.y)
    local len_sq = (px2 - proj.x)^2 + (py2 - proj.y)^2
    if dot >= 0 and dot <= len_sq then
     is_dead = true
     death_timer = 60
     death_shake = 10
     sfx(-1, 0)
     sfx(-1, 1)
     sfx(7, 2)
     del(projectiles, proj)
    end
   end
  end
 end
 
 if not is_dead then
  local sphere_can_move_down = not (is_solid(sphere_x - sphere_radius, sphere_y + sphere_radius + 1) or
                                     is_solid(sphere_x + sphere_radius, sphere_y + sphere_radius + 1))
  
  local sphere_can_move_up = not (is_solid(sphere_x - sphere_radius, sphere_y - sphere_radius - 1) or
                                   is_solid(sphere_x + sphere_radius, sphere_y - sphere_radius - 1))
  
  local sphere_touching_floor = not sphere_can_move_down
  local sphere_touching_ceiling = not sphere_can_move_up
  
  if sphere_bubble_timer > 0 then
   sphere_bubble_timer -= 1
  end
  
  if btn(4) and sphere_offset_y < sphere_offset_max then
   if sphere_can_move_down and not sphere_touching_floor then
    if sphere_bubble_timer <= 0 then
     for i=1,3 do
      add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
     end
     sphere_bubble_timer = 8
    end
    
    if not sfx_playing then
     sfx(0, 0)
     sfx_playing = true
    end
    sphere_offset_y += sphere_offset_speed
    if sphere_offset_y > sphere_offset_max then
     sphere_offset_y = sphere_offset_max
    end
   else
    if sfx_playing then
     sfx(-1, 0)
     sfx_playing = false
    end
   end
  else
   if sfx_playing then
    sfx(-1, 0)
    sfx_playing = false
   end
   if not btn(4) then
    sphere_bubble_timer = 0
   end
  end
  
  if btn(5) and sphere_offset_y > sphere_offset_min then
   if sphere_can_move_up and not sphere_touching_ceiling then
    if sphere_bubble_timer <= 0 then
     for i=1,3 do
      add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
     end
     sphere_bubble_timer = 8
    end
    
    if not sfx_in_playing then
     sfx(1, 1)
     sfx_in_playing = true
    end
    sphere_offset_y -= sphere_offset_speed
    if sphere_offset_y < sphere_offset_min then
     sphere_offset_y = sphere_offset_min
    end
   else
    if sfx_in_playing then
     sfx(-1, 1)
     sfx_in_playing = false
    end
   end
  else
   if sfx_in_playing then
    sfx(-1, 1)
    sfx_in_playing = false
   end
   if not btn(5) then
    sphere_bubble_timer = 0
   end
  end
 else
  if sfx_playing then
   sfx(-1, 0)
   sfx_playing = false
  end
  if sfx_in_playing then
   sfx(-1, 1)
   sfx_in_playing = false
  end
 end
 
 local bubble_x=sub_flip and sub_x+8 or sub_x-8
 if rnd(1)<0.3 then
  add_particle(bubble_x,sub_y+rnd(4)-2)
 end
 
 for p in all(particles) do
  p.y-=0.5+rnd(0.5)
  p.x+=rnd(0.6)-0.3
  p.life-=1
  if p.life<=0 then
   del(particles,p)
  end
 end
 
 if death_timer > 0 then
  death_timer -= 1
  
  if death_shake > 0 then
   death_shake -= 1
  end
  
  if death_timer == 40 and not transition_active then
   transition_active = true
   transition_timer = 40
   sfx(4, 2)
   for i=1,100 do
    add(transition_bubbles, {
     x = rnd(128),
     y = 128 + rnd(80),
     vy = -1.5 - rnd(2),
     size = 3 + rnd(5),
     life = 70
    })
   end
  end
  
  if death_timer == 0 then
   sub_x = checkpoint_x
   sub_y = checkpoint_y
   sub_vx = 0
   sub_vy = 0
   sphere_x = checkpoint_x
   sphere_y = checkpoint_y + checkpoint_sphere_dist
   sphere_vx = 0
   sphere_vy = 0
   sphere_offset_y = checkpoint_sphere_dist
   
   is_dead = false
   death_sound_played = false
   spike_collision_detected = false
   transition_active = false
   transition_bubbles = {}
   
   for spike in all(falling_spikes) do
    spike.y = spike.original_y
    spike.vy = 0
    spike.falling = false
   end
   
   projectiles = {}
   for turret in all(turrets) do
    turret.cooldown = 0
   end
   
   -- RESETEAR PUZZLES (botones y puertas)
   for i=1,#puzzles do
    local puzzle = puzzles[i]
    
    for j=1,#puzzle.buttons do
     buttons_state[i][j] = false
     local btn = puzzle.buttons[j]
     if btn.type == "floor" then
      mset(btn.x, btn.y, 6)
     elseif btn.type == "ceiling" then
      mset(btn.x, btn.y, 8)
     elseif btn.type == "wall_left" then
      mset(btn.x, btn.y, 39)
     elseif btn.type == "wall_right" then
      mset(btn.x, btn.y, 40)
     end
    end
    
    if doors_open[i] then
     doors_open[i] = false
     local door = puzzle.door
     local door_type = door.type or "vertical"

     if door_type == "vertical" then
      mset(door.x, door.y, 20)
      mset(door.x, door.y + 1, 36)
      fset(mget(door.x, door.y), 0, true)
      fset(mget(door.x, door.y + 1), 0, true)
     elseif door_type == "horizontal" then
      mset(door.x, door.y, 35)
      mset(door.x + 1, door.y, 51)
      fset(mget(door.x, door.y), 0, true)
      fset(mget(door.x + 1, door.y), 0, true)
     end
    end
   end
  end
 end
 
 if transition_active then
  transition_timer -= 1
  for b in all(transition_bubbles) do
   b.y += b.vy
   b.x += sin(time() * 2 + b.y * 0.1) * 0.5
   b.life -= 1
   if b.life <= 0 or b.y < -10 then
    del(transition_bubbles, b)
   end
  end
 end
end

function is_solid(x, y)
 local celda_x = flr(x / 8)
 local celda_y = flr(y / 8)
 local sprite_num = mget(celda_x, celda_y)
 
 if fget(sprite_num, 3) then
  local pixel_x = flr(x) % 8
  local pixel_y = flr(y) % 8
  local sprite_x = (sprite_num % 16) * 8
  local sprite_y = flr(sprite_num / 16) * 8
  local pixel_color = sget(sprite_x + pixel_x, sprite_y + pixel_y)
  return pixel_color != 0
 end
 
 return fget(sprite_num, 0)
end

function is_spike(x, y)
 local celda_x = flr(x / 8)
 local celda_y = flr(y / 8)
 local sprite_num = mget(celda_x, celda_y)
 
 if not fget(sprite_num, 3) then
  return false
 end
 
 local pixel_x = flr(x) % 8
 local pixel_y = flr(y) % 8
 
 if sprite_num == 5 then
  if pixel_y == 0 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 elseif sprite_num == 7 then
  if pixel_y == 7 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 elseif sprite_num == 17 then
  if pixel_x == 7 and (pixel_y >= 1 and pixel_y <= 6) then
   return true
  end
 elseif sprite_num == 18 then
  if pixel_x == 0 and (pixel_y >= 1 and pixel_y <= 6) then
   return true
  end
 end
 
 return false
end

function is_damage_zone(x, y)
 local celda_x = flr(x / 8)
 local celda_y = flr(y / 8)
 local sprite_num = mget(celda_x, celda_y)
 return fget(sprite_num, 1)
end

-- ============================================
-- DETECCIÓN DE BOTONES
-- ============================================
-- floor:      esfera entra por ABAJO → hitbox en los píxeles inferiores del tile (y >= 5)
-- ceiling:    esfera entra por ARRIBA → hitbox en los píxeles superiores del tile (y <= 2)
-- wall_left:  esfera entra por la DERECHA → hitbox en los píxeles derechos del tile (x >= 5)
-- wall_right: esfera entra por la IZQUIERDA → hitbox en los píxeles izquierdos del tile (x <= 2)
function is_button_pressed(sphere_x, sphere_y, button)
 local sphere_cell_x = flr(sphere_x / 8)
 local sphere_cell_y = flr(sphere_y / 8)
 
 if sphere_cell_x != button.x or sphere_cell_y != button.y then
  return false
 end
 
 local pixel_x = flr(sphere_x) % 8
 local pixel_y = flr(sphere_y) % 8
 
 if button.type == "floor" then
  -- botón en suelo: la esfera viene de abajo, toca los píxeles superiores
  if pixel_y <= 2 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 elseif button.type == "ceiling" then
  -- botón en techo: la esfera viene de arriba, toca los píxeles inferiores
  if pixel_y >= 5 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 elseif button.type == "wall_left" then
  -- botón en pared izquierda: la esfera viene de la derecha, toca los píxeles derechos
  if pixel_x >= 5 and (pixel_y >= 1 and pixel_y <= 6) then
   return true
  end
 elseif button.type == "wall_right" then
  -- botón en pared derecha: la esfera viene de la izquierda, toca los píxeles izquierdos
  if pixel_x <= 2 and (pixel_y >= 1 and pixel_y <= 6) then
   return true
  end
 end
 
 return false
end

function _draw()
 cls(0)
 
 
 local shake_x = 0
 local shake_y = 0
 if death_shake > 0 then
  shake_x = rnd(4) - 2
  shake_y = rnd(4) - 2
 end
 
 camera(sub_x - 64 + shake_x, sub_y - 20 + shake_y)

-----------------------------------------------------------
-- dibujar algas con vaivén
for seaweed in all(seaweeds) do
  local x, y = seaweed.x, seaweed.bottom_y  -- empieza desde ABAJO (donde pusiste el sprite)
  local segments = 0
  
  -- dibujar segmentos desde abajo hacia arriba
  while y > seaweed.top_y and segments < seaweed.max_segments do
    local angle = sin(y / 50 + time() * 0.2) * 0.05 + 0.25
    draw_seaweed_segment(x, y, angle)
    
    -- siguiente segmento HACIA ARRIBA
    x += 8 * cos(angle)
    y -= 8  -- AQUÍ: resta para ir hacia arriba
    segments += 1
  end
end

 map(0,0,0,0,128,64,0)

 for i=1,#checkpoints do
  if checkpoints_activated[i] then
   local cp = checkpoints[i]
   pal(8, 11)
   spr(49, cp.x * 8, cp.y * 8)
   pal()
  end
 end
 
 for m in all(mines) do
  local float_offset = sin(time() * 0.5 + m.offset) * 1
  spr(53, m.x * 8, m.y * 8 + float_offset)
 end
 
 for spike in all(falling_spikes) do
  spr(23, spike.x - 4, spike.y)
 end
 
 for turret in all(turrets) do
  spr(54, turret.x - 4, turret.y - 4)
 end
 
 for proj in all(projectiles) do
  local speed = sqrt(proj.vx * proj.vx + proj.vy * proj.vy)
  local px2 = proj.x + (proj.vx / speed) * proj_length
  local py2 = proj.y + (proj.vy / speed) * proj_length
  line(proj.x, proj.y, px2, py2, 8)
 end

 local sphere_color1 = 9
 local sphere_color2 = 10
 
 if is_dead then
  if death_timer % 4 < 2 then
   sphere_color1 = 8
   sphere_color2 = 2
  end
 end
 
 circfill(sphere_x, sphere_y, sphere_radius, sphere_color1)
 circfill(sphere_x, sphere_y, sphere_radius-1, sphere_color2)
 if not is_dead or death_timer % 4 < 2 then
  pset(sphere_x-1, sphere_y-1, 7)
 end

 map(0,0,0,0,128,64,4)
 
 for p in all(particles) do
  local c=1
  if p.life>15 then c=12 end
  circfill(p.x,p.y,0.1,c)
 end
 
 local sub_color_swap = false
 if is_dead and death_timer % 4 < 2 then
  pal(10, 8)
  pal(9, 2)
  sub_color_swap = true
 end
 
 if sub_flip then
  spr(2,sub_x-8,sub_y-4,1,1,true)
  spr(1,sub_x,sub_y-4,1,1,true)
 else
  spr(1,sub_x-8,sub_y-4)
  spr(2,sub_x,sub_y-4)
 end
 
 if sub_color_swap then
  pal()
 end
 
 camera()
 
 if transition_active then
  for b in all(transition_bubbles) do
   local alpha = min(b.life / 20, 1)
   if alpha > 0 then
    circfill(b.x, b.y, b.size, 12)
    circfill(b.x, b.y, b.size - 1, 7)
    pset(b.x - b.size/2, b.y - b.size/2, 7)
   end
  end
 end
end

function add_particle(x,y)
 add(particles,{
  x=x,
  y=y,
  life=30+rnd(20)
 })
end

function draw_seaweed_segment(x, y, angle)
  -- versión simple: usar spr con flip según ángulo
  local flip = cos(angle) < 0
  spr(64, x - 4, y - 8, 1, 1, flip)
end