var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
sprite_index = arr[? CHARACTER_METAL][state];

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
		image_speed = 0.15 + min(abs(yspd), 12) * 0.02;
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
	case METAL_ATTACK:
		image_speed = 1;

		if(xspd > 0)
			image_xscale = 1;
		else if(xspd < 0)
			image_xscale = -1;
		break;

	case METAL_ELECTRO:
		image_speed = 0.8;
		break;
}
