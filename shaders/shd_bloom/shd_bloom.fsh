//
// Extraccion de brillo para el bloom (shd_bloom).
// Se dibuja la application_surface (480x270) reescalada a la MITAD
// de resolucion: el shader muestrea 5 puntos en cruz del source para
// que el reescalado no pierda pixeles brillantes pequenos.
//   u_threshold : luminancia a partir de la cual un pixel "brilla"
//   u_soft      : anchura de la zona de transicion (rodilla suave)
//   u_texel     : 1/ancho, 1/alto del SOURCE (la app surface)
//
precision highp float;
precision highp int;

uniform vec2  u_texel;
uniform float u_threshold;
uniform float u_soft;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

float luma(vec3 c)
{
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main()
{
	vec3 c = texture2D(gm_BaseTexture, v_vTexcoord).rgb * 0.36;
	c += texture2D(gm_BaseTexture, v_vTexcoord + vec2( u_texel.x, 0.0)).rgb * 0.16;
	c += texture2D(gm_BaseTexture, v_vTexcoord + vec2(-u_texel.x, 0.0)).rgb * 0.16;
	c += texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0,  u_texel.y)).rgb * 0.16;
	c += texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, -u_texel.y)).rgb * 0.16;

	float b = luma(c);

	// rodilla suave: 0 por debajo de (threshold - soft/2), 1 por encima
	// de (threshold + soft/2), rampa smoothstep en medio
	float lo = u_threshold - u_soft * 0.5;
	float hi = u_threshold + u_soft * 0.5;
	float k  = clamp((b - lo) / max(hi - lo, 0.0001), 0.0, 1.0);
	k = k * k * (3.0 - 2.0 * k);

	gl_FragColor = vec4(c * k, 1.0);
}
