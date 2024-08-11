/*
 * note: This file is not really a .h file to be included somehow,
 *  it is just an overview of which .hlsl contains what
 */

/* #include "../../shadertastic-lib/geometry/inside_box.hlsl" */
/* public */ bool inside_box(float2 v, float2 left_top, float2 right_bottom);

/* #include "../../shadertastic-lib/debug/print_glyph.hlsl" */
#define DEBUG_FONT_GLYPH_WIDTH 4
#define DEBUG_FONT_GLYPH_HEIGHT 6
#define DEBUG_FONT_GLYPHS ...
/* public */ float2 debug_get_text_coords_from_uv(in float2 uv, in float2 uv_grid_origin, in float uv_aspect_ratio, in float uv_line_height, in int2 text_offset);
/* public */ int debug_get_wanted_digit_from_text_coords(in float2 text_coords);
/* public */ bool debug_inside_text_box(in float2 text_coords, in int2 text_offset, in int text_len);
/* public */ float4 debug_print_text_grid(in float4 rgba, in float2 text_coords, in int2 text_offset;
/* public */ bool debug_print_glyph(in float2 text_coords, in int glyph_index);

/* #include "../../shadertastic-lib/debug/decode_int.hlsl" */
/* public */ int debug_decode_int_decimal_fixed(in int int_to_decode, in int wanted_digit, in int total_digits);
/* public */ int debug_decode_int_decimal(in int int_to_decode, in int wanted_digit);
/* public */ int debug_decode_int_hexadecimal_fixed(in int int_to_decode, in int wanted_digit, in int total_digits);
/* public */ int debug_decode_int_binary_fixed(in int int_to_decode, in int wanted_digit, in int total_digits);

/* #include "../../shadertastic-lib/debug/decode_float_internals.hlsl" */
/* internal */ int debug_decode_float_sign(in float float_to_decode);
/* internal */ int2 debug_decode_float_mantissa_to_fixed_point(in float mantissa_pow);
/* internal */ int debug_format_float_special_values(in int sign, in int3 glyphs, in int wanted_digit);

/* #include "../../shadertastic-lib/debug/decode_float.hlsl" */
/* public */ void debug_decode_float(in float float_to_decode, in int wanted_digit, in int integer_digits, in int fractionnal_digits, out int sign, out int exp, out int mant, out int signi, out float expf, out int2 fixed_point, out int glyph_index);

/* #include "../../shadertastic-lib/debug/print_values.hlsl" */
// TODO provide high-level wrappers on the other functions here ? print_float() ? print_int() ? print_float4() ? print_float4x4() ?
