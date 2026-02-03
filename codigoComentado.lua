-- ============================================
-- variables del juego - submarine with sphere
-- ============================================

-- === submarino ===
sub_x = 600--640--345 --32
sub_y = 60 --40 --30 --16
sub_vx = 0
sub_vy = 0
sub_flip = false

-- === física del submarino ===
accel = 1
max_speed = 1.5
friction = 0.80

-- === esfera que sigue al submarino ===
sphere_offset_y = 4  -- distancia vertical debajo del submarino
sphere_x = 0
sphere_y = 0
sphere_vx = 0  -- velocidad horizontal de la esfera
sphere_vy = 0  -- velocidad vertical de la esfera
sphere_radius = 3

-- === control de distancia de la esfera ===
sphere_offset_speed = 1
sphere_offset_min = 10
sphere_offset_max = 100

-- === control de burbujas de la esfera ===
sphere_bubble_timer = 0
sphere_last_collision = false

-- === detección de colisión con pinchos ===
spike_collision_detected = false

-- === sistema de checkpoint y muerte ===
checkpoint_x = 32
checkpoint_y = 16
checkpoint_sphere_dist = 80  -- distancia inicial de la esfera
is_dead = false
death_timer = 0
death_shake = 0 
death_sound_played = false  -- bandera para evitar sonido repetido
transition_bubbles = {}
transition_active = false
transition_timer = 0

-- === sistema de checkpoints (banderas) ===
checkpoints = {
 {x=4, y=2, sphere_dist=10},    -- primer checkpoint, esfera a 10 píxeles
 {x=32, y=5, sphere_dist=5},   -- segundo checkpoint, esfera a 15 píxeles
 {x=47, y=5, sphere_dist=5},
 {x=76, y=7, sphere_dist=5},

 -- añade más checkpoints con su distancia personalizada
 -- ejemplo: {x=50, y=10, sphere_dist=5}
}
current_checkpoint = 0  -- empieza en 0 (sin checkpoint activado)
checkpoints_activated = {}  -- tabla para saber qué checkpoints están activados

-- === sistema de minas ===
mines = {}  -- tabla para almacenar posiciones de minas y su animación

-- === sistema de pinchos cayentes ===
falling_spikes = {}  -- tabla para pinchos que caen del techo
spike_trigger_range =7  -- distancia horizontal para activar caída (en píxeles)
spike_gravity = 0.3  -- gravedad de los pinchos
spike_max_fall_speed = 8  -- velocidad máxima de caída

-- === sistema de puzzles (botones y compuertas) ===
puzzles = {
 -- Puzzle 1: dos botones, una compuerta
 {
  buttons = {
   {x=15, y=14, type="floor"},   -- botón suelo
   {x=15, y=9, type="ceiling"}   -- botón techo
  },
  door = {x=20, y=13}  -- posición de la compuerta superior (la inferior está en y+1)
 },
 
  {
  buttons = {
   {x=25, y=8, type="floor"},   -- botón suelo
  },
  door = {x=19, y=6}  -- posición de la compuerta superior (la inferior está en y+1)
 },
 {
  buttons = {
   {x=42, y=14, type="floor"},   -- botón suelo
   {x=43, y=14, type="floor"} 
  },
  door = {x=45, y=4}  -- posición de la compuerta superior (la inferior está en y+1)
 },
  {
  buttons = {
   {x=63, y=13, type="floor"},   -- botón suelo
   {x=64, y=10, type="ceiling"} 
  },
  door = {x=68, y=5}  -- posición de la compuerta superior (la inferior está en y+1)
 }
}

-- estado de botones y puertas
buttons_state = {}  -- tabla para saber qué botones están pulsados
doors_open = {}     -- tabla para saber qué puertas están abiertas

-- === partículas (burbujas) ===
particles = {}

-- === control de sonido ===
sfx_playing = false
sfx_in_playing = false

-- ============================================
-- main game code
-- ============================================

function _init()

  
 -- inicializar posición de la esfera
 sphere_x = sub_x
 sphere_y = sub_y + sphere_offset_y
 
 -- inicializar estado de puzzles
 for i=1,#puzzles do
  buttons_state[i] = {}
  for j=1,#puzzles[i].buttons do
   buttons_state[i][j] = false
  end
  doors_open[i] = false
 end
 
 -- inicializar checkpoints
 for i=1,#checkpoints do
  checkpoints_activated[i] = false
 end
 
 
 -- escanear el mapa para encontrar todas las minas (sprite 53)
 for y=0,63 do
  for x=0,127 do
   if mget(x, y) == 53 then
    add(mines, {
     x = x,
     y = y,
     offset = rnd(1)  -- offset aleatorio para que no floten todas igual
    })
   end
  end
 end
 
 -- escanear el mapa para encontrar pinchos cayentes (sprite 23)
 for y=0,63 do
  for x=0,127 do
   if mget(x, y) == 23 then
    add(falling_spikes, {
     x = x * 8 + 4,  -- centro del tile
     y = y * 8,
     original_y = y * 8,
     vy = 0,
     falling = false
    })
    mset(x, y, 0)  -- quitar del mapa
   end
  end
 end
end

function _update()
 -- input horizontal
 if btn(0) then -- left
  sub_vx-=accel
  sub_flip=true
 end
 if btn(1) then -- right
  sub_vx+=accel
  sub_flip=false
 end
 
 -- input vertical 
 if btn(2) then -- up
  sub_vy-=accel
 end
 if btn(3) then -- down
  sub_vy+=accel
 end

 -- limit max speed
 sub_vx=mid(-max_speed,sub_vx,max_speed)
 sub_vy=mid(-max_speed,sub_vy,max_speed)
 
 -- apply friction
 sub_vx*=friction
 sub_vy*=friction

 -- guardar posición anterior del submarino
 local old_sub_x = sub_x
 local old_sub_y = sub_y

 -- intentar mover el submarino
 sub_x += sub_vx
 sub_y += sub_vy

 -- verificar colisión del submarino con hitbox más pequeña (12x6 en vez de 16x16)
 if is_solid(sub_x - 6, sub_y - 3) or
    is_solid(sub_x + 5, sub_y - 3) or
    is_solid(sub_x - 6, sub_y + 2) or
    is_solid(sub_x + 5, sub_y + 2) then
  
  -- hay colisión, volver a la posición anterior
  sub_x = old_sub_x
  sub_y = old_sub_y
  
  -- detener el movimiento
  sub_vx = 0
  sub_vy = 0
 end
 
-- verificar si el submarino toca una mina/zona de daño
 if not is_dead and death_timer <= 0 then
  -- verificar esquinas + puntos centrales (6 puntos total)
  if is_damage_zone(sub_x - 6, sub_y - 3) or  -- esquina superior izq
     is_damage_zone(sub_x + 5, sub_y - 3) or  -- esquina superior der
     is_damage_zone(sub_x - 6, sub_y + 2) or  -- esquina inferior izq
     is_damage_zone(sub_x + 5, sub_y + 2) or  -- esquina inferior der
     is_damage_zone(sub_x, sub_y - 3) or      -- centro superior
     is_damage_zone(sub_x, sub_y + 2) then    -- centro inferior
   is_dead = true
   death_timer = 60
   death_shake = 10
   death_sound_played = true
   
   sfx(-1, 0)
   sfx(-1, 1)
   sfx(7, 2)  -- sonido de explosión en canal 2
  end
 end
 
 -- ============================================
 -- MOVER LA ESFERA PARALELA AL SUBMARINO
 -- ============================================
 
 -- resetear detección de pinchos
 spike_collision_detected = false
 
 -- calcular posición objetivo de la esfera (debajo del submarino)
 local target_x = sub_x
 local target_y = sub_y + sphere_offset_y
 
 -- calcular dirección hacia el objetivo
 local dx = target_x - sphere_x
 local dy = target_y - sphere_y
 
 -- aplicar aceleración suave hacia el objetivo (física de agua)
 local sphere_accel = 0.15  -- aceleración muy suave
 local sphere_friction = 0.88  -- fricción del agua
 
 sphere_vx += dx * sphere_accel
 sphere_vy += dy * sphere_accel
 
 -- aplicar fricción del agua
 sphere_vx *= sphere_friction
 sphere_vy *= sphere_friction
 
 -- limitar velocidad máxima
 local sphere_max_speed = 1.2
 if abs(sphere_vx) > sphere_max_speed then
  sphere_vx = sgn(sphere_vx) * sphere_max_speed
 end
 if abs(sphere_vy) > sphere_max_speed then
  sphere_vy = sgn(sphere_vy) * sphere_max_speed
 end
 
 -- guardar posición anterior
 local old_sphere_x = sphere_x
 local old_sphere_y = sphere_y
 
 -- VERIFICACIÓN DE PINCHOS - función auxiliar
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
 
 -- intentar mover en X
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
 
 -- intentar mover en Y
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
 
 -- ÚNICA verificación de pinchos Y MINAS DESPUÉS de todo el movimiento
 if not is_dead and death_timer <= 0 then
  -- verificar pinchos
  local hit_spike = check_spike_collision()
  
  -- verificar minas/zonas de daño
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
  
  -- si toca pincho o mina, morir
  if hit_spike or hit_damage then
   spike_collision_detected = true
   is_dead = true
   death_timer = 60
   death_shake = 10
   death_sound_played = true
   
   -- DETENER canales específicos de Z y X
   sfx(-1, 0)  -- detener canal 0 (Z)
   sfx(-1, 1)  -- detener canal 1 (X)
   
   -- sonido diferente según qué tocó
   if hit_damage then
    sfx(7, 2)  -- explosión de mina
   else
    sfx(2, 2)  -- pincho normal
   end
  end
 end
 
 -- detectar colisión y generar burbujas
 local sphere_collision = collision_x or collision_y
 if sphere_collision and not sphere_last_collision then
  -- generar burbujas al chocar
  for i=1,3 do
   add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
  end
 end
 sphere_last_collision = sphere_collision
 
 -- ============================================
 -- SISTEMA DE PUZZLES (BOTONES Y COMPUERTAS)
 -- ============================================
 
 -- verificar botones tocados por la esfera
 for i=1,#puzzles do
  local puzzle = puzzles[i]
  
  for j=1,#puzzle.buttons do
   local btn_data = puzzle.buttons[j]
   
   -- si el botón ya está pulsado, saltar
   if not buttons_state[i][j] then
    -- verificar si la esfera toca el botón
    if is_button_pressed(sphere_x, sphere_y, btn_data) then
     buttons_state[i][j] = true
     -- cambiar sprite a pulsado
     if btn_data.type == "floor" then
      mset(btn_data.x, btn_data.y, 22)  -- botón suelo pulsado
     elseif btn_data.type == "ceiling" then
      mset(btn_data.x, btn_data.y, 24)  -- botón techo pulsado
     end
     sfx(3, 3)  -- sonido de botón en canal 3
    end
   end
  end
  
  -- verificar si todos los botones del puzzle están pulsados
  local all_pressed = true
  for j=1,#puzzle.buttons do
   if not buttons_state[i][j] then
    all_pressed = false
    break
   end
  end
  
  -- si todos están pulsados y la puerta no está abierta, abrirla
  if all_pressed and not doors_open[i] then
   doors_open[i] = true
   local door_x = puzzle.door.x
   local door_y = puzzle.door.y
   
   -- cambiar sprites a versión abierta
   mset(door_x, door_y, 37)      -- compuerta superior abierta
   mset(door_x, door_y + 1, 52)  -- compuerta inferior abierta
   
   -- quitar flag de sólido
   fset(mget(door_x, door_y), 0, false)
   fset(mget(door_x, door_y + 1), 0, false)
   
   sfx(5, 3)  -- sonido de puerta en canal 3
  end
 end
 
 -- ============================================
 -- SISTEMA DE CHECKPOINTS (BANDERAS)
 -- ============================================
 
 -- verificar si la esfera toca un checkpoint
 for i=1,#checkpoints do
  local cp = checkpoints[i]
  local sphere_cell_x = flr(sphere_x / 8)
  local sphere_cell_y = flr(sphere_y / 8)
  
  -- si la esfera toca esta bandera y no está activada aún
  if sphere_cell_x == cp.x and sphere_cell_y == cp.y and not checkpoints_activated[i] then
   checkpoints_activated[i] = true
   current_checkpoint = i
   -- actualizar coordenadas del checkpoint
   -- submarino aparece ENCIMA de la bandera
   checkpoint_x = cp.x * 8 + 4  -- centrado en la celda
   checkpoint_y = cp.y * 8 - 8  -- 8 píxeles arriba de la bandera
   checkpoint_sphere_dist = cp.sphere_dist  -- guardar la distancia de la esfera
   sfx(6, 3)  -- sonido de checkpoint activado
  end
 end
 
 -- ============================================
 -- SISTEMA DE PINCHOS CAYENTES
 -- ============================================
 
 -- actualizar pinchos cayentes
 for spike in all(falling_spikes) do
  -- detectar si el submarino pasa cerca horizontalmente
  if not spike.falling then
   local horizontal_dist = abs(sub_x - spike.x)
   -- si el submarino está debajo y cerca horizontalmente
   if sub_y > spike.y and horizontal_dist < spike_trigger_range then
    spike.falling = true
    sfx(8, 3)  -- sonido de pincho cayendo (opcional)
   end
  end
  
  -- aplicar física de caída
  if spike.falling then
   spike.vy += spike_gravity
   if spike.vy > spike_max_fall_speed then
    spike.vy = spike_max_fall_speed
   end
   spike.y += spike.vy
   
   -- verificar colisión con submarino (6 puntos)
   if not is_dead and death_timer <= 0 then
    local spike_left = spike.x - 4
    local spike_right = spike.x + 3
    local spike_top = spike.y
    local spike_bottom = spike.y + 7
    
    -- puntos del submarino
    local sub_points = {
     {x = sub_x - 6, y = sub_y - 3},  -- esquina sup izq
     {x = sub_x + 5, y = sub_y - 3},  -- esquina sup der
     {x = sub_x - 6, y = sub_y + 2},  -- esquina inf izq
     {x = sub_x + 5, y = sub_y + 2},  -- esquina inf der
     {x = sub_x, y = sub_y - 3},      -- centro superior
     {x = sub_x, y = sub_y + 2}       -- centro inferior
    }
    
    for p in all(sub_points) do
     if p.x >= spike_left and p.x <= spike_right and
        p.y >= spike_top and p.y <= spike_bottom then
      -- MUERTE POR PINCHO CAYENTE
      is_dead = true
      death_timer = 60
      death_shake = 10
      sfx(-1, 0)
      sfx(-1, 1)
      sfx(2, 2)  -- sonido de muerte
      break
     end
    end
   end
   
   -- verificar colisión con esfera
   if not is_dead and death_timer <= 0 then
    local spike_left = spike.x - 4
    local spike_right = spike.x + 3
    local spike_top = spike.y
    local spike_bottom = spike.y + 7
    
    if sphere_x + sphere_radius >= spike_left and
       sphere_x - sphere_radius <= spike_right and
       sphere_y + sphere_radius >= spike_top and
       sphere_y - sphere_radius <= spike_bottom then
     -- MUERTE POR PINCHO CAYENTE
     is_dead = true
     death_timer = 60
     death_shake = 10
     sfx(-1, 0)
     sfx(-1, 1)
     sfx(2, 2)  -- sonido de muerte
    end
   end
  end
 end
 
 -- ============================================
 -- CONTROL DE DISTANCIA DE LA ESFERA
 -- ============================================
 
 -- NO permitir controles si está muerto
 if not is_dead then
  -- verificar si la esfera puede moverse verticalmente
  local sphere_can_move_down = not (is_solid(sphere_x - sphere_radius, sphere_y + sphere_radius + 1) or
                                     is_solid(sphere_x + sphere_radius, sphere_y + sphere_radius + 1))
  
  local sphere_can_move_up = not (is_solid(sphere_x - sphere_radius, sphere_y - sphere_radius - 1) or
                                   is_solid(sphere_x + sphere_radius, sphere_y - sphere_radius - 1))
  
  -- verificar si la esfera está actualmente bloqueada
  local sphere_touching_floor = not sphere_can_move_down
  local sphere_touching_ceiling = not sphere_can_move_up
  
  -- decrementar timer de burbujas
  if sphere_bubble_timer > 0 then
   sphere_bubble_timer -= 1
  end
  
  -- control distancia esfera - alejar (Z)
  -- solo si puede bajar Y no está tocando el suelo
  if btn(4) and sphere_offset_y < sphere_offset_max then
   if sphere_can_move_down and not sphere_touching_floor then
    -- generar burbujas solo una vez al empezar a bajar
    if sphere_bubble_timer <= 0 then
     for i=1,3 do
      add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
     end
     sphere_bubble_timer = 8  -- cooldown
    end
    
    if not sfx_playing then
     sfx(0, 0)  -- canal 0
     sfx_playing = true
    end
    sphere_offset_y += sphere_offset_speed
    if sphere_offset_y > sphere_offset_max then
     sphere_offset_y = sphere_offset_max
    end
   else
    if sfx_playing then
     sfx(-1, 0)  -- ESPECIFICAR CANAL
     sfx_playing = false
    end
   end
  else
   if sfx_playing then
    sfx(-1, 0)  -- ESPECIFICAR CANAL
    sfx_playing = false
   end
   -- resetear timer si no se presiona el botón
   if not btn(4) then
    sphere_bubble_timer = 0
   end
  end
  
  -- control distancia esfera - acercar (X)
  -- solo si puede subir Y no está tocando el techo
  if btn(5) and sphere_offset_y > sphere_offset_min then
   if sphere_can_move_up and not sphere_touching_ceiling then
    -- generar burbujas solo una vez al empezar a subir
    if sphere_bubble_timer <= 0 then
     for i=1,3 do
      add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
     end
     sphere_bubble_timer = 8  -- cooldown
    end
    
    if not sfx_in_playing then
     sfx(1, 1)  -- canal 1
     sfx_in_playing = true
    end
    sphere_offset_y -= sphere_offset_speed
    if sphere_offset_y < sphere_offset_min then
     sphere_offset_y = sphere_offset_min
    end
   else
    if sfx_in_playing then
     sfx(-1, 1)  -- ESPECIFICAR CANAL
     sfx_in_playing = false
    end
   end
  else
   if sfx_in_playing then
    sfx(-1, 1)  -- ESPECIFICAR CANAL
    sfx_in_playing = false
   end
   -- resetear timer si no se presiona el botón
   if not btn(5) then
    sphere_bubble_timer = 0
   end
  end
 else
  -- si está muerto, detener sonidos de control en sus canales específicos
  if sfx_playing then
   sfx(-1, 0)  -- detener canal 0
   sfx_playing = false
  end
  if sfx_in_playing then
   sfx(-1, 1)  -- detener canal 1
   sfx_in_playing = false
  end
 end
 
 -- create bubbles
 local bubble_x=sub_flip and sub_x+8 or sub_x-8
 if rnd(1)<0.3 then
  add_particle(bubble_x,sub_y+rnd(4)-2)
 end
 
 -- update particles
 for p in all(particles) do
  p.y-=0.5+rnd(0.5)
  p.x+=rnd(0.6)-0.3
  p.life-=1
  if p.life<=0 then
   del(particles,p)
  end
 end
 
 -- ============================================
 -- GESTIÓN DE MUERTE Y RESPAWN
 -- ============================================
 
 if death_timer > 0 then
  death_timer -= 1
  
  -- decrementar temblor
  if death_shake > 0 then
   death_shake -= 1
  end
  
  -- iniciar transición de burbujas
  if death_timer == 40 and not transition_active then
   transition_active = true
   transition_timer = 40
   -- REPRODUCIR EN CANAL DE SFX, NO EN CANAL DE MÚSICA
   sfx(4, 2)  -- canal 2 en vez de -2
   -- crear MUCHÍSIMAS burbujas grandes para la transición
   for i=1,100 do
    add(transition_bubbles, {
     x = rnd(128),
     y = 128 + rnd(80),  -- más rango de aparición
     vy = -1.5 - rnd(2),  -- más rápidas
     size = 3 + rnd(5),  -- más grandes
     life = 70
    })
   end
  end
  
  -- respawn cuando termine el timer
  if death_timer == 0 then
   -- resetear posición al checkpoint
   sub_x = checkpoint_x
   sub_y = checkpoint_y
   sub_vx = 0
   sub_vy = 0
   -- ESFERA aparece a la distancia configurada del checkpoint
   sphere_x = checkpoint_x
   sphere_y = checkpoint_y + checkpoint_sphere_dist  -- usa la distancia del checkpoint
   sphere_vx = 0
   sphere_vy = 0
   sphere_offset_y = checkpoint_sphere_dist  -- offset según el checkpoint
   
   is_dead = false
   death_sound_played = false  -- resetear bandera de sonido
   spike_collision_detected = false
   transition_active = false
   transition_bubbles = {}
   
   -- RESETEAR PINCHOS CAYENTES
   for spike in all(falling_spikes) do
    spike.y = spike.original_y
    spike.vy = 0
    spike.falling = false
   end
   
   -- RESETEAR PUZZLES
   for i=1,#puzzles do
    local puzzle = puzzles[i]
    
    -- resetear botones
    for j=1,#puzzle.buttons do
     buttons_state[i][j] = false
     local btn = puzzle.buttons[j]
     -- volver sprite a sin pulsar
     if btn.type == "floor" then
      mset(btn.x, btn.y, 6)
     elseif btn.type == "ceiling" then
      mset(btn.x, btn.y, 8)
     end
    end
    
    -- resetear puertas
    if doors_open[i] then
     doors_open[i] = false
     local door = puzzle.door
     -- volver sprites a cerrados
     mset(door.x, door.y, 20)      -- compuerta superior
     mset(door.x, door.y + 1, 36)  -- compuerta inferior
     -- restaurar flag de sólido
     fset(mget(door.x, door.y), 0, true)
     fset(mget(door.x, door.y + 1), 0, true)
    end
   end
  end
 end
 
 -- actualizar burbujas de transición
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
 -- convertir píxeles a celdas del mapa
 local celda_x = flr(x / 8)
 local celda_y = flr(y / 8)
 
 -- obtener qué sprite está en esa celda
 local sprite_num = mget(celda_x, celda_y)
 
 -- si tiene flag 3 (pinchos), hacer colisión por píxel
 if fget(sprite_num, 3) then
  -- calcular posición dentro del sprite (0-7)
  local pixel_x = flr(x) % 8
  local pixel_y = flr(y) % 8
  
  -- obtener el color del píxel en esa posición del sprite
  local sprite_x = (sprite_num % 16) * 8
  local sprite_y = flr(sprite_num / 16) * 8
  local pixel_color = sget(sprite_x + pixel_x, sprite_y + pixel_y)
  
  -- si el píxel es color 0 (negro/hueco), NO es sólido
  -- si el píxel tiene color, SÍ es sólido
  return pixel_color != 0
 end
 
 -- si no es pincho, verificar flag 0 normal
 return fget(sprite_num, 0)
end

function is_spike(x, y)
 -- convertir a celda del mapa
 local celda_x = flr(x / 8)
 local celda_y = flr(y / 8)
 local sprite_num = mget(celda_x, celda_y)
 
 -- solo verificar si tiene flag 3 (pinchos)
 if not fget(sprite_num, 3) then
  return false
 end
 
 -- calcular posición dentro del sprite (0-7)
 local pixel_x = flr(x) % 8
 local pixel_y = flr(y) % 8
 
 -- detectar orientación según número de sprite
 if sprite_num == 5 then
  -- pincho del SUELO - 6 píxeles centrales superiores
  if pixel_y == 0 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 elseif sprite_num == 7 then
  -- pincho del TECHO - 6 píxeles centrales inferiores
  if pixel_y == 7 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 elseif sprite_num == 17 then
  -- pincho DERECHA - 6 píxeles centrales del lado derecho
  if pixel_x == 7 and (pixel_y >= 1 and pixel_y <= 6) then
   return true
  end
 elseif sprite_num == 18 then
  -- pincho IZQUIERDA - 6 píxeles centrales del lado izquierdo
  if pixel_x == 0 and (pixel_y >= 1 and pixel_y <= 6) then
   return true
  end
 end
 
 return false
end

function is_damage_zone(x, y)
 -- verificar flag 1 (minas y zonas de daño 8x8)
 local celda_x = flr(x / 8)
 local celda_y = flr(y / 8)
 local sprite_num = mget(celda_x, celda_y)
 return fget(sprite_num, 1)
end

function is_button_pressed(sphere_x, sphere_y, button)
 -- convertir posición de la esfera a coordenadas del mapa
 local sphere_cell_x = flr(sphere_x / 8)
 local sphere_cell_y = flr(sphere_y / 8)
 
 -- si la esfera no está en la celda del botón, no está presionado
 if sphere_cell_x != button.x or sphere_cell_y != button.y then
  return false
 end
 
 -- verificar colisión por píxel con la zona del botón
 -- calcular posición dentro del sprite
 local pixel_x = flr(sphere_x) % 8
 local pixel_y = flr(sphere_y) % 8
 
 if button.type == "floor" then
  -- botón de suelo: 6 píxeles centrales superiores (como los pinchos)
  if pixel_y <= 2 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 elseif button.type == "ceiling" then
  -- botón de techo: 6 píxeles centrales inferiores
  if pixel_y >= 5 and (pixel_x >= 1 and pixel_x <= 6) then
   return true
  end
 end
 
 return false
end

function _draw()
 cls(0) -- dark blue bg


 
 
 -- aplicar temblor de pantalla si está muriendo
 local shake_x = 0
 local shake_y = 0
 if death_shake > 0 then
  shake_x = rnd(4) - 2
  shake_y = rnd(4) - 2
 end
 
 -- cámara sigue al submarino (con temblor)
 camera(sub_x - 64 + shake_x, sub_y - 20 + shake_y)

 -- dibujar el mapa (capa de fondo)
 map(0,0,0,0,128,64,0)

 -- dibujar banderas activadas con color diferente
 for i=1,#checkpoints do
  if checkpoints_activated[i] then
   local cp = checkpoints[i]
   -- cambiar color de la bandera activada
   -- cambiar color 8 (rojo) por color 11 (verde)
   pal(8, 11)  -- ajusta estos colores según tu sprite
   spr(49, cp.x * 8, cp.y * 8)
   pal()  -- resetear paleta
  end
 end
 
-- dibujar minas con animación flotante (suave)
 for m in all(mines) do
  local float_offset = sin(time() * 0.5 + m.offset) * 1  -- lento: 0.5, rango 1px
  spr(53, m.x * 8, m.y * 8 + float_offset)
 end
 
 -- dibujar pinchos cayentes
 for spike in all(falling_spikes) do
  spr(23, spike.x - 4, spike.y)
 end

 -- draw sphere (ball) - roja si está muriendo
 local sphere_color1 = 9
 local sphere_color2 = 10
 
 if is_dead then
  -- esfera roja parpadeando
  if death_timer % 4 < 2 then
   sphere_color1 = 8  -- rojo
   sphere_color2 = 2  -- rojo oscuro
  end
 end
 
 circfill(sphere_x, sphere_y, sphere_radius, sphere_color1)
 circfill(sphere_x, sphere_y, sphere_radius-1, sphere_color2)
 -- brillo
 if not is_dead or death_timer % 4 < 2 then
  pset(sphere_x-1, sphere_y-1, 7)
 end

 -- dibujar el mapa (capa de frente - flag 2)
map(0,0,0,0,128,64,4)

 
 -- draw particles/bubbles
 for p in all(particles) do
  local c=1
  if p.life>15 then c=12 end
  circfill(p.x,p.y,0.1,c)
 end
 
 -- draw submarine - rojo si está muriendo
 local sub_color_swap = false
 if is_dead and death_timer % 4 < 2 then
  -- cambiar colores del submarino a rojo
  pal(10, 8)  -- amarillo -> rojo
  pal(9, 2)   -- naranja -> rojo oscuro
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
  pal()  -- resetear paleta
 end
 
 -- resetear cámara para UI
 camera()
 
 -- dibujar burbujas de transición (pantalla completa)
 if transition_active then
  for b in all(transition_bubbles) do
   local alpha = min(b.life / 20, 1)
   if alpha > 0 then
    circfill(b.x, b.y, b.size, 12)
    circfill(b.x, b.y, b.size - 1, 7)
    -- brillo en la burbuja
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