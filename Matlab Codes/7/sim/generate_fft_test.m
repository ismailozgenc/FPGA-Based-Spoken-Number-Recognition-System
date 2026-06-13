function generate_fft_test(type)
    FRAME_LEN = 512;
    fs = 16000;

    n = 0:FRAME_LEN-1;

    switch type
        case 'bin_exact'
            f = 32 * fs/512;
            x = 0.8 * sin(2*pi*f*n/fs);

        case 'bin_between'
            f = 987;
            x = 0.8 * sin(2*pi*f*n/fs);

        case 'two_tone'
            x = 0.6*sin(2*pi*800*n/fs) + 0.4*sin(2*pi*2400*n/fs);

        case 'impulse'
            x = zeros(1, FRAME_LEN);
            x(10) = 1;

        case 'noise'
            x = 0.5 * randn(1, FRAME_LEN);

        otherwise
            error('Unknown test type');
    end

    x = x(:);
    full_scale = 2048;
    s_signed = round(x * full_scale);
    s_signed(s_signed > 2047) = 2047;
    s_signed(s_signed < -2048) = -2048;

    w = hann(FRAME_LEN,'periodic');
    coef = round(w * 255);

    prod = s_signed .* coef;
    prod(prod > 2^19-1) = 2^19-1;
    prod(prod < -2^19) = -2^19;

    fid = fopen('window_in.txt','w');
    fprintf(fid, '%d\n', prod);
    fclose(fid);

    fprintf('Generated window_in.txt for test: %s\n', type);
end
