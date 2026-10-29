image_xscale = sign(dir);
x += dir * 4;
y += vdir;

if(!instance_exists(global.player))
	return;

if(place_meeting(x, y, global.player))
	// exeSource=true: habilidad del EXE (parry puede negarla)
	scr_player_hurt(20, -global.player.image_xscale * 4, -6, snd_hurt, spr_blood1, false, true);