#!/bin/bash
zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf | grep -EA13 "^STARTCHAR (zero|one|two|three|four|five|six|seven|eight|nine)$" | awk --non-decimal-data \
	'BEGIN {
       		digit=0; fontwidth=4; fontheight=6;
	       	print "#define DigitBin(x) ( \\"
       	}
	/^STARTCHAR/ { character=0; printf "x==" digit "?" }
	/^BITMAP/ { lineno=fontheight }
	/^..$/ { if (lineno > 0 ) {
       		line = rshift(sprintf("%d", "0x" $1), 8-fontwidth);
		character = or(character, lshift(line,fontwidth*(lineno-1)));
		lineno = lineno-1;
       	} }
	/^ENDCHAR/ { print character ".0:\\"; digit = digit+1 }
	END { print "0.0 )" }
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
