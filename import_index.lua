-- Copyright (c) 2022-2023, tumuyan <tumuyan@gmail.com>
local tr = aegisub.gettext

script_name = tr "Import index"
script_author = "tumuyan"
script_version = "0.1.0"
script_description = "导入文本索引到字幕中"

function ms2str(ms)
    local s = ms / 1000.0
    local m = math.floor(s / 60)
    s = s - 60 * m
    local h = math.floor(m / 60)
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

function str2ms(text)
    local p = string.split(text, ":")
    local s = 0 + p[#p]
    local m = 0
    local h = 0
    if #p > 1 then
        m = 0 + p[#p - 1]
    end

    if #p > 2 then
        h = 0 + p[#p - 2]
    end
    local r = ((h * 60 + m) * 60 + s) * 1000
    -- print(h .. "," .. m .. "," .. s ," = " , r )
    return r
end

function import_index(subs, sel)
    local r_gui = {{
        class = "textbox",
        x = 1,
        y = 2,
        width = 60,
        height = 20,
        name = "fx",
        text = ""
    }}
    local rg, rg_res = aegisub.dialog.display(r_gui, {tr"OK", tr"Cancel"})
    if rg ==tr"OK" then
        local lines = string.split(rg_res.fx, "\n")
        local textlist = {}
        local timelist = {}
        local sample = nil
        for l, text in ipairs(lines) do
            local t = string.gsub(text, "^%s?(.-)%s?$", "%1")
            t = string.gsub(t, "%s+", " ")
            if string.find(t, " ") then
                local t1 = string.gsub(t, "%s.+$", "")
                local t2 = string.gsub(t, "^%S+%s", "")
                local ms = str2ms(t1)
                table.insert(timelist, ms)
                table.insert(textlist, "# " .. t2)
            end
        end

        if #timelist < 1 then
            aegisub.dialog.display({{ x=1, y=0, width=1, height=1, class="label", label="没有待导入的内容" }}, {tr"OK"})
            return
        end

        local j = 1
        local insert_time = timelist[1]

        for i = 1, #subs do
            local line = subs[i]
            if line.class == "dialogue" then
                if sample == nil then
                    sample = line
                    sample.comment = true
                end

                if line.start_time >= insert_time then
                    aegisub.progress.set(j * 100 / #timelist)
                    aegisub.progress.task(textlist[j])
                    local it = sample
                    it.start_time = insert_time
                    it.end_time = insert_time
                    it.text = textlist[j]
                    subs.insert(i, it)
                    j = j + 1
                    if j > #timelist then
                        break
                    else
                        insert_time = timelist[j]
                    end
                end
            end
        end

        for k = j, #timelist, 1 do
            aegisub.progress.set(k * 100 / #timelist)
            aegisub.progress.task(textlist[j])
            local it = sample
            it.start_time = timelist[j]
            it.end_time = timelist[j]
            it.text = textlist[j]
            subs.append(it)
        end
    end
    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name .. ' - ' .. script_description, script_description, import_index)
