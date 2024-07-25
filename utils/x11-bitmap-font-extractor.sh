#!/bin/bash
x11_names_regex='period|zero|one|two|three|four|five|six|seven|eight|nine|question|[a-z]|minus'
ascii_repr='.0123456789?abcdefghijklmnopqrstuvwxyz-'

zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf | grep -EA13 "^STARTCHAR ($x11_names_regex)$" \
	| awk --non-decimal-data -v ascii_repr="$ascii_repr" \
	'BEGIN {
        for(n=0;n<256;n++)ord[sprintf("%c",n)]=n;
		char_indice=1; font_width=4; font_height=6; def=0;
		indent="    "; indent2="        ";
		print "// int font_width = " font_width ";"
		print "// int font_height = " font_height ";"
		print "float printValue_digitBin(int x) {"
		print indent "return ("
	}
    /^STARTCHAR/ { character=0; ascii_char=substr(ascii_repr,char_indice,1); printf indent2 "/* " ascii_char " */ x==" ord[ascii_char] "?" }
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
	/^ENDCHAR/ {
		print character ".0:";
		if (substr(ascii_repr,char_indice,1) == "?" ){ def=character }
		char_indice = char_indice+1;
	}
	END {
		print indent2 "/* default: ? */ " def ".0";
		print indent ");"
		; print "}"
	}
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
