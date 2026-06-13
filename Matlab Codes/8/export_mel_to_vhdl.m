function export_mel_to_vhdl
fs = 16000;
nfft = 512;
num_mel_fpga = 32;
[H, ~] = lab_mel_filterbank(num_mel_fpga, nfft, fs);
H = H(:,1:256);
nbits = 12;
frac_bits = 11;
scale = 2^frac_bits;
Hq = round(H * scale);
max_val = 2^(nbits-1) - 1;
Hq(Hq > max_val) = max_val;
Hq(Hq < 0) = 0;
fid = fopen('mel_coeffs_vhdl.txt','w');
fprintf(fid,'constant coeff_rom : coeff_rom_t := (\n');
for m = 1:num_mel_fpga
    fprintf(fid,'    %d => (', m-1);
    for k = 1:256
        fprintf(fid,'to_signed(%d, COEF_WIDTH)', Hq(m,k));
        if k < 256
            fprintf(fid,', ');
        end
    end
    if m < num_mel_fpga
        fprintf(fid,'),\n');
    else
        fprintf(fid,')\n');
    end
end
fprintf(fid,');\n');
fclose(fid);
end
