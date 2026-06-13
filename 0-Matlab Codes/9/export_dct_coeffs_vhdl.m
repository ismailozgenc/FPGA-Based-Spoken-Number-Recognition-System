function export_dct_coeffs_vhdl
M = 32;
N = 13;
nbits = 16;
frac_bits = 14;
scale = 2^frac_bits;

C = zeros(N,M);
for n = 0:N-1
    for m = 0:M-1
        C(n+1,m+1) = cos(pi*n*(m+0.5)/M);
    end
end

Cq = round(C * scale);
max_val = 2^(nbits-1)-1;
Cq(Cq > max_val) = max_val;
Cq(Cq < -max_val-1) = -max_val-1;

fid = fopen('dct_coeffs_vhdl.txt','w');
fprintf(fid,'constant coeff_rom : coeff_rom_t := (\n');
for n = 1:N
    fprintf(fid,'    %d => (', n-1);
    for m = 1:M
        fprintf(fid,'to_signed(%d, COEF_WIDTH)', Cq(n,m));
        if m < M
            fprintf(fid,', ');
        end
    end
    if n < N
        fprintf(fid,'),\n');
    else
        fprintf(fid,')\n');
    end
end
fprintf(fid,');\n');
fclose(fid);
end

%% Code that is for generating  coefficients to be used in DCT.VHDL