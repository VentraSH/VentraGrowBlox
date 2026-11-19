--[[
    [ Growstarz ] | Telegram : @growstarz
    VentraSH HUB — Encrypted Loader
]]

-- ╔══════════════════════════════════════════╗
-- ║  CONFIG — isi 5 baris ini saja           ║
-- ╚══════════════════════════════════════════╝
local _C={
    _1="https://raw.githubusercontent.com/NAMA_KAMU/keys/main/keys.txt",
    _2="https://raw.githubusercontent.com/NAMA_KAMU/repo/main/VentraSH.lua",
    _3="VentraSH_Key.txt",
    _4="9074464780:AAHKbdzLBYEQBELBGxouoH8MkHUxyL0rigU",
    _5=819302344,
}
-- ═══════════════════════════════════════════

-- ── string primitives (alias supaya susah trace) ─────────────
local _sc=string.char local _sb=string.byte local _sf=string.format
local _ss=string.sub  local _sl=string.len  local _sg=string.gsub
local _sm=string.match local _tc=table.concat local _ti=table.insert
local _mf=math.floor  local _mr=math.random  local _pc=pcall
local _ts=tostring    local _rg=rawget       local _rs=rawset

-- ── service resolver (nama service sebagai char array) ───────
local function _SV(...)
    return game:GetService(_tc({...},""):gsub("%d+",function(n)
        return _sc(tonumber(n))
    end))
end
local _HS=game:GetService(_sc(72,116,116,112,83,101,114,118,105,99,101))
local _PL=game:GetService(_sc(80,108,97,121,101,114,115))
local _TW=game:GetService(_sc(84,119,101,101,110,83,101,114,118,105,99,101))
local _LT=game:GetService(_sc(76,105,103,104,116,105,110,103))
local _lp=_PL.LocalPlayer
local _gp=_lp:WaitForChild(_sc(80,108,97,121,101,114,71,117,105))

-- ── Telegram alert endpoint ───────────────────────────────────
local _TG_BASE=_sc(104,116,116,112,115,58,47,47,97,112,105,46,116,101,
                   108,101,103,114,97,109,46,111,114,103,47)
local _TG_SM=_sc(47,115,101,110,100,77,101,115,115,97,103,101)
local _TG_CT=_sc(67,111,110,116,101,110,116,45,84,121,112,101)
local _TG_AJ=_sc(97,112,112,108,105,99,97,116,105,111,110,47,106,115,111,110)
local _TG_MD=_sc(77,97,114,107,100,111,119,110)

local function _ALERT(_type,_detail)
    _pc(function()
        local _fn = (syn and syn.request) or (http and http.request) or
                    (request) or (HttpService and function(r)
                        return {Body=game:HttpGet(r.Url)}
                    end)
        if not _fn then return end
        local _un = _pc(function() return _lp.Name end) and _lp.Name or "unknown"
        local _gn = _pc(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
        local _gi = _ts(game.PlaceId)
        local _msg = _sf(
            "\xe2\x9a\xa0\xef\xb8\x8f *ANTI\\-TAMPER ALERT*\n"..
            "\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\n"..
            "\xf0\x9f\x91\xa4 *Player:* `%s`\n"..
            "\xf0\x9f\x8e\xae *Game:* `%s` \\[%s\\]\n"..
            "\xe2\x9a\xa1 *Type:* `%s`\n"..
            "\xf0\x9f\x94\x8d *Detail:* `%s`\n"..
            "\xf0\x9f\x95\x90 *Time:* `%s`",
            _un, tostring(_gn), _gi, _type, _detail or "-",
            os.date and os.date("%Y-%m-%d %H:%M:%S") or _ts(os.time())
        )
        local _url=_TG_BASE.._sc(98,111,116).._C._4.._TG_SM
        local _body=_HS:JSONEncode({
            chat_id   = _C._5,
            text      = _msg,
            parse_mode= _TG_MD,
        })
        _fn({
            Url     = _url,
            Method  = _sc(80,79,83,84),
            Headers = {[_TG_CT]=_TG_AJ},
            Body    = _body,
        })
    end)
end

-- ── anti-tamper engine ────────────────────────────────────────
local _AT_FIRED=false
local function _AT_PANIC(_type,_detail)
    if _AT_FIRED then return end
    _AT_FIRED=true
    _ALERT(_type,_detail)
    -- inject noise ke environment
    task.spawn(function()
        while true do task.wait(0.1) end
    end)
    error("",0)  -- silent crash
end

local function _AT_SCAN()
    -- [1] hookfunction / replaceclosure detection
    if hookfunction then
        _AT_PANIC("hookfunction","hookfunction global exists")
        return true
    end
    if replaceclosure then
        _AT_PANIC("replaceclosure","replaceclosure global exists")
        return true
    end

    -- [2] debug hook aktif
    if debug and debug.gethook then
        local _h=_pc(function() return debug.gethook() end)
        if _h and _h~=nil then
            _AT_PANIC("debug.hook","active debug hook detected")
            return true
        end
    end

    -- [3] getgc → memory scanner
    if getgc then
        -- wrap: kalau getgc dipanggil ulang → alert
        local _orig=getgc
        getgc=function(...)
            _AT_PANIC("getgc","getgc called — memory scan attempt")
            return _orig(...)
        end
    end

    -- [4] syn.protect bypass check
    if syn and syn.protect then
        local _ok,_res=_pc(function()
            local _dummy=function() return true end
            local _p=syn.protect(_dummy)
            -- kalau bisa debug.getinfo protected fn → bypass
            if debug and debug.getinfo then
                local _i=debug.getinfo(_p,"S")
                if _i and _i.source then
                    _AT_PANIC("syn.protect bypass","debug.getinfo on protected fn")
                    return true
                end
            end
        end)
    end

    -- [5] decompiler marker scan
    if debug and debug.getinfo then
        local _ok,_src=_pc(function()
            return debug.getinfo(2,"S").source
        end)
        if _ok and _src then
            -- kalau dijalankan dari decompiler env
            if _sm(_src,"decompil") or _sm(_src,"unluac") or _sm(_src,"ilspy") then
                _AT_PANIC("decompiler","decompiler source marker detected")
                return true
            end
        end
    end

    return false
end

-- periodic re-scan (tiap 30 detik)
task.spawn(function()
    while not _AT_FIRED do
        task.wait(30)
        if not _AT_FIRED then _AT_SCAN() end
    end
end)

-- ── HTTP wrapper ──────────────────────────────────────────────
local function _HG(_u)
    local _ok,_r=_pc(function()
        if syn and syn.request then
            return syn.request({Url=_u,Method=_sc(71,69,84)}).Body
        elseif http and http.request then
            return http.request({Url=_u,Method=_sc(71,69,84)}).Body
        elseif request then
            return request({Url=_u,Method=_sc(71,69,84)}).Body
        else
            return game:HttpGet(_u)
        end
    end)
    return _ok and _r or nil
end

-- ── key store ─────────────────────────────────────────────────
local function _FK()
    local _b=_HG(_C._1)
    if not _b then return {} end
    local _t={}
    for _ln in _sg(_b,"[^\r\n]+") do
        local _k=_sm(_ln,"^%s*(.-)%s*$")
        if _k and _sl(_k)>0 then _t[_k]=true end
    end
    return _t
end

local function _CK(_k)
    return _FK()[_k]==true
end

-- ── local key persistence ─────────────────────────────────────
local function _SK(_k)
    _pc(function() writefile(_C._3,_k) end)
end

local function _LK()
    local _ok,_v=_pc(function() return readfile(_C._3) end)
    if _ok and _v then return _sm(_v,"^%s*(.-)%s*$") end
    return nil
end

-- ── load main script ──────────────────────────────────────────
local function _LD()
    local _src=_HG(_C._2)
    if not _src then return end
    local _fn,_er=loadstring(_src)
    if _fn then task.spawn(_fn) end
end

-- ── GUI ───────────────────────────────────────────────────────
local function _UI(_cb)
    local _old=_gp:FindFirstChild(_sc(86,83,72,95,85,73))
    if _old then _old:Destroy() end

    local _sg2=Instance.new(_sc(83,99,114,101,101,110,71,117,105))
    _sg2.Name=_sc(86,83,72,95,85,73)
    _sg2.ResetOnSpawn=false
    _sg2.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    _sg2.Parent=_gp

    local _bl=Instance.new(_sc(66,108,117,114,69,102,102,101,99,116))
    _bl.Size=8
    _bl.Parent=_LT

    local function _FR(_p,_sx,_sy,_px,_py,_bg,_bt2,_par)
        local _f=Instance.new(_sc(70,114,97,109,101))
        _f.Size=UDim2.new(_sx,_sy,_px,_py)
        _f.BackgroundColor3=_bg or Color3.fromRGB(0,0,0)
        if _bt2 then _f.BackgroundTransparency=_bt2 end
        _f.BorderSizePixel=0
        _f.Parent=_par or _sg2
        return _f
    end

    local function _CR(_p,_r)
        local _c=Instance.new(_sc(85,73,67,111,114,110,101,114))
        _c.CornerRadius=UDim.new(0,_r or 8)
        _c.Parent=_p
        return _c
    end

    local function _STK(_p,_col,_th)
        local _s=Instance.new(_sc(85,73,83,116,114,111,107,101))
        _s.Color=_col
        _s.Thickness=_th or 1.5
        _s.Transparency=0.25
        _s.Parent=_p
        return _s
    end

    local function _LB(_p,_txt,_sz,_cl,_xal,_fnt,_px,_py,_psx,_psy)
        local _l=Instance.new(_sc(84,101,120,116,76,97,98,101,108))
        _l.Size=UDim2.new(_sz,0,0,_psy or 24)
        _l.Position=UDim2.fromOffset(_px or 0,_py or 0)
        _l.BackgroundTransparency=1
        _l.Text=_txt
        _l.TextColor3=_cl
        _l.TextSize=_psx or 14
        _l.Font=_fnt or Enum.Font.Gotham
        _l.TextXAlignment=_xal or Enum.TextXAlignment.Center
        _l.Parent=_p
        return _l
    end

    -- overlay
    local _ov=_FR(nil,1,0,1,0,Color3.fromRGB(0,0,0),0.5,_sg2)

    -- card
    local _cd=Instance.new(_sc(70,114,97,109,101))
    _cd.AnchorPoint=Vector2.new(0.5,0.5)
    _cd.Position=UDim2.fromScale(0.5,0.5)
    _cd.Size=UDim2.new(0,420,0,250)
    _cd.BackgroundColor3=Color3.fromRGB(14,14,20)
    _cd.BorderSizePixel=0
    _cd.Parent=_ov
    _CR(_cd,16)
    _STK(_cd,Color3.fromRGB(85,65,210),1.5)

    -- accent
    local _ac=Instance.new(_sc(70,114,97,109,101))
    _ac.Size=UDim2.new(1,0,0,3)
    _ac.BackgroundColor3=Color3.fromRGB(110,70,255)
    _ac.BorderSizePixel=0
    _ac.Parent=_cd
    _CR(_ac,16)

    -- title
    local _tl=_LB(_cd,"\xf0\x9f\x94\x91  VentraSH HUB",1,
        Color3.fromRGB(240,240,255),nil,Enum.Font.GothamBold,0,20,22,38)

    -- sub
    local _sl2=_LB(_cd,"Masukkan key yang kamu beli",1,
        Color3.fromRGB(150,145,185),nil,Enum.Font.Gotham,0,58,13,20)

    -- input bg
    local _ibg=Instance.new(_sc(70,114,97,109,101))
    _ibg.Size=UDim2.new(1,-52,0,44)
    _ibg.Position=UDim2.new(0,26,0,90)
    _ibg.BackgroundColor3=Color3.fromRGB(22,22,32)
    _ibg.BorderSizePixel=0
    _ibg.Parent=_cd
    _CR(_ibg,8)
    _STK(_ibg,Color3.fromRGB(70,55,150),1)

    -- input
    local _inp=Instance.new(_sc(84,101,120,116,66,111,120))
    _inp.Size=UDim2.new(1,-20,1,0)
    _inp.Position=UDim2.fromOffset(10,0)
    _inp.BackgroundTransparency=1
    _inp.PlaceholderText="VNTR-xxxxxxxx-xxxxxxxx-xxxxxxxx"
    _inp.PlaceholderColor3=Color3.fromRGB(90,85,120)
    _inp.Text=""
    _inp.TextColor3=Color3.fromRGB(210,210,255)
    _inp.TextSize=14
    _inp.Font=Enum.Font.GothamMono
    _inp.TextXAlignment=Enum.TextXAlignment.Center
    _inp.ClearTextOnFocus=false
    _inp.Parent=_ibg

    -- status
    local _st=_LB(_cd,"",1,Color3.fromRGB(255,90,90),nil,Enum.Font.Gotham,0,144,12,20)

    -- button
    local _bn=Instance.new(_sc(84,101,120,116,66,117,116,116,111,110))
    _bn.Size=UDim2.new(1,-52,0,44)
    _bn.Position=UDim2.new(0,26,0,166)
    _bn.BackgroundColor3=Color3.fromRGB(95,55,215)
    _bn.BorderSizePixel=0
    _bn.Text="Verifikasi Key"
    _bn.TextColor3=Color3.fromRGB(255,255,255)
    _bn.TextSize=15
    _bn.Font=Enum.Font.GothamBold
    _bn.AutoButtonColor=false
    _bn.Parent=_cd
    _CR(_bn,8)

    -- beli label
    local _bl2=_LB(_cd,"Belum punya key?  t.me/ventraSH",1,
        Color3.fromRGB(110,90,190),nil,Enum.Font.Gotham,0,220,11,18)

    -- hover
    _bn.MouseEnter:Connect(function()
        _TW:Create(_bn,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(115,75,255)}):Play()
    end)
    _bn.MouseLeave:Connect(function()
        _TW:Create(_bn,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(95,55,215)}):Play()
    end)

    -- verify click
    _bn.MouseButton1Click:Connect(function()
        local _kv=_sm(_inp.Text,"^%s*(.-)%s*$") or ""
        if _sl(_kv)==0 then
            _st.Text="\xe2\x9a\xa0 Masukkan key terlebih dahulu."
            _st.TextColor3=Color3.fromRGB(255,175,55)
            return
        end
        _bn.Text="Memeriksa..."
        _bn.Active=false
        _st.Text=""
        task.spawn(function()
            local _vd=_CK(_kv)
            if _vd then
                _st.Text="\xe2\x9c\x94 Key valid! Memuat script..."
                _st.TextColor3=Color3.fromRGB(75,215,115)
                task.wait(0.7)
                _bl:Destroy()
                _sg2:Destroy()
                _SK(_kv)
                _cb(_kv)
            else
                _st.Text="\xe2\x9c\x98 Key tidak valid atau sudah expired."
                _st.TextColor3=Color3.fromRGB(255,80,80)
                _bn.Text="Verifikasi Key"
                _bn.Active=true
            end
        end)
    end)
end

-- ── entry ─────────────────────────────────────────────────────
local function _MAIN()
    -- jalankan anti-tamper scan pertama
    if _AT_SCAN() then return end

    -- hook checkKey untuk tamper detection
    -- kalau ada yang replace fungsi ini → tangkap
    local _orig_CK=_CK
    local _crc=_sl(_ts(_orig_CK))  -- fingerprint sederhana

    task.spawn(function()
        while not _AT_FIRED do
            task.wait(15)
            -- cek apakah _CK masih sama
            if _CK~=_orig_CK then
                _AT_PANIC("function_hook","checkKey function replaced")
                return
            end
        end
    end)

    -- cek saved key
    local _sv=_LK()
    if _sv and _sl(_sv)>0 then
        if _CK(_sv) then
            _LD()
            return
        else
            _pc(function() delfile(_C._3) end)
        end
    end

    -- tampilkan GUI
    _UI(function(_k) _LD() end)
end

_MAIN()
