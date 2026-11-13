//
// shd_negative — MODO NEGATIVO DE NEGAGEN (v8 Jina)
//
// Verificado pixel a pixel contra los sprites del build Negagen
// (spr_amynega_* / spr_eggnega_*): el "negativo" de Negagen es la
// INVERSION FOTOGRAFICA PURA del sprite original — 592/592 pixeles
// opacos coinciden exactamente con 1-x en el frame comparado. Ninguna
// paleta por personaje: una sola linea lo hace para cualquier sprite
// (cuerpo, barra de vida, retrato del HUD).
//
// u_keepDark (0 o 1): los retratos del HUD canon (spr_playerhealth_
// negademon*) CONSERVAN el contorno negro al pasar a nega — se
// dibujaron a mano en el build original. Con u_keepDark = 1 los
// pixeles casi negros (luminancia < 0.25) no se invierten: el retrato
// queda azulado pero con su contorno intacto, fiel al canon. El CUERPO
// usa 0 (inversion pura, contorno incluido: asi son los spr_*nega_*).
//

uniform float u_keepDark;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 colour = texture2D(gm_BaseTexture, v_vTexcoord);

    float lum = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
    if (u_keepDark < 0.5 || lum > 0.25)
        colour.rgb = vec3(1.0) - colour.rgb;

    gl_FragColor = v_vColour * colour;
}
