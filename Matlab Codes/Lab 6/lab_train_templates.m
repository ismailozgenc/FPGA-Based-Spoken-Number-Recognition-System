clear; clc;

digits_list = 0:9;
num_reps = 3;

fs16 = 16000;
all_feats = [];

for d = digits_list
    for r = 1:num_reps
        fprintf('Digit %d, rep %d/%d\n', d, r, num_reps);
        [x, fs] = lab_record_digit(1.5, 0.5);
        [x_q, fs16] = lab_preprocess_signal(x, fs);
        feat = lab_compute_features(x_q, fs16);
        all_feats = [all_feats, [feat; d]];
    end
end

num_ceps = size(all_feats, 1) - 1;
templates = zeros(num_ceps, numel(digits_list));

for idx = 1:numel(digits_list)
    d = digits_list(idx);
    mask = (all_feats(end, :) == d);
    feats_d = all_feats(1:end-1, mask);
    templates(:, idx) = mean(feats_d, 2);
end

save templates.mat templates
fprintf('Saved templates.mat\n');
