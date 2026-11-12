//
// Grading final (shd_grade): la app surface se dibuja escalada a la
// ventana con estos retoques de "profundidad":
//   1. aberracion cromatica radial sutil (u_ca, en texels del source)
//   2. split-tone: sombras levemente frias (u_liftS), luces calidas (u_liftH)
//   3. saturacion (u_sat) y contraste (u_con) alrededor del gris medio
//   4. vineta suave, solo el anillo exterior (u_vig)
//
precision highp float;
precision highp int;

uniform float u_sat;
uniform float u_con;
uniform float u_vig;
uniform float u_ca;
uniform vec2  u_texel;
uniform float u_liftS;
uniform float u_liftH;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
	// aberracion cromatica: separacion radial, 0 en el centro
	vec2 off = u_texel * u_ca * (v_vTexcoord - vec2(0.5)) * 2.0;
	vec3 col;
	col.r = texture2D(gm_BaseTexture, v_vTexcoord + off).r;
	col.g = texture2D(gm_BaseTexture, v_vTexcoord).g;
	col.b = texture2D(gm_BaseTexture, v_vTexcoord - off).b;

	// split-tone: sombras frias, luces calidas
	float l = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col.r += u_liftH * l;
	col.b += u_liftS * (1.0 - l);

	// saturacion
	l = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(l), col, u_sat);

	// contraste alrededor del gris medio
	col = (col - 0.5) * u_con + 0.5;

	// vineta suave (r = 0 en el centro, 1.0 en la esquina)
	vec2 d = v_vTexcoord - vec2(0.5);
	float r = length(d) * 1.4142;
	col *= 1.0 - u_vig * smoothstep(0.55, 1.15, r);

	gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
