/* Inspired from https://www.shadertoy.com/view/3lGBDm ; Licensed under CC BY-NC-SA 3.0
    Font extracted with : zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf
    See: https://github.com/ludolpif/obs-shadertastic-effects/blob/main/utils/x11-bitmap-font-extractor.sh
   You might like https://www.shadertoy.com/view/7dfyRH (I discovered it lately, use font texture).

    Primarily written for OBS Shadertastic plugin (shader library for live streaming with OBS Studio)
    See: https://shadertastic.com
*/
#define float2 vec2
#define float4 vec4
#define int2 ivec2
#define int3 ivec3

const bool should_print_grid = true;
const bool should_print_font_test = true;
const float font_size = 0.083333333;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    uv.y = 1.0 - uv.y; // with 'v' going from 0.0:top to 1.0:bottom as OBS do
    float aspect_ratio = iResolution.x/iResolution.y;
    // Tech demo on gray background
    vec4 rgba = vec4(0.2, 0.2, 0.2, 1.0);
    float4 text_color = float4(0.9, 0.2, 0.2, 1.0);
    // Compute once current pixel in text_coords space
    int2 text_offset = int2(0,-1);
    float2 text_coords = debug_get_text_coords_from_uv(uv, float2(0.5,0.15), aspect_ratio, font_size, text_offset );

    if ( should_print_grid ) {
        rgba = debug_print_text_grid(rgba, text_coords, text_offset, -12, 0, 13, 9);
    }

    if ( should_print_font_test ) {
        text_offset = int2(-11, 0);
        if ( debug_inside_text_box(text_coords, text_offset, 24) ) {
            int wanted_digit_font_test = debug_get_wanted_digit_from_text_coords(text_coords);
            int glyph_index_font_test = 12 - wanted_digit_font_test;
            rgba = debug_print_glyph(text_coords, glyph_index_font_test)?text_color:rgba;
        }
    }

    // debug_decode_float() in:
    float float_to_decode = iTime;
    int wanted_digit = debug_get_wanted_digit_from_text_coords(text_coords);
    // debug_decode_float() out:
    int sign, exp, mant, signi, glyph_index;
    float expf;
    int2 fixed_point;
    // debug_decode_float() call:
    debug_decode_float(float_to_decode, wanted_digit, 9, 8, sign, exp, mant, signi, expf, fixed_point, glyph_index);
    /*
     * note: you should call debug_decode_float() call only for pixels that will display it's values
     *  because doing the decoding for the full texture may make the GPU too busy.
     *  For this demo, multiple lines of text will depend on this debug_decode_float() so we call it unconditionnaly
     */
    // displaying the result then inner details as an API demo
    text_offset = int2(-8, 1);
    if ( debug_inside_text_box(text_coords, text_offset, 19) ) {
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // show the float_to_decode as hex, from previously splitted bit fields
    text_offset = int2(0, 2);
    if ( debug_inside_text_box(text_coords, text_offset, 10) ) {
        int decoded_float = sign<<31 | (exp&0xff)<<23 | mant;
        glyph_index = debug_decode_int_hexadecimal_fixed(decoded_float, wanted_digit, 8);
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // show the float_to_decode mantissa 23 bits as binary number (0b........................)
    text_offset = int2(-12, 3);
    if ( debug_inside_text_box(text_coords, text_offset, 25) ) {
        glyph_index = debug_decode_int_binary_fixed(mant, wanted_digit+12, 23);
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // show the float_to_decode mantissa 23 bits as decimal number
    text_offset = int2(0, 4);
    if ( debug_inside_text_box(text_coords, text_offset, 8) ) {
        glyph_index = debug_decode_int_decimal(mant, wanted_digit);
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // show the float_to_decode exponent (without IEEE -127 offset) as decimal number
    text_offset = int2(0, 5);
    if ( debug_inside_text_box(text_coords, text_offset, 4) ) {
        glyph_index = debug_decode_int_decimal(int(expf), wanted_digit);
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // show the -inf special case
    text_offset = int2(-2, 6);
    if ( debug_inside_text_box(text_coords, text_offset, 6) ) {
        float_to_decode = -1e39; // Should be -inf
        debug_decode_float(float_to_decode, wanted_digit, 9, 8, sign, exp, mant, signi, expf, fixed_point, glyph_index);
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // show the +nan special case
    text_offset = int2(-2, 7);
    if ( debug_inside_text_box(text_coords, text_offset, 6) ) {
        float_to_decode = sqrt(-abs(expf)); // Maybe +nan if float_to_decode not between 1.0 and 1.5
        debug_decode_float(float_to_decode, wanted_digit, 9, 8, sign, exp, mant, signi, expf, fixed_point, glyph_index);
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // show the -0.0 special case
    text_offset = int2(-2, 8);
    if ( debug_inside_text_box(text_coords, text_offset, 6) ) {
        float_to_decode = -0.0; // Maybe -0.0, and it's a different binary representation than +0.0 but compilers may throw it
        debug_decode_float(float_to_decode, wanted_digit, 9, 8, sign, exp, mant, signi, expf, fixed_point, glyph_index);
        rgba = debug_print_glyph(text_coords, glyph_index)?text_color:rgba;
    }
    // Output to screen
    fragColor = rgba;
}
