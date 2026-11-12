//
// Blur gaussiano separable (shd_blur).
// Un solo shader para horizontal y vertical: la direccion va en u_dir.
// 9 taps clasicos reducidos a 5 lecturas (aprovechando el sampling lineal).
//   u_texel : 1/ancho, 1/alto de la superficie de bloom (mitad de res)
//   u_dir   : (1,0) horizontal | (0,1) vertical
//   u_width : multiplicador de separacion (2a pasada mas ancha)
//
precision highp float;
precision highp int;

uniform vec2  u_texel;
uniform vec2  u_dir;
uniform float u_width;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
	vec2 o = u_texel * u_dir * u_width;

	vec3 c = texture2D(gm_BaseTexture, v_vTexcoord).rgb * 0.2270270270;
	c += texture2D(gm_BaseTexture, v_vTexcoord + o * 1.3846153846).rgb * 0.3162162162;
	c += texture2D(gm_BaseTexture, v_vTexcoord - o * 1.3846153846).rgb * 0.3162162162;
	c += texture2D(gm_BaseTexture, v_vTexcoord + o * 3.2307692308).rgb * 0.0702702703;
	c += texture2D(gm_BaseTexture, v_vTexcoord - o * 3.2307692308).rgb * 0.0702702703;

	gl_FragColor = vec4(c, 1.0);
}
