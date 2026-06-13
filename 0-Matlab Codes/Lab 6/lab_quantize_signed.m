function xq = lab_quantize_signed(x, nbits, frac_bits)

max_val = 2^(nbits-1) - 1;
min_val = -2^(nbits-1);

x_scaled = round(x * 2^frac_bits);
x_clipped = min(max(x_scaled, min_val), max_val);

xq = x_clipped / 2^frac_bits;
