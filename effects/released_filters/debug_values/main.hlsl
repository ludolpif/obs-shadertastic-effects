// Common parameters for all shaders, as reference. Do not uncomment this (but you can remove it safely).
/*
uniform float time;            // Time since the shader is running. Goes from 0 to 1 for transition effects; goes from 0 to infinity for filter effects
uniform texture2d image;       // Texture of the source (filters only)
uniform texture2d tex_interm;  // Intermediate texture where the previous step will be rendered (for multistep effects)
uniform float upixel;          // Width of a pixel in the UV space
uniform float vpixel;          // Height of a pixel in the UV space
uniform float rand_seed;       // Seed for random functions
uniform int current_step;      // index of current step (for multistep effects)
*/

// Specific parameters of the shader. They must be defined in the meta.json file next to this one.
uniform bool should_print_grid;
uniform bool should_print_font_test;
uniform float debug_value;
uniform float font_size;
uniform int coord_mode;
uniform float pixel_u;
uniform float pixel_v;
uniform int pixel_x;
uniform int pixel_y;

/* #include "../../shadertastic-lib/geometry/inside_box.hlsl" */
#ifndef _INSIDE_BOX_HLSL
#define _INSIDE_BOX_HLSL
/**
 * Returns true if v is included in the rectangle defined by left_top (inclusive) and right_bottom (exclusive)
 * Alternative definition : with left_top.x <= right_bottom.x and left_top.y <= right_bottom.y,
 *  it returns ( left_top.x <= v.x < right_bottom.x && left_top.y <= v.y < right_bottom.y )
 * Behavior on limits is tricky if left_top.x > right_bottom.x or left_top.y > right_bottom.y
 * @param v coordinates of a point to test
 * @param left_top coordinates of the top left corner of the rectangle
 * @param right_bottom coordinates of the bottom right corner of the rectangle
 */
bool inside_box(float2 v, float2 left_top, float2 right_bottom) {
    float2 s = step(left_top, v) - step(right_bottom, v);
    return s.x * s.y != 0.0;
}
#endif /* _INSIDE_BOX_HLSL */

/* #include "../../shadertastic-lib/debug/print_glyph.hlsl" */
#ifndef _PRINT_GLYPH_HLSL
#define _PRINT_GLYPH_HLSL
/* Inspired from https://www.shadertoy.com/view/3lGBDm ; Licensed under CC BY-NC-SA 3.0
    Font extracted with : zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf
    See: https://github.com/ludolpif/obs-shadertastic-effects/blob/main/utils/x11-bitmap-font-extractor.sh
   You might like https://www.shadertoy.com/view/7dfyRH (I discovered it lately, use font texture).

    Primarily written for OBS Shadertastic plugin (shader library for live streaming with OBS Studio)
    See: https://shadertastic.com
*/
#ifndef DEBUG_FONT_GLYPHS
#define DEBUG_FONT_GLYPH_WIDTH 4
#define DEBUG_FONT_GLYPH_HEIGHT 6
#define DEBUG_FONT_GLYPHS \
        /*" "*/ 0, \
        /* + */ 320512, \
        /* . */ 4194304, \
        /* 0 */ 4909632, \
        /* 1 */ 14961728, \
        /* 2 */ 14953024, \
        /* 3 */ 12731104, \
        /* 4 */ 2288288, \
        /* 5 */ 12765408, \
        /* 6 */ 4900960, \
        /* 7 */ 8930016, \
        /* 8 */ 13257312, \
        /* 9 */ 12741184, \
        /* a */ 6989312, \
        /* b */ 13282432, \
        /* c */ 6850048, \
        /* d */ 6989344, \
        /* e */ 7119872, \
        /* f */ 4514848, \
        /* i */ 14991424, \
        /* n */ 11185152, \
        /* x */ 10766848, \
        /* - */ 57344, \
        /* ? */ 4211392
#endif /* DEBUG_FONT_GLYPHS */
/* Note : '+' is 4514880 from the x11 font + script, but it's ugly, manually changed here. */

/**
 * Returns a point in the text_coords space from uv space taking ratio, origin, offset and text height into account.
 *  text_coords has integer part that represent a glyph, and fractionnal part for glyph pixels.
 *  text_coords[0] goes from right to left (as numbers digit powers/positions goes)
 *  text_coords[1] goes from top to bottom (as lines in a terminal)
 * @param uv point in uv space, should be in [0.0,1.0]²
 * @param uv_grid_origin point in uv space that becomes the origin [0.0,0.0] in text_coord space
 * @param uv_aspect_ratio ratio to keep glyph pixels as square in case of non square target texture
 * @param uv_line_height font size expressed as a fraction of target texture height
 *  (1.0: one line of text occupies the full texture height. 0.1: ten lines of text avaiable in the texture height)
 * @param text_offset offset in text_coords space to ease text positionning in a glyph size unit
 */
float2 debug_get_text_coords_from_uv(in float2 uv, in float2 uv_grid_origin, in float uv_aspect_ratio,
        in float uv_line_height, in int2 text_offset) {
    float font_ratio = float(DEBUG_FONT_GLYPH_HEIGHT)/float(DEBUG_FONT_GLYPH_WIDTH);
    return (uv - uv_grid_origin)*float2(-uv_aspect_ratio*font_ratio, 1.0)/uv_line_height - float2(text_offset);
}

/**
 * returns the wanted_digit integer number from a text_coords point for debug_decode_* functions.
 *  wanted_digit convention for int: 0 will be units, 1 tens, 2 hundreds...
 *  wanted_digit convention for floats : 0 will be '.', 1 units, 2 tens... -1 first digit of fractionnal part...
 * @param text_coords the text_coords point from current uv space point (see debug_get_text_coords_from_uv)
 * @param text_offset offset in text_coords space to ease text positionning in a glyph size unit
 */
int debug_get_wanted_digit_from_text_coords(in float2 text_coords, int2 text_offset) {
    //note: floor() will make a double wanted_digit==0 for text_coords in [-1.0;1.0], round() will not but needs -0.5
    return int(round(text_coords.x-0.5)) - text_offset.x;
}

/**
 * returns true if text_coords is the rectangle defined by text_offset and text_len, considering only one line of text
 * @param text_coords current point in text_coords space
 * @param text_offset offset in text_coords space to ease text positionning in a glyph size unit
 * @param text_len maximum number of glyphs to be expected on the text field
 */
bool debug_inside_text_box(in float2 text_coords, in int2 text_offset, in int text_len) {
    return inside_box(text_coords, float2(text_offset), float2(text_offset.x + text_len, text_offset.y + 1));
}

/**
 * returns an rgba pixel value to display the pixel at text_coords of a text grid.
 *  Meant to help choosing parameters for debug_get_text_coords_from_uv().
 *  Not really for final render.
 * @param rgba pixel value to return of the current text_coords is not on the grid
 * @param text_coords current point in text_coords space
 * @param text_offset should be same as text_offset in debug_get_text_coords_from_uv() call
 * @param cols_neg number of columns on the right of (0,0) character
 * @param lines_neg number of lines over the (0,0) character
 * @param cols_pos number of columns on the left of (0,0) character
 * @param lines_pos number of lines below the (0,0) character
 */
float4 debug_print_text_grid(in float4 rgba, in float2 text_coords, in int2 text_offset,
        in int cols_neg, in int lines_neg, in int cols_pos, in int lines_pos) {
    // Make lines width thick like 1 pixel in font
    float2 line_width = 1.0/float2(DEBUG_FONT_GLYPH_WIDTH,DEBUG_FONT_GLYPH_HEIGHT);

    // Don't draw anything if we are computing a pixel outside of the grid rectangle
    float2 left_top = float2(cols_neg, lines_neg);
    float2 right_bottom = float2(cols_pos, lines_pos) + line_width;
    if ( !inside_box(text_coords, left_top, right_bottom) ) {
        return rgba;
    }

    // Highlight the uv-spaced anchor of the grid
    if ( inside_box(text_coords + float2(text_offset), float2(0.0, 0.0), line_width) ) {
        return float4(0.0, 0.0, 1.0, 1.0);
    }
    // Print the grid
    if ( frac(text_coords.x) < line_width.x || frac(text_coords.y) < line_width.y ) {
        return float4(0.2, 0.2, 0.2, 1.0);
    }
    // Make the character at origin with a dark background
    if ( debug_inside_text_box(text_coords, int2(0,0), 1) ) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }
    // Make a gray background for the whole grid
    return float4(0.3, 0.3, 0.3, 1.0);
}

/**
 * returns true if a debug pixel should be printed on target texture.
 *  Alternative definition: return glyph_bit from the glyph at glyph_index in font for the position given by text_coords.
 * @param text_coords the text_coords point from current uv space point (see debug_get_text_coords_from_uv)
 * @param glyph_index index of the glyph to display from the array made from DEBUG_FONT_GLYPHS
 */
bool debug_print_glyph(in float2 text_coords, in int glyph_index) {
#ifdef _OPENGL
    const int font[24] = int[24](DEBUG_FONT_GLYPHS);
#else
    static int font[24] = {DEBUG_FONT_GLYPHS};
#endif
    int2 bit_coord = int2( frac(text_coords) * float2(DEBUG_FONT_GLYPH_WIDTH, DEBUG_FONT_GLYPH_HEIGHT) );
    int bit_number = bit_coord.y * DEBUG_FONT_GLYPH_WIDTH + bit_coord.x;

    int i = (glyph_index >= 0 && glyph_index < 24)?glyph_index:23;
    return (font[i] >> bit_number & 1) == 1;
}
#endif /* _PRINT_GLYPH_HLSL */

/* #include "../../shadertastic-lib/debug/decode_int.hlsl" */
#ifndef _DECODE_INT_HLSL
#define _DECODE_INT_HLSL
/**
 * returns a glyph_index to use with debug_print_glyph() to make a rudimentary printf("%d",int_to_decode), one wanted_digit at a time.
 * @param int_to_decode int value to be decoded as a decimal number
 * @param wanted_digit digit number you want to get from int_to_decode (0: units, 1: tens, 2: hundreds...)
 * @param total_digits int_to_decode will be displayed on total_digits digits + 1 for sign, with leading 0's.
 */
int debug_decode_int_decimal_fixed(in int int_to_decode, in int wanted_digit, in int total_digits) {
#ifdef _OPENGL
    const int pow10_table[10] = int[10](1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000);
#else
    static int pow10_table[10] = {1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000};
#endif
    if ( total_digits < 1 ) total_digits = 1;
    int glyph_index;
    if ( wanted_digit < 0 || wanted_digit > total_digits ) {
        glyph_index = 0; // for ' '
    } else if ( wanted_digit == total_digits ) {
        glyph_index = int_to_decode<0?22:1; // for '-' or '+'
    } else if ( wanted_digit == 9 ) {
        glyph_index = 3 + abs(int_to_decode) / pow10_table[9];
    } else {
        int pow10_next = pow10_table[wanted_digit+1];
        int pow10_curr = pow10_table[wanted_digit];
        glyph_index = 3 + ( abs(int_to_decode) % pow10_next ) / pow10_curr;
    }
    return glyph_index;
}

/**
 * returns a glyph_index to use with debug_print_glyph() to make a rudimentary printf("%d",int_to_decode), one wanted_digit at a time.
 *  This is a wrapper for debug_decode_int_decimal_fixed() trying to guess the right total_digits for you.
 *  for a few int_to_decode values, it may lead to print one spurious leading non-significative 0
 *  because it uses approximations (log2(x)/log2(10)) to compute total_digits.
 * @param int_to_decode int value to be decoded as a decimal number
 * @param wanted_digit digit number you want to get from int_to_decode (0: units, 1: tens, 2: hundreds...)
 */
int debug_decode_int_decimal(in int int_to_decode, in int wanted_digit) {
    // Note: total_digits estimation is not always exact, may a leading 0 could appear
    int total_digits = 1 + int(log2(abs(float(int_to_decode)))/log2(10.0));
    return debug_decode_int_decimal_fixed(int_to_decode, wanted_digit, total_digits);
}

/**
 * returns a glyph_index to use with debug_print_glyph() to make a rudimentary printf("%x",int_to_decode), one wanted_digit at a time.
 * @param int_to_decode int value to be decoded as an hexadecimal number
 * @param wanted_digit digit number you want to get from int_to_decode (0: first hex digit, least significate, 1: second hex digit...)
 * @param total_digits int_to_decode will be displayed on total_digits digits + 2 for "0x" prefix.
 */
int debug_decode_int_hexadecimal_fixed(in int int_to_decode, in int wanted_digit, in int total_digits) {
    int glyph_index = 0; // for ' '
    if ( total_digits < 1 ) total_digits=1;
    if ( wanted_digit == total_digits+1 ) {
        glyph_index = 3; // for '0'
    } else if ( wanted_digit == total_digits ) {
        glyph_index = 21; // for 'x'
    } else if ( wanted_digit >= 0 && wanted_digit < total_digits) {
        glyph_index = 3 + (int_to_decode >> (wanted_digit*4)) % 16; // for [0-9a-f]
    }
    return glyph_index;
}
/**
 * returns a glyph_index to use with debug_print_glyph() to make a rudimentary printf("%b",int_to_decode), one wanted_digit at a time.
 * @param int_to_decode int value to be decoded as an binary number
 * @param wanted_digit digit number you want to get from int_to_decode (0: least significant bit, 1: second bit...)
 * @param total_digits int_to_decode will be displayed on total_digits digits + 2 for "0b" prefix.
 */
int debug_decode_int_binary_fixed(in int int_to_decode, in int wanted_digit, in int total_digits) {
    int glyph_index = 0; // for ' '
    if ( total_digits < 1 ) total_digits=1;
    if ( wanted_digit == total_digits+1 ) {
        glyph_index = 3; // for '0'
    } else if ( wanted_digit == total_digits ) {
        glyph_index = 14; // for 'b'
    } else if ( wanted_digit >= 0 && wanted_digit < total_digits) {
        glyph_index = 3 + (int_to_decode >> wanted_digit) % 2; // for '0' or '1'
    }
    return glyph_index;
}
#endif /* _DECODE_INT_HLSL */

/* #include "../../shadertastic-lib/debug/decode_float_internals.hlsl" */
#ifndef _DECODE_FLOAT_INTERNALS_HLSL
#define _DECODE_FLOAT_INTERNALS_HLSL
/**
 * returns the "sign" bitfield as encoded in IEEE754 floats. 0b0: positive numbers, 0b1:negative numbers.
 *  Internally used by debug_decode_float(). You should not need to call this function directly.
 * @param float_to_decode float from which we want field extraction
 */
int debug_decode_float_sign(in float float_to_decode) {
    return
        float_to_decode < 0.0?1:
        float_to_decode > 0.0?0:
        (1.0 / float_to_decode < 1.0)?1: // for -0.0
        0; // for +0.0
    // note: -0.0 is not < +0.0 if using comparison operators
}

/**
 * returns a fixed-point decimal reprensentation of a certain mantissa power of two (adjusted by exp)
 *  Internally used by debug_decode_float(). You should not need to call this function directly.
 *  The first int is integer part, the second is fractionnal part.
 *  For fractionnal part, a +9 implied decimal fraction digits is used.
 *  So, to get the canonical representation, divide the fractionnal part value value by 10^9.
 *  This function will return wrong integer part if mantissa_pow > 30.0
 *    and 0 fractionnal part if mantissa_pow < -29.0.
 * @param mantissa_pow the mantissa power of two (adjusted by exp) to retreive (max 30.0).
 */
int2 debug_decode_float_mantissa_to_fixed_point(in float mantissa_pow) {
    int fpart = int(clamp(-mantissa_pow, 0.0, 31.0));
    int ipart = int(clamp( mantissa_pow, 0.0, 31.0));
    return int2( 1 << ipart >> fpart, (1000000000 >> fpart)%1000000000 );
    /*
     * note: two tricks are used here to not have conditionnal branches on this code called frequently
     *  ">> fpart"  makes result[0] equals to 0 (and not 1)   for all strictly negative mantissa_pow
     *  %1000000000 makes result[1] equals to 0 (and not 1e9) for all strictly positive mantissa_pow
     */
}

/**
 * returns a glyph_index for a special float value described by glyphs, at wanted_digit.
 *  Internally used by debug_decode_float(). You should not need to call this function directly.
 *  It's for +/-inf, +/-nan, +/-0.0.
 * @param sign Sign of the specal value
 * @param glyphs triplet of glyph indices needed for the current float special value to display
 * @param wanted_digit digit number you want to get from glyphs triplet (from 2 to -1 to center nicely, including sign)
 */
int debug_format_float_special_values(in int sign, in int3 glyphs, in int wanted_digit) {
    return
        wanted_digit==2?(sign==1?22:1): // for '-' or '+'
        wanted_digit==1?glyphs[0]:
        wanted_digit==0?glyphs[1]:
        wanted_digit==-1?glyphs[2]:
        0;
}
#endif /* _DECODE_FLOAT_INTERNALS_HLSL */

/* #include "../../shadertastic-lib/debug/decode_float.hlsl" */
#ifndef _DECODE_FLOAT_HLSL
#define _DECODE_FLOAT_HLSL
/**
 * returns a glyph_index to use with debug_print_glyph() to make a rudimentary printf("%f",float_to_decode), one wanted_digit at a time.
 *  This function has many out paramters to get as many details as possible from float_to_decode.
 *  With IEEE754 floats on 32 bits, biggest is -/+3.4028235e38, tiniest non-zero is -/+1e-45.
 * @param float_to_decode int value to be decoded as a decimal number with fractionnal part
 * @param wanted_digit digit number you want to get from int_to_decode (1: units, 2: tens, -1: first fractionnal digit...)
 * @param integer_digits number of digit to display for the integer part of float_to_decode (max 9)
 * @param fractionnal_digits number of digit to display for the fractionnal part of float_to_decode (max 8)
 * @param sign outputs the sign bit as encoded in IEE754
 * @param exp outputs the exp bitfield as encoded in IEE754 (=expf+127 encoded on unsigned int of 8 bits)
 * @param mant outputs the mantissa bitfield as encoded in IEE754 (23 bits, the 24th bit is always 1 and is implicit)
 * @param signi outputs the sign as a integer directly usable to multiply numbers against (-1:negative, +1:positive)
 * @param expf outputs the exponent with IEEE754 offset, as float (but will never have any fractionnal part)
 * @param fixed_point outputs the fixed point reprensentation of float_to_decode
 *  (limited with 9 digits for integer part and 8 for fractionnal part)
 * @param glyph_index outputs the glyph index for in wanted_digit of float_to_decode to use with debug_print_glyph()
 */
void debug_decode_float(in float float_to_decode, in int wanted_digit, in int integer_digits, in int fractionnal_digits,
        out int sign, out int exp, out int mant, out int signi,
        out float expf, out int2 fixed_point, out int glyph_index)
{
    // Floats numbers are coded in IEEE754 in a way roughly representable as signi*2^expf*(1+mantissa_fractionnal)
    sign = debug_decode_float_sign(float_to_decode);
    signi = sign==1?-1:1;

    // Before exponent extraction, eliminate special cases on which log2(x) will not be useful
    if ( float_to_decode == 0.0 ) {
        expf = -126.0; exp = 0; mant = 0; fixed_point = int2(0,0);
        glyph_index = debug_format_float_special_values(sign, int3(3,2,3), wanted_digit); // for " +0.0 "
        return;
    }
    if ( isnan(float_to_decode) || isinf(float_to_decode) ) {
        expf = float_to_decode; // non-finite value as a placeholder
        exp = 255; mant = 0; fixed_point = int2(0,0);
        int3 glyphs = isnan(float_to_decode)?int3(20,13,20):int3(19,20,18); // for "nan" or "inf"
        glyph_index = debug_format_float_special_values(sign, glyphs, wanted_digit);
        return;
    }
    float float_to_decode_abs = abs(float_to_decode);
    // We will transform float_to_decode to conveniently decode it, do it in a copy for clarity
    float float_tmp = float_to_decode_abs;

    // Exponent extraction (for all finite cases)
    expf = floor(log2(float_tmp)); // float exponent without -127 offset (out parameter)
    exp = int(expf) + 127; // IEEE754 encoded 8bits-wide exponent (out parameter)

    // Extract the mantissa bit per bit, compute the fixed_point value simultaneously
    // using only float values that are exactly represented in IEEE754 encoding (powers of two)
    mant = 0; // IEEE754 23bits-wide mantissa as int without the leading implicit one
    //fixed_point: limited range fixed point representation with 8 decimals for floats in [-1e10-1 ; 1e10-1]
    fixed_point = debug_decode_float_mantissa_to_fixed_point(expf);
    // The 1 is always implicit in the sense that no bit represent it in the mantissa nor exponent bitfields
    float mantissa_implicit_one = pow(2.0, expf);
    for ( int i = 1; i < 24; i++ ) {
        mant *= 2;
        float mantissa_pow = expf - float(i);
        float mantissa_fractionnal = pow(2.0, mantissa_pow); // All power of two are exactly representable (mant==0, exp varies)
        float crible = mantissa_implicit_one + mantissa_fractionnal;
        if ( float_tmp >= crible ) {
            float_tmp -= mantissa_fractionnal;
            mant += 1;
            // Fixed point is split into integer part and fractionnal part
            // The way the floats are encoded garantee there is not carry to handle between those two parts
            fixed_point += debug_decode_float_mantissa_to_fixed_point(mantissa_pow);
        }
    }
    //TODO may the user want to round are arbitraty number of digit, allow it, this may lead to carry for fixed_point[0]
    // Manually round fixed_point fractionnal part from 9 to 8 digits because the 9th digit
    //  is not always exact with the table we use (and we can't put 5e9 in int)
    int to_be_rounded = fixed_point[1];
    if ( to_be_rounded % 10 >= 5 ) to_be_rounded += 10;
    fixed_point[1] = to_be_rounded / 10;

    // To ease a rudimentary printf("%f",x) this function output glyph_index, the character index to display at wanted_digit position
    //TODO make number of digits on integer and fractionnal part configurable by the user (max 9 and 8)
    /* Note: next if() need to be at least as restrictive as preconditions
     * of debug_decode_float_mantissa_to_fixed_point() to not display wrong results
     */
    if ( float_to_decode_abs >= 0.00000001 && float_to_decode_abs < 1000000000.0 ) {
        // print a natural form
        if ( wanted_digit < -8 || wanted_digit > 10 ) {
            glyph_index = 0; // for ' '
        //} else if ( wanted_digit == 10 ) {
    //FIXME do use integer/fractionnal_digits arg
        } else if ( wanted_digit == 5 ) {
            glyph_index = (sign==1?22:1); // for '-' or '+'
        } else if ( wanted_digit > 0 ) {
            glyph_index = debug_decode_int_decimal_fixed(fixed_point[0], wanted_digit-1, 9);
        } else if ( wanted_digit == 0 ) {
            glyph_index = 2; // for '.'
        } else /* ( wanted_digit < 0 ) */ {
            glyph_index = debug_decode_int_decimal_fixed(fixed_point[1], wanted_digit+8, 8);
        }
    } else {
        // print using scientific notation like -1e12 or +1e-36 or sci_m * 10^sci_n
        // log10f seems to loose precision for tiny float_to_decode_abs values (negative log values)
        float log10f = log2(float_to_decode_abs)/log2(10.0);
        if ( wanted_digit < -3 || wanted_digit > 2 ) {
            glyph_index = 0; // for ' '
        } else if ( wanted_digit == 2 ) {
            glyph_index = (sign==1?22:1); // for '-' or '+'
        } else if ( wanted_digit == 1 ) {
            // no sci_m calculus, seems tricky to write
            glyph_index = 4; // for '1'
        } else if ( wanted_digit == 0 ) {
            glyph_index = 17; // for 'e'
        } else /* ( wanted_digit < 0 ) */ {
            int sci_n = int(log10f);
            glyph_index = debug_decode_int_decimal_fixed(sci_n, wanted_digit+3, 2);
        }
    }
}
#endif /* _DECODE_FLOAT_HLSL */

/* #include "../../shadertastic-lib/debug/print_values.hlsl" */
#ifndef _PRINT_VALUES_HLSL
#define _PRINT_VALUES_HLSL
// TODO provide high-level wrappers on the other functions here ? print_float() ? print_int() ? print_float4() ? print_float4x4() ?
bool debug_print_float(in float2 text_coords, in float float_to_decode, in int integer_digits, in int fractionnal_digits, in int text_offset_col, in int text_offset_line) {
    bool glyph_bit = false;
    int2 text_offset1 = int2(text_offset_col - fractionnal_digits, text_offset_line); //XXX is that a good idea to position relatively to '.' ?
    if ( debug_inside_text_box(text_coords, text_offset1, integer_digits+fractionnal_digits+2) ) {
        int2 text_offset2 = int2(text_offset_col, text_offset_line); //FIXME inconsistent positionning
        int wanted_digit = debug_get_wanted_digit_from_text_coords(text_coords, text_offset2);
        int sign, exp, mant, signi, glyph_index;
        float expf;
        int2 fixed_point;
        debug_decode_float(float_to_decode, wanted_digit, integer_digits, fractionnal_digits, sign, exp, mant, signi, expf, fixed_point, glyph_index);
        glyph_bit = debug_print_glyph(text_coords, glyph_index);
    }
    return glyph_bit;
}

bool debug_print_float4(in float2 text_coords, in float4 float4_to_decode, in int integer_digits, in int fractionnal_digits, in int text_offset_col, in int text_offset_line) {
    bool glyph_bit = false;
    if ( inside_box(text_coords,
                float2(text_offset_col - fractionnal_digits, text_offset_line),
                float2(text_offset_col - fractionnal_digits + integer_digits + fractionnal_digits + 2, text_offset_line + 4) ) ) {
        int2 text_offset2 = int2(text_offset_col, text_offset_line); //FIXME inconsistent positionning
        int wanted_digit = debug_get_wanted_digit_from_text_coords(text_coords, text_offset2);
        int sign, exp, mant, signi, glyph_index;
        float expf;
        int2 fixed_point;
        float float_to_decode = float4_to_decode[int(text_coords.y)-text_offset_line];
        debug_decode_float(float_to_decode, wanted_digit, integer_digits, fractionnal_digits, sign, exp, mant, signi, expf, fixed_point, glyph_index);
        glyph_bit = debug_print_glyph(text_coords, glyph_index);
    }
    return glyph_bit;
}

bool debug_print_int_decimal_fixed(in float2 text_coords, in int int_to_decode, in int total_digits, in int text_offset_col, in int text_offset_line) {
    bool glyph_bit = false;
    int2 text_offset = int2(text_offset_col, text_offset_line);
    if ( debug_inside_text_box(text_coords, text_offset, total_digits+1) ) {
        int wanted_digit = debug_get_wanted_digit_from_text_coords(text_coords, text_offset);
        int glyph_index = debug_decode_int_decimal_fixed(int_to_decode, wanted_digit, total_digits);
        glyph_bit = debug_print_glyph(text_coords, glyph_index);
    }
    return glyph_bit;
}

bool debug_print_int_hexadecimal_fixed(in float2 text_coords, in int int_to_decode, in int total_digits, in int text_offset_col, in int text_offset_line) {
    bool glyph_bit = false;
    int2 text_offset = int2(text_offset_col, text_offset_line);
    if ( debug_inside_text_box(text_coords, text_offset, total_digits+2) ) {
        int wanted_digit = debug_get_wanted_digit_from_text_coords(text_coords, text_offset);
        int glyph_index = debug_decode_int_hexadecimal_fixed(int_to_decode, wanted_digit, total_digits);
        glyph_bit = debug_print_glyph(text_coords, glyph_index);
    }
    return glyph_bit;
}

bool debug_print_int_binary_fixed(in float2 text_coords, in int int_to_decode, in int total_digits, in int text_offset_col, in int text_offset_line) {
    bool glyph_bit = false;
    int2 text_offset = int2(text_offset_col, text_offset_line);
    if ( debug_inside_text_box(text_coords, text_offset, total_digits+2) ) {
        int wanted_digit = debug_get_wanted_digit_from_text_coords(text_coords, text_offset);
        int glyph_index = debug_decode_int_binary_fixed(int_to_decode, wanted_digit, total_digits);
        glyph_bit = debug_print_glyph(text_coords, glyph_index);
    }
    return glyph_bit;
}
#endif /* _PRINT_VALUES_HLSL */

// These are required objects for the shader to work.
// You don't need to change anything here, unless you know what you are doing
sampler_state textureSampler {
    Filter    = Linear;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

struct VertData {
    float2 uv  : TEXCOORD0;
    float4 pos : POSITION;
};

struct VertDataOut {
    float2 uv  : TEXCOORD0;
	float4 debug1: TEXCOORD1;
	float4 debug2: TEXCOORD2;
	float4 debug3: TEXCOORD3;
	float4 debug4: TEXCOORD4;
    float4 pos : POSITION;
};

struct FragData {
    float2 uv  : TEXCOORD0;
	float4 debug1: TEXCOORD1;
	float4 debug2: TEXCOORD2;
	float4 debug3: TEXCOORD3;
	float4 debug4: TEXCOORD4;
};

VertDataOut VSDefaultWithViewProjDebugHack(VertData v_in)
{
    VertDataOut vert_out;
    vert_out.uv  = v_in.uv;
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	vert_out.debug1 = float4(ViewProj[0][0],ViewProj[0][1],ViewProj[0][2],ViewProj[0][3]);
	vert_out.debug2 = float4(ViewProj[1][0],ViewProj[1][1],ViewProj[1][2],ViewProj[1][3]);
	vert_out.debug3 = float4(ViewProj[2][0],ViewProj[2][1],ViewProj[2][2],ViewProj[2][3]);
	vert_out.debug4 = float4(ViewProj[3][0],ViewProj[3][1],ViewProj[3][2],ViewProj[3][3]);
    return vert_out;
}

VertData VSDefault(VertData v_in)
{
    VertData vert_out;
    vert_out.uv  = v_in.uv;
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
    return vert_out;
}

int2 get_texture_size(texture2d s) {
#ifdef _OPENGL
    return textureSize(s,0);
#else
    uint width, height, levels;
    s.GetDimensions(0, width, height, levels);
    return int2(width, height);
#endif
}

float4 PSEffect(FragData f_in) : TARGET
{
	float2 uv = f_in.uv;
    float aspect_ratio = vpixel/upixel;

    float4 rgba = image.Sample(textureSampler, uv);

    float4 text_color = float4(0.9, 0.2, 0.2, 1.0);

    int2 text_offset = int2(0,0);
    float2 text_coords = debug_get_text_coords_from_uv(uv, float2(0.52,0.0), aspect_ratio, font_size, text_offset );

    int2 texture_size = get_texture_size(image);
    rgba = debug_print_int_decimal_fixed(text_coords, texture_size.x, 4, 6, 0)?text_color:rgba;
    rgba = debug_print_int_decimal_fixed(text_coords, texture_size.y, 4, 0, 0)?text_color:rgba;

    rgba = debug_print_float4(text_coords, f_in.debug1, 4, 4, 18, 2)?text_color:rgba;
    rgba = debug_print_float4(text_coords, f_in.debug2, 4, 4,  6, 2)?text_color:rgba;
    rgba = debug_print_float4(text_coords, f_in.debug3, 4, 4, -6, 2)?text_color:rgba;
    rgba = debug_print_float4(text_coords, f_in.debug4, 4, 4,-18, 2)?text_color:rgba;

	//float4x4 debug = float4x4(f_in.debug1, f_in.debug2, f_in.debug3, f_in.debug4);

    return rgba;
}

technique Draw
{
    pass
    {
        vertex_shader = VSDefaultWithViewProjDebugHack(v_in);
        pixel_shader = PSEffect(f_in);
    }
}
