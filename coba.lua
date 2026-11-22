gg.setRanges(gg.REGION_ANONYMOUS)
local info = gg.getTargetInfo()
if not info or info.cmdLine ~= "com.mobile.legends:UnityKillsMe" then 
    gg.setVisible(false)
    gg.toast("\n## ERROR ##\nHarap pilih proses Mobile Legends\n(com.mobile.legends:UnityKillsMe) terlebih dahulu !")
end
gg.sleep(3000)
--====================================================================================
--                        KONFIGURASI VERSI & KONFIGURASI SERVER
--====================================================================================
local CURRENT_VERSION = "1.2"
local GIST_RAW_SLOTS  = "https://gist.github.com/ZeeStore02/33f50d78418027eb9f024b4f9b59814e/raw/Projects3.lua"
local FIREBASE_URL    = "https://keypengguna-default-rtdb.asia-southeast1.firebasedatabase.app/"

local _currentTimerOffsetMode = "advance" 
local OFFSET_TIMER = 0xC
local isPremiumUser = false
local _currentTierSetting = "v1"
local DEFAULT = { HIJAU = 22222, BIRU = 4994, PINK = 1500 }
local POLA = { p1 = 30000, p2 = 45000 }
local _slots = {}
local CACHE_DIR          = "/storage/emulated/0/"
local QUICK_CACHE_FILE   = CACHE_DIR .. "Zee_quick.lua"
local DEFAULT_CACHE_FILE = CACHE_DIR .. "Zee_default.lua"
local SLOTS_CACHE_FILE   = CACHE_DIR .. "Zee_slots.lua"
local LOG_CACHE_FILE     = CACHE_DIR .. "Zee_activity.lua"
local TOKEN_CACHE_FILE   = CACHE_DIR .. "Zee_token.lua"
local TIMER_CONFIG_FILE  = CACHE_DIR .. "Zee_timer_offset.lua"
--====================================================================================
--                        KONFIGURASI MENU & VISIBILITAS MENU
--====================================================================================
local _menuVisible = {
    quick          = true,
    inject         = true,
    timeskip       = true,
    kda            = true,
    setting_savage = true,
    drone          = true,
    maphack        = true,
    nograss        = true,
    bypass         = true,
    setting        = true,
    setting_damage = true,
    setting_add    = true,
    setting_urutkan= true,
    setting_import = true,
    log            = true,
    reset          = true,
    update         = true,
    usage          = true,
    token          = true,
}
local _menuIcons = {
    quick          = "⚡",
    inject         = "💉",
    timeskip       = "⏱️",
    kda            = "☣️",
    setting_savage = "☢️",
    drone          = "📹",
    maphack        = "🗺️",
    nograss        = "🌿",
    bypass         = "🛡️",
    setting        = "⚙️",
    setting_damage = "⚔️",
    setting_add    = "➕",
    setting_urutkan= "🔃",
    setting_import = "📥",
    log            = "📜",
    reset          = "🔄",
    update         = "➗",
    usage          = "🔄",
    token          = "🔄",
}
local _menuLabels = {
    quick          = "SETUP QUICK INJECT",
    inject         = "INJECT HERO",
    timeskip       = "SKIP WAKTU",
    kda            = "KDA (kill death assist)",
    setting_savage = "INJECT SAVAGE",
    drone          = "DRONE VIEW",
    maphack        = "MAPHACK (NO ICON)",
    nograss        = "NO GRASS",
    bypass         = "BYPASS",
    setting        = "SETTING",
    setting_damage = "SETTING DEFAULT DAMAGE",
    setting_add    = "TAMBAH SLOT HERO",
    setting_urutkan= "URUTKAN SLOT HERO",
    setting_import = "IMPORT HERO DARI GITHUB",
    log            = "LIHAT LOG AKTIVITAS",
    reset          = "RESET AKUN (root)",
    update         = "CEK UPDATE SCRIPT",
    usage          = "RESET HITUNGAN PEMAKAIAN HERO",
    token          = "GANTI AKUN / RESET TOKEN",
}
local _headerTitle = "ZEE STORE"
local _headerPesan = ""

local function loadOnlineMenuConfig()
    local res = gg.makeRequest(FIREBASE_URL .. "/.json?t=" .. os.time())
    if res and res.code == 200 and res.content and res.content ~= "null" then
        local content = res.content

        local titleFound = content:match('"header_title"%s*:%s*"([^"]+)"')
        if titleFound then _headerTitle = titleFound end

        local visibleBlock = content:match('"visible"%s*:%s*{(.-)}')
        if visibleBlock then
            for key in pairs(_menuVisible) do
                local visVal = visibleBlock:match('"' .. key .. '"%s*:%s*(true)') 
                            or visibleBlock:match('"' .. key .. '"%s*:%s*(false)')
                if visVal then
                    _menuVisible[key] = (visVal == "true")
                end
            end
        end

        local iconBlock = content:match('"icons"%s*:%s*{(.-)}')
        if iconBlock then
            for key in pairs(_menuIcons) do
                local iconFound = iconBlock:match('"' .. key .. '"%s*:%s*"([^"]+)"')
                if iconFound then _menuIcons[key] = iconFound end
            end
        end

        local labelBlock = content:match('"labels"%s*:%s*{(.-)}')
        if labelBlock then
            for key in pairs(_menuLabels) do
                local labelFound = labelBlock:match('"' .. key .. '"%s*:%s*"([^"]+)"')
                if labelFound then _menuLabels[key] = labelFound end
            end
        end
    end
end
--====================================================================================
--                             ENKRIPSI & DEKRIPSI CACHE
--====================================================================================
local function buildEncKey()
    local codes = {
        75, 66, 84, 77, 95, 82, 67, 52, 95, 83, 69, 67, 82, 69, 84, 95,
        107, 87, 57, 113, 55, 95, 50, 48, 50, 54,
    }
    local t = {}
    for i, c in ipairs(codes) do t[i] = string.char(c % 256) end
    return table.concat(t)
end
local ENC_KEY = buildEncKey()

local function byteXor(a, b)
    local result, bit = 0, 1
    for i = 1, 8 do
        local abit, bbit = a % 2, b % 2
        if abit ~= bbit then result = result + bit end
        a, b = (a - abit) / 2, (b - bbit) / 2
        bit = bit * 2
    end
    return result
end

local function rc4(data, key)
    local S = {}
    for i = 0, 255 do S[i] = i end
    local j, klen = 0, #key
    for i = 0, 255 do
        j = (j + S[i] + string.byte(key, (i % klen) + 1)) % 256
        S[i], S[j] = S[j], S[i]
    end
    local i, j2 = 0, 0
    local out = {}
    for n = 1, #data do
        i  = (i + 1) % 256
        j2 = (j2 + S[i]) % 256
        S[i], S[j2] = S[j2], S[i]
        local ks = S[(S[i] + S[j2]) % 256]
        out[n] = string.char(byteXor(string.byte(data, n), ks))
    end
    return table.concat(out)
end

local function encryptData(str)
    return (rc4(str, ENC_KEY):gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end

local function decryptData(str)
    local raw = str:gsub('%x%x', function(cc) return string.char(tonumber(cc, 16)) end)
    return rc4(raw, ENC_KEY)
end

local function saveTokenCache(token, status, expired)
    local dataStr = string.format("%s;%s;%s", token, status, expired)
    local f = io.open(TOKEN_CACHE_FILE, "w")
    if f then
        f:write(encryptData(dataStr))
        f:close()
    end
end

local function loadTokenCache()
    local f = io.open(TOKEN_CACHE_FILE, "r")
    if not f then return nil end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return nil end
    local ok, line = pcall(decryptData, raw)
    if not ok or not line then return nil end
    local token, status, expired = line:match("([^;]+);([^;]+);([^;]+)")
    return token, status, expired
end

local function saveTimerOffsetCache()
    local f = io.open(TIMER_CONFIG_FILE, "w")
    if f then
        f:write(encryptData(_currentTimerOffsetMode))
        f:close()
    end
end

local function loadTimerOffsetCache()
    local f = io.open(TIMER_CONFIG_FILE, "r")
    if not f then return end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return end
    local ok, line = pcall(decryptData, raw)
    if ok and line and (line == "advance" or line == "original") then
        _currentTimerOffsetMode = line
        if line == "original" then
            OFFSET_TIMER = 0x8
        else
            OFFSET_TIMER = 0xC
        end
    end
end
--====================================================================================
--               MEMBACA DEVICE ID UNIK DARI ANDROID (SAFE POPENABLE)
--====================================================================================
local function getAndroidDeviceId()
    local cacheFile = CACHE_DIR .. "Zee_dev_id.txt"
    
    local f = io.open(cacheFile, "r")
    if f then
        local savedId = f:read("*a")
        f:close()
        if savedId and savedId ~= "" then
            return savedId:gsub("%s+", "")
        end
    end

    local deviceId = ""
    local ok, handle = pcall(io.popen, "settings get secure android_id 2>/dev/null")
    if ok and handle then
        local okRead, res = pcall(function() return handle:read("*a") end)
        if okRead and res and res ~= "" then
            deviceId = res:gsub("%s+", "")
        end
        pcall(function() handle:close() end)
    end

    if deviceId == "" or deviceId == "null" or deviceId == "FALLBACK_DEVICE_ID" then
        math.randomseed(os.time() + os.clock() * 1000)
        deviceId = string.format("GEN_%04X%04X%04X", math.random(0, 0xFFFF), math.random(0, 0xFFFF), math.random(0, 0xFFFF))
    end

    local fWrite = io.open(cacheFile, "w")
    if fWrite then
        fWrite:write(deviceId)
        fWrite:close()
    end

    return deviceId
end
--====================================================================================
--            VERIFIKASI TOKEN (PASTI CEK ONLINE KE FIREBASE)
--====================================================================================
local function verifikasiTokenFirebase()
    local currentDeviceId = getAndroidDeviceId()
    local savedToken, savedStatus, savedExpired = loadTokenCache()
    local inputToken = ""

    if savedToken and savedToken ~= "" then
        inputToken = savedToken
        gg.toast("⏳ Memeriksa masa aktif & versi online...")
    else
        local promptToken = gg.prompt(
            {"🔑 MASUKKAN TOKEN AKSES ANDA:"},
            {""},
            {"text"}
        )
        
        if not promptToken or promptToken[1] == "" then
            gg.alert("❌ Token wajib diisi untuk menjalankan script!")
            os.exit()
        end
        inputToken = promptToken[1]:gsub("%s+", "")
        gg.toast("⏳ Memeriksa token online & mengunci device...")
    end

    local cleanBaseUrl = FIREBASE_URL:gsub("/$", "")
    local urlRequest = cleanBaseUrl .. "/tokens/" .. inputToken .. ".json?t=" .. os.time()
    local res = gg.makeRequest(urlRequest)
    
    if type(res) ~= "table" then
        gg.alert("❌ GAGAL TERHUBUNG!\n\nPastikan koneksi internet aktif atau izinkan akses internet pada GameGuardian.\nDetail: " .. tostring(res))
        os.exit()
    end

    if res.code ~= 200 then
        gg.alert("❌ SERVER ERROR (Kode: " .. tostring(res.code) .. ")\n\nPeriksa FIREBASE_URL atau Rules Firebase Anda.")
        os.exit()
    end

    if not res.content or res.content == "null" or res.content == "" then
        os.remove(TOKEN_CACHE_FILE)
        gg.alert("❌ TOKEN TIDAK DITEMUKAN!\n\nToken '" .. inputToken .. "' tidak terdaftar di database atau sudah kedaluwarsa dan terhapus.")
        os.exit()
    end
    
    local konten = res.content
    local statusToken = konten:match('"status"%s*:%s*"([^"]+)"')
    if not statusToken then
        local bersih = konten:gsub('%W', ''):lower()
        if bersih:find("premium") then statusToken = "premium"
        elseif bersih:find("free") then statusToken = "free" end
    end
    
    if statusToken == "premium" then
        isPremiumUser = true
    elseif statusToken == "free" then
        isPremiumUser = false
    else
        gg.alert("❌ Status token tidak valid di database!")
        os.exit()
    end
    
    local parsedExpired = konten:match('"expired"%s*:%s*"([^"]+)"')
    if parsedExpired then
        expiredToken = parsedExpired
        local thn, bln, tgl = expiredToken:match("(%d+)-(%d+)-(%d+)")
        if thn and bln and tgl then
            local formatExpiredDB = string.format("%s%s%s", thn, bln, tgl)
            if os.date("%Y%m%d") > formatExpiredDB then
                os.remove(TOKEN_CACHE_FILE)
                gg.alert("❌ TOKEN EXPIRED!\n\nMasa aktif token ini telah habis pada:\n" .. expiredToken)
                os.exit()
            end
        end
    end

    local tokenDeviceId = konten:match('"deviceId"%s*:%s*"([^"]+)"')
    if not tokenDeviceId or tokenDeviceId == "" then
        local patchData = string.format('{"deviceId":"%s","claimedAt":"%s"}', currentDeviceId, os.date("%Y-%m-%d"))
        gg.makeRequest(cleanBaseUrl .. "/tokens/" .. inputToken .. ".json", { method = "PATCH" }, patchData)
        tokenDeviceId = currentDeviceId
    end

    if tokenDeviceId ~= currentDeviceId then
        os.remove(TOKEN_CACHE_FILE)
        gg.alert("❌ AKSES DITOLAK!\n\nToken ini sudah terikat dengan Perangkat/Device ID lain!\n1 Token hanya untuk 1 Perangkat.")
        os.exit()
    end

    if not isPremiumUser then
        local urlDeviceCheck = cleanBaseUrl .. "/devices/" .. currentDeviceId .. ".json?t=" .. os.time()
        local resDev = gg.makeRequest(urlDeviceCheck)
        
        if type(resDev) == "table" and resDev.code == 200 and resDev.content and resDev.content ~= "null" then
            local lastFreeClaim = resDev.content:match('"lastFreeClaim"%s*:%s*"([^"]+)"')
            local lastUsedToken = resDev.content:match('"lastToken"%s*:%s*"([^"]+)"')
            
            if lastFreeClaim then
                local y, m, d = lastFreeClaim:match("(%d+)-(%d+)-(%d+)")
                if y and m and d then
                    local tKlaim = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d)})
                    local tSekarang = os.time()
                    local selisihHari = math.floor((tSekarang - tKlaim) / 86400)
                    
                    if inputToken ~= lastUsedToken and selisihHari < 30 then
                        local sisaHari = 30 - selisihHari
                        os.remove(TOKEN_CACHE_FILE)
                        gg.alert(string.format(
                            "❌ PENOLAKAN TOKEN FREE!\n\nPerangkat ini sudah pernah menggunakan Token Free pada: %s.\n\nAnda baru bisa menggunakan Token Free baru dalam %d HARI lagi.\n\nSilakan gunakan Token PREMIUM jika ingin akses tanpa jeda!",
                            lastFreeClaim, sisaHari
                        ))
                        os.exit()
                    end
                end
            end
        else
            local devData = string.format('{"lastFreeClaim":"%s","lastToken":"%s"}', os.date("%Y-%m-%d"), inputToken)
            gg.makeRequest(cleanBaseUrl .. "/devices/" .. currentDeviceId .. ".json", { method = "PATCH" }, devData)
        end
    end
    
    saveTokenCache(inputToken, statusToken, expiredToken)
    
    if isPremiumUser then
        gg.toast("🔥 Login Berhasil: Akses PREMIUM Aktif!")
    else
        gg.toast("👤 Login Berhasil: Akses FREE Aktif!")
    end
end

--====================================================================================
--               FITUR CHECK UPDATE AUTOMATIS (FREE vs PREMIUM)
--====================================================================================
local function cekUpdateScript()
    gg.toast("🔍 Memeriksa pembaruan script...")
    local res = gg.makeRequest(FIREBASE_URL .. "/version_info.json?t=" .. os.time())
    
    if res and res.code == 200 and res.content and res.content ~= "null" then
        local latestVer = res.content:match('"latestVersion"%s*:%s*"([^"]+)"') 
                        or res.content:match('"latestVersion"%s*:%s*([%d%.]+)')
        
        local urlFree = res.content:match('"downloadUrlFree"%s*:%s*"([^"]+)"') 
                        or "https://zeestore02.github.io"
        local urlPremium = res.content:match('"downloadUrlPremium"%s*:%s*"([^"]+)"') 
                        or "https://zeestore02.github.io"
        
        local downloadUrl = isPremiumUser and urlPremium or urlFree
        
        local rawChangelog = res.content:match('"changelog"%s*:%s*"([^"]+)"') or "Perbaikan bug & peningkatan performa."
        local updateChangelog = rawChangelog:gsub("\\n", "\n")

        latestVer = latestVer and tostring(latestVer)
        
        if latestVer and latestVer ~= tostring(CURRENT_VERSION) then
            if not isPremiumUser then
                gg.alert(string.format(
                    "❌ UPDATE WAJIB UNTUK AKUN FREE!\n\nScript v%s Anda sudah kedaluwarsa.\nVersi Terbaru Tersedia: v%s\n\nLink Update (FREE):\n%s\n\nCatatan Pembaruan:\n%s\n\nSilakan unduh versi terbaru untuk melanjutkan!",
                    CURRENT_VERSION, latestVer, downloadUrl, updateChangelog
                ))
                os.remove(TOKEN_CACHE_FILE)
                gg.copyText(downloadUrl)
                gg.toast("📋 Link Update (FREE) telah disalin ke clipboard!")
                os.exit()
            else
                local opt = gg.choice({
                    "▶️ LANJUTKAN PAKAI VERSI LAMA (v" .. CURRENT_VERSION .. ")",
                    "📋 SALIN LINK SCRIPT TERBARU (v" .. latestVer .. ")"
                }, nil, string.format("🚀 UPDATE SCRIPT TERSEDIA (PREMIUM USER)\n\nVersi Saat Ini: v%s\nVersi Terbaru: v%s\n\nCatatan Pembaruan:\n%s", CURRENT_VERSION, latestVer, updateChangelog))
                
                if opt == 2 then
                    gg.copyText(downloadUrl)
                    gg.alert("✅ Link versi terbaru (PREMIUM) berhasil disalin ke clipboard!\n\nLink: " .. downloadUrl)
                end
            end
        end
    end
end
--====================================================================================
--                   PROSES EKSEKUSI LOGIN, SYNC MENU & CEK UPDATE
--====================================================================================
verifikasiTokenFirebase()
loadOnlineMenuConfig()
cekUpdateScript()
loadTimerOffsetCache()
local statusTeks = isPremiumUser and "PREMIUM 🔥" or "FREE 👤"
_headerPesan = string.format("%s\n\n[%s] | EXP = %s", _headerTitle, statusTeks, expiredToken or "N/A")
--====================================================================================
--                          RIWAYAT AKTIVITAS (MAX 100 BARIS)
--====================================================================================
local function writeLog(aktivitas)
    local waktuSekarang = os.date("%d/%m/%Y %H:%M:%S")
    local formatTeks = string.format("[%s] %s", waktuSekarang, aktivitas)
    
    local barisLog = {}
    local fRead = io.open(LOG_CACHE_FILE, "r")
    if fRead then
        local rawLama = fRead:read("*a")
        fRead:close()
        if rawLama and rawLama ~= "" then
            local ok, decrypted = pcall(decryptData, rawLama)
            if ok and decrypted then
                for baris in decrypted:gmatch("[^\r\n]+") do
                    table.insert(barisLog, baris)
                end
            end
        end
    end
    
    table.insert(barisLog, formatTeks)
    
    while #barisLog > 100 do
        table.remove(barisLog, 1)
    end
    
    local logTerbaru = table.concat(barisLog, "\n") .. "\n"
    local encryptedDataStr = encryptData(logTerbaru)
    
    local fWrite = io.open(LOG_CACHE_FILE, "w")
    if fWrite then
        fWrite:write(encryptedDataStr)
        fWrite:close()
    end
end
--====================================================================================
--                     BOLD
--====================================================================================
local function toBold(str)
    if (gg.ANDROID_SDK_INT or 99) <= 27 then
        return str
    end
    local upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local lower = "abcdefghijklmnopqrstuvwxyz"
    local digit = "0123456789"
    local boldUpperStart = 0x1D5D4
    local boldLowerStart = 0x1D5EE
    local boldDigitStart = 0x1D7EC
    local function utf8char(cp)
        return string.char(
            0xF0 + math.floor(cp / 0x40000),
            0x80 + (math.floor(cp / 0x1000) % 0x40),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    end
    local result = {}
    for i = 1, #str do
        local c = str:sub(i, i)
        local idxU = upper:find(c, 1, true)
        local idxL = lower:find(c, 1, true)
        local idxD = digit:find(c, 1, true)
        if idxU then
            table.insert(result, utf8char(boldUpperStart + idxU - 1))
        elseif idxL then
            table.insert(result, utf8char(boldLowerStart + idxL - 1))
        elseif idxD then
            table.insert(result, utf8char(boldDigitStart + idxD - 1))
        else
            table.insert(result, c)
        end
    end
    return table.concat(result)
end
--====================================================================================
--                        SIMPAN DAN MUAT HERO
--====================================================================================
local function saveDefaultCache()
    local f = io.open(DEFAULT_CACHE_FILE, "w")
    if f then
        f:write(encryptData(string.format("%d;%d;%d", DEFAULT.HIJAU, DEFAULT.BIRU, DEFAULT.PINK)))
        f:close()
    else
        gg.toast("⚠️ Gagal simpan default!")
    end
end

local function loadDefaultCache()
    local f = io.open(DEFAULT_CACHE_FILE, "r")
    if not f then return end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return end
    local ok, line = pcall(decryptData, raw)
    if not ok or not line then return end
    local h, b, p = line:match("(%d+);(%d+);(%d+)")
    if h and b and p then
        DEFAULT = { HIJAU = tonumber(h), BIRU = tonumber(b), PINK = tonumber(p) }
    end
end
--====================================================================================
--                        PENGURUTAN HERO FREKUENSI
--====================================================================================
local function sortSlotsByUsage()
    table.sort(_slots, function(a, b)
        local countA = a.useCount or 0
        local countB = b.useCount or 0
        return countA > countB
    end)
end

local function saveSlotsCache()
    local lines = { "return {" }
    for _, s in ipairs(_slots) do
        table.insert(lines, string.format(
            "{ nama = %q, PINK = %d, BIRU = %d, HIJAU = %d, source = %q, hidden = %s, useCount = %d },",
            s.nama, s.PINK, s.BIRU, s.HIJAU, s.source or "user", s.hidden and "true" or "nil", s.useCount or 0
        ))
    end
    table.insert(lines, "}")
    local f = io.open(SLOTS_CACHE_FILE, "w")
    if f then
        f:write(encryptData(table.concat(lines, "\n")))
        f:close()
    else
        gg.toast("⚠️ Gagal simpan slot!")
    end
end
--====================================================================================
--                         MUAT HERO
--====================================================================================
local function loadSlotsCache()
    local f = io.open(SLOTS_CACHE_FILE, "r")
    if not f then return false end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return false end
    local ok1, content = pcall(decryptData, raw)
    if not ok1 or not content or content == "" then return false end
    local fn = load(content)
    if not fn then return false end
    local ok, result = pcall(fn)
    if ok and type(result) == "table" and #result > 0 then
        for _, s in ipairs(result) do
            if s.source == nil then s.source = "gist" end
            if s.useCount == nil then s.useCount = 0 end
        end
        _slots = result
        sortSlotsByUsage()
        return true
    end
    return false
end
--====================================================================================
--                      SIMPAN DAN MUAT SETUP QUICK INJECT
--====================================================================================
local _quick = { slot = nil, menit = nil, kdaVersi = nil, kdaTim = nil, kdaMusuh = nil } 
local function saveQuickCache()
    if not _quick.slot then return end
    local dataStr = string.format("%s;%d;%s;%d;%d;%d", 
        _quick.slot.nama, 
        math.floor(_quick.menit or 0), 
        _currentTierSetting,
        _quick.kdaVersi or 0,
        _quick.kdaTim or 0,
        _quick.kdaMusuh or 0
    )
    local f = io.open(QUICK_CACHE_FILE, "w")
    if f then
        f:write(encryptData(dataStr))
        f:close()
    end
end

local function loadQuickCache()
    local f = io.open(QUICK_CACHE_FILE, "r")
    if not f then return end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return end
    local ok, line = pcall(decryptData, raw)
    if not ok or not line then return end
    local namaHero, menit, tierKey, kdaVersi, kdaTim, kdaMusuh = line:match("([^;]+);(%d+);([^;]+);(%d+);(%d+);(%d+)")
    if namaHero and menit and tierKey then
        for _, s in ipairs(_slots) do
            if s.nama == namaHero then
                _quick.slot = s
                _quick.menit = tonumber(menit)
                _currentTierSetting = tierKey 
                _quick.kdaVersi = tonumber(kdaVersi) or 0
                _quick.kdaTim = tonumber(kdaTim) or 0
                _quick.kdaMusuh = tonumber(kdaMusuh) or 0
                break
            end
        end
    end
end
math.randomseed(os.time())
--====================================================================================
--              PROSES INJECT HERO
--====================================================================================
local TIER_LIST = {
    { key = "v1", label = "⚔️ v1", nama = "v1" },
    { key = "v2", label = "⭐ v2", nama = "v2" },
    { key = "v3", label = "💎 v3", nama = "v3" },
}
local function namaTier(tierKey)
    for _, t in ipairs(TIER_LIST) do
        if t.key == tierKey then return t.nama end
    end
    return nil
end
local function doInjectOnce(PINK, BIRU, HIJAU)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber(string.format("%d;%d;%d", PINK, BIRU, HIJAU), gg.TYPE_DWORD)
    local hasil = gg.getResults(200)
    if not hasil or #hasil == 0 then
        return false
    end
    for _, v in ipairs(hasil) do
        if v.value == PINK then
            v.value = DEFAULT.PINK
        elseif v.value == BIRU then
            v.value = DEFAULT.BIRU
        elseif v.value == HIJAU then
            v.value = DEFAULT.HIJAU
        end
    end
    gg.setValues(hasil)
    gg.clearResults()
    gg.clearList()
    return true
end
local function nilaiTier(PINK, tierKey)
    if tierKey == "v1" then
        return PINK + 40
    elseif tierKey == "v2" then
        return PINK + 20
    else
        return PINK
    end
end
--====================================================================================
--                      PROSES QUICK INJECT (WITH FALLBACK: V1 -> V3 -> V2)
--====================================================================================
local function doInjectTier(PINK, BIRU, HIJAU, namaHero, tierKey)
    local searchOrder = { tierKey }
    
    if tierKey == "v1" then
        searchOrder = { "v1", "v3", "v2" }
    elseif tierKey == "v2" then
        searchOrder = { "v2", "v1", "v3" }
    elseif tierKey == "v3" then
        searchOrder = { "v3", "v1", "v2" }
    end

    local hasil = nil
    local successTier = nil

    for _, currentTier in ipairs(searchOrder) do
        local targetPink = nilaiTier(PINK, currentTier)
        gg.clearResults()
        gg.clearList()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber(string.format("%d;%d;%d", targetPink, BIRU, HIJAU), gg.TYPE_DWORD)
        
        local tempHasil = gg.getResults(200)
        if tempHasil and #tempHasil > 0 then
            hasil = tempHasil
            successTier = currentTier
            break
        end
    end

    if not hasil or #hasil == 0 then
        writeLog(string.format("Gagal Inject Hero: %s [%s]", (namaHero or "Manual"), string.upper(tierKey)))
        gg.toast("❌ Tidak ditemukan di semua versi !")
        return false
    end

    local targetPinkFound = nilaiTier(PINK, successTier)
    for _, v in ipairs(hasil) do
        if v.value == targetPinkFound then
            v.value = DEFAULT.PINK
        elseif v.value == BIRU then
            v.value = DEFAULT.BIRU
        elseif v.value == HIJAU then
            v.value = DEFAULT.HIJAU
        end
    end

    gg.setValues(hasil)
    gg.clearResults()
    gg.clearList()

    for _, s in ipairs(_slots) do
        if s.nama == namaHero then
            s.useCount = (s.useCount or 0) + 1
            break
        end
    end
    sortSlotsByUsage()
    saveSlotsCache()
    
    local infoTier = string.upper(successTier)
    if successTier ~= tierKey then
        infoTier = infoTier .. " (Fallback)"
    end

    writeLog(string.format("Sukses Inject Hero: %s [%s]", (namaHero or "Manual"), infoTier))
    gg.toast("✅ Inject " .. (namaHero or "Manual") .. " [" .. (namaTier(successTier) or successTier) .. "] Selesai!")
    return true
end
--====================================================================================
--                          SKIP TIME
--====================================================================================
local function doSkipTime(menit)
    if POLA.p1 == 0 and POLA.p2 == 0 then
        gg.toast("❌ POLA belum diisi di script! Edit p1/p2 dulu.")
        return
    end

    local nilaiMs   = menit * 60000
    local MAX_WAJAR = 3000000
    local target    = nil
    local maxRetryScan = 4
    local sleepMs   = 250

    for percobaan = 1, maxRetryScan do
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber(string.format("%d;%d;1", POLA.p1, POLA.p2), gg.TYPE_DWORD)
        gg.refineNumber(POLA.p1, gg.TYPE_DWORD)
        local hasil = gg.getResults(50)

        if hasil and #hasil > 0 then
            local save = {}
            for _, v in ipairs(hasil) do
                table.insert(save, { address = v.address - OFFSET_TIMER, flags = gg.TYPE_DWORD })
            end

            local snap1 = gg.getValues(save)
            gg.sleep(sleepMs)
            local snap2 = gg.getValues(save)
            gg.sleep(sleepMs)
            local snap3 = gg.getValues(save)

            local kandidat = {}
            for i = 1, #snap1 do
                local v1, v2, v3 = snap1[i].value, snap2[i].value, snap3[i].value
                if v1 and v2 and v3 then
                    local d1 = v2 - v1
                    local d2 = v3 - v2
                    local berubah   = (v1 ~= v2) and (v2 ~= v3)
                    local rangeOk   = v1 > 0 and v1 <= MAX_WAJAR
                                  and v2 > 0 and v2 <= MAX_WAJAR
                                  and v3 > 0 and v3 <= MAX_WAJAR
                    -- delta antar snapshot harus konsisten arah & besarannya wajar
                    local deltaKonsisten = berubah
                        and (d1 * d2 > 0 or (d1 ~= 0 and d2 ~= 0))
                        and math.abs(d1) <= sleepMs * 2
                        and math.abs(d2) <= sleepMs * 2

                    if rangeOk and deltaKonsisten then
                        table.insert(kandidat, {
                            address = save[i].address,
                            flags   = gg.TYPE_DWORD,
                            skor    = math.abs(d1) + math.abs(d2)
                        })
                    end
                end
            end

            if #kandidat > 0 then
                table.sort(kandidat, function(a, b) return a.skor < b.skor end)
                target = kandidat[1]
                break
            end
        end

        gg.sleep(sleepMs)
    end

    gg.clearResults()

    if not target then
        local namaServerTeks = (_currentTimerOffsetMode == "original") and "Original Server" or "Advance Server"
        writeLog("Skip Waktu Gagal: Timer tidak ditemukan (" .. namaServerTeks .. ")")
        gg.toast("💀 Timer tidak ditemukan (" .. namaServerTeks .. ")!")
        return
    end

    target.value = nilaiMs
    target.name  = "skipwaktu"

    local sukses = false
    local TOLERANSI_MS = 3000
    for cobaWrite = 1, 3 do
        gg.setValues({ target })
        gg.sleep(150)
        local cek = gg.getValues({ target })
        if cek[1] and math.abs(cek[1].value - nilaiMs) <= TOLERANSI_MS then
            sukses = true
            break
        end
        gg.sleep(150)
    end

    gg.clearResults()

    if sukses then
        local namaServerTeks = (_currentTimerOffsetMode == "original") and "Original Server" or "Advance Server"
        writeLog("Skip Waktu Berhasil (" .. namaServerTeks .. ")")
        gg.toast("✅ Skip timer berhasil! ⏱️")
    else
        gg.toast("⚠️ Timer gagal  (untuk a16 no root)")
    end
end
--====================================================================================
--                      DRONE VIEW
--====================================================================================
function split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

function xgxc(szpy, qmxg)
    xgsl = 0
    for x = 1, #(qmxg) do
        xgpy = szpy + qmxg[x]["offset"]
        xglx = qmxg[x]["type"]
        xgsz = qmxg[x]["value"]
        xgdj = qmxg[x]["freeze"]
        if xgdj == nil or xgdj == "" then
            gg.setValues({[1] = {address = xgpy, flags = xglx, value = xgsz}})
        else
            gg.addListItems({[1] = {address = xgpy, flags = xglx, freeze = xgdj, value = xgsz}})
        end
        xgsl = xgsl + 1
        xgjg = true
    end
end

function xqmnb(qmnb)
    gg.clearResults()
    gg.clearList()
    gg.setRanges(qmnb[1]["memory"])
    gg.searchNumber(qmnb[3]["value"], qmnb[3]["type"])
    
    if gg.getResultCount() ~= 0 then
        gg.refineNumber(qmnb[3]["value"], qmnb[3]["type"])
        if gg.getResultCount() ~= 0 then
            sl = gg.getResults(999999)
            sz = gg.getResultCount()
            xgsl = 0
            if sz > 999999 then sz = 999999 end
            
            for i = 1, sz do
                pdsz = true
                for v = 4, #(qmnb) do
                    if pdsz == true then
                        pysz = {}
                        pysz[1] = {}
                        pysz[1].address = sl[i].address + qmnb[v]["offset"]
                        pysz[1].flags = qmnb[v]["type"]
                        szpy = gg.getValues(pysz)
                        pdpd = qmnb[v]["lv"] .. ";" .. szpy[1].value
                        szpd = split(pdpd, ";")
                        tzszpd = szpd[1]
                        pyszpd = szpd[2]
                        if tzszpd == pyszpd then
                            pdjg = true
                            pdsz = true
                        else
                            pdjg = false
                            pdsz = false
                        end
                    end
                end
                if pdjg == true then
                    szpy = sl[i].address
                    xgxc(szpy, qmxg)
                end
            end
        end
    end
end

function Drone()
    local values = {
        ["1"]  = "1084227584", ["2"]  = "1092616192", ["3"]  = "1095712192",
        ["4"]  = "1097859072", ["5"]  = "1101004800", ["6"]  = "1103626240",
        ["7"]  = "1106247680", ["8"]  = "1108082688", ["9"]  = "1109393408",
        ["10"] = "1110704128", ["11"] = "1112014848", ["12"] = "1112512598"
    }

    local UBED = gg.prompt({" \nDRONE VIEW [0;12]", "BACK"}, {}, {"number", "checkbox"})
    if not UBED then return end

    local choice = UBED[1]

    if choice == "0" then
        gg.clearResults()
        gg.clearList()
        writeLog("DRONE VIEW Reset (0)")
    elseif values[choice] then
        local qmnb = {
            {memory = "4"},
            {name = ""},
            {value = "4294968312.0", type = "64"},
            {lv = "1081006571", offset = "-168", type = "32"}
        }
        qmxg = {{value = values[choice], offset = "-128", type = "4"}}

        xqmnb(qmnb)
        
        gg.clearResults()
        gg.clearList()
        
        writeLog("DRONE VIEW Level " .. choice)
    end

    if UBED[2] then os.exit() end
    gg.toast("BERHASIL DI MODIFIKASI")
end
--====================================================================================
--                      BYPASS ANTI CHEAT
--====================================================================================
function bypassAntiCheat()
    
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.toast("🔒 Activating Bypass...")

    gg.searchNumber("59916", gg.TYPE_AUTO)
    gg.searchNumber("-5620", gg.TYPE_WORD)
    gg.getResults(100)
    gg.editAll("0", gg.TYPE_WORD)
    gg.clearResults()
    gg.clearList()
    
    gg.searchNumber("59916", gg.TYPE_DWORD)
    gg.getResults(100)
    gg.editAll("0", gg.TYPE_DWORD)
    gg.clearResults()
    gg.clearList()
    
    gg.searchNumber("59916", gg.TYPE_XOR)
    gg.getResults(100)
    gg.editAll("0", gg.TYPE_XOR)
    gg.clearResults()
    gg.clearList()
    writeLog("BYPASS ACTIVATED")
    gg.toast("✅ BYPASS ACTIVATED")
end
--====================================================================================
--                      MAPS HACK (NO ICON)
--====================================================================================
function Maphack()
    
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    
    gg.searchNumber("98784247822;47244640279;4510805388492275723:512", gg.TYPE_QWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
    gg.refineNumber("98784247822", gg.TYPE_QWORD, false, gg.SIGN_EQUAL, 0, -1, 0)
    
    gg.getResults(100, nil, nil, nil, nil, nil, nil, nil, nil)
    gg.editAll("9", gg.TYPE_QWORD)
    
    writeLog("ACTIVATED MAPS HACK")
    gg.toast("MAPS HACK ACTIVATED (no icon)")
    gg.clearResults()
    gg.clearList()
end
--====================================================================================
--                      NO GRASS (HAPUS RUMPUT)
--====================================================================================
function noGrass()
    gg.toast("No Grass Searching...")
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS)

    gg.searchNumber("1.0F;256.0F;20.0F", gg.TYPE_FLOAT)
    
    if gg.getResultsCount() > 0 then
        gg.refineNumber("1.0", gg.TYPE_FLOAT)
        local results = gg.getResults(9999)
        
        if #results > 0 then
            for i = 1, #results do results[i].value = "0.0" end
            gg.setValues(results)
            gg.toast("No Grass Active! Edited: " .. #results .. " ✓")
        else
            gg.toast("No Grass: No results! Use INGAME only!")
        end
    else
        gg.toast("No Grass: No results! Use INGAME only!")
    end
    gg.clearResults()
end
--====================================================================================
--                          KDA (KILL, DEATH, ASSIST)
--====================================================================================
local HARGA_KDA = {
    signature = { 601295421455, 601295421580 },
    vietnam   = { apel = 0x24, anggur = 0x28, mangga = 0x38 },
    india     = { apel = 0x28, anggur = 0x2C, mangga = 0x3C },
}
local BUAH_IDX_KDA   = { 10, 8, 6, 4, 2 }
local BAGING_IDX_KDA = { 9, 7, 5, 3, 1 }
local _pedagangTerpakai      = {}
local _pedagangBatchTerakhir = nil

local function getBasePedagangKDA(harga)
    local sig = harga.signature
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber(sig[1] .. ";" .. sig[2], gg.TYPE_QWORD, false, gg.SIGN_EQUAL, 0, -1)
    local results = gg.getResults(1000)
    local filtered = {}
    for _, v in ipairs(results) do
        if v.value == sig[1] then table.insert(filtered, v) end
    end
    gg.clearResults()
    gg.clearList()
    if #filtered < 10 then return nil end
    local segar = {}
    for _, v in ipairs(filtered) do
        if not _pedagangTerpakai[v.address] then table.insert(segar, v) end
    end
    if #segar >= 10 then
        local pedagang = {}
        for j = #segar - 9, #segar do table.insert(pedagang, segar[j]) end
        for _, v in ipairs(pedagang) do _pedagangTerpakai[v.address] = true end
        _pedagangBatchTerakhir = pedagang
        return pedagang
    end
    if _pedagangBatchTerakhir then return _pedagangBatchTerakhir end
    return nil
end

local function distribusiKDA(total, n)
    math.randomseed(os.time() + total)
    local base = math.floor(total / n)
    local hasil, terkumpul = {}, 0
    for i = 1, n - 1 do
        local val = math.max(0, base + math.random(-2, 2))
        hasil[i] = val
        terkumpul = terkumpul + val
    end
    hasil[n] = math.max(0, total - terkumpul)
    return hasil
end

local function distribusiManggaKDA(apel_dist, n, kecil, pct_min, pct_max)
    local hasil = {}
    for i = 1, n do
        if pct_min and pct_max then
            local pct = pct_min + math.random() * (pct_max - pct_min)
            hasil[i] = math.max(0, math.floor(apel_dist[i] * pct))
        else
            local kurang = kecil and math.random(1, 2) or math.random(3, 7)
            hasil[i] = math.max(0, apel_dist[i] - kurang)
        end
    end
    return hasil
end

local function injectKDA(offApel, offAnggur, offMangga, apelBuah, apelBaging)
    local pedagang = getBasePedagangKDA(HARGA_KDA)
    if not pedagang then return false end
    local apel_b    = distribusiKDA(apelBuah, 5)
    local apel_bg   = distribusiKDA(apelBaging, 5)
    local anggur_b  = distribusiKDA(apelBaging, 5)
    local anggur_bg = distribusiKDA(apelBuah, 5)
    local mangga_b  = distribusiManggaKDA(apel_b, 5, false, 0.70, 0.80)
    local mangga_bg = distribusiManggaKDA(apel_bg, 5, true)
    for i, idx in ipairs(BUAH_IDX_KDA) do
        local base = pedagang[idx]
        if base then
            gg.setValues({
                { address = base.address + offApel,   flags = gg.TYPE_DWORD, value = apel_b[i] },
                { address = base.address + offAnggur, flags = gg.TYPE_DWORD, value = anggur_b[i] },
                { address = base.address + offMangga, flags = gg.TYPE_DWORD, value = mangga_b[i] },
            })
        end
    end
    for i, idx in ipairs(BAGING_IDX_KDA) do
        local base = pedagang[idx]
        if base then
            gg.setValues({
                { address = base.address + offApel,   flags = gg.TYPE_DWORD, value = apel_bg[i] },
                { address = base.address + offAnggur, flags = gg.TYPE_DWORD, value = anggur_bg[i] },
                { address = base.address + offMangga, flags = gg.TYPE_DWORD, value = mangga_bg[i] },
            })
        end
    end
    return true
end

local function menuKDA()
    local kdaVersi = gg.choice({
        "🔹 VERSION 32 BIT",
        "🔹 VERSION 64 BIT",
    }, nil, "🔷 KDA - Pilih Versi MLBB")
    if not kdaVersi then 
        writeLog("Inject KDA Dibatalkan")
        return false 
    end
    local offsets    = kdaVersi == 1 and HARGA_KDA.vietnam or HARGA_KDA.india
    local input = gg.prompt(
        { "KDA TIM (total)", "KDA MUSUH (total)" },
        { "100", "12" },
        { "number", "number" }
    )
    if not input then 
        writeLog("Inject KDA Dibatalkan")
        return false 
    end
    local apelBuah   = tonumber(input[1])
    local apelBaging = tonumber(input[2])
    if not apelBuah or not apelBaging then return false end
    gg.toast("🔍 Scanning pedagang...")
    local hasilKDA = injectKDA(offsets.apel, offsets.anggur, offsets.mangga, apelBuah, apelBaging)
    if not hasilKDA then
        writeLog("Gagal Inject KDA")
        gg.toast("❌ Gagal menemukan pedagang KDA!")
        return false
    end
    
    writeLog("Inject KDA Berhasil (Tim: " .. apelBuah .. " | Musuh: " .. apelBaging .. ")")
    return true
end
--====================================================================================
--                      DAMAGE OUTPUT
--====================================================================================
local function settingDefault()
    local input = gg.prompt(
        {
            "🟢 HP (default: " .. DEFAULT.HIJAU .. ")",
            "🔵 ATK (default: " .. DEFAULT.BIRU .. ")",
            "🌸 SPD (default: " .. DEFAULT.PINK .. ")",
        },
        { tostring(DEFAULT.HIJAU), tostring(DEFAULT.BIRU), tostring(DEFAULT.PINK) },
        { "number", "number", "number" }
    )
    if not input then 
        writeLog("Setting Default Damage Dibatalkan")
        return 
    end
    local h, b, p = tonumber(input[1]), tonumber(input[2]), tonumber(input[3])
    if h and b and p and h > 0 and b > 0 and p > 0 then
        DEFAULT = { HIJAU = h, BIRU = b, PINK = p }
        saveDefaultCache()
        writeLog("ubah output Damage (HP:" .. h .. ", ATK:" .. b .. ", SPD:" .. p .. ")")
        gg.toast("✅ Default diubah & tersimpan!")
    else
        writeLog("Gagal Setting Default Damage")
        gg.toast("⚠️ Input tidak valid!")
    end
end
--====================================================================================
--                      TIPE MODE TIER DAN OFFSET TIME
--====================================================================================
local function settingTierMode()
    local pilih = gg.choice({
        "⚔️ v1 (Plus 40)",
        "⭐ v2 (plus 20)",
        "💎 v3 (normal)",
        "⬅️ Batal"
    }, nil, "⚙️ PILIH MODE TIER UTAMA\n\ncontoh nilai SPD (290) pakai v1\nStatus Saat Ini: [" .. string.upper(_currentTierSetting) .. "]\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    if not pilih or pilih == 4 then 
        writeLog("Setting Tier Mode Dibatalkan")
        return 
    end
    if pilih == 1 then _currentTierSetting = "v1"
    elseif pilih == 2 then _currentTierSetting = "v2"
    elseif pilih == 3 then _currentTierSetting = "v3" end
    
    if _quick.slot then
        saveQuickCache()
    end
    
    writeLog("Mode Tier Diubah ke: " .. string.upper(_currentTierSetting))
    gg.toast("✅ Mode Tier dikunci ke: " .. string.upper(_currentTierSetting))
end

local function settingTimerOffsetMode()
    local statusTeks = (_currentTimerOffsetMode == "original") and "Original Server" or "Advance Server"
    local pilih = gg.choice({
        "⚙️ Advance Server",
        "⚙️ Original Server",
        "⬅️ Batal"
    }, nil, "⚙️ PILIH MODE SERVER TIMER\n\nPilih sesuaikan dengan server game yang digunakan.\nStatus Saat Ini: [" .. statusTeks .. "]\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    if not pilih or pilih == 3 then 
        writeLog("Setting Mode Timer Dibatalkan")
        return 
    end
    
    if pilih == 1 then 
        _currentTimerOffsetMode = "advance"
        OFFSET_TIMER = 0xC
    elseif pilih == 2 then 
        _currentTimerOffsetMode = "original"
        OFFSET_TIMER = 0x8
    end
    
    saveTimerOffsetCache()
    local serverBaruTeks = (_currentTimerOffsetMode == "original") and "Original Server" or "Advance Server"
    writeLog("Mode Timer Diubah ke: " .. serverBaruTeks)
    gg.toast("✅ Mode Timer dikunci ke: " .. serverBaruTeks)
end
--====================================================================================
--                      TAMBAH HERO
--====================================================================================
local function tambahSlot()
    local input = gg.prompt(
        { "Nama Hero", "SPD", "ATK", "HP" },
        { "", "", "", "" },
        { "text", "number", "number", "number" }
    )
    if not input then 
        writeLog("Tambah Slot Hero Dibatalkan")
        return 
    end
    local nama  = input[1]
    local pink, biru, hijau = tonumber(input[2]), tonumber(input[3]), tonumber(input[4])
    if not nama or nama == "" or not pink or not biru or not hijau then 
        writeLog("Gagal Tambah Slot Hero")
        gg.toast("⚠️ Data tidak lengkap!")
        return 
    end
    table.insert(_slots, { nama = nama, PINK = pink, BIRU = biru, HIJAU = hijau, source = "user", useCount = 0 })
    sortSlotsByUsage()
    saveSlotsCache()
    writeLog("Menambahkan Slot Hero Baru: " .. nama)
    gg.toast("✅ Slot '" .. nama .. "' ditambahkan!")
end
--====================================================================================
--                      FORMAT SLOT (emoji & counter)
--====================================================================================
local _paletteWarna = { "💟", "⚛️", "🕉️", "☸️", "☮️", "☯", "☪️", "✝️", "☦️", "✡️", "♾️" }
local function warnaAbjad(nama)
    local huruf = nama and nama:sub(1, 1):upper() or ""
    local kode = huruf:byte()
    if not kode or kode < 65 or kode > 90 then return "🧬" end
    return _paletteWarna[((kode - 65) % #_paletteWarna) + 1]
end
local function formatSlotLabels(list)
    local labels = {}
    for i, s in ipairs(list) do
        local countTeks = (s.useCount and s.useCount > 0) and (" 🔥(" .. s.useCount .. "x)") or ""
        table.insert(labels, toBold(i .. ". " .. warnaAbjad(s.nama) .. s.nama .. countTeks))
    end
    return labels
end
--====================================================================================
--                      HAPUS HERO
--====================================================================================
local function hapusSlot()
    if #_slots == 0 then
        writeLog("Gagal Hapus Hero: Slot kosong")
        gg.toast("❌ Tidak ada hero yang tersimpan.")
        return
    end
    local labels = {}
    local statusAwal = {}
    for _, s in ipairs(_slots) do
        table.insert(labels, warnaAbjad(s.nama) .. s.nama)
        table.insert(statusAwal, false)
    end
    table.insert(labels, "⬅ Batal")
    table.insert(statusAwal, false)
    local pilih = gg.multiChoice(labels, statusAwal, "🗑️ HAPUS HERO\n(Centang hero yang ingin dihapus)\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    if not pilih then 
        writeLog("Menu Hapus Hero Dibatalkan")
        return 
    end
    if pilih[#labels] then 
        writeLog("Hapus Hero Dibatalkan")
        return 
    end
    local heroDihapus = {}
    local slotBaru = {}
    for i, s in ipairs(_slots) do
        if not pilih[i] then
            table.insert(slotBaru, s)
        else
            table.insert(heroDihapus, s.nama)
        end
    end
    if #heroDihapus == 0 then
        writeLog("Gagal Hapus Hero: Tidak ada yang dicentang")
        gg.toast("⚠️ Tidak ada hero yang dipilih untuk dihapus.")
        return
    end
    _slots = slotBaru
    saveSlotsCache()
    writeLog("Menghapus " .. #heroDihapus .. " hero dari slot.")
    gg.toast("✅ Berhasil menghapus " .. #heroDihapus .. " hero!")
end
--====================================================================================
--                          URUTKAN HERO
--====================================================================================
local function pindahUrutanSlot()
    local visIdx = {}
    for i, s in ipairs(_slots) do
        if not s.hidden then table.insert(visIdx, i) end
    end
    if #visIdx < 2 then 
        writeLog("Gagal Urutkan Slot: kurang dari 2")
        gg.toast("⚠️ Minimal 2 slot.") 
        return 
    end
    local visList = {}
    for pos, idx in ipairs(visIdx) do visList[pos] = _slots[idx] end
    local labels = {}
    for i, s in ipairs(visList) do table.insert(labels, i .. ". " .. s.nama) end
    table.insert(labels, "⬅ Batal")
    local pilih = gg.choice(labels, nil, "Pilih slot:")
    if not pilih or pilih == #labels then 
        writeLog("Pengurutan Slot Dibatalkan")
        return 
    end
    local inputPos = gg.prompt({ "Pindah ke posisi:" }, { tostring(pilih) }, { "number" })
    if not inputPos then 
        writeLog("Pengurutan Slot Dibatalkan")
        return 
    end
    local posBaru = tonumber(inputPos[1])
    if not posBaru or posBaru < 1 or posBaru > #visList then 
        writeLog("Gagal Urutkan Slot: Posisi tujuan tidak valid")
        gg.toast("⚠️ Posisi tidak valid!")
        return 
    end
    local item = table.remove(visList, pilih)
    table.insert(visList, posBaru, item)
    for pos, idx in ipairs(visIdx) do _slots[idx] = visList[pos] end
    saveSlotsCache()
    writeLog("Mengubah urutan slot hero.")
    gg.toast("✅ Urutan diubah!")
end
--====================================================================================
--                  RESET PENGGUNAAN HERO
--====================================================================================
local function resetHeroUsageCounter()
    local confirm = gg.choice({ "✅ YA, RESET SEMUA", "❌ BATAL" }, nil, "Reset hitungan pemakaian semua hero menjadi 0?")
    if confirm == 1 then
        for _, s in ipairs(_slots) do
            s.useCount = 0
        end
        saveSlotsCache()
        writeLog("Reset Hitungan Pemakaian Hero Dijalankan")
        gg.toast("✅ Hitungan pemakaian hero berhasil di-reset!")
    end
end
--====================================================================================
--              FETCH SLOT GIST
--====================================================================================
local function fetchSlotGist()
    local parsed = nil
    for percobaan = 1, 3 do
        local res = gg.makeRequest(GIST_RAW_SLOTS .. "?t=" .. os.time())
        if res and res.code == 200 and res.content and #res.content > 10 then
            local fn = load(res.content)
            if fn then
                local ok, hasil = pcall(fn)
                if ok and type(hasil) == "table" and #hasil > 0 then
                    parsed = hasil
                    break
                end
            end
        end
        if percobaan < 3 then gg.sleep(50) end
    end
    if not parsed then return nil end
    local slotBersih = {}
    for _, s in ipairs(parsed) do
        if s.nama and s.PINK and s.BIRU and s.HIJAU then
            table.insert(slotBersih, {
                nama = s.nama, PINK = tonumber(s.PINK),
                BIRU = tonumber(s.BIRU), HIJAU = tonumber(s.HIJAU),
                hidden = (s.hidden == true or s.hidden == "true"), source = "gist",
                useCount = tonumber(s.useCount) or 0
            })
        end
    end
    if #slotBersih == 0 then return nil end
    return slotBersih
end
--====================================================================================
--                      IMPORT DARI GITS (DENGAN MODE OTOMATIS)
--====================================================================================
local function importSlotGist(isAuto)
    if not isAuto then
        local izin = gg.choice({ "✅ Ya, lanjut import", "❌ Batal" }, nil, "Ambil data slot terbaru dari GitHub?")
        if not izin or izin == 2 then 
            writeLog("Import Slot Dibatalkan oleh Pengguna")
            return 
        end
    end

    local slotBersih = fetchSlotGist()
    if not slotBersih then 
        writeLog("Gagal Import Slot : gagal terhubung")
        if not isAuto then gg.toast("❌ Gagal import!") end
        return false
    end

    if isAuto then
        _slots = slotBersih
        sortSlotsByUsage()
        saveSlotsCache()
        writeLog("Otomatis mengunduh hero dari GitHub karena slot lokal kosong.")
        gg.toast("✅ Otomatis mengunduh " .. #slotBersih .. " Hero dari GitHub!")
        return true
    end

    local aksi = gg.choice({ "🔄 Timpa semua slot lokal", "➕ Gabung", "❌ Batal" }, nil, "Total " .. #slotBersih .. " slot ditemukan.")
    if not aksi or aksi == 3 then 
        writeLog("Import Dibatalkan pada Pemilihan")
        return false
    end

    if aksi == 1 then
        _slots = slotBersih
    else
        for _, s in ipairs(slotBersih) do
            local sudahAda = false
            for _, existing in ipairs(_slots) do
                if existing.nama == s.nama then sudahAda = true break end
            end
            if not sudahAda then table.insert(_slots, s) end
        end
    end

    sortSlotsByUsage()
    saveSlotsCache()
    writeLog("Import slot hero berhasil.")
    gg.toast("✅ Import slot selesai!")
    return true
end
--====================================================================================
--                          INJECT SAVAGE
--====================================================================================
function skipperClassicLoop()
    gg.clearResults()
    gg.clearList()
    gg.setRanges(gg.REGION_ANONYMOUS)
    local targetWaktu = 16000
    gg.toast("Mencari timer...")
    local hasil = {}
    gg.searchNumber("30000;45000;1", gg.TYPE_DWORD)
    gg.refineNumber("30000", gg.TYPE_DWORD)
    hasil = gg.getResults(50)
    if #hasil == 0 then 
        writeLog("Inject Savage : tidak ditemukan")
        gg.toast("❌ Gagal!") 
        return 
    end
    local save = {}
    for _, v in ipairs(hasil) do
        table.insert(save, { address = v.address - OFFSET_TIMER, flags = gg.TYPE_DWORD })
    end
    local sebelum = gg.getValues(save)
    gg.sleep(50)
    local sesudah = gg.getValues(save)
    local target = nil
    for i = 1, #sebelum do
        if sebelum[i] and sesudah[i] and sebelum[i].value ~= sesudah[i].value then
            target = { address = save[i].address, flags = gg.TYPE_DWORD, value = 0, name = "skipwaktu" }
            break
        end
    end
    if not target then 
        writeLog("Inject Savage : Target dynamic timer error")
        gg.toast("❌ Error!") 
        return 
    end
    local nilaiAsli = gg.getValues({target})[1].value
    target.value = nilaiAsli
    gg.addListItems({target})
    gg.clearList()
    gg.clearResults()
    
    writeLog("Inject Savage aktif.")
    
    local waktuKetukSebelumnya, hitungKetuk = 0, 0
    while true do
        if gg.isVisible(true) then
            gg.setVisible(false)
            local selisih = os.clock() - waktuKetukSebelumnya
            if selisih < 0.8 then hitungKetuk = hitungKetuk + 1 else hitungKetuk = 1 end
            waktuKetukSebelumnya = os.clock()
            if hitungKetuk >= 2 then
                writeLog("Inject Savage Dihentikan Pengguna")
                gg.toast("🔄 Kembali...")
                gg.sleep(60)
                return
            else
                local currentVal1 = gg.getValues({target})
                target.value = currentVal1[1].value + targetWaktu
                gg.setValues({target})
                
                gg.sleep(150)

                local currentVal2 = gg.getValues({target})
                target.value = currentVal2[1].value + targetWaktu
                gg.setValues({target})
                
                gg.toast("ketuk 1 X (melanjutkan inject savage)\nketuk 3 X (keluar dari mode)")
            end
        end
    end
end
--====================================================================================
--                          RIWAYAT AKTIVITAS
--====================================================================================
local function menuLihatLog()
    while true do
        local f = io.open(LOG_CACHE_FILE, "r")
        local isiLogMentah = ""
        if f then
            isiLogMentah = f:read("*a")
            f:close()
        end
        
        local decryptedLog = ""
        if isiLogMentah ~= "" then
            local ok, decrypted = pcall(decryptData, isiLogMentah)
            if ok and decrypted then
                decryptedLog = decrypted
            end
        end
        
        local barisLog = {}
        for baris in decryptedLog:gmatch("[^\r\n]+") do
            table.insert(barisLog, baris)
        end
        
        local tampilPreview = ""
        if #barisLog == 0 then
            tampilPreview = "Belum ada riwayat aktivitas tercatat."
        else
            local mulai = math.max(1, #barisLog - 4)
            for i = mulai, #barisLog do
                tampilPreview = tampilPreview .. barisLog[i] .. "\n"
            end
        end
        
        local daftarMenu = {
            "📜 LIHAT SEMUA (" .. #barisLog .. ")",
            "🗑️ HAPUS / BERSIHKAN SEMUA LOG",
            "🔄 REFRESH",
            "⬅ KEMBALI"
        }
        
        local pilihan = gg.choice(daftarMenu, nil, "📋 LOG AKTIVITAS REAL-TIME\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" .. tampilPreview)
        
        if not pilihan or pilihan == 4 then 
            break
        elseif pilihan == 1 then
            local semuaLogTeks = "📜 SEMUA RIWAYAT AKTIVITAS:\n\n"
            if #barisLog == 0 then
                semuaLogTeks = semuaLogTeks .. "(Kosong)"
            else
                semuaLogTeks = semuaLogTeks .. decryptedLog
            end
            gg.alert(semuaLogTeks)
        elseif pilihan == 2 then
            local konfirmasi = gg.choice({ "Ya, Hapus Semua", "Batal" }, nil, "Yakin ingin menghapus semua riwayat log?")
            if konfirmasi == 1 then
                os.remove(LOG_CACHE_FILE)
                gg.toast("✅ Log berhasil dibersihkan!")
            end
        elseif pilihan == 3 then
            gg.toast("🔄 Memperbarui log...")
        end
        
        gg.sleep(30)
    end
end
--====================================================================================
--                      RESET / GANTI TOKEN CACHE
--====================================================================================
local function resetTokenCache()
    local confirm = gg.alert(
        "Yakin ingin menghapus cache token & melakukan login ulang?",
        "YA", "BATAL"
    )
    if confirm == 1 then
        os.remove(TOKEN_CACHE_FILE)
        writeLog("Token Cache Direset oleh Pengguna")
        gg.alert("✅ Cache token berhasil dihapus!\nSilakan jalankan ulang script untuk memasukkan token baru.")
        os.exit()
    end
end
--====================================================================================
--               FUNGSI CEK / SALIN LINK UPDATE KHUSUS MENU SETTING
--====================================================================================
local function salinLinkUpdateSetting()
    gg.toast("🔍 Mengambil informasi update...")
    local res = gg.makeRequest(FIREBASE_URL .. "/version_info.json?t=" .. os.time())
    
    if res and res.code == 200 and res.content and res.content ~= "null" then
        local latestVer = res.content:match('"latestVersion"%s*:%s*"([^"]+)"') 
                        or res.content:match('"latestVersion"%s*:%s*([%d%.]+)') or CURRENT_VERSION
        
        local urlFree = res.content:match('"downloadUrlFree"%s*:%s*"([^"]+)"') 
        local urlPremium = res.content:match('"downloadUrlPremium"%s*:%s*"([^"]+)"') 

        if not urlFree or urlFree == "" then urlFree = "belum ada update terbaru" end
        if not urlPremium or urlPremium == "" then urlPremium = "belum ada update terbaru" end

        local downloadUrl = isPremiumUser and urlPremium or urlFree
        local rawChangelog = res.content:match('"changelog"%s*:%s*"([^"]+)"') or "Tidak ada catatan."
        local updateChangelog = rawChangelog:gsub("\\n", "\n")
        
        local tipeUserTeks = isPremiumUser and "PREMIUM" or "FREE"
        
        local pesanInfo = string.format(
            "🚀 INFORMASI SCRIPT TERBARU (%s)\n\nVersi Saat Ini: v%s\nVersi Terbaru: v%s\n\nLink Update (%s):\n%s\n\nCatatan Pembaruan:\n%s\n\nApakah Anda ingin menyalin link ke clipboard?",
            tipeUserTeks, CURRENT_VERSION, latestVer, tipeUserTeks, downloadUrl, updateChangelog
        )

        local konfirmasi = gg.choice({
            "📋 SALIN LINK UPDATE",
            "❌ BATAL / KEMBALI"
        }, nil, pesanInfo)

        if konfirmasi == 1 then
            if downloadUrl ~= "belum ada update terbaru" then
                gg.copyText(downloadUrl)
                gg.toast("📋 Link berhasil disalin ke clipboard!")
                gg.alert("✅ Link update berhasil disalin!\n\nLink:\n" .. downloadUrl)
            else
                gg.alert("⚠️ Tidak ada link update yang dapat disalin!")
            end
        else
            gg.toast("Dibatalkan.")
        end
    else
        gg.alert("❌ Gagal terhubung ke server untuk mengecek link update!")
    end
end
--====================================================================================
--                          MENU SETTING
--====================================================================================
local function menuSetting()
    while true do
        local labels, actions = {}, {}
        table.insert(labels, toBold("⚙️ UBAH MODE TIER [" .. string.upper(_currentTierSetting) .. "]"))
        table.insert(actions, "tier_mode")

        -- Label menu setting menggunakan nama server agar aman (tanpa offset 0x8/0xC)
        local statusServerMenu = (_currentTimerOffsetMode == "original") and "Original Server" or "Advance Server"
        table.insert(labels, toBold("⏱️ SERVER TIMER [" .. statusServerMenu .. "]"))
        table.insert(actions, "timer_offset_mode")

        if _menuVisible.setting_damage then
            table.insert(labels, toBold(_menuIcons.setting_damage .. " " .. _menuLabels.setting_damage))
            table.insert(actions, "damage")
        end
        if _menuVisible.setting_add then
            table.insert(labels, toBold(_menuIcons.setting_add .. " " .. _menuLabels.setting_add))
            table.insert(actions, "add")
        end
        table.insert(labels, toBold("🗑️ HAPUS HERO"))
        table.insert(actions, "hapus_hero")

        if _menuVisible.setting_urutkan then
            table.insert(labels, toBold(_menuIcons.setting_urutkan .. " " .. _menuLabels.setting_urutkan))
            table.insert(actions, "urutkan")
        end

        if _menuVisible.setting_import then
            table.insert(labels, toBold(_menuIcons.setting_import .. " " .. _menuLabels.setting_import))
            table.insert(actions, "import")
        end

        if _menuVisible.log then
            table.insert(labels, toBold(_menuIcons.log .. " " .. _menuLabels.log))
            table.insert(actions, "view_log")
        end
        
        if _menuVisible.update then
            table.insert(labels, toBold(_menuIcons.update .. " " .. _menuLabels.update))
            table.insert(actions, "check_update")
        end

        if _menuVisible.usage then
            table.insert(labels, toBold(_menuIcons.usage .. " " .. _menuLabels.usage))
            table.insert(actions, "reset_usage")
        end
        
        if _menuVisible.token then
            table.insert(labels, toBold(_menuIcons.token .. " " .. _menuLabels.token))
            table.insert(actions, "reset_token")
        end

        table.insert(labels, toBold("⬅️ BACK"))
        table.insert(actions, "back")

        local pilih = gg.choice(labels, nil, toBold("⚙️ SETTING") .. "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        if not pilih then return end
        local aksi = actions[pilih]
        if aksi == "back" then return
        elseif aksi == "tier_mode" then settingTierMode()
        elseif aksi == "timer_offset_mode" then settingTimerOffsetMode()
        elseif aksi == "damage" then settingDefault()
        elseif aksi == "add" then tambahSlot()
        elseif aksi == "hapus_hero" then hapusSlot()
        elseif aksi == "urutkan" then pindahUrutanSlot()
        elseif aksi == "reset_usage" then resetHeroUsageCounter()
        elseif aksi == "import" then importSlotGist()
        elseif aksi == "view_log" then menuLihatLog() 
        elseif aksi == "check_update" then salinLinkUpdateSetting()
        elseif aksi == "reset_token" then resetTokenCache() end
    end
end
--====================================================================================
--                          CARI NAME SLOT
--====================================================================================
local function visibleSlots()
    local hasil = {}
    for _, s in ipairs(_slots) do
        if not s.hidden then table.insert(hasil, s) end
    end
    return hasil
end

local function pilihSlot()
    if #visibleSlots() == 0 then 
        gg.toast("❌ Slot kosong!") 
        return nil 
    end
    local currentList = visibleSlots()
    local keyword = nil
    while true do
        local labels = {}
        if keyword then table.insert(labels, toBold("🔄 RESET PENCARIAN")) else table.insert(labels, toBold("🔍 CARI SLOT")) end
        for _, l in ipairs(formatSlotLabels(currentList)) do table.insert(labels, l) end
        table.insert(labels, toBold("⬅️ Batal"))
        local pilih = gg.choice(labels, nil, toBold("Pilih Slot") .. "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        if not pilih or pilih == #labels then return nil end
        if pilih == 1 then
            if keyword then keyword = nil; currentList = visibleSlots()
            else
                local inputCari = gg.prompt({"🔍 Cari nama hero"}, {""}, {"text"})
                if inputCari and inputCari[1] and inputCari[1] ~= "" then
                    local kw = inputCari[1]:lower()
                    local hasil = {}
                    for _, s in ipairs(visibleSlots()) do
                        if s.nama:lower():find(kw, 1, true) then table.insert(hasil, s) end
                    end
                    if #hasil == 0 then 
                        writeLog("Pencarian Hero '" .. inputCari[1] .. "' Tidak Ketemu")
                        gg.toast("❌ Tidak ketemu") 
                    else 
                        keyword = inputCari[1]
                        currentList = hasil 
                    end
                end
            end
        else
            return currentList[pilih - 1]
        end
    end
end
--====================================================================================
--                      INJECT HERO
--====================================================================================
local function menuInjectSlot()
    local s = pilihSlot()
    if not s then return end
    doInjectTier(s.PINK, s.BIRU, s.HIJAU, s.nama, _currentTierSetting)
end
--====================================================================================
--                      QUICK INJECT
--====================================================================================
local function setupQuickInject()
    local s = pilihSlot()
    if not s then return false end
    
    local inputMenit = gg.prompt({"⏱️ Menit Time Skip (0 = nonaktif)"}, {"4"}, {"number"})
    if not inputMenit then 
        writeLog("Setup Quick Inject Dibatalkan")
        return false 
    end

    local kdaVersi = 3
    local kdaTim, kdaMusuh = 0, 0

    -- CEK APAKAH USER PREMIUM SEBELUM MENAMPILKAN PILIHAN KDA
    if isPremiumUser then
        local pilihKda = gg.choice({
            "🔹 VERSION 32 BIT",
            "🔹 VERSION 64 BIT",
            "🚫 Tanpa Inject KDA"
        }, nil, "🔷 SETUP QUICK INJECT - Pilih Versi KDA")
        
        if not pilihKda then
            writeLog("Setup Quick Inject Dibatalkan")
            return false
        end
        kdaVersi = pilihKda
    else
        gg.toast("ℹ️ Fitur KDA di Quick Inject khusus Premium. Dilewati.")
    end

    if kdaVersi ~= 3 then
        local inputKda = gg.prompt(
            { "KDA TIM (total)", "KDA MUSUH (total)" },
            { "100", "12" },
            { "number", "number" }
        )
        if not inputKda then
            writeLog("Setup Quick Inject Dibatalkan")
            return false
        end
        kdaTim = tonumber(inputKda[1]) or 0
        kdaMusuh = tonumber(inputKda[2]) or 0
    end

    _quick.slot     = s
    _quick.menit    = tonumber(inputMenit[1]) or 0
    _quick.kdaVersi = (kdaVersi == 3) and 0 or kdaVersi
    _quick.kdaTim   = kdaTim
    _quick.kdaMusuh = kdaMusuh

    saveQuickCache() 
    writeLog("Setup Quick Inject: " .. s.nama)
    gg.toast("✅ Quick Inject siap: " .. s.nama)
    return true
end
--====================================================================================
--                      EKSEKUSI QUICK INJECT
--====================================================================================
local function runQuickInject()
    if not _quick.slot then
        gg.toast("⚠️ Quick Inject belum di-setup!")
        return false
    end

    local s = _quick.slot
    local suksesInject = doInjectTier(s.PINK, s.BIRU, s.HIJAU, s.nama, _currentTierSetting)
    
    if not suksesInject then
        return false
    end

    if _quick.menit and _quick.menit > 0 then
        doSkipTime(_quick.menit)
    end

    if _quick.kdaVersi and _quick.kdaVersi > 0 and _quick.kdaTim and _quick.kdaTim > 0 then
        local offsets = (_quick.kdaVersi == 1) and HARGA_KDA.vietnam or HARGA_KDA.india
        injectKDA(offsets.apel, offsets.anggur, offsets.mangga, _quick.kdaTim, _quick.kdaMusuh)
        writeLog("Quick Inject KDA Berhasil (Tim: " .. _quick.kdaTim .. " | Musuh: " .. _quick.kdaMusuh .. ")")
    end

    gg.toast("⚡ Quick Inject Berhasil: " .. s.nama)
    return true
end

--====================================================================================
--                         RESET AKUN BANNED
--====================================================================================
function reset_akun_safe()
    local confirm = gg.alert(
        "Pastikan aplikasi Mobile Legends sudah DITUTUP sebelum melanjutkan!\n\nLanjutkan pembersihan token ML & Google Play Services?",
        "YA", "BATAL"
    )
    
    if confirm ~= 1 then
        gg.toast("Dibatalkan.")
        return
    end

    gg.toast("Menghapus data token & cache sinkronisasi...")

    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/lib_burst_generated.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libAkSoundEngine.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libcsharp.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libfirst.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libhttp_downloader.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/liblogic.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libmlsdk_logreport.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libmoba.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libmola_download.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/libnativelogin.so")
    pcall(os.remove, "/data/data/com.mobile.legends/app_libs/librudp.so")

    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/__MLSDK_APM__.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/__SharedPreference__.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/_apm_global_cache.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/adjust_preferences.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/applog_stats_1000247.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/bytebench_6571.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.dvi.internal.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.facebook.internal.MODEL_STORE.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.facebook.internal.preferences.APP_GATEKEEPERS.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.facebook.internal.preferences.APP_SETTINGS.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.facebook.sdk.appEventPreferences.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.facebook.sdk.attributionTracking.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.facebook.sdk.USER_SETTINGS.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.google.android.gms.appid.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.google.android.gms.measurement.prefs.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.mobile.legends.v2.playerprefs.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/com.mobile.legends_preferences.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/DeviceSettings.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/FirebaseHeartBeatW0RFRkFVTFRd+MTozMjE4NTQ1MTg3NDphbmRyb2lkOjg1NjhjN2Q5ZGY2NGI5ZjM.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/snssdk_openudid.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/ug_install_settings_pref.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/last_sp_session_1000247.xml")
    pcall(os.remove, "/data/data/com.mobile.legends/shared_prefs/WebViewChromiumPrefs.xml")

    pcall(os.remove, "/data/data/com.google.android.gms/shared_prefs/common.selected_account_prefs.xml")
    pcall(os.remove, "/data/data/com.google.android.gms/shared_prefs/gsid_shared_preference.xml")
    pcall(os.remove, "/data/data/com.google.android.gms/shared_prefs/adid_settings.xml")
    pcall(os.remove, "/data/data/com.google.android.gms/shared_prefs/com.google.android.gms.measurement.prefs.xml")
    pcall(os.remove, "/data/data/com.google.android.gms/shared_prefs/common.clientcontext_-1934347371.xml")
    pcall(os.remove, "/data/data/com.google.android.gms/shared_prefs/games.account_types.xml")
    pcall(os.remove, "/data/data/com.google.android.gms/shared_prefs/games.sign_in_cache.xml")

    pcall(os.remove, "/data/data/com.google.android.gms/files/games/shared/GameConnectStore.pb")
    pcall(os.remove, "/data/data/com.google.android.gms/files/authaccount/shared/IntermediateTokenStore.pb")
    pcall(os.remove, "/data/data/com.google.android.gms/files/mobstore/shared/mobstore_accounts.pb")

    pcall(os.remove, "/data/data/com.google.android.gms/files/managed/authaccount/shared/syncPolicyEngine/allAccounts/syncid_1/subid_none/sync_metadata.pb")
    pcall(os.remove, "/data/data/com.google.android.gms/files/managed/authaccount/0/syncPolicyEngine/syncid_1/subid_none/sync_metadata.pb")
    pcall(os.remove, "/data/data/com.google.android.gms/files/managed/mdisync/0/syncPolicyEngine/syncid_1/subid_none/sync_metadata.pb")
    pcall(os.remove, "/data/data/com.google.android.gms/files/managed/mdisync/shared/syncPolicyEngine/allAccounts/syncid_1/subid_none/sync_metadata.pb")
    pcall(os.remove, "/data/data/com.google.android.gms/files/managed/udc/0/syncPolicyEngine/syncid_1/subid_none/sync_metadata.pb")
    pcall(os.remove, "/data/data/com.google.android.gms/files/managed/udc/shared/syncPolicyEngine/allAccounts/syncid_1/subid_none/sync_metadata.pb")

    gg.alert("SELESAI!\n\nSeluruh file token login ML, cache Google Play Games, dan sinkronisasi akun telah dibersihkan.")
end
--====================================================================================
--                              EXIT
--====================================================================================
function Sai()
  menu = gg.alert("follow chanel whatapp\nZEE STORE\n", "[Belum]", "[Sudah]")
  if menu == 1 then
    gg.toast("Thanks Guys")
    gg.setVisible(false)
  end
  if menu == 2 then
  print("MODDED BY Zee Store")
  print("\n        ░░░░░░░░░░░░░░░░░░░\n        ░███████╗░███████╗░\n        ░╚══███╔╝░██╔════╝░\n        ░░░███╔╝░░███████╗░\n        ░░███╔╝░░░╚════██║░\n        ░███████╗░███████║░\n        ░╚══════╝░╚══════╝░\n        ░░░░░░░░░░░░░░░░░░░\n༺═──────────────────────────═༻")
  print("Script Ini Diakhiri, Silahkan Hidupkan Ulang Untuk Menggunakannya ^_^")
  os.exit()
  end
end
--====================================================================================
--                             START
--====================================================================================
local function mainMenu()
    local labels, actions = {}, {}
    if _menuVisible.quick then
        if _quick.slot then
            local qinfo = "⚡ Quick: " .. _quick.slot.nama .. " [" .. string.upper(_currentTierSetting or "v1") .. "]"
            if _quick.menit and _quick.menit > 0 then 
                qinfo = qinfo .. " | ⏱️" .. _quick.menit .. "m" 
            end
            
            if _quick.kdaVersi and _quick.kdaVersi > 0 and _quick.kdaTim and _quick.kdaTim > 0 then
                local vKdaStr = (_quick.kdaVersi == 1) and "32b" or "64b"
                qinfo = qinfo .. " | ☣️KDA: ( " .. vKdaStr .. ": " .. _quick.kdaTim .. "/" .. _quick.kdaMusuh .. " )"
            else
                qinfo = qinfo .. " | ☣️KDA (Off)"
            end

            table.insert(labels, toBold(qinfo))
            table.insert(actions, "quick_run")
        else
            table.insert(labels, toBold(_menuIcons.quick .. " " .. _menuLabels.quick))
            table.insert(actions, "quick_setup")
        end
    end

    if _menuVisible.inject then
        table.insert(labels, toBold(_menuIcons.inject   .. " " .. _menuLabels.inject)); table.insert(actions, "inject")
    end

    if _menuVisible.timeskip then
        table.insert(labels, toBold(_menuIcons.timeskip .. " " .. _menuLabels.timeskip)); table.insert(actions, "timeskip")
    end
    
    if isPremiumUser then
        if _menuVisible.kda then
            table.insert(labels, toBold(_menuIcons.kda      .. " " .. _menuLabels.kda));      table.insert(actions, "kda")
        end
        if _menuVisible.setting_savage then
            table.insert(labels, toBold(_menuIcons.setting_savage .. " " .. _menuLabels.setting_savage)); table.insert(actions, "savage")
        end
        if _menuVisible.drone then
            table.insert(labels, toBold(_menuIcons.drone    .. " " .. _menuLabels.drone));    table.insert(actions, "drone")
        end
        if _menuVisible.maphack then
            table.insert(labels, toBold(_menuIcons.maphack  .. " " .. _menuLabels.maphack));  table.insert(actions, "maphack")
        end
        if _menuVisible.nograss then
            table.insert(labels, toBold(_menuIcons.nograss .. " " .. _menuLabels.nograss)); table.insert(actions, "prem_nograss")
        end
        if _menuVisible.bypass then
            table.insert(labels, toBold(_menuIcons.bypass   .. " " .. _menuLabels.bypass));   table.insert(actions, "bypass")
        end
        if _menuVisible.reset then
            table.insert(labels, toBold(_menuIcons.reset   .. " " .. _menuLabels.reset));   table.insert(actions, "prem_reset_akun")
        end
    else
        if _menuVisible.kda then
            table.insert(labels, toBold("🔒 " .. _menuLabels.kda))
            table.insert(actions, "locked_kda")
        end
        if _menuVisible.setting_savage then
            table.insert(labels, toBold("🔒 " .. _menuLabels.setting_savage))
            table.insert(actions, "locked_savage")
        end
        if _menuVisible.drone then
            table.insert(labels, toBold("🔒 " .. _menuLabels.drone))
            table.insert(actions, "locked_drone")
        end
        if _menuVisible.maphack then
            table.insert(labels, toBold("🔒 " .. _menuLabels.maphack))
            table.insert(actions, "locked_maphack")
        end
        if _menuVisible.nograss then
            table.insert(labels, toBold("🔒 " .. _menuLabels.nograss))
            table.insert(actions, "locked_nograss")
        end
        if _menuVisible.bypass then
            table.insert(labels, toBold("🔒 " .. _menuLabels.bypass))
            table.insert(actions, "locked_bypass")
        end
        if _menuVisible.reset then
            table.insert(labels, toBold("🔒 RESET AKUN (SAFE)"))
            table.insert(actions, "locked_reset_akun")
        end
    end
    
    if _menuVisible.setting then
        table.insert(labels, toBold(_menuIcons.setting  .. " " .. _menuLabels.setting));  table.insert(actions, "setting")
    end

    table.insert(labels, toBold("🔁 RESET QUICK INJECT"));                table.insert(actions, "quick_reset")
    table.insert(labels, toBold("❌ EXIT"));                              table.insert(actions, "out")

    local pilih = gg.choice(labels, nil, toBold(_headerPesan) .. "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    if not pilih then return true end
    local aksi = actions[pilih]
    if aksi == "quick_setup" then setupQuickInject(); return false
    elseif aksi == "quick_run" then if runQuickInject() then return true end return false
    elseif aksi == "inject" then menuInjectSlot(); return true
    elseif aksi == "timeskip" then
        local input = gg.prompt({"⏱️ Menit"}, {"6"}, {"number"})
        if input and tonumber(input[1]) then 
            doSkipTime(tonumber(input[1])) 
        else
            writeLog("Skip Waktu Dibatalkan")
        end
        return true
    elseif aksi == "kda" then menuKDA();  return true
    elseif aksi == "savage" then skipperClassicLoop();  return true
    elseif aksi == "drone" then Drone();  return true
    elseif aksi == "maphack" then Maphack();  return true
    elseif aksi == "prem_nograss" then noGrass();  return true
    elseif aksi == "bypass" then bypassAntiCheat();  return true
    elseif aksi == "prem_reset_akun" then reset_akun_safe(); return true
    elseif aksi == "locked_kda" then gg.alert("⚠️ Fitur KDA terkunci!\nToken Anda adalah tipe FREE. Silakan upgrade ke PREMIUM.") return false
    elseif aksi == "locked_savage" then gg.alert("⚠️ Fitur Inject Savage terkunci!\nToken Anda adalah tipe FREE. Silakan upgrade ke PREMIUM.") return false
    elseif aksi == "locked_drone" then gg.alert("⚠️ Fitur Drone terkunci!\nToken Anda adalah tipe FREE. Silakan upgrade ke PREMIUM.") return false
    elseif aksi == "locked_maphack" then gg.alert("⚠️ Fitur Maphack terkunci!\nToken Anda adalah tipe FREE. Silakan upgrade ke PREMIUM.") return false
    elseif aksi == "locked_nograss" then gg.alert("⚠️ Fitur No Grass terkunci!\nToken Anda adalah tipe FREE. Silakan upgrade ke PREMIUM.") return false
    elseif aksi == "locked_bypass" then gg.alert("⚠️ Fitur Bypass terkunci!\nToken Anda adalah tipe FREE. Silakan upgrade ke PREMIUM.") return false
    elseif aksi == "locked_reset_akun" then gg.alert("⚠️ Fitur Reset Akun terkunci!\nToken Anda adalah tipe FREE. Silakan upgrade ke PREMIUM.") return false
    elseif aksi == "setting" then menuSetting(); return false
    elseif aksi == "quick_reset" then
        _quick.slot, _quick.menit, _quick.kdaVersi, _quick.kdaTim, _quick.kdaMusuh = nil, nil, nil, nil, nil
        _currentTierSetting = "v1"
        os.remove(QUICK_CACHE_FILE)
        writeLog("Quick Inject Direset.")
        gg.toast("✅ Quick Direset!")
        return false

    elseif aksi == "out" then Sai() end
    return false
end
--====================================================================================
--                             START & LOOP UTAMA
--====================================================================================
loadDefaultCache()
local adaSlotLokal = loadSlotsCache()
if not adaSlotLokal or #_slots == 0 then
    gg.toast("📥 Mengunduh semua slot Hero dari GitHub...")
    local suksesAuto = importSlotGist(true)
    
    if not suksesAuto or #_slots == 0 then
        writeLog("Peringatan: Gagal mengambil data slot dari GitHub.")
        gg.toast("❌ Gagal mengunduh Hero dari GitHub! Periksa koneksi internet.")
    end
end
loadQuickCache()

local lastConfigUpdate = os.time()
local CONFIG_UPDATE_INTERVAL = 5

local _doExit = false
while true do
    if os.time() - lastConfigUpdate >= CONFIG_UPDATE_INTERVAL then
        loadOnlineMenuConfig()
        
        local statusTeks = isPremiumUser and "PREMIUM 🔥" or "FREE 👤"
        _headerPesan = string.format("%s\n\n[%s] | EXP = %s", _headerTitle, statusTeks, expiredToken or "N/A")
        
        lastConfigUpdate = os.time()
    end
    if gg.isVisible(true) then
        gg.setVisible(false)
        while true do
            local shouldExit = mainMenu()
            if shouldExit == "exit" then _doExit = true; break
            elseif shouldExit == true then break end
        end
    end
    if _doExit then break end
    gg.sleep(100)
end
