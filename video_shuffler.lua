﻿-- Copyright (c) 2022, Tumuyan <tumuyan@gmail.com>
video_shuffler = "C:\\prg\\video-shuffler\\main.py "
local tr = aegisub.gettext

script_name = tr "Video Shuffler"
script_description =
    tr "Cut video to clips and shuffle them by ass file \n洋片箱：用ASS字幕文件切割视频，并重组输出"
script_author = "Tumuyan"
script_version = "1.1"

-- 检查文件格式是否为视频。
-- 当文件不是视频时，视频相关的菜单不激活
function validate_video(subs, sel)
    -- if aegisub.project_properties().video_file == nil then
    --     return false
    -- end
    suffix = string.lower(string.gsub(aegisub.project_properties().video_file, '.+%.', ''))
    return string.len(suffix) == 3;
end

function is_windows(subs, sel)
    return package.config:sub(1, 1) == "\\"
end

function cut(mode, skip_blank_chapter_name)
    -- 分割
    script_path = aegisub.decode_path("?script/" .. aegisub.file_name())
    video_path = aegisub.project_properties().video_file
    audio_path = aegisub.project_properties().audio_file
    output_folder = string.gsub(script_path, "%.[^.]+$", "\\")

    if mode == 0 then
        cmd = string.sub(output_folder, 0, 2) .. " & cd \"" .. output_folder .. "\" & dir & explorer . "
        os.execute(cmd)
        return
    end

    script_suffix = string.gsub(script_path,  '.+%.', '')
    if script_suffix ~= "ass" then
        local dialog=
		{
			{
				class="label",
				x=0,y=0,width=2,height=2,
				label="字幕格式错误：\n洋片箱只能处理ASS格式的字幕，但目前的字幕格式是" .. script_suffix
			}
		}
		local script_suffix_validate, results = aegisub.dialog.display(dialog)
        return
    end

    cmd = "python " .. video_shuffler .. " \""
    if mode == 1 then
        cmd = cmd .. script_path .. "\" -rt"
    elseif mode == 2 then
        cmd = cmd .. script_path .. "\" -i \"" .. audio_path .. "\" -a -r \"" .. output_folder .. " content.txt\""
    elseif mode == 3 then
        cmd = cmd .. script_path .. "\" -i \"" .. video_path .. "\" -v -r \"" .. output_folder .. " content.txt\""
    elseif mode == 4 then
        cmd = cmd .. script_path .. "\" -i \"" .. video_path .. "\" -v "
    end

    if skip_blank_chapter_name then
        cmd = cmd ..  " -b"
    end
    os.execute(cmd .. " & pause")
end

function cut_0(subs, sel)
    cut(0, true)
end

function cut_1(subs, sel)
    cut(1, false)
end

function cut_2(subs, sel)
    cut(2, true)
end

function cut_3(subs, sel)
    cut(3, true)
end

function cut_4(subs, sel)
    cut(4, true)
end

function cut_12(subs, sel)
    cut(2, false)
end

function cut_13(subs, sel)
    cut(3, false)
end

function cut_14(subs, sel)
    cut(4, false)
end

aegisub.register_macro(script_name .. tr "/1 切分字幕（原时间轴）", script_description, cut_1)
aegisub.register_macro(script_name .. tr "/2 使用参考文件切分音频(跳过空章节名)", script_description,
    cut_2)
aegisub.register_macro(script_name .. tr "/3 使用参考文件切分视频(跳过空章节名)", script_description,
    cut_3, validate_video)
aegisub.register_macro(script_name .. tr "/4 切分视频(跳过空章节名)", script_description, cut_4,
    validate_video)
aegisub.register_macro(script_name .. tr "/2 使用参考文件切分音频", script_description, cut_12)
aegisub.register_macro(script_name .. tr "/3 使用参考文件切分视频", script_description, cut_13, validate_video)
aegisub.register_macro(script_name .. tr "/4 切分视频", script_description, cut_14, validate_video)
aegisub.register_macro(script_name .. tr "/0 打开输出目录", script_description, cut_0, is_windows)

