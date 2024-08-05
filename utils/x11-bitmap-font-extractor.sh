#!/bin/bash
x11_names_regex='space|period|zero|one|two|three|four|five|six|seven|eight|nine|question|[aefin]|minus'
ascii_repr=' .0123456789?aefin-'

zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf | grep -EA13 "^STARTCHAR ($x11_names_regex)$" \
	| awk --non-decimal-data -v ascii_repr="$ascii_repr" \
	'BEGIN {
        for(n=0;n<256;n++)ord[sprintf("%c",n)]=n;
		char_indice=1; font_width=4; font_height=6; def=0;
		indent="    "; indent2="        ";
        print "#ifndef DCB_FONT_VALUES"
        print "#define DCB_FONT_GLYPH_WIDTH " font_width
        print "#define DCB_FONT_GLYPH_HEIGHT " font_height
        print "#define DCB_FONT_VALUES \\"
	}
    /^STARTCHAR/ { 
        character=0;
        ascii_char=substr(ascii_repr,char_indice,1);
		if (ascii_char != "?" ) printf indent2 "/* " ascii_char " */ "
    }
	/^BITMAP/ { line_number=0 }
	/^..$/ {
        if (line_number < font_height ) {
            line = sprintf("%d", "0x" $1)
            character = or(character, lshift(line,font_width*(line_number)));
            line_number = line_number+1;
        }
    }
	/^ENDCHAR/ {
		if (ascii_char == "?" ) {
            def=character;
        } else {
            print character ".0, \\";
        }
		char_indice = char_indice+1;
	}
	END {
		print indent2 "/* ? */ " def ".0";
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
