var ch = char;

if(char > CHARACTER_AMY_CANON)
{
	ch -= CHARACTER_AMY_CANON + 1;
	ch += PALETTE_EXE;
}
else if(demon)
	ch += PALETTE_DEMON;

ind++;
if(ind >= array_length(global.palettes[? ch]))
	ind = -1;