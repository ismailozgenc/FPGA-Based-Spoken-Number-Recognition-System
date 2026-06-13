fs = 16000;
nfft = 512;
num_mel_fpga = 32;

[H, ~] = lab_mel_filterbank(num_mel_fpga, nfft, fs);
H = H(:, 1:256);

nbits      = 12;
frac_bits  = 11;
scale      = 2^frac_bits;
Hq         = round(H * scale);
max_val    = 2^(nbits-1) - 1;
Hq(Hq > max_val) = max_val;
Hq(Hq < 0)       = 0;

coef_sums = sum(Hq, 2);

disp(coef_sums);
