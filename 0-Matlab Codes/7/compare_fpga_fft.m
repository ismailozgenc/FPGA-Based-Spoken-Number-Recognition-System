function compare_fpga_fft(x_windowed_20bit, mags2_fpga)
FRAME_LEN = 512;

x = double(x_windowed_20bit);

X = fft(x, FRAME_LEN);
mags2_mat = abs(X).^2;

mags2_mat = mags2_mat(:);
mags2_mat_0_255 = mags2_mat(1:256);

scale = max(double(mags2_fpga)) / max(mags2_mat_0_255);
mags2_mat_scaled = mags2_mat_0_255 * scale;

k = 0:255;

figure;
subplot(2,1,1);
plot(k, double(mags2_fpga), 'o-'); hold on;
plot(k, mags2_mat_scaled, 'x-');
xlabel('Bin'); ylabel('|X[k]|^2 (scaled)');
legend('FPGA','MATLAB scaled');
title('FPGA FFT vs MATLAB FFT (single frame)');

subplot(2,1,2);
diff_vec = double(mags2_fpga) - mags2_mat_scaled;
plot(k, diff_vec, '-');
xlabel('Bin'); ylabel('Difference');
title(sprintf('Difference (max abs = %.2f)', max(abs(diff_vec))));
end
