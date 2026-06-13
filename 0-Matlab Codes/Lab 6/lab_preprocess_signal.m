function [x_q, fs16] = lab_preprocess_signal(x, fs)

fs16 = 16000;
x_rs = resample(x, fs16, fs);

x_rs = x_rs / max(abs(x_rs) + eps);

nbits_adc = 12;
frac_bits_adc = 11;

x_q = lab_quantize_signed(x_rs, nbits_adc, frac_bits_adc);
