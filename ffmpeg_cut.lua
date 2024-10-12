-- Copyright (c) 2022 - 2024, tumuyan <tumuyan@gmail.com>
local tr = aegisub.gettext
-- require('luacom')
-- local Shell = luacom.CreateObject("WScript.Shell")
-- Shell:Run (command, 0)


DEBUG_LOG = false
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

-- 检查打开的音频流和视频流是否为同一个文件
function validate_video_audio()
    return aegisub.project_properties().video_file ~= aegisub.project_properties().audio_file;
end

-- 毫秒转换为时分秒
function ms2str(ms)
    s = ms / 1000
    m = math.floor(s / 60)
    s = s - 60 * m
    h = math.floor(m / 60)
    m = m - 60 * h
    return string.format("%02d:%02d:%.2f", h, m, s)
end

-- 定义一个分割字符串的方法
string.split = function(s, p)
    local rt = {}
    string.gsub(s, '[^' .. p .. ']+', function(w)
        table.insert(rt, w)
    end)
    return rt
end

NAME_BY_TEXT = 0
NAME_BY_NUM = 1
NAME_BY_NUM_TEXT = 2

function ffmpeg_cut(subs, sel, to_audio, to_mult, keyframe, name_mode)
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
        codec = " -codec copy -avoid_negative_ts make_zero "
    end
    if (to_mult) then
        local num_start = 0
        if name_mode == NAME_BY_NUM then
            output_folder = string.lower(string.gsub(audio_path, '%..-$', ''))
            os.execute('mkdir "' .. output_folder .. '"')
            for i = 1, #subs do
                local line = subs[i]
                if (line.class == "dialogue") then
                    num_start = i - 1
                    break
                end
            end
        end


        currentTimestamp = os.time()
        -- 创建一个临时批处理文件
        batFile = "temp_ffmpeg".. currentTimestamp ..".bat"
        
        -- 写入FFmpeg命令到批处理文件
        file = io.open(batFile, "w", "UTF-8")
        if file then
            file:write("@echo off\n")
            file:write("chcp 65001 > nul\n")  -- 设置代码页为UTF-8
        else
            aegisub.debug.out("无法创建临时批处理文件")
            return
        end

        for _, i in ipairs(sel) do
            local line = subs[i]
            local p1 = ""
            if name_mode==NAME_BY_NUM then
                p1 = '/' .. (i - num_start)
            elseif name_mode==NAME_BY_NUM_TEXT then
                local p = string.split(line.text, "\\N")
                p1 = '/' .. (i - num_start) .. '.' .. p[1]
            else
                local p = string.split(line.text, "\\N")
                p1 = p[1]
            end

            local cmd2 = "ffmpeg  -ss " .. ms2str(line.start_time) .. " -to " .. ms2str(line.end_time) .. ' -i "' ..
                             input_path .. '" ' .. codec .. ' -y "' .. output_folder .. p1 .. output_suffix .. '"'
            if DEBUG_LOG then
                aegisub.debug.out(cmd2)
                aegisub.debug.out("\n")
            end
            aegisub.progress.title(title)
            aegisub.progress.set(_ * 100 / #sel)
            aegisub.progress.task(line.text)
            -- os.execute(cmd2)
            -- os.execute('start /b ' .. cmd2)
            -- Shell:Run (cmd2 .. " & pause", 0)
            file:write(cmd2 .. "\n")
        end

        -- file:write("echo Finish!\n")
        -- file:write("pause\n")
        file:write("exit\n")
        file:close()
        -- 使用cmd /c调用批处理文件
        os.execute("cmd /c " .. batFile)
        os.remove(batFile)

    else
        local line = subs[sel[1]]
        local p = string.split(line.text, "\\N")
        local start_time = line.start_time
        local end_time = subs[sel[#sel]].end_time
        local cmd2 =
            "ffmpeg -ss " .. ms2str(start_time) .. " -to " .. ms2str(end_time) .. ' -i "' .. input_path .. '" ' .. codec ..
                ' -y "' .. output_folder .. p[1] .. output_suffix .. '"'
        if DEBUG_LOG then
            aegisub.debug.out(cmd2)
        end
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

function cut_audio_mult_num(subs, sel)
    ffmpeg_cut(subs, sel, true, true, false, NAME_BY_NUM)
end

function cut_audio_mult_num_text(subs, sel)
    ffmpeg_cut(subs, sel, true, true, false, NAME_BY_NUM_TEXT)
end

function cut_video_mult(subs, sel)
    ffmpeg_cut(subs, sel, false, true, false, NAME_BY_TEXT)
end

function cut_video_mult_num_text(subs, sel)
    ffmpeg_cut(subs, sel, false, true, false, NAME_BY_NUM_TEXT)
end

function cut_video_mult_keyframe(subs, sel)
    ffmpeg_cut(subs, sel, false, true, true)
end

-- 用打开的音频替换视频中的音频
function merge_video_audio()
    os.execute('ffmpeg -i "' .. aegisub.project_properties().video_file .. '" -i "' ..
                   aegisub.project_properties().audio_file .. '"   -vcodec copy  -map 0:0 -map 1:0 -y "' ..
                   aegisub.project_properties().video_file .. '_replace_audio.' .. suffix .. '" & pause');
end


function merge_video_audio2()
    os.execute('ffmpeg -i "' .. aegisub.project_properties().video_file .. '" -i "' ..
                   aegisub.project_properties().audio_file .. '"    -c:v copy -c:a copy -shortest -y "' ..
                   aegisub.project_properties().video_file .. '_replace_audio2.' .. suffix .. '" & pause');
end

-- 压制打开的视频和字幕
function merge_video_sub()
    script_path = (aegisub.decode_path("?script/" .. aegisub.file_name()));
    cmd = string.gsub(script_path, ":.+", ": & ") .. 'cd "' .. script_path .. '\\..\" & ';

    video_path = aegisub.project_properties().video_file;
    script_suffix = (string.gsub(script_path, '.+%.', ''));
    video_suffix = (string.gsub(video_path, '.+%.', ''));

    vf = '"subtitles=' .. aegisub.file_name() .. '"';
    if (script_suffix == "ass") then
        vf = '"ass=' .. aegisub.file_name() .. '"';
    end
    cmd = cmd .. 'ffmpeg -i "' .. aegisub.project_properties().video_file .. '" -vf ' .. vf .. ' -y "' ..
              aegisub.project_properties().video_file .. '_merge_sub.' .. video_suffix .. '" & pause'
    aegisub.debug.out(aegisub.file_name() .. "\n" .. cmd)
    os.execute(cmd);
end

-- 在Aegisub自动化菜单下增加命令
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个/" .. tr "Video", script_description,
    cut_video_mult, validate_video)
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个/" .. tr "Video" .. "(使用序号+文本命名)", script_description,
    cut_video_mult_num_text, validate_video)
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个/" .. tr "Video" .. tr "(不重编码)",
    script_description, cut_video_mult_keyframe, validate_video)
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个/" .. tr "Audio", script_description,
    cut_audio_mult)
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个/" .. tr "Audio" .. "(使用序号命名)",
    script_description, cut_audio_mult_num)
aegisub.register_macro("保存选中每行字幕对应的媒体的为一个/" .. tr "Audio" .. "(使用序号+文本命名)",
    script_description, cut_audio_mult_num_text)

aegisub.register_macro("保存选中字幕始末范围的媒体为一个/" .. tr "Video", script_description,
    cut_video_one, validate_video)
aegisub.register_macro("保存选中字幕始末范围的媒体为一个/" .. tr "Video" .. tr "(不重编码)",
    script_description, cut_video_one_keyframe, validate_video)
aegisub.register_macro("保存选中字幕始末范围的媒体为一个/" .. tr "Audio", script_description,
    cut_audio_one)

aegisub.register_macro("合并" .. tr "Video" .. "和" .. tr "Audio", "用打开的音频替换视频中的音频",
    merge_video_audio, validate_video_audio)
aegisub.register_macro("合并" .. tr "Video" .. "和" .. tr "Audio" .. " (Fast&Short)", "用打开的音频替换视频中的音频2",
    merge_video_audio2, validate_video_audio)

aegisub.register_macro("合并" .. tr "Video" .. "和" .. tr "字幕", "压制打开的视频和字幕",
    merge_video_sub, validate_video)
