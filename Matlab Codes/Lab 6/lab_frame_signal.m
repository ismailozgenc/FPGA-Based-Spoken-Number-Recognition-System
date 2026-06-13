function frames = lab_frame_signal(x, frame_len, hop)

x = x(:);
L = length(x);

num_frames = 1 + floor((L - frame_len)/hop);
if num_frames < 1
    num_frames = 1;
end

frames = zeros(frame_len, num_frames);

idx = 1;
for k = 1:num_frames
    if idx+frame_len-1 <= L
        frames(:, k) = x(idx:idx+frame_len-1);
    else
        tmp = zeros(frame_len, 1);
        remain = L - idx + 1;
        tmp(1:remain) = x(idx:L);
        frames(:, k) = tmp;
    end
    fprintf('Progress %d/%d frames\n', k, num_frames);
    idx = idx + hop;
end
