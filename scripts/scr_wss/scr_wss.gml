// ============================================================================
// scr_wss — v72 WSS (Wacky Stretchy & Squashy)
// Port del mod Lua de SRB2 "L_WackyStretchyandSquashy" al juego: el cuerpo
// del personaje se ESTIRA al saltar/despegar y se APLASTA al aterrizar (o
// al cambiar de pose / por velocidad de carrera, segun estilo), con vuelta
// al reposo linear, exponencial o de muelle con rebote ("jelly").
//
// QUE TOCA Y QUE NO TOCA:
//   - Es 100% VISUAL. Solo cambia la escala del draw_sprite_ext del cuerpo
//     (y ancla el pie al suelo con un offset en Y). La fisica (yspd, gspd,
//     colisiones, hitboxes) y el image_xscale de DIRECCION quedan intactos:
//     la mascara de colision no sabe que esto existe. El ejemplo de la casa
//     es el fase 2 de Sally Canon (f2Sq): mismo metodo de anclaje.
//   - CERO RED. El jugador local deriva su escala de su propia fisica; los
//     puppets la derivan del yspd y del estado que YA viajaban en
//     CLIENT_PLAYER_DATA. Ni un byte nuevo de protocolo, nada que el
//     anti-cheat tenga que vigilar.
//
// ANCLAJE AL SUELO: el sprite se dibuja en y + yoff con
//   yoff = (sprite_height - sprite_yoffset) * (1 - escalaY_total)
// asi el pie queda plantado y el cuerpo se estira/aplasta HACIA ARRIBA
// (misma formula del _f2yoff de Sally Canon / obj_player_puppet).
//
// GATILLOS (los mismos estilos que el Lua original):
//   WSS_STRETCH_STYLE 0 = Classic: estiron de UNA vez al despegar hacia
//                       arriba (salto — tambien el coyote, via justJumped —
//                       o lanzamiento por pendiente), proporcional a yspd.
//                    1 = Airflow: estira continuo en el aire segun |yspd|.
//   WSS_SQUASH_STYLE  0 = Landing: aplaston al aterrizar, proporcional a
//                       la velocidad de caida del ultimo frame en el aire.
//                    1 = State: aplaston al cambiar de sprite EN el suelo
//                       (idle->andar->correr->frenar: la "anticipacion" del
//                       Lua adaptada a las animaciones del juego; se salta
//                       el frame del aterrizaje, la bola y la carga).
//                    2 = Speed: aplaston continuo en el suelo segun |gspd|
//                       (a mas carrera, mas agachado; satura en
//                       WSS_SPEED_FULL). Mientras corre NO decae: es una
//                       postura, como en el Lua.
//   WSS_RETURN_STYLE  0 = Sharp: vuelta linear a paso fijo.
//                    1 = Smooth: vuelta exponencial (mismo feel que
//                       SALLY_CANON_SQ_DECAY del fase 2).
//                    2 = Jelly: muelle amortiguado con rebote (overshoot
//                       ~-0.14 y 3 cruces, calibrado por simulacion a 60fps).
//
// v74 RETUNING (feedback de la duena: "la caida se nota un poco pero el
// salto y lo demas no se nota mucho"): gains al doble, topes +29%/+40% y
// Smooth un pelin mas lento — estiron del salto 0.315 -> 0.450, aplaste
// de aterrizaje normal 0.21 -> 0.35. Misma proporcion de rebote Jelly.
//
// Los valores viven en macros para que el Suite (Suite_TD2D.html) pueda
// tunearlos con su motor de #macro ya existente (mismo patron que
// ITEMBOX_*_TIME de la v70). WSS_ENABLED a 0 lo apaga entero y todos los
// draws vuelven bit-a-bit a como eran antes.
// ============================================================================

#macro WSS_ENABLED 1
#macro WSS_STRETCH_STYLE 0
#macro WSS_SQUASH_STYLE 0
#macro WSS_RETURN_STYLE 1
#macro WSS_STRETCH_MAX 0.45
#macro WSS_SQUASH_MAX 0.42
#macro WSS_TAKEOFF_GAIN 0.085
#macro WSS_AIRFLOW_GAIN 0.055
#macro WSS_IMPACT_GAIN 0.050
#macro WSS_STATE_SQUASH 0.24
#macro WSS_SPEED_FULL 12
#macro WSS_X_RATIO 0.6
#macro WSS_SHARP_STEP 0.030
#macro WSS_SMOOTH_DECAY 0.10
#macro WSS_JELLY_K 0.035
#macro WSS_JELLY_DAMP 0.88

// scr_wss_update — jugador LOCAL. La engancha el final de
// scr_collision_basic (todos los personajes la llaman desde su Step_0
// despues de resolver el suelo de este frame): aqui isGrounded/yspd ya
// son los definitivos del frame.
function scr_wss_update()
{
        if(!WSS_ENABLED)
                return;
        
        // Guard de contexto: solo instancias con la fisica del jugador.
        // (Los 22 personajes declaran isGrounded/yspd en su Create; el
        // guard cubre el primer frame pre-handshake y cualquier llamador
        // futuro que no sea un personaje — leccion v71: leer una variable
        // no declarada es FATAL en este runtime.)
        if(!variable_instance_exists(id, "isGrounded") || !variable_instance_exists(id, "yspd"))
                return;
        
        // Declaracion lazy (patron coyoteTimer de scr_move_basic): sin
        // tocar el Create de los 22 personajes.
        if(!variable_instance_exists(id, "wssSq"))
        {
                wssSq = 0;
                wssVel = 0;
                wssPrevGrounded = isGrounded;
                wssAirYspd = 0;
                wssPrevSpr = sprite_index;
        }
        
        // Impacto de aterrizaje = velocidad vertical del ULTIMO frame que
        // estuvo en el aire (en GameMaker Y crece hacia abajo: caer es
        // yspd > 0, por eso los signos estan invertidos respecto al Lua
        // de SRB2, donde momz > 0 es subir).
        if(!isGrounded)
                wssAirYspd = yspd;
        
        // ---- gatillos de ESTIRADO (solo en el aire) ----
        if(!isGrounded)
        {
                if(WSS_STRETCH_STYLE == 0)
                {
                        // Classic: una vez por despegue. Flanco: estaba en
                        // el suelo el frame anterior y ahora sube (salto,
                        // pendiente que despega) — o acabo de saltar via
                        // coyote (justJumped, que cubre el despegue cuyo
                        // flanco de suelo ya se perdio).
                        var _jumped = variable_instance_exists(id, "justJumped") && justJumped;
                        
                        if(_jumped || (wssPrevGrounded && yspd < 0))
                                wssSq = max(wssSq, min(WSS_STRETCH_MAX, -yspd * WSS_TAKEOFF_GAIN));
                }
                else
                {
                        // Airflow: continuo por velocidad vertical (subiendo
                        // o cayendo, como el estilo del Lua).
                        wssSq = max(wssSq, min(WSS_STRETCH_MAX, abs(yspd) * WSS_AIRFLOW_GAIN));
                }
        }
        
        // ---- gatillos de APLASTADO ----
        if(WSS_SQUASH_STYLE == 0)
        {
                // Landing: flanco aire->suelo, impacto = ultima caida.
                if(isGrounded && !wssPrevGrounded && wssAirYspd > 0)
                        wssSq = min(wssSq, -min(WSS_SQUASH_MAX, wssAirYspd * WSS_IMPACT_GAIN));
        }
        else if(WSS_SQUASH_STYLE == 1)
        {
                // State: cambio de sprite EN el suelo, sin contar el frame
                // del aterrizaje (wssPrevGrounded), la bola ni la carga de
                // revoluciones (sus sprites pulsan y meterian ruido).
                var _spin = variable_instance_exists(id, "isSpinning") && isSpinning;
                var _charge = variable_instance_exists(id, "isSpinCharging") && isSpinCharging;
                
                if(!_spin && !_charge && isGrounded && wssPrevGrounded && sprite_index != wssPrevSpr)
                        wssSq = min(wssSq, -WSS_STATE_SQUASH);
        }
        else if(isGrounded && variable_instance_exists(id, "gspd"))
        {
                // Speed: postura continua por velocidad de carrera (asigno
                // absoluto cada frame, como el Lua; el |gspd| del jugador
                // acelera suave, asi que la transicion tambien es suave).
                wssSq = -min(WSS_SQUASH_MAX, abs(gspd) / WSS_SPEED_FULL * WSS_SQUASH_MAX);
        }
        
        // ---- vuelta al reposo ----
        // Mientras un estilo CONTINUO esta activo no decae (paridad con el
        // WSS_ReturnScale del Lua): airflow en el aire, speed en el suelo.
        var _hold = (WSS_STRETCH_STYLE == 1 && !isGrounded) || (WSS_SQUASH_STYLE == 2 && isGrounded);
        
        if(!_hold)
                scr_wss_return();
        
        // bookkeeping del frame
        wssPrevGrounded = isGrounded;
        wssPrevSpr = sprite_index;
}

// scr_wss_puppet_update — personajes REMOTOS (obj_player_puppet). Deriva
// la escala de datos que YA viajan: yspd (velocidad vertical real del
// dueno) y state (JUMP/FALL son constantes compartidas de scr_survivors,
// iguales para los 22 personajes). Solo eventos DISCRETOS (despegue /
// aterrizaje): los estilos continuos confundirian "correr por una
// pendiente" (yspd != 0 en el suelo) con "estar en el aire". Limitacion
// conocida: el salto en bola viaja como state SPIN, asi que esos saltos
// no estiran en las pantallas ajenas (en la del dueno si: su trigger es
// la fisica real, no el estado).
function scr_wss_puppet_update()
{
        if(!WSS_ENABLED)
                return;
        
        // Antes del primer paquete el puppet no tiene yspd: fuera. (state
        // si existe desde el Create; wss* las declara el Create v72.)
        if(!variable_instance_exists(id, "yspd"))
                return;
        
        var _air = (state == JUMP || state == FALL);
        
        // despegue: estaba en el suelo y ahora sube
        if(_air && !wssWasAir && yspd < -1.2)
                wssSq = max(wssSq, min(WSS_STRETCH_MAX, -yspd * WSS_TAKEOFF_GAIN));
        
        // aterrizaje: estaba en el aire y dejo de estarlo, con caida
        // registrada (el umbral 1.2 filtra el ruido del redondeo f16)
        if(!_air && wssWasAir && wssAirYspd > 1.2)
                wssSq = min(wssSq, -min(WSS_SQUASH_MAX, wssAirYspd * WSS_IMPACT_GAIN));
        
        if(_air)
                wssAirYspd = yspd;
        
        wssWasAir = _air;
        
        scr_wss_return();
}

// scr_wss_return — vuelta al reposo de wssSq (compartida por el jugador
// local y los puppets; opera sobre las variables de ESTA instancia).
function scr_wss_return()
{
        if(WSS_RETURN_STYLE == 0)
        {
                // Sharp: linear
                if(wssSq > 0)
                        wssSq = max(0, wssSq - WSS_SHARP_STEP);
                else if(wssSq < 0)
                        wssSq = min(0, wssSq + WSS_SHARP_STEP);
        }
        else if(WSS_RETURN_STYLE == 1)
        {
                // Smooth: exponencial (mismo feel del fase 2)
                wssSq += (0 - wssSq) * WSS_SMOOTH_DECAY;
                
                if(abs(wssSq) < 0.01)
                        wssSq = 0;
        }
        else
        {
                // Jelly: muelle amortiguado — rebota y se pasa un pelin
                // antes de asentarse (3 cruces, calibrado por simulacion:
                // 0.45 -> -0.138 -> asienta en 60 frames)
                wssVel += (0 - wssSq) * WSS_JELLY_K;
                wssVel *= WSS_JELLY_DAMP;
                wssSq += wssVel;
                
                if(abs(wssSq) < 0.01 && abs(wssVel) < 0.002)
                {
                        wssSq = 0;
                        wssVel = 0;
                }
        }
}

// scr_wss_draw — factores de dibujo del cuerpo de ESTA instancia.
// Devuelve [fx, fy, yoff]:
//   fx = 1 - wssSq * WSS_X_RATIO   (multiplicador horizontal)
//   fy = 1 + wssSq                 (multiplicador vertical)
//   yoff = anclaje al suelo para esa escalaY
// Sin datos WSS (primer frame antes del Step, sistema apagado, reposo)
// devuelve la identidad [1, 1, 0]: el draw queda exactamente como era.
// Se compone multiplicando con image_xscale/image_yscale (y con la escala
// del fase 2 en Sally Canon / puppets de Sally Canon).
function scr_wss_draw()
{
        if(!WSS_ENABLED || !variable_instance_exists(id, "wssSq") || wssSq == 0)
                return [1, 1, 0];
        
        var _fy = 1 + wssSq;
        var _fx = 1 - wssSq * WSS_X_RATIO;
        var _yoff = (sprite_height - sprite_yoffset) * (1 - _fy);
        
        return [_fx, _fy, _yoff];
}
