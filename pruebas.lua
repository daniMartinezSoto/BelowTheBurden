-- ============================================
-- variables del juego - submarine with sphere
-- ============================================

-- === submarino ===
sub_x = 32
sub_y = 16
sub_vx = 0
sub_vy = 0
sub_flip = false

-- === física del submarino ===
accel = 1
max_speed = 1.5
friction = 0.80

-- === esfera que sigue al submarino ===
sphere_offset_y = 80  -- distancia vertical debajo del submarino
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

 -- verificar colisión del submarino en las 4 esquinas
 if is_solid(sub_x - 8, sub_y - 8) or
    is_solid(sub_x + 7, sub_y - 8) or
    is_solid(sub_x - 8, sub_y + 7) or
    is_solid(sub_x + 7, sub_y + 7) then
  
  -- hay colisión, volver a la posición anterior
  sub_x = old_sub_x
  sub_y = old_sub_y
  
  -- detener el movimiento
  sub_vx = 0
  sub_vy = 0
 end
 
 -- ============================================
 -- MOVER LA ESFERA PARALELA AL SUBMARINO
 -- ============================================
 
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
 
 -- intentar mover en X
 local new_x = sphere_x + sphere_vx
 local collision_x = false
 if not (is_solid(new_x - sphere_radius, sphere_y - sphere_radius) or
         is_solid(new_x + sphere_radius, sphere_y - sphere_radius) or
         is_solid(new_x - sphere_radius, sphere_y + sphere_radius) or
         is_solid(new_x + sphere_radius, sphere_y + sphere_radius)) then
  sphere_x = new_x
 else
  sphere_vx = 0  -- detener velocidad al chocar
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
  sphere_vy = 0  -- detener velocidad al chocar
  collision_y = true
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
 -- CONTROL DE DISTANCIA DE LA ESFERA
 -- ============================================
 
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
    sfx(0)
    sfx_playing = true
   end
   sphere_offset_y += sphere_offset_speed
   if sphere_offset_y > sphere_offset_max then
    sphere_offset_y = sphere_offset_max
   end
  else
   if sfx_playing then
    sfx(-1)
    sfx_playing = false
   end
  end
 else
  if sfx_playing then
   sfx(-1)
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
    sfx(1)
    sfx_in_playing = true
   end
   sphere_offset_y -= sphere_offset_speed
   if sphere_offset_y < sphere_offset_min then
    sphere_offset_y = sphere_offset_min
   end
  else
   if sfx_in_playing then
    sfx(-1)
    sfx_in_playing = false
   end
  end
 else
  if sfx_in_playing then
   sfx(-1)
   sfx_in_playing = false
  end
  -- resetear timer si no se presiona el botón
  if not btn(5) then
   sphere_bubble_timer = 0
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
end

function is_solid(x, y)
 -- convertir píxeles a celdas del mapa
 local celda_x = flr(x / 8)
 local celda_y = flr(y / 8)
 
 -- obtener qué sprite está en esa celda
 local sprite_num = mget(celda_x, celda_y)
 
 -- verificar si ese sprite tiene la flag 0 (sólido)
 return fget(sprite_num, 0)
end

function _draw()
 cls(0) -- dark blue bg
 
 -- cámara sigue al submarino
 camera(sub_x - 64, sub_y - 20)

 -- dibujar el mapa
 map(0, 0, 0, 0, 128, 64)

 -- draw sphere (ball)
 circfill(sphere_x, sphere_y, sphere_radius, 9)
 circfill(sphere_x, sphere_y, sphere_radius-1, 10)
 -- brillo
 pset(sphere_x-1, sphere_y-1, 7)
 
 -- draw particles/bubbles
 for p in all(particles) do
  local c=1
  if p.life>15 then c=12 end
  circfill(p.x,p.y,0.1,c)
 end
 
 -- draw submarine
 if sub_flip then
  spr(2,sub_x-8,sub_y-4,1,1,true)
  spr(1,sub_x,sub_y-4,1,1,true)
  spr(18,sub_x-8,sub_y+4,1,1,true)
  spr(17,sub_x,sub_y+4,1,1,true)
 else
  spr(1,sub_x-8,sub_y-4)
  spr(2,sub_x,sub_y-4)
  spr(17,sub_x-8,sub_y+4)
  spr(18,sub_x,sub_y+4)
 end
 
 -- resetear cámara para UI
 camera()
 
 -- debug info (opcional)
 -- print("sphere offset:"..flr(sphere_offset_y),2,2,7)
end

function add_particle(x,y)
 add(particles,{
  x=x,
  y=y,
  life=30+rnd(20)
 })
end