-- Copyright (c) 2022, tumuyan <tumuyan@gmail.com>
local tr = aegisub.gettext

script_name = tr "import index"
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

function import_indexx(subs, sel)
    -- aegisub.progress.title(title)
    local start = sel[1]
    for i = start, start + 3 do
        local line = subs[i]
        subs.insert(#subs - 1, line)
        aegisub.progress.set(i * 100 / 3)
        aegisub.progress.task('' .. line.class)
    end
    aegisub.set_undo_point(script_name)
end

function import_index(subs, sel)
    -- local start = sel[1]
    -- -- os.execute("echo before & pause")
    -- local text = "04:12 开始\n"
    -- local t = string.gsub(text, "^%s?(.-)%s?$", "%1")
    -- t = string.gsub(t, "%s+", " ")
    -- if string.find(t, " ") then
    --     -- os.execute("echo find & pause")
    --     local t1 = string.gsub(t, "%s.+$", "")
    --     local t2 = string.gsub(t, "^%S+%s", "")
    --     local ms = str2ms(t1)
    --     local item =  {
    --         class = "dialogue",
    --         comment = True,
    --         start_time=ms, end_time=ms,
    --         text = "# "..t2
    --     }
    --     subs.insert(start,subs[start])
    -- --     os.execute("echo done & pause")
    -- -- else
    -- --     os.execute("echo not find & pause")
    -- end

    local start = sel[1]
    -- for i = start, start + 3 do
    --     local line = subs[i]
    --     subs.insert(#subs - 1, line)
    --     aegisub.progress.set(i * 100 / 3)
    --     aegisub.progress.task('' .. line.class)
    --     os.execute("echo " .. line.class .. " " .. line.start_time .. " & pause")
    -- end

    local r_gui = { -- {class="label",x=1,y=0,width=3,height=1,label="function_name"},
    -- {class="edit",x=4,y=0,width=30,height=1,name="name",value="abc"},
    -- {class="label",x=1,y=1,width=1,height=1,label="function"},
    {
        class = "textbox",
        x = 1,
        y = 2,
        width = 60,
        height = 20,
        name = "fx",
        text = ""
    }}
    local rg, rg_res = aegisub.dialog.display(r_gui, {"OK", "Cancel"})
    if rg == "OK" then
        -- os.execute("echo  ok & pause")
        local lines = string.split(rg_res.fx, "\n")
        local textlist = {}
        local timelist = {}
        local sample = nil
        for l, text in ipairs(lines) do
            local t = string.gsub(text, "^%s?(.-)%s?$", "%1")
            t = string.gsub(t, "%s+", " ")
            -- os.execute("echo "..t.." & pause")
            if string.find(t, " ") then
                local t1 = string.gsub(t, "%s.+$", "")
                local t2 = string.gsub(t, "^%S+%s", "")
                local ms = str2ms(t1)
                table.insert(timelist, ms)
                table.insert(textlist, "# " .. t2)
            end
        end

        if #timelist < 1 then
            os.execute("echo no find subs & pause")
            return
        end

        local j = 1
        local insert_time = timelist[1]

        for i = 1, #subs do
            local line = subs[i]
            if line.class == "dialogue" then
                -- os.execute("echo  ok i=" .. i .. ", text=" .. line.text .. ", start=" .. line.start_time .. " insert_time=" ..insert_time.." & pause")
                if sample == nil then
                    sample = line
                    sample.comment = True
                end
                -- os.execute("echo  ok 2 & pause")
                if line.start_time >= insert_time then
                    local it = sample
                    -- os.execute("echo  ok 21 & pause")
                    it.start_time = insert_time
                    it.end_time = insert_time
                    it.text = textlist[j]
                    -- os.execute("echo  ok 22 & pause")
                    subs.insert(i, it)
                    j = j + 1
                    -- os.execute("echo  ok 23 j= " .. j .." & pause")
                    if j > #timelist then
                        break
                    else
                        insert_time = timelist[j]
                    end
                end
                os.execute("echo  ok 3 & pause")
            end
        end
        os.execute("echo  ok 4 & pause")
        for k = j, #timelist, 1 do
            local it = sample
            it.start_time = timelist[j]
            it.end_time = timelist[j]
            it.text = textlist[j]
            subs.append(it)
        end
    end
    os.execute("echo  ok 5 & pause")
    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name .. ' - ' .. script_description, script_description, import_index)
