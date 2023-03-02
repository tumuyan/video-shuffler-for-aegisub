-- Copyright (c) 2023 - 2023, tumuyan <tumuyan@gmail.com>
local tr = aegisub.gettext

script_name = "Get selected text"
script_name_cn = "提取选中的纯文本"
script_author = "tumuyan"
script_version = "0.1"
script_description = "提取选中的字幕为纯文本（跳过Comment行和空行）"

-- 检查是否选择了多行字幕（单行字幕应该直接复制）
function validate_select(subs, sel)
    return #sel > 1
end
 

function save_selected(subs,sel)
    local text = ''
    for _, i in ipairs(sel) do
        local line = subs[i]
        if not (line.comment) then
            local p  = line.text:gsub("{[^}]+}", "")
            if string.len(string.gsub(p,"%s",""))>0 then
                if string.len(text)>0 then
                    text = text .. '\n' .. p
                else
                    text = p
                end
            end
        end
    end

    aegisub.debug.out(text)
end


aegisub.register_macro(script_name .. ' - '.. script_name_cn, script_description, save_selected , validate_select)
