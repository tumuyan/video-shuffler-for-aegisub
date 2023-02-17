-- Copyright (c) 2022 - 2023, tumuyan <tumuyan@gmail.com>
local tr = aegisub.gettext

script_name = tr "ffmpeg cut"
script_author = "tumuyan"
script_version = "0.2"
script_description = "Cut video or audio to clips by ffmpeg. \n用ffmpeg切分选中的字幕对应的视频/音频"

video_suffixs = {"mp4", "mkv", "flv"}
audio_suffixs = {".mp3", ".wav", ".ogg", ".m4a", ".aac", ".ape", ".flac", ".wma"}

function validate_mult_select(subs, sel)
    return #sel > 1
end

-- 检查文件格式是否为视频。
-- 当文件不是视频时，视频相关的菜单不激活
function validate_video(subs, sel)
    suffix = string.lower(string.gsub(aegisub.project_properties().video_file, '.+%.', ''))
    for k, v in ipairs(video_suffixs) do
        if v == suffix then
            return true;
        end
    end
    return false;
end

-- 检查文件格式是否为音频。
-- 当文件是视频时，切割音频需要转码
-- suffix = string.lower(string.gsub(aegisub.project_properties().audio_file, '.+%.', '') )
function validate_audio(suffix)
    for k, v in ipairs(audio_suffixs) do
        if v == suffix then
            return true;
        end
    end
    return false;
end

function ms2str(ms)
    s = ms / 1000.0
    m = math.floor(s / 60)
    s = s - 60 * m
    h = math.floor(m / 60)
    m = m - 60 * h
    return "" .. h .. ":" .. m .. ":" .. s
end

string.split = function(s, p)
    local rt = {}
    string.gsub(s, '[^' .. p .. ']+', function(w)
        table.insert(rt, w)
    end)
    return rt
end

function ffmpeg_cut(subs, sel, to_audio, to_mult, keyframe)
    script_path = aegisub.decode_path("?script/" .. aegisub.file_name())
    video_path = aegisub.project_properties().video_file
    audio_path = aegisub.project_properties().audio_file

    video_suffix = string.lower(string.gsub(video_path, '.+%.', '.'))
    audio_suffix = string.lower(string.gsub(audio_path, '.+%.', '.'))

    input_path = video_path
    output_folder = aegisub.decode_path("?video/")
    output_suffix = video_suffix
    codec = ""
    title = tr "Video:"

    if to_audio then
        input_path = audio_path
        output_folder = aegisub.decode_path("?audio/")
        title = tr "Audio:"
        if validate_audio(audio_suffixs) then
            output_suffix = audio_suffix
            codec = " -acodec copy "
        elseif audio_suffix == ".mp4" then
            output_suffix = ".m4a"
            codec = " -vn -acodec copy "
        else
            output_suffix = ".wav"
            codec = " -vn "
        end
    elseif keyframe then
        codec = " -acodec copy -vcodec copy  -avoid_negative_ts make_zero "
    end

    if (to_mult) then
        for _, i in ipairs(sel) do
            local line = subs[i]
            local p = string.split(line.text, "\\N")
            local cmd2 = "ffmpeg  -ss " .. ms2str(line.start_time) .. " -to " .. ms2str(line.end_time) .. " -i \"" ..
                             input_path .. "\" " .. codec .. " -y \"" .. output_folder .. p[1] .. output_suffix .. "\""
            -- os.execute("echo " .. cmd2 .. " & pause")
            aegisub.progress.title(title)
            aegisub.progress.set(_ * 100 / #sel)
            aegisub.progress.task(line.text)
            os.execute(cmd2)
            -- break
        end
    else
        local line = subs[sel[1]]
        local p = string.split(line.text, "\\N")
        local start_time = line.start_time
        local end_time = subs[sel[#sel]].end_time
        local cmd2 = "ffmpeg -ss " .. ms2str(start_time) .. " -to " .. ms2str(end_time) .. " -i \"" .. input_path ..
                         "\" " .. codec .. " -y " .. " \"" .. output_folder .. p[1] .. output_suffix .. "\""
        os.execute(cmd2 .. " & pause")
    end
end

function cut_audio_one(subs, sel)
    ffmpeg_cut(subs, sel, true, false, false)
end

function cut_video_one(subs, sel)
    ffmpeg_cut(subs, sel, false, false, false)
end

function cut_video_one_keyframe(subs, sel)
    ffmpeg_cut(subs, sel, false, false, true)
end

function cut_audio_mult(subs, sel)
    ffmpeg_cut(subs, sel, true, true, false)
end

function cut_video_mult(subs, sel)
    ffmpeg_cut(subs, sel, false, true, false)
end

function cut_video_mult_keyframe(subs, sel)
    ffmpeg_cut(subs, sel, false, true, true)
end

aegisub.register_macro("保存选中每行字幕对应的媒体的为一个" .. tr "Video", script_description,
    cut_video_mult, validate_video)
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个" .. tr "Video" .. tr "(不重编码)",
    script_description, cut_video_mult_keyframe, validate_video)
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个" .. tr "Audio", script_description,
    cut_audio_mult)

aegisub.register_macro("保存选中字幕始末范围的媒体为一个" .. tr "Video", script_description,
    cut_video_one, validate_video)
aegisub.register_macro("保存选中字幕始末范围的媒体为一个" .. tr "Video" .. tr "(不重编码)",
    script_description, cut_video_one_keyframe, validate_video)
aegisub.register_macro("保存选中字幕始末范围的媒体为一个" .. tr "Audio", script_description,
    cut_audio_one)
