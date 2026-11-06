var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
sprite_index = arr[? CHARACTER_BLAZE][state];

switch(state)
{
	case IDLE:
		image_speed = 1;
		break;

	case HURT:
		image_speed = 0;
		image_index = 0;
		break;

	case BALANCING:
		image_xscale = edgeDir;
		image_speed = 1;
		break;

	case FALL:
		// (MUELLES): frames de subida/bajada configurados con la
		// Suite (global.fallAnims en scr_survivors.gml)
		scr_fall_anim();
		break;

	case WALK:
		image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
		break;

	case RUN:
	case JUMP:
		image_speed = max(abs(xspd) / 20, 0.5);
		break;

	case LOOKUP:
	case LOOKDOWN:
		image_speed = 0.2;

		// Stop on last frame
		if(image_index >= 1)
			image_index = 1;

		break;

	case SPIN:
		image_speed = abs(xspd) / 5;
		break;
	case BLAZE_SHOOT:
		image_speed = 1;

		if(image_index >= image_number - 1)
			image_index = image_number - 1;
		break;

	case BLAZE_BURNING:
		image_speed = 0.7;
		break;
}
