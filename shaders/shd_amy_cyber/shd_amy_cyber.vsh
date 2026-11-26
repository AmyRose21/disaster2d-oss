//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // unused
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

uniform vec2  uPivot;    // punto de dibujo del sprite (x, y + yoff)
uniform vec2  uRot;      // (cos, sin) de la rotacion del sprite
uniform vec4  uRect;     // caja del sprite sin rotar, relativa al pivote: (x, y, ancho, alto)
uniform float uRectOK;   // 1 = uRect es valido

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_vLocal;   // 0..1 dentro de la caja del sprite (y = 1 en los pies)

void main()
{
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);

    v_vTexcoord = in_TextureCoord;
    v_vColour = in_Colour;

    // v82: coordenada DENTRO del sprite. Se des-rota alrededor del punto
    // de dibujo (rot positivo = antihorario en pantalla, lo mismo que
    // image_angle). El volteo no hace falta deshacerlo: el 0..1 sale bien
    // porque caja y posicion cambian de signo a la vez.
    vec2 d = in_Position.xy - uPivot;
    vec2 un = vec2(d.x * uRot.x - d.y * uRot.y, d.x * uRot.y + d.y * uRot.x);
    vec2 sz = max(abs(uRect.zw), vec2(1.0));

    v_vLocal = (un - uRect.xy) / sz * uRectOK;
}
