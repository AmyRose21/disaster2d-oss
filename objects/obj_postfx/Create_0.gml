/// obj_postfx - controlador de post-proceso (bloom + grading).
// Persistente: lo crea obj_logo al arrancar y vive toda la sesion.
// El efecto es 100% visual del cliente: el server no interviene.

// ================== AJUSTES (calibra a tu gusto) ==================
// BLOOM (resplandor de los pixeles brillantes)
threshold  = 0.72;   // luminancia minima para brillar (0-1); mas bajo = mas cosas brillan
softKnee   = 0.35;   // suavidad del umbral (0 = corte duro)
bloomPower = 0.60;   // cuanto glow se suma (alpha del blend aditivo)

// COLOR ("profundidad")
saturation = 1.14;   // 1 = sin cambio; >1 = colores mas vivos
contrast   = 1.06;   // 1 = sin cambio; >1 = mas punch
liftS      = 0.030;  // azul anadido a las sombras
liftH      = 0.025;  // calor anadido a las luces

// AMBIENTE
vignette   = 0.28;   // oscurecido del anillo exterior (0 = nada)
aberration = 1.5;    // separacion RGB en texels del source (0 = nada)
// ==================================================================

enabled = true;

// superficies de trabajo (la mitad de resolucion que la app surface;
// se crean bajo demanda en el Draw_77 porque en Android la app surface
// se redimensiona al arrancar)
surfA = -1;
surfB = -1;
surfW = 0;
surfH = 0;

// el motor NO debe dibujar la app surface: la dibujamos nosotros con
// los shaders (mismo patron que obj_marijuna_crystalcontroller)
application_surface_draw_enable(false);

// uniforms de los 3 shaders
uBloomTexel  = shader_get_uniform(shd_bloom, "u_texel");
uBloomThresh = shader_get_uniform(shd_bloom, "u_threshold");
uBloomSoft   = shader_get_uniform(shd_bloom, "u_soft");
uBlurTexel   = shader_get_uniform(shd_blur, "u_texel");
uBlurDir     = shader_get_uniform(shd_blur, "u_dir");
uBlurWidth   = shader_get_uniform(shd_blur, "u_width");
uGradeSat    = shader_get_uniform(shd_grade, "u_sat");
uGradeCon    = shader_get_uniform(shd_grade, "u_con");
uGradeVig    = shader_get_uniform(shd_grade, "u_vig");
uGradeCA     = shader_get_uniform(shd_grade, "u_ca");
uGradeTexel  = shader_get_uniform(shd_grade, "u_texel");
uGradeLiftS  = shader_get_uniform(shd_grade, "u_liftS");
uGradeLiftH  = shader_get_uniform(shd_grade, "u_liftH");

depth = -99999;