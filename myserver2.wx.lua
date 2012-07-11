package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")
require ("luacurl")
require("luafann")

local TIME_TICK_COUNT		= 5 * 1000 * 60
local TICK_TIMER_START		= 100
local TICK_TIMER_PAUSE		= 101



local function get_html(url)
    local result = { }
    local c = curl.new()
        c:setopt(curl.OPT_URL, url)
        c:setopt(curl.OPT_WRITEDATA, result)
        c:setopt(curl.OPT_WRITEFUNCTION, function(tab, buffer)
        table.insert(tab, buffer)
        return #buffer
    end)
    local ok = c:perform()
    c:close()
    c = nil
    return ok, table.concat(result)
end

local function post_html(url, postdata)
	local c = curl.new()

	rsp_buffer = ""

	c:setopt( curl.OPT_WRITEFUNCTION, function ( stream, buffer)
	rsp_buffer = rsp_buffer .. buffer
	return #buffer
	end);

	c:setopt( curl.OPT_PROGRESSFUNCTION, function ( _, dltotal, dlnow, uptotal, upnow )
	if dltotal == dlnow then
	req_done = true
	end
	end )

	c:setopt( curl.OPT_NOPROGRESS, false )

	c:setopt( curl.OPT_URL, url )
	c:setopt( curl.OPT_CONNECTTIMEOUT, 5 )
	c:setopt( curl.OPT_POSTFIELDS, postdata)
	c:setopt( curl.OPT_POST, true)

	c:perform()

	c:close()
	c=nil

	return req_done, rsp_buffer
end


local function split_params(row, redball)
	local t = {}
	local j = 1
	if(redball == true) then
		for i = 1, 33 do
			if( i == tonumber(row[j])) then
				t[i] = 1
				if(j < 6) then
					j = j + 1
				end
			else
				t[i] = 0
			end
		end
	else
		for i = 1, 16 do
			if(i == tonumber(row[7])) then
				t[i] = 1
			else
				t[i] = 0
			end
		end
	end

	if(redball == true) then
		return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33]
	else
		return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16]
	end
end

local function pick_numbers(row)
	local t = {}
	local n = #row
	for i = 1, n do
		t[i] = {k = i, v = row[i]}
	end
	table.sort(t, function(a,b)	if( a.v > b.v) then return true else return false end end)
	if(n == 16) then
		return t[1].k
	else
		return {t[1].k,t[2].k,t[3].k,t[4].k,t[5].k,t[6].k}
	end
end

local last_draw = 0
local function process_html(html)
	--<font class="cfont2"><strong>03001</strong></font>
	local draw = string.match(html, "<font class=\"cfont2\"><strong>(%d+)</strong></font>")

	--[[								<ul>
										<li class="ball_red">10</li>
										<li class="ball_red">11</li>
										<li class="ball_red">12</li>
										<li class="ball_red">13</li>
										<li class="ball_red">26</li>
										<li class="ball_red">28</li>
										<li class="ball_blue">11</li>
									</ul>
	]]

	local redball1,redball2,redball3,redball4,redball5,redball6,blueball = string.match(html, "<ul>%s-<li class=\"ball_red\">(%d+)</li>%s-<li class=\"ball_red\">(%d+)</li>%s-<li class=\"ball_red\">(%d+)</li>%s-<li class=\"ball_red\">(%d+)</li>%s-<li class=\"ball_red\">(%d+)</li>%s-<li class=\"ball_red\">(%d+)</li>%s-<li class=\"ball_blue\">(%d+)</li>%s-</ul>")
	local msg_string = draw .. ": " .. redball1 .. " " .. redball2 .. " " .. redball3 .. " " .. redball4 .. " " .. redball5 .. " " .. redball6 .. " + " .. blueball
	display(msg_string)
	frame:SetStatusText(msg_string)
	if(tonumber(draw) > tonumber(last_draw) and last_draw > 0) then
		local rows = {tonumber(redball1), tonumber(redball2), tonumber(redball3), tonumber(redball4), tonumber(redball5), tonumber(redball6), tonumber(blueball)}
		local times = {"2y","3y","5y","8y","all"}
		local blueballs = {}
		local redballs = {}
		display("下期预测 " .. tostring(tonumber(draw) + 1))
		local postdata = "DATA=" .. draw .. "|" .. redball1 .. "|" .. redball2 .. "|" .. redball3 .. "|" .. redball4 .. "|" .. redball5 .. "|" .. redball6 .. "|" .. blueball
		for i = 1, 5 do
			redballs[i] = {}
			local ann1 =  fann.create_from_file("red_train_" .. times[i] .. ".net")
			local t1 = {}
			t1[1],t1[2],t1[3],t1[4],t1[5],t1[6],t1[7],t1[8],t1[9],t1[10],t1[11],t1[12],t1[13],t1[14],t1[15],t1[16],t1[17],t1[18],t1[19],t1[20],t1[21],t1[22],t1[23],t1[24],t1[25],t1[26],t1[27],t1[28],t1[29],t1[30],t1[31],t1[32],t1[33] = ann1:run(split_params(rows, true))
			redballs[i] = pick_numbers(t1)
			local ann2 =  fann.create_from_file("blue_train_" .. times[i] .. ".net")
			local t2 = {}
			t2[1],t2[2],t2[3],t2[4],t2[5],t2[6],t2[7],t2[8],t2[9],t2[10],t2[11],t2[12],t2[13],t2[14],t2[15],t2[16] = ann2:run(split_params(rows, false))
			blueballs[i] = pick_numbers(t2)
			local draw_string = "  ";
			table.sort(redballs[i])
			for j = 1, 6 do
				draw_string = draw_string .. " " .. string.format("%02d", redballs[i][j])
				postdata = postdata .. "|" .. redballs[i][j]
			end
			draw_string = draw_string .. " + " .. string.format("%02d", blueballs[i])
			postdata = postdata .. "|" .. blueballs[i]
			display(draw_string)
		end
		local req_done, rsp_buffer = post_html("http://unionlotto.sinaapp.com/index.php/Index/notify_draw_open", postdata)
		display(rsp_buffer)
	end
	last_draw = draw
end

frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "双色球预测大师服务端",
                     wx.wxDefaultPosition, wx.wxDefaultSize)
local statusBar = frame:CreateStatusBar(1)

local m_text = wx.wxTextCtrl(frame, wx.wxID_ANY, "",
                             wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE + wx.wxTE_READONLY)
frame:Show(true)



local menuBar = wx.wxMenuBar()
fileMenu = wx.wxMenu {
    {TICK_TIMER_START, "运行",       "运行脚本" },
    {TICK_TIMER_PAUSE, "暂停",       "暂停脚本" },
    {},
    {wx.wxID_EXIT,  "退出",     "关闭本服务端" }
}

helpMenu = wx.wxMenu {
    {wx.wxID_ABOUT, "关于",       "关于本服务端" }
}

menuBar:Append(fileMenu, "程序")
menuBar:Append(helpMenu, "帮助")

frame:SetMenuBar(menuBar)

function TimerTick()
  --  display("现在时间 " .. os.date("%c"))
	local tod = os.date("*t", os.time())
	local h = tod["hour"]
	local m = tod["min"]
	local w = tod["wday"]
	local draw_is_open = false
	if( w == 1 or w == 3 or w == 5) then --sunday equals 1
		if(h == 21 and m > 25 ) then
			draw_is_open = true
		end
	end

	if(draw_is_open) then
		local url = "http://kaijiang.500wan.com/shtml/ssq/"
		local code, html = get_html(url)
		if(code) then
			process_html(html)
		end
	else
		display("未到开奖时间")
		frame:SetStatusText("程序正在运行")
	end
end

local gstimer = wx.wxTimer(frame)
frame:Connect(wx.wxEVT_TIMER, TimerTick)


gstimer:Start(TIME_TICK_COUNT)

frame:Connect( TICK_TIMER_START, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
		if(not gstimer:IsRunning()) then
			gstimer:Start(TIME_TICK_COUNT)
		end
    end)

frame:Connect( TICK_TIMER_PAUSE, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
		if(gstimer:IsRunning()) then
			gstimer:Stop()
        end
    end)

frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
		gstimer:Stop()
        frame:Close()
    end)


frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        wx.wxMessageBox('双色球预测大师取数服务端.\n\n'..
            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
            "About wxLua",
            wx.wxOK + wx.wxICON_INFORMATION,
            frame)
    end )

function display(m)
    m_text:AppendText(os.date("%c") .. " " ..tostring(m)..'\n')
end

frame:Show(true)


wx.wxGetApp():MainLoop()
