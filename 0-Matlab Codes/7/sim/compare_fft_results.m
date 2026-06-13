function compare_fft_results
    win = readmatrix('window_in.txt');
    hw  = readmatrix('fft_out.txt');

    N = length(win);
    X = fft(double(win), N);
    mag2 = abs(X(1:N/2)).^2;

    k = (hw' * mag2) / (mag2' * mag2);
    mag2_scaled = k * mag2;

    figure;

    subplot(2,1,1);
    plot(hw, 'o-'); hold on;
    plot(mag2_scaled, 'x-');
    title('FPGA FFT vs MATLAB FFT (scaled)');
    legend('FPGA', 'MATLAB scaled');
    grid on;

    subplot(2,1,2);
    plot(hw - mag2_scaled(:));
    title('Difference');
    grid on;
end
