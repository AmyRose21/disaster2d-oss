/// Post-proceso: bloom + grading. Mismo evento y mismo patron que
/// obj_marijuna_crystalcontroller: aqui la app surface ya esta
/// completa y se dibuja escalada a la ventana.

if(!enabled)
	return;
if(!surface_exists(application_surface))
	return;

// El mapa marijuna tiene su propio efecto de shader a pantalla
// completa: no lo tapamos con nuestra composicion
if(instance_exists(obj_marijuna_crystalcontroller))
	return;

// ---- superficies de trabajo (mitad de la resolucion) ----
var _aw = surface_get_width(application_surface);
var _ah = surface_get_height(application_surface);
var _bw = max(1, _aw div 2);
var _bh = max(1, _ah div 2);

if(!surface_exists(surfA) || !surface_exists(surfB) || surfW != _bw || surfH != _bh)
{
	if(surface_exists(surfA))
		surface_free(surfA);
	if(surface_exists(surfB))
		surface_free(surfB);

	surfA = surface_create(_bw, _bh);
	surfB = surface_create(_bw, _bh);
	surfW = _bw;
	surfH = _bh;
}

// ---- destino en ventana (letterbox en Android, como el marijuna) ----
var _ww = window_get_width();
var _wh = window_get_height();
var _dx = 0;
var _dy = 0;
var _dw = _ww;
var _dh = _wh;

if(os_type == os_android)
{
	var _ar = _ww / _wh;
	var _va = _aw / _ah;

	if(_ar > _va)
	{
		var _s = _wh / _ah;
		_dw = _aw * _s;
		_dh = _wh;
		_dx = (_ww - _dw) / 2;
	}
	else
	{
		var _s = _ww / _aw;
		_dw = _ww;
		_dh = _ah * _s;
		_dy = (_wh - _dh) / 2;
	}
}

// ---- estado GPU: suavizado para el glow, reset del blend ----
var _tf = gpu_get_texfilter();
gpu_set_blendmode(bm_normal);
gpu_set_texfilter(true);

// ---- 1) extraccion de brillo (app surface -> surfA, mitad) ----
surface_set_target(surfA);
shader_set(shd_bloom);
shader_set_uniform_f(uBloomTexel, 1 / _aw, 1 / _ah);
shader_set_uniform_f(uBloomThresh, threshold);
shader_set_uniform_f(uBloomSoft, softKnee);
draw_surface_stretched(application_surface, 0, 0, _bw, _bh);
shader_reset();
surface_reset_target();

// ---- 2) blur separable en 3 pasadas progresivas (halo suave) ----
shader_set(shd_blur);
shader_set_uniform_f(uBlurTexel, 1 / _bw, 1 / _bh);

surface_set_target(surfB);
shader_set_uniform_f(uBlurDir, 1, 0);
shader_set_uniform_f(uBlurWidth, 1.0);
draw_surface_stretched(surfA, 0, 0, _bw, _bh);

surface_set_target(surfA);
shader_set_uniform_f(uBlurDir, 0, 1);
shader_set_uniform_f(uBlurWidth, 1.0);
draw_surface_stretched(surfB, 0, 0, _bw, _bh);

surface_set_target(surfB);
shader_set_uniform_f(uBlurDir, 1, 0);
shader_set_uniform_f(uBlurWidth, 2.2);
draw_surface_stretched(surfA, 0, 0, _bw, _bh);

surface_set_target(surfA);
shader_set_uniform_f(uBlurDir, 0, 1);
shader_set_uniform_f(uBlurWidth, 2.2);
draw_surface_stretched(surfB, 0, 0, _bw, _bh);

surface_set_target(surfB);
shader_set_uniform_f(uBlurDir, 1, 0);
shader_set_uniform_f(uBlurWidth, 4.4);
draw_surface_stretched(surfA, 0, 0, _bw, _bh);

surface_set_target(surfA);
shader_set_uniform_f(uBlurDir, 0, 1);
shader_set_uniform_f(uBlurWidth, 4.4);
draw_surface_stretched(surfB, 0, 0, _bw, _bh);

shader_reset();
surface_reset_target();

// ---- 3) base + grading (app surface -> ventana) ----
gpu_set_texfilter(false);
shader_set(shd_grade);
shader_set_uniform_f(uGradeSat, saturation);
shader_set_uniform_f(uGradeCon, contrast);
shader_set_uniform_f(uGradeVig, vignette);
shader_set_uniform_f(uGradeCA, aberration);
shader_set_uniform_f(uGradeTexel, 1 / _aw, 1 / _ah);
shader_set_uniform_f(uGradeLiftS, liftS);
shader_set_uniform_f(uGradeLiftH, liftH);
draw_surface_stretched(application_surface, _dx, _dy, _dw, _dh);
shader_reset();

// ---- 4) glow aditivo (surfA -> ventana, por encima de la base) ----
gpu_set_texfilter(true);
gpu_set_blendmode(bm_add);
draw_surface_ext(surfA, _dx, _dy, _dw, _dh, 0, c_white, bloomPower);
gpu_set_blendmode(bm_normal);

gpu_set_texfilter(_tf);