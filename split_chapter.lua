-- Copyright (c) 2022-2023, tumuyan <tumuyan@gmail.com>
local tr = aegisub.gettext

script_name = tr "Split chapter"
script_author = "tumuyan"
script_version = "0.1.0"
script_description = "用章节信息分割媒体文件"
-- 当音频视频文件不同时，分割的媒体文件为音频
-- 切割时间点为注释信息#章节标题的end_time

function split_chapter_all(subs, sel)
    split_chapter(subs, sel, true)
end

function split_chapter_(subs, sel)
    split_chapter(subs, sel, false)
end

function split_chapter(subs, sel, keep_space_title_chapter)
    local c = 1
    local title = ''
    local t0 = -1
    local t1 = -1
    local script_path = aegisub.decode_path("?script/" .. aegisub.file_name())
    local audio_path = aegisub.project_properties().audio_file
    local suffix = string.gsub(audio_path, "^.+%.", ".")

    for i = 1, #subs do
        local line = subs[i]
        if (line.class == "dialogue") and (string.sub(line.text, 1, 1) == '#') then
            t1 = line.end_time / 1000

            aegisub.progress.title('' .. t0 .. ' - ' .. t1)
            aegisub.progress.set(i * 100 / #subs)
            aegisub.progress.task(title)

            if t0 >= 0 and t1 > t0 then
                if keep_space_title_chapter or string.len(title) > 0 then
                    os.execute(
                        'ffmpeg -ss ' .. t0 .. ' -to ' .. t1 .. ' -i "' .. audio_path .. '"   -c copy -y "' ..
                            audio_path .. '_' .. c .. '_' .. title .. suffix .. '" ')
                    c = c + 1
                end
            -- else
            --     aegisub.debug.out('t0=' .. t0 .. ',t1=' .. t1)
            end
            title = line.text:gsub("^#+\\s*", "")
            t0 = t1
        end
    end
    if keep_space_title_chapter or string.len(title) > 0 then
        os.execute('ffmpeg -ss ' .. t0 .. ' -i "' .. audio_path .. '"   -c copy -y "' .. audio_path .. '_' .. c ..
                       '_' .. title .. suffix .. '" ')
    end
end

aegisub.register_macro(script_name .. ' - ' .. script_description .. '/分割全部章节', script_description,
    split_chapter_all)
aegisub.register_macro(script_name .. ' - ' .. script_description .. '/只分割非空章节', script_description,
    split_chapter_)
