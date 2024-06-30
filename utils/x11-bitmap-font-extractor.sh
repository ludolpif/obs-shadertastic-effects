#!/bin/bash
x11_names_regex='period|zero|one|two|three|four|five|six|seven|eight|nine|question|minus|[a-z]'
ascii_repr='.0123456789?-abcdefghijklmnopqrstuvwxyz'

zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf | grep -EA13 "^STARTCHAR ($x11_names_regex)$" \
	| awk --non-decimal-data -v ascii_repr="$ascii_repr" \
	'BEGIN {
		char_indice=1; font_width=4; font_height=6; indent="        ";
		print "#define font_width " font_width ".0"
		print "#define font_height " font_height ".0"
	       	print "#define DigitBin(x) ( \\"
       	}
	/^STARTCHAR/ { character=0; printf indent "x=='\''" substr(ascii_repr,char_indice,1) "'\''?" }
	/^BITMAP/ { line_number=font_height }
	/^..$/ { if (line_number > 0 ) {
		parsed = sprintf("%d", "0x" $1)
		line = 0
		for (i=0; i<8; i++) {
			bit = and(rshift(parsed, i),1)
			line = or(lshift(line,1), bit)
		}
		character = or(character, lshift(line,font_width*(line_number-1)));
		line_number = line_number-1;
       	} }
	/^ENDCHAR/ { print character ".0:\\"; char_indice = char_indice+1 }
	END { print indent "0.0 )" }
'
#STARTCHAR nine
#ENCODING 57
#SWIDTH 640 0
#DWIDTH 4 0
#BBX 4 6 0 -1
#BITMAP
#40
#A0
#60
#20
#C0
#00
#ENDCHAR
