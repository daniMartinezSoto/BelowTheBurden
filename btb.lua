-- ============================================
-- variables del juego - submarine with sphere
-- ============================================


-- === submarino ===
sub_x = 600  -- posición inicial X (en píxeles)
sub_y = 60   -- posición inicial Y (en píxeles)
sub_vx = 0   -- velocidad horizontal
sub_vy = 0   -- velocidad vertical
sub_flip = false  -- true = mira izquierda, false = mira derecha

-- === física del submarino ===
accel = 1           -- aceleración al presionar teclas
max_speed = 1.5     -- velocidad máxima
friction = 0.80     -- fricción del agua (0.80 = conserva 80% de velocidad)

-- === esfera que sigue al submarino ===
sphere_offset_y = 4  -- distancia vertical debajo del submarino (modifica con Z/X)
sphere_x = 0         -- posición actual X de la esfera
sphere_y = 0         -- posición actual Y de la esfera
sphere_vx = 0        -- velocidad horizontal de la esfera
sphere_vy = 0        -- velocidad vertical de la esfera
sphere_radius = 3    -- radio de la esfera (para colisiones)

-- === control de distancia de la esfera ===
sphere_offset_speed = 1    -- velocidad de cambio de distancia
sphere_offset_min = 10     -- distancia mínima permitida
sphere_offset_max = 100    -- distancia máxima permitida

-- === control de burbujas de la esfera ===
sphere_bubble_timer = 0     -- cooldown para no crear burbujas constantemente
sphere_last_collision = false  -- bandera para detectar choques nuevos

-- === detección de colisión con pinchos ===
spike_collision_detected = false  -- true si la esfera tocó un pincho

-- === sistema de checkpoint y muerte ===
checkpoint_x = 32               -- posición X del checkpoint actual
checkpoint_y = 16               -- posición Y del checkpoint actual
checkpoint_sphere_dist = 80     -- distancia de la esfera en checkpoint actual
is_dead = false                 -- true cuando el jugador muere
death_timer = 0                 -- cuenta regresiva hasta respawn (60 frames = 2 segundos)
death_shake = 0                 -- intensidad del temblor de pantalla
death_sound_played = false      -- bandera para evitar sonido repetido
transition_bubbles = {}         -- burbujas de la transición de muerte
transition_active = false       -- true durante la animación de muerte
transition_timer = 0            -- timer de la transición

-- === sistema de checkpoints (banderas) ===
-- Cada checkpoint tiene: x, y (coordenadas del tile), sphere_dist (distancia personalizada)
checkpoints = {
 {x=4, y=2, sphere_dist=10},    -- primer checkpoint, esfera a 10 píxeles
 {x=32, y=5, sphere_dist=5},    -- segundo checkpoint, esfera a 5 píxeles
 {x=47, y=5, sphere_dist=5},    -- tercer checkpoint
 {x=76, y=7, sphere_dist=5},    -- cuarto checkpoint
 -- añade más checkpoints con su distancia personalizada
 -- ejemplo: {x=50, y=10, sphere_dist=15}
}
current_checkpoint = 0          -- índice del checkpoint actual (0 = ninguno activado)
checkpoints_activated = {}      -- tabla para saber qué checkpoints están activados

-- === sistema de minas ===
mines = {}  -- tabla para almacenar posiciones de minas y su animación flotante

-- === sistema de pinchos cayentes ===
falling_spikes = {}         -- tabla para pinchos que caen del techo
spike_trigger_range = 7     -- distancia horizontal para activar caída (en píxeles)
spike_gravity = 0.3         -- gravedad de los pinchos
spike_max_fall_speed = 8    -- velocidad máxima de caída

-- === definiciones de torretas por posición ===
-- Configuración manual: clave = "x,y" en coordenadas de mapa (tiles)
-- Valores: range (alcance en píxeles), fire_rate (frames entre disparos), proj_speed (velocidad proyectil)
turret_defs = {
 ["110,13"] = {range=120, fire_rate=60, proj_speed=2},  -- torreta lenta, largo alcance
 ["121,15"] = {range=80,  fire_rate=50, proj_speed=2},  -- torreta media
 ["110,13"] = {range=80,  fire_rate=50, proj_speed=2},  -- (duplicado, se sobrescribe)
 ["88,7"]   = {range=80,  fire_rate=100, proj_speed=5}  -- torreta lenta, proyectiles rápidos
}

-- === sistema de torretas ===
turrets = {}       -- tabla de torretas activas (se rellena detectando sprite 54 en el mapa)
projectiles = {}   -- proyectiles disparados por torretas (líneas rojas)
proj_length = 8    -- longitud visual del proyectil (línea)

-- === sistema de puzzles (botones y compuertas) ===
-- tipos de botón: "floor" (suelo), "ceiling" (techo), "wall_left" (pared izq), "wall_right" (pared der)
-- tipos de puerta: "vertical" (ocupa 2 tiles verticales), "horizontal" (ocupa 2 tiles horizontales)
--
-- SPRITES DE BOTONES:
-- - floor sin pulsar: 6, pulsado: 22
-- - ceiling sin pulsar: 8, pulsado: 24
-- - wall_left sin pulsar: 39, pulsado: 55
-- - wall_right sin pulsar: 40, pulsado: 56
--
-- PUERTA VERTICAL:
--   door = {x=20, y=13, type="vertical"}
--   sprites cerrados: superior=20, inferior=36
--   sprites abiertos: superior=37, inferior=52
--   ocupa: (x, y) y (x, y+1)
--
-- PUERTA HORIZONTAL:
--   door = {x=20, y=13, type="horizontal"}
--   sprites cerrados: izquierda=35, derecha=51
--   sprites abiertos: izquierda=57, derecha=58
--   ocupa: (x, y) y (x+1, y)
puzzles = {
 -- Puzzle 1: dos botones, una compuerta vertical
 {
  buttons = {
   {x=15, y=14, type="floor"},   -- botón suelo
   {x=15, y=9, type="ceiling"}   -- botón techo
  },
  door = {x=20, y=13, type="vertical"}  -- puerta vertical
 },
 
 -- Puzzle 2: un botón, una compuerta vertical
 {
  buttons = {
   {x=25, y=8, type="floor"},
  },
  door = {x=19, y=6, type="vertical"}
 },
 
 -- Puzzle 3: tres botones (dos suelo, uno pared), una compuerta vertical
 {
  buttons = {
   {x=42, y=14, type="floor"},
   {x=43, y=14, type="floor"},
   {x=42, y=11, type="wall_left"}  -- botón pared izquierda
  },
  door = {x=45, y=4, type="vertical"}
 },
 
 -- Puzzle 4: dos botones, una compuerta vertical
 {
  buttons = {
   {x=63, y=13, type="floor"},
   {x=64, y=10, type="ceiling"}
  },
  door = {x=68, y=5, type="vertical"}
 },
 
 -- Puzzle 5: cuatro botones, una compuerta vertical
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

-- estado de botones y puertas
buttons_state = {}  -- tabla para saber qué botones están pulsados [puzzle_index][button_index]
doors_open = {}     -- tabla para saber qué puertas están abiertas [puzzle_index]

-- === partículas (burbujas) ===
particles = {}  -- tabla de burbujas flotantes

-- === control de sonido ===
sfx_playing = false     -- true cuando el sonido de bajar esfera está sonando (canal 0)
sfx_in_playing = false  -- true cuando el sonido de subir esfera está sonando (canal 1)

-- ============================================
-- main game code
-- ============================================

function _init()
 -- inicializar posición de la esfera debajo del submarino
 sphere_x = sub_x
 sphere_y = sub_y + sphere_offset_y
 
 -- inicializar estado de puzzles (todos los botones sin pulsar, todas las puertas cerradas)
 for i=1,#puzzles do
  buttons_state[i] = {}
  for j=1,#puzzles[i].buttons do
   buttons_state[i][j] = false
  end
  doors_open[i] = false
 end
 
 -- inicializar checkpoints (todos sin activar)
 for i=1,#checkpoints do
  checkpoints_activated[i] = false
 end
 
 -- escanear el mapa para encontrar todas las minas (sprite 53)
 -- las minas se quitan del mapa y se dibujan manualmente con animación
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
 -- los pinchos se quitan del mapa y se dibujan manualmente
 for y=0,63 do
  for x=0,127 do
   if mget(x, y) == 23 then
    add(falling_spikes, {
     x = x * 8 + 4,      -- centro del tile en píxeles
     y = y * 8,          -- posición Y inicial
     original_y = y * 8, -- guardar posición original para resetear
     vy = 0,             -- velocidad vertical inicial
     falling = false     -- todavía no está cayendo
    })
    mset(x, y, 0)  -- quitar del mapa para dibujarlo manualmente
   end
  end
 end
end

-- === detectar torretas en el mapa (sprite 54) ===
-- Este código se ejecuta FUERA de _init() para que se ejecute al cargar el cartucho
for y=0,63 do
 for x=0,127 do
  if mget(x,y) == 54 then
   local key = x..","..y
   local def = turret_defs[key]  -- buscar configuración manual

   add(turrets,{
    x = x*8 + 4,  -- centro del tile en píxeles
    y = y*8 + 4,
    range = def and def.range or 100,       -- usar definición o valor por defecto
    fire_rate = def and def.fire_rate or 60,
    proj_speed = def and def.proj_speed or 3,
    cooldown = 0,          -- frames restantes hasta poder disparar
    sound_cooldown = 0,    -- frames restantes hasta poder reproducir sonido
    sound_range = 50       -- solo suena si está visible en pantalla
   })

   mset(x,y,0)  -- limpiar del mapa para dibujarlo manualmente
  end
 end
end


function _update()
 -- ============================================
 -- INPUT Y MOVIMIENTO DEL SUBMARINO
 -- ============================================
 
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

 -- limitar velocidad máxima
 sub_vx=mid(-max_speed,sub_vx,max_speed)
 sub_vy=mid(-max_speed,sub_vy,max_speed)
 
 -- aplicar fricción del agua
 sub_vx*=friction
 sub_vy*=friction

 -- guardar posición anterior del submarino
 local old_sub_x = sub_x
 local old_sub_y = sub_y

 -- intentar mover el submarino
 sub_x += sub_vx
 sub_y += sub_vy

 -- verificar colisión del submarino con hitbox más pequeña (12x6 en vez de 16x16)
 -- se verifica en 4 esquinas de la hitbox
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
 
 -- verificar si el submarino toca una mina/zona de daño (flag 1)
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
   
   -- DETENER sonidos de control de esfera
   sfx(-1, 0)  -- detener canal 0 (Z)
   sfx(-1, 1)  -- detener canal 1 (X)
   sfx(7, 2)   -- sonido de explosión en canal 2
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
 local sphere_accel = 0.15     -- aceleración muy suave
 local sphere_friction = 0.88  -- fricción del agua
 
 sphere_vx += dx * sphere_accel
 sphere_vy += dy * sphere_accel
 
 -- aplicar fricción del agua
 sphere_vx *= sphere_friction
 sphere_vy *= sphere_friction
 
 -- limitar velocidad máxima de la esfera
 local sphere_max_speed = 1.2
 if abs(sphere_vx) > sphere_max_speed then
  sphere_vx = sgn(sphere_vx) * sphere_max_speed
 end
 if abs(sphere_vy) > sphere_max_speed then
  sphere_vy = sgn(sphere_vy) * sphere_max_speed
 end
 
 -- guardar posición anterior de la esfera
 local old_sphere_x = sphere_x
 local old_sphere_y = sphere_y
 
 -- VERIFICACIÓN DE PINCHOS - función auxiliar
 -- verifica 8 puntos alrededor del círculo + el centro
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
 
 -- intentar mover en X (verificando las 4 esquinas del círculo)
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
 
 -- intentar mover en Y (verificando las 4 esquinas del círculo)
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
  -- verificar pinchos (flag 3)
  local hit_spike = check_spike_collision()
  
  -- verificar minas/zonas de daño (flag 1)
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
 
 -- detectar colisión con paredes y generar burbujas
 local sphere_collision = collision_x or collision_y
 if sphere_collision and not sphere_last_collision then
  -- generar burbujas al chocar (solo en el primer frame de colisión)
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
     -- cambiar sprite a pulsado según tipo
     if btn_data.type == "floor" then
      mset(btn_data.x, btn_data.y, 22)  -- botón suelo pulsado
     elseif btn_data.type == "ceiling" then
      mset(btn_data.x, btn_data.y, 24)  -- botón techo pulsado
     elseif btn_data.type == "wall_left" then
      mset(btn_data.x, btn_data.y, 55)  -- botón pared izq pulsado
     elseif btn_data.type == "wall_right" then
      mset(btn_data.x, btn_data.y, 56)  -- botón pared der pulsado
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
   local door = puzzle.door
   local door_type = door.type or "vertical"

   if door_type == "vertical" then
    -- puerta vertical: ocupa (x,y) y (x, y+1)
    mset(door.x, door.y, 37)      -- compuerta superior abierta
    mset(door.x, door.y + 1, 52)  -- compuerta inferior abierta
    fset(mget(door.x, door.y), 0, false)      -- quitar flag sólido
    fset(mget(door.x, door.y + 1), 0, false)
   elseif door_type == "horizontal" then
    -- puerta horizontal: ocupa (x,y) y (x+1, y)
    mset(door.x, door.y, 57)      -- compuerta izquierda abierta
    mset(door.x + 1, door.y, 58)  -- compuerta derecha abierta
    fset(mget(door.x, door.y), 0, false)      -- quitar flag sólido
    fset(mget(door.x + 1, door.y), 0, false)
   end
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
   checkpoint_x = cp.x * 8 + 4  -- centrado en la celda
   checkpoint_y = cp.y * 8 - 8  -- submarino aparece 8 píxeles arriba de la bandera
   checkpoint_sphere_dist = cp.sphere_dist  -- guardar la distancia personalizada
   sfx(6, 3)  -- sonido de checkpoint activado
  end
 end
 
 -- ============================================
 -- SISTEMA DE PINCHOS CAYENTES
 -- ============================================
 
 -- actualizar pinchos cayentes
 for spike in all(falling_spikes) do
  -- detectar si el submarino O la esfera pasan cerca horizontalmente
  if not spike.falling then
   local horizontal_dist_sub = abs(sub_x - spike.x)
   local horizontal_dist_sph = abs(sphere_x - spike.x)
   -- si el submarino O la esfera están debajo del pincho y cerca horizontalmente
   if (sub_y > spike.y and horizontal_dist_sub < spike_trigger_range) or
      (sphere_y > spike.y and horizontal_dist_sph < spike_trigger_range) then
    spike.falling = true
    sfx(8, 3)  -- sonido de pincho cayendo
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
 -- SISTEMA DE TORRETAS
 -- ============================================
 
 for turret in all(turrets) do
  -- decrementar cooldown del disparo
  if turret.cooldown > 0 then
   turret.cooldown -= 1
  end

  -- decrementar cooldown de sonido
  if turret.sound_cooldown > 0 then
   turret.sound_cooldown -= 1
  end

  -- calcular distancia a la esfera
  local dx = sphere_x - turret.x
  local dy = sphere_y - turret.y
  local dist = sqrt(dx*dx + dy*dy)

  -- disparar si está en rango y el cooldown está listo
  if dist <= turret.range and turret.cooldown == 0 then
   local angle = atan2(dx, dy)
   add(projectiles, {
    x = turret.x,
    y = turret.y,
    vx = cos(angle) * turret.proj_speed,
    vy = sin(angle) * turret.proj_speed,
    max_dist = turret.range*1.2,  -- desaparece a 120% del rango
    traveled = 0                  -- distancia recorrida
   })
   turret.cooldown = turret.fire_rate

   -- sonido SOLO si la torreta está visible en pantalla
   local cam_x = sub_x - 64
   local cam_y = sub_y - 20
   if turret.x >= cam_x and turret.x <= cam_x + 128 and
      turret.y >= cam_y and turret.y <= cam_y + 128 and
      turret.sound_cooldown == 0 then
    sfx(9, 3)
    turret.sound_cooldown = 10  -- evita sonidos repetidos
   end
  end
 end

 -- actualizar proyectiles
 for proj in all(projectiles) do
  proj.x += proj.vx
  proj.y += proj.vy
  proj.traveled += sqrt(proj.vx * proj.vx + proj.vy * proj.vy)
  
  -- eliminar si toca un bloque sólido
  if is_solid(proj.x, proj.y) then
   del(projectiles, proj)
  elseif proj.traveled > proj.max_dist then
   -- eliminar si viajó demasiado
   del(projectiles, proj)
  elseif not is_dead and death_timer <= 0 then
   -- verificar colisión con esfera (círculo vs línea)
   local speed = sqrt(proj.vx * proj.vx + proj.vy * proj.vy)
   local px2 = proj.x + (proj.vx / speed) * proj_length
   local py2 = proj.y + (proj.vy / speed) * proj_length
   
   -- distancia punto-línea
   local dist_to_line = abs((py2-proj.y)*sphere_x - (px2-proj.x)*sphere_y + px2*proj.y - py2*proj.x) / 
                        sqrt((py2-proj.y)^2 + (px2-proj.x)^2)
   if dist_to_line < sphere_radius + 1 then
    -- verificar si está en el segmento
    local dot = (sphere_x - proj.x)*(px2 - proj.x) + (sphere_y - proj.y)*(py2 - proj.y)
    local len_sq = (px2 - proj.x)^2 + (py2 - proj.y)^2
    if dot >= 0 and dot <= len_sq then
     -- MUERTE POR PROYECTIL
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
  
  -- control distancia esfera - alejar (botón Z)
  -- solo si puede bajar Y no está tocando el suelo
  if btn(4) and sphere_offset_y < sphere_offset_max then
   if sphere_can_move_down and not sphere_touching_floor then
    -- generar burbujas solo una vez al empezar a bajar
    if sphere_bubble_timer <= 0 then
     for i=1,3 do
      add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
     end
     sphere_bubble_timer = 8  -- cooldown de 8 frames
    end
    
    if not sfx_playing then
     sfx(0, 0)  -- reproducir sonido en canal 0
     sfx_playing = true
    end
    sphere_offset_y += sphere_offset_speed
    if sphere_offset_y > sphere_offset_max then
     sphere_offset_y = sphere_offset_max
    end
   else
    if sfx_playing then
     sfx(-1, 0)  -- detener canal 0
     sfx_playing = false
    end
   end
  else
   if sfx_playing then
    sfx(-1, 0)  -- detener canal 0
    sfx_playing = false
   end
   -- resetear timer si no se presiona el botón
   if not btn(4) then
    sphere_bubble_timer = 0
   end
  end
  
  -- control distancia esfera - acercar (botón X)
  -- solo si puede subir Y no está tocando el techo
  if btn(5) and sphere_offset_y > sphere_offset_min then
   if sphere_can_move_up and not sphere_touching_ceiling then
    -- generar burbujas solo una vez al empezar a subir
    if sphere_bubble_timer <= 0 then
     for i=1,3 do
      add_particle(sphere_x + rnd(6) - 3, sphere_y + rnd(6) - 3)
     end
     sphere_bubble_timer = 8  -- cooldown de 8 frames
    end
    
    if not sfx_in_playing then
     sfx(1, 1)  -- reproducir sonido en canal 1
     sfx_in_playing = true
    end
    sphere_offset_y -= sphere_offset_speed
    if sphere_offset_y < sphere_offset_min then
     sphere_offset_y = sphere_offset_min
    end
   else
    if sfx_in_playing then
     sfx(-1, 1)  -- detener canal 1
     sfx_in_playing = false
    end
   end
  else
   if sfx_in_playing then
    sfx(-1, 1)  -- detener canal 1
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
 
 -- generar burbujas del propulsor del submarino
 local bubble_x=sub_flip and sub_x+8 or sub_x-8
 if rnd(1)<0.3 then
  add_particle(bubble_x,sub_y+rnd(4)-2)
 end
 
 -- actualizar partículas (burbujas)
 for p in all(particles) do
  p.y-=0.5+rnd(0.5)  -- subir con variación
  p.x+=rnd(0.6)-0.3  -- movimiento horizontal aleatorio
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
  
  -- decrementar temblor de pantalla
  if death_shake > 0 then
   death_shake -= 1
  end
  
  -- iniciar transición de burbujas
  if death_timer == 40 and not transition_active then
   transition_active = true
   transition_timer = 40
   sfx(4, 2)  -- sonido de transición en canal 2
   -- crear MUCHÍSIMAS burbujas grandes para la transición
   for i=1,100 do
    add(transition_bubbles, {
     x = rnd(128),
     y = 128 + rnd(80),  -- aparecen abajo
     vy = -1.5 - rnd(2),  -- suben rápido
     size = 3 + rnd(5),   -- burbujas grandes
     life = 70
    })
   end
  end
  
  -- respawn cuando termine el timer
  if death_timer == 0 then
   -- resetear posición al checkpoint activado
   sub_x = checkpoint_x
   sub_y = checkpoint_y
   sub_vx = 0
   sub_vy = 0
   -- ESFERA aparece a la distancia configurada del checkpoint
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
   
   -- RESETEAR PINCHOS CAYENTES
   for spike in all(falling_spikes) do
    spike.y = spike.original_y
    spike.vy = 0
    spike.falling = false
   end
   
   -- RESETEAR PROYECTILES Y TORRETAS
   projectiles = {}
   for turret in all(turrets) do
    turret.cooldown = 0
   end
   
   -- RESETEAR PUZZLES (botones y puertas)
   for i=1,#puzzles do
    local puzzle = puzzles[i]
    
    -- resetear botones a sin pulsar
    for j=1,#puzzle.buttons do
     buttons_state[i][j] = false
     local btn = puzzle.buttons[j]
     -- volver sprite a sin pulsar según tipo
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
    
    -- resetear puertas a cerradas
    if doors_open[i] then
     doors_open[i] = false
     local door = puzzle.door
     local door_type = door.type or "vertical"

     if door_type == "vertical" then
      -- volver sprites a cerrados (vertical)
      mset(door.x, door.y, 20)      -- compuerta superior
      mset(door.x, door.y + 1, 36)  -- compuerta inferior
      -- restaurar flag de sólido
      fset(mget(door.x, door.y), 0, true)
      fset(mget(door.x, door.y + 1), 0, true)
     elseif door_type == "horizontal" then
      -- volver sprites a cerrados (horizontal)
      mset(door.x, door.y, 35)      -- compuerta izquierda
      mset(door.x + 1, door.y, 51)  -- compuerta derecha
      -- restaurar flag de sólido
      fset(mget(door.x, door.y), 0, true)
      fset(mget(door.x + 1, door.y), 0, true)
     end
    end
   end
  end
 end
 
 -- actualizar burbujas de transición
 if transition_active then
  transition_timer -= 1
  for b in all(transition_bubbles) do
   b.y += b.vy
   b.x += sin(time() * 2 + b.y * 0.1) * 0.5  -- movimiento ondulante
   b.life -= 1
   if b.life <= 0 or b.y < -10 then
    del(transition_bubbles, b)
   end
  end
 end
end

-- ============================================
-- FUNCIONES DE COLISIÓN
-- ============================================

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

-- ============================================
-- DETECCIÓN DE BOTONES
-- ============================================
-- La detección de botones funciona según desde dónde viene la esfera:
--
-- floor:      la esfera viene de ABAJO → hitbox en píxeles superiores (y <= 2)
-- ceiling:    la esfera viene de ARRIBA → hitbox en píxeles inferiores (y >= 5)
-- wall_left:  la esfera viene de la DERECHA → hitbox en píxeles derechos (x >= 5)
-- wall_right: la esfera viene de la IZQUIERDA → hitbox en píxeles izquierdos (x <= 2)
--
-- Todos los botones usan una zona de 6 píxeles centrales (píxeles 1-6)
function is_button_pressed(sphere_x, sphere_y, button)
 -- convertir posición de la esfera a coordenadas del mapa
 local sphere_cell_x = flr(sphere_x / 8)
 local sphere_cell_y = flr(sphere_y / 8)
 
 -- si la esfera no está en la celda del botón, no está presionado
 if sphere_cell_x != button.x or sphere_cell_y != button.y then
  return false
 end
 
 -- verificar colisión por píxel con la zona del botón
 -- calcular posición dentro del sprite (0-7)
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

-- ============================================
-- FUNCIÓN DE DIBUJO
-- ============================================

function _draw()
 cls(0) -- fondo azul oscuro
 
 -- aplicar temblor de pantalla si está muriendo
 local shake_x = 0
 local shake_y = 0
 if death_shake > 0 then
  shake_x = rnd(4) - 2
  shake_y = rnd(4) - 2
 end
 
 -- cámara sigue al submarino (con temblor si está muriendo)
 camera(sub_x - 64 + shake_x, sub_y - 20 + shake_y)

 -- dibujar el mapa (capa de fondo, sin flag 2)
 map(0,0,0,0,128,64,0)

 -- dibujar banderas activadas con color diferente
 for i=1,#checkpoints do
  if checkpoints_activated[i] then
   local cp = checkpoints[i]
   -- cambiar color de la bandera activada
   pal(8, 11)  -- cambiar color 8 (rojo) por 11 (verde)
   spr(49, cp.x * 8, cp.y * 8)
   pal()  -- resetear paleta
  end
 end
 
 -- dibujar minas con animación flotante suave
 for m in all(mines) do
  -- sin(time() * velocidad + offset) * amplitud
  local float_offset = sin(time() * 0.5 + m.offset) * 1  -- lento: 0.5, rango 1px
  spr(53, m.x * 8, m.y * 8 + float_offset)
 end
 
 -- dibujar pinchos cayentes
 for spike in all(falling_spikes) do
  spr(23, spike.x - 4, spike.y)
 end
 
 -- dibujar torretas
 for turret in all(turrets) do
  spr(54, turret.x - 4, turret.y - 4)
 end
 
 -- dibujar proyectiles (líneas rojas)
 for proj in all(projectiles) do
  local speed = sqrt(proj.vx * proj.vx + proj.vy * proj.vy)
  local px2 = proj.x + (proj.vx / speed) * proj_length
  local py2 = proj.y + (proj.vy / speed) * proj_length
  line(proj.x, proj.y, px2, py2, 8)  -- color 8 = rojo
 end

 -- dibujar esfera (roja parpadeando si está muriendo)
 local sphere_color1 = 9   -- naranja
 local sphere_color2 = 10  -- amarillo
 
 if is_dead then
  -- esfera roja parpadeando cada 4 frames
  if death_timer % 4 < 2 then
   sphere_color1 = 8  -- rojo
   sphere_color2 = 2  -- rojo oscuro
  end
 end
 
 circfill(sphere_x, sphere_y, sphere_radius, sphere_color1)
 circfill(sphere_x, sphere_y, sphere_radius-1, sphere_color2)
 -- brillo en la esfera
 if not is_dead or death_timer % 4 < 2 then
  pset(sphere_x-1, sphere_y-1, 7)
 end

 -- dibujar el mapa (capa de frente con flag 2)
 map(0,0,0,0,128,64,4)
 
 -- dibujar partículas/burbujas
 for p in all(particles) do
  local c=1  -- azul oscuro
  if p.life>15 then c=12 end  -- azul claro si tiene mucha vida
  circfill(p.x,p.y,0.1,c)
 end
 
 -- dibujar submarino (rojo si está muriendo)
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
 
 -- resetear cámara para UI (si hubiera)
 camera()
 
 -- dibujar burbujas de transición de muerte (pantalla completa)
 if transition_active then
  for b in all(transition_bubbles) do
   local alpha = min(b.life / 20, 1)
   if alpha > 0 then
    circfill(b.x, b.y, b.size, 12)  -- azul claro
    circfill(b.x, b.y, b.size - 1, 7)  -- blanco
    -- brillo en la burbuja
    pset(b.x - b.size/2, b.y - b.size/2, 7)
   end
  end
 end
 
end

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================

function add_particle(x,y)
 add(particles,{
  x=x,
  y=y,
  life=30+rnd(20)  -- vida entre 30 y 50 frames
 })
end