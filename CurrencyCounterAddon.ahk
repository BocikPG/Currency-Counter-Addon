
Class CurrencyCounterAddon
{
	__New(name) ; name is loaded from the JSON file
	{
		global vars, settings
		this.name := name, this.settings := {}, this.hwnd := {}
		this.addon_path := "add-ons\" name  ; path to the add-on's folder
		this.config_path := this.addon_path "\config" vars.poe_version ".ini" ; vars.poe_version is blank for PoE1 and " 2" for PoE2 // split into separate configs not necessarily required

		If !FileExist(this.config_path)
			IniWrite, % "", % this.config_path, settings
		ini := IniBatchRead(this.config_path)

		this.settings.fSize := (ini.UI.font ? ini.UI.font : settings.general.fSize)
		LLK_FontDimensions(this.settings.fSize, h, w), this.settings.fWidth := w, this.settings.fHeight := h ; get approx. dimensions for font width and height (optional)

        Currency_Counter_instance := this
        this.LoadUI()
        Init_currency_counter()
	}

	Hotkeys() ; called when a customizable hotkey is pressed
	{
		global vars, settings
		hotkey := (StrLen(A_ThisHotkey) > 1 ? LTrim(A_ThisHotkey, "~!+#^") : A_ThisHotkey) ; remove key-modifiers (if needed)
		Switch GetKeyName(hotkey)
		{
			Case "F6": ; TEMP: manual trigger for OmniClick() testing
				this.OmniClick()
		}
		KeyWait, % hotkey ; wait until the hotkey is released (prevents continuous function call)
	}

    LoadUI() ; temp method in case Lailloken doesn't create loading on his side in time
    {
        global vars, settings

        ; --- UI.txt: flat "key = "value"" pairs, one per line, ";" comments ---
        lang := FileExist(this.addon_path "\data\" settings.general.lang_client "\UI.txt") ? settings.general.lang_client : "english"
        file := this.addon_path "\data\" lang "\UI.txt"
        If FileExist(file)
        {
            raw := LLK_FileRead(file, 1, "65001")
            Loop, Parse, raw, `n, % " `r"
            {
                If Blank(A_LoopField) || (SubStr(Trim(A_LoopField), 1, 1) = ";") || !InStr(A_LoopField, "=")
                    Continue
                key := Trim(SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1))
                val := Trim(SubStr(A_LoopField, InStr(A_LoopField, "=") + 1))
                val := (SubStr(val, 1, 1) = """" && SubStr(val, 0, 1) = """") ? SubStr(val, 2, -1) : val
                If !IsObject(vars.lang[key])
            		vars.lang[key] := []
				If key
                    vars.lang[key].Push(val)
            }
        }

        ; --- help tooltips.json: nested {check: {control: text}} - merge
        ;     one level deep so we add to any existing "check" section
        ;     instead of replacing it outright ---
        lang := FileExist(this.addon_path "\data\" settings.general.lang_client "\help tooltips.json") ? settings.general.lang_client : "english"
        file := this.addon_path "\data\" lang "\help tooltips.json"
        If FileExist(file)
        {
            tooltips := Json.Load(LLK_FileRead(file,, "65001"))
            If IsObject(tooltips)
                For check, controls in tooltips
                {
                    If !IsObject(vars.help[check])
                        vars.help[check] := {}
                    If IsObject(controls)
                        For control, text in controls
                            vars.help[check][control] := text
                }
        }
    }

    LogRead(log_text)
    {
        CurrencyCounter_ProcessLog(log_text)
    }

    Settings_Open(mode := "") ; called when clicking the cogwheel-icon in the "add-ons" section of the settings menu
	{
		global vars, settings
		static fSize, wHotkey

		If (mode == "refresh")
		{
			Settings_menu("addons_" this.name)
			Return
		}
        Settings_currency_counter()
    }

    Omni_OnBlank()
    {
        local
    	global vars, settings

        If (vars.poe_version != "") ; Horticrafting and Allflame stations only exist in PoE 1
            Return false
        If CurrencyCounter_HorticraftingClick()
		{
			Return true
		}
        ; If CurrencyCounter_AllflameClick()
		; {
		; 	Return true
		; }
    }

	Omni_ItemContext()
	{
		local
    	global vars, settings

	}

	Omni_OnItem()
	{
		local
    	global vars, settings

	}

	ESC(ByRef passESC)
	{
		local
		global vars, settings

		If CurrencyCounter_OverlayVisible()
		{
			CurrencyCounter_HorticraftingOverlay("destroy")
			CurrencyCounter_AllflameOverlay("destroy")
			passESC := true
			Return true
		}
		Else If WinExist("ahk_id " vars.hwnd.cc_logs.main)
		{
			LLK_Overlay(vars.hwnd.cc_logs.main, "destroy")
			vars.hwnd.cc_logs := {"main": ""}
			passESC := false
			Return true
		}
	}
}

global Currency_Counter_instance := ""

#If vars.hwnd.cc_logs.main && (vars.general.wMouse = vars.hwnd.cc_logs.main) && (vars.general.cMouse != vars.hwnd.cc_logs.name_edit) && (vars.general.cMouse != vars.hwnd.cc_logs.search_name)
WheelUp::CurrencyCounter_ShiftCarousel("up")
WheelDown::CurrencyCounter_ShiftCarousel("down")

#If settings.features.currency_counter && vars.hwnd.currency_counter.main && (vars.general.wMouse = vars.hwnd.currency_counter.main) && (vars.general.cMouse = vars.hwnd.currency_counter.drag)
LButton::CurrencyCounter_Click(1)
RButton::CurrencyCounter_Click(2)

#If settings.features.currency_counter && vars.hwnd.currency_counter.main && (vars.general.wMouse = vars.hwnd.currency_counter.main) && (vars.general.cMouse != vars.hwnd.currency_counter.drag)
LButton::CurrencyCounter_BarClick()

#If vars.hwnd.cc_logs.main && (vars.general.wMouse = vars.hwnd.cc_logs.main) && (vars.general.cMouse != vars.hwnd.cc_logs.name_edit) && (vars.general.cMouse != vars.hwnd.cc_logs.search_name)
LButton::CurrencyCounter_Logs2(vars.general.cMouse)

#If settings.features.currency_counter && (vars.general.wMouse = vars.hwnd.poe_client)
~*RButton::CurrencyCounter_RClick()

#If settings.features.currency_counter && (vars.general.wMouse = vars.hwnd.poe_client) && vars.currency_counter.picked
~*LButton::CurrencyCounter_LClick()

#If CurrencyCounter_HorticraftingVisible()
~LButton::CurrencyCounter_HorticraftingCraftClick()

#If CurrencyCounter_AllflameVisible()
~LButton::CurrencyCounter_AllflameCraftClick()

; ──────────────────────────────────────────────────────────────
;  Init
; ──────────────────────────────────────────────────────────────
Init_currency_counter()
{
    local
    global vars, settings, Json, Currency_Counter_instance

    If !IsObject(Json)
        Json := new JSON()

    If !FileExist(Currency_Counter_instance.config_path)
        IniWrite, % "", % Currency_Counter_instance.config_path, settings

    If IsObject(settings.currency_counter)
        Return

    ini := IniBatchRead(Currency_Counter_instance.config_path)

    settings.currency_counter := {}
	settings.features.currency_counter := !Blank(check := ini.settings["enabled"]) ? check : 1
    settings.currency_counter.ssf := !Blank(check := ini.settings["ssf mode"]) ? check : 0
    settings.currency_counter.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize

    ; Saved bar position (monitor-relative, empty = use default)
    settings.currency_counter.bar_x := !Blank(check := ini.settings["bar-x"]) ? check : ""
    settings.currency_counter.bar_y := !Blank(check := ini.settings["bar-y"]) ? check : ""

    raw := ini.settings["sessions"]
    settings.currency_counter.sessions := IsObject(check := Json.Load(raw)) ? check : {}
    settings.currency_counter.active := !Blank(check := ini.settings["active"]) ? check : ""

    settings.currency_counter.bar_x := !Blank(check := ini.settings["bar-x"]) ? check : ""
    settings.currency_counter.bar_y := !Blank(check := ini.settings["bar-y"]) ? check : ""
    settings.currency_counter.logs_x := !Blank(check := ini.settings["logs-x"]) ? check : ""
    settings.currency_counter.logs_y := !Blank(check := ini.settings["logs-y"]) ? check : ""

    settings.currency_counter.display_cur := !Blank(check := ini.settings["display-currency"]) ? check : "divine"
    settings.currency_counter.ninja_prices := !Blank(check := ini.settings["ninja-prices"]) ? check : 0
    settings.currency_counter.ninja_stale_hours := !Blank(check := ini.settings["ninja-stale-hours"]) ? check + 0 : 3
    settings.currency_counter.max_rows := !Blank(check := ini.settings["max-rows"]) ? check + 0 : 0
    settings.currency_counter.price_warn_hours  := !Blank(check := ini.settings["price-warn-hours"])  ? check + 0 : 3
    settings.currency_counter.price_stale_hours := !Blank(check := ini.settings["price-stale-hours"]) ? check + 0 : 6
    settings.currency_counter.rate_warn_hours   := !Blank(check := ini.settings["rate-warn-hours"])   ? check + 0 : 3
    settings.currency_counter.rate_stale_hours  := !Blank(check := ini.settings["rate-stale-hours"])  ? check + 0 : 6 
    settings.currency_counter.spacing := !Blank(check := ini.settings["spacing"]) ? check + 0 : 10
    settings.currency_counter.visibleCount := !Blank(check := ini.settings["visible-sessions"]) ? check + 0 : ""

    settings.currency_counter.chaos_div := !Blank(check := ini.settings["chaos-div"]) ? check + 0 : 1
    settings.currency_counter.exalt_div := !Blank(check := ini.settings["exalt-div"]) ? check + 0 : 1
    settings.currency_counter.chaos_div_updated := !Blank(check := ini.settings["chaos-div-updated"]) ? check : 0
    settings.currency_counter.exalt_div_updated := !Blank(check := ini.settings["exalt-div-updated"]) ? check : 0
	settings.currency_counter.chaos_div_src := ini.settings["chaos-div-src"]
    settings.currency_counter.exalt_div_src := ini.settings["exalt-div-src"]

    LLK_FontDimensions(settings.currency_counter.fSize, height, width)
    settings.currency_counter.fHeight := height
    settings.currency_counter.fWidth := width

    ; Runtime state
    vars.currency_counter := {"picked": 0, "name": "", "group": [], "last_used": "", "currencies": {}, "session_name": "", "session_img": "", "drop_on_shift_release": 0, "shift_timer": 0}

    ; Names that must never be "picked up" as a counted currency
    vars.currency_counter.blacklist_poe1 := ["OMEN","FOSSIL","OIL","SPLINTER","PORTAL","SHARD","LIFEFORCE"] 
    vars.currency_counter.blacklist_poe2 := ["OMEN"] 

    ; Blacklisted names that are still allowed to be staged into a group
    ; (e.g. fossils, since a resonator's sockets get filled and logged
    ; together). See CurrencyCounter_IsGroupable().
    vars.currency_counter.groupable_poe1 := ["RESONATOR"]
    vars.currency_counter.groupable_poe2 := []

    ; ─── PoE 1-only features (fossils/resonators, Horticrafting, Allflame) ───
    ; vars.poe_version is blank for PoE 1 and " 2" for PoE 2, so nothing in this
    ; block is registered, seeded or loaded when playing PoE 2.
    If (vars.poe_version = "")
    {
	    ; Fossil name -> array of effect description lines
	    vars.currency_counter.fossils := {}
		lang := FileExist(Currency_Counter_instance.addon_path "\data\" settings.general.lang_client "\fossils.json") ? settings.general.lang_client : "english"
	    file := Currency_Counter_instance.addon_path "\data\" lang "\fossils.json"
	    If FileExist(file)
	    {
	        FileRead, raw_fossils, % file
	        vars.currency_counter.fossils := IsObject(check := Json.Load(raw_fossils)) ? check : {}
	    }

	    ; Horticrafting station screen-check - reuses the existing image-check
	    ini_sc := IniBatchRead("ini" vars.poe_version "\screen checks (" vars.client.h "p).ini")
	    vars.imagesearch.list.horticrafting := 1
	    If !LLK_HasVal(vars.imagesearch.search, "horticrafting")
	        vars.imagesearch.search.Push("horticrafting")
	    parse := StrSplit(ini_sc.horticrafting["last coordinates"], ",")
	    vars.imagesearch.horticrafting := {"check": 0, "x1": parse.1, "y1": parse.2, "x2": parse.3, "y2": parse.4}
	    vars.imagesearch.checks.horticrafting := {"x": Round(vars.client.h * (483/1080)), "y": Round(vars.client.h * (183/1080)), "w": Round(vars.client.h * (85/1080)), "h": Round(vars.client.h * (30/1080))}

	    ; Horticrafting lifeforce labels - named in row order as they appear
	    ; in the station's stock panel (see CurrencyCounter_HorticraftingOverlay()).
	    ; They don't go through the normal RClick/LClick pick-up flow (the
	    ; station consumes them internally), so seed a sensible starting
	    ; count the first time each is seen instead of starting at 0.
	    vars.currency_counter.horticrafting_lifeforces := ["WILD CRYSTALLISED LIFEFORCE", "VIVID CRYSTALLISED LIFEFORCE", "PRIMAL CRYSTALLISED LIFEFORCE", "SACRED CRYSTALLISED LIFEFORCE", "CRYSTALLISED RANCOUR"]
	    horticrafting_defaults := {"WILD CRYSTALLISED LIFEFORCE": 50, "VIVID CRYSTALLISED LIFEFORCE": 50, "PRIMAL CRYSTALLISED LIFEFORCE": 50, "SACRED CRYSTALLISED LIFEFORCE": 1, "CRYSTALLISED RANCOUR": 1}
	    For name, default_count in horticrafting_defaults
	        If !IsObject(vars.currency_counter.currencies[name])
	            vars.currency_counter.currencies[name] := {"count": default_count, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}

	    ; 2-character abbreviations used for the small clickable label boxes
	    vars.currency_counter.horticrafting_abbr := {"WILD CRYSTALLISED LIFEFORCE": "WI", "VIVID CRYSTALLISED LIFEFORCE": "VI", "PRIMAL CRYSTALLISED LIFEFORCE": "PR", "SACRED CRYSTALLISED LIFEFORCE": "SA", "CRYSTALLISED RANCOUR": "RA"}

	    ; Lifeforce labels used to be mutually exclusive (WILD/VIVID/PRIMAL); they can now all be active at once.
	    ; Leave empty to keep every label independent.
	    vars.currency_counter.horticrafting_exclusive := []

	    ; Active/inactive toggle state per lifeforce label
	    vars.currency_counter.horticrafting_active := {"WILD CRYSTALLISED LIFEFORCE": 1, "VIVID CRYSTALLISED LIFEFORCE": 0, "PRIMAL CRYSTALLISED LIFEFORCE": 0, "SACRED CRYSTALLISED LIFEFORCE": 0, "CRYSTALLISED RANCOUR": 0}

	    ; Editable copy of horticrafting_defaults shown/edited in the amount
	    ; fields next to each label; kept separate so the original defaults
	    ; stay available as a reset point later if needed.
	    vars.currency_counter.horticrafting_defaults := horticrafting_defaults
	    vars.currency_counter.horticrafting_amounts := horticrafting_defaults.Clone()

		; ─── Horticrafting overlay layout (scaled once at init) ───
		; All coordinates measured on 1920x1080 as fractions of vars.client.h.
		vars.currency_counter.horticrafting_layout := {}

		; Row Y positions for each lifeforce (row1..row5)
		rows_y := [351, 410, 469, 528, 587]
		vars.currency_counter.horticrafting_layout.rows_y := []
		For i, y in rows_y
		    vars.currency_counter.horticrafting_layout.rows_y.Push(Round(vars.client.h * (y / 1080)))

		; Label (abbreviation) position
		vars.currency_counter.horticrafting_layout.xLabel := Round(vars.client.h * (1165 / 1080))
		vars.currency_counter.horticrafting_layout.wLabel := Round(vars.client.h * (24 / 1080))
		vars.currency_counter.horticrafting_layout.hLabel := Round(vars.client.h * (22 / 1080))

		; Amount Edit field position (right of label)
		layout := vars.currency_counter.horticrafting_layout
		layout.xAmount := layout.xLabel + layout.wLabel + Round(vars.client.h * (1 / 1080))
		layout.wAmount := Round(vars.client.h * (60 / 1080))
		layout.hAmount := layout.hLabel

		; CRAFT button rectangle (used for the hotkey and the visual frame)
		layout.craft_rect := {}
		layout.craft_rect.x := Round(vars.client.h * (896 / 1080))
		layout.craft_rect.y := Round(vars.client.h * (585 / 1080))
		layout.craft_rect.w := Round(vars.client.h * (142 / 1080))
		layout.craft_rect.h := Round(vars.client.h * (44 / 1080))

		; ; ─── Allflame Crafting station ───
		; vars.imagesearch.list.allflame := 1
		; If !LLK_HasVal(vars.imagesearch.search, "allflame")
		;     vars.imagesearch.search.Push("allflame")
		; parse := StrSplit(ini_sc.allflame["last coordinates"], ",")
		; vars.imagesearch.allflame := {"check": 0, "x1": parse.1, "y1": parse.2, "x2": parse.3, "y2": parse.4}
		; vars.imagesearch.checks.allflame := {"x": Round(vars.client.h * (478/1080)), "y": Round(vars.client.h * (228/1080)), "w": Round(vars.client.h * (172/1080)), "h": Round(vars.client.h * (22/1080))}

		; Allflame's cost currency ("Dead Man's Sulphur") - like the
		; horticrafting lifeforces, this is consumed by the station itself
		; rather than picked up via the normal RClick/LClick flow, so make
		; sure a tracked entry exists instead of starting blank.
		vars.currency_counter.allflame_currency := "DEAD MAN'S SULPHUR"
		If !IsObject(vars.currency_counter.currencies[vars.currency_counter.allflame_currency])
		    vars.currency_counter.currencies[vars.currency_counter.allflame_currency] := {"count": 0, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}


		vars.currency_counter.allflame_amount := 1200

		; ─── Allflame Crafting overlay layout (scaled once at init) ───
		; All coordinates measured on 1920x1080 as fractions of vars.client.h.
		vars.currency_counter.allflame_layout := {}
		alayout := vars.currency_counter.allflame_layout

		; OCR read region - the station's own black "1200" cost box. Kept
		; separate from the Edit field below, since that's now placed to the
		; right as a manual fallback rather than directly overlaying it.
		alayout.xOCR := Round(vars.client.h * (658 / 1080))
		alayout.yOCR := Round(vars.client.h * (485 / 1080))
		alayout.wOCR := Round(vars.client.h * (70 / 1080))
		alayout.hOCR := Round(vars.client.h * (26 / 1080))

		; Currency-count Edit field (manual fallback, placed to the right of
		; the station's own cost box so it doesn't cover the OCR region above)
		alayout.xAmount := Round(vars.client.h * (750 / 1080))
		alayout.yAmount := Round(vars.client.h * (485 / 1080))
		alayout.wAmount := Round(vars.client.h * (70 / 1080))
		alayout.hAmount := Round(vars.client.h * (26 / 1080))

		; CRAFT button rectangle (used for the hotkey and the visual frame)
		alayout.craft_rect := {}
		alayout.craft_rect.x := Round(vars.client.h * (575 / 1080))
		alayout.craft_rect.y := Round(vars.client.h * (538 / 1080))
		alayout.craft_rect.w := Round(vars.client.h * (107 / 1080))
		alayout.craft_rect.h := Round(vars.client.h * (34 / 1080))
    }

    vars.hwnd.currency_counter := {"main": "", "drag": ""}
    vars.hwnd.currency_counter_table := {"main": ""}
    vars.hwnd.currency_counter_horticrafting := {"main": "", "craft": "", "labels": {}, "label_bg": {}, "amounts": {}}
    vars.hwnd.currency_counter_allflame := {"main": "", "craft": "", "amount": ""}
    vars.cc_logs := {"sort_col": "", "sort_asc": 1, "x": settings.currency_counter.logs_x, "y": settings.currency_counter.logs_y, "keywords": {}}

    CurrencyCounter_UpdateExaltRate()

    ; Cache icon image (placeholder path - replace with real asset)
    If FileExist("img\GUI\currency\blessed.png")
        vars.pics.currency_counter := {"icon": LLK_ImageCache("img\GUI\currency\blessed.png")}
    Else
        vars.pics.currency_counter := {"icon": ""}

    ; Activate a session that actually exists: the saved one, else the first one, else create one
    active := settings.currency_counter.active
    If active && settings.currency_counter.sessions.HasKey(active)
        CurrencyCounter_SetActive(active)
    Else If settings.currency_counter.sessions.Count()
    {
        For id in settings.currency_counter.sessions
        {
            CurrencyCounter_SetActive(id)
            Break
        }
    }
    Else
        CurrencyCounter_NewSession()

    CurrencyCounter_DrawBar()
}

; ──────────────────────────────────────────────────────────────
;  Session management
; ──────────────────────────────────────────────────────────────
CurrencyCounter_LoadSession(id)
{
    local
    global vars, settings, Json, Currency_Counter_instance

    If !IsObject(Json)
        Json := new JSON()

    ini := IniBatchRead(Currency_Counter_instance.config_path)

    raw_section := ini["session_" id "_currencies"]
    vars.currency_counter.currencies := {}

    If IsObject(raw_section)
        For currency_name, raw_val in raw_section
        {
            entry := Json.Load(raw_val)
            If IsObject(entry)
                vars.currency_counter.currencies[Format("{:U}", currency_name)] := entry
        }
    Return 1
}

CurrencyCounter_NewSession()
{
    local
    global vars, settings

    id := A_Now
    name := "New Session"
    settings.currency_counter.sessions[id] := { name : name , img : ""}
    CurrencyCounter_SaveIndex()
    CurrencyCounter_SetActive(id)
}

CurrencyCounter_SetActive(id)
{
    local
    global vars, settings, Currency_Counter_instance

    If Blank(id)
    {
        LLK_Overlay("CRITICAL ERROR WITH CURRENCY COUNTER RESTART MODULE", 5,,"red")
        Return 0
    }

    CurrencyCounter_LoadSession(id)

    settings.currency_counter.active := id
    IniWrite, % id, % Currency_Counter_instance.config_path, settings, active
    vars.currency_counter.picked := 0, vars.currency_counter.name := "", vars.currency_counter.group := []
    CurrencyCounter_DrawBar()
    Return 1
}

CurrencyCounter_DeleteSession(id)
{
    local
    global vars, settings, Currency_Counter_instance

    ; Remove from index
    settings.currency_counter.sessions.Delete(id)
    CurrencyCounter_SaveIndex()

    ; Remove INI sections
    IniDelete, % Currency_Counter_instance.config_path, % "session_" id
    IniDelete, % Currency_Counter_instance.config_path, % "session_" id "_currencies"
}

; Default price_currency used when seeding a brand-new currency entry -
; PoE1 (vars.poe_version blank) defaults to chaos, PoE2 stays on exalt.
CurrencyCounter_DefaultCurrency()
{
    global vars
    Return (vars.poe_version = "") ? "chaos" : "exalt"
}

CurrencyCounter_SaveIndex()
{
    local
    global vars, settings, Json, Currency_Counter_instance

    If !IsObject(Json)
        Json := new JSON()

    IniWrite, % Json.Dump(settings.currency_counter.sessions), % Currency_Counter_instance.config_path, settings, sessions
}

CurrencyCounter_SaveCurrency(currency_name)
{
    local
    global vars, settings, Json, Currency_Counter_instance

    If !IsObject(Json)
        Json := new JSON()

    currency_name := Format("{:U}", currency_name)
    id := settings.currency_counter.active
    If Blank(id) || Blank(currency_name)
        Return

    entry := vars.currency_counter.currencies[currency_name]
    If !IsObject(entry)
        Return

    IniWrite, % Json.Dump(entry), % Currency_Counter_instance.config_path, % "session_" id "_currencies", % currency_name
}


; ──────────────────────────────────────────────────────────────
;  Bar click → open/close table
; ──────────────────────────────────────────────────────────────
CurrencyCounter_BarClick()
{
    local
    global vars, settings

    check := LLK_HasVal(vars.hwnd.currency_counter, vars.general.cMouse)
    If (check = "drag")
        Return
    CurrencyCounter_Logs()
}

; ──────────────────────────────────────────────────────────────
;  Currency blacklist check - names that must never be "picked
;  up" as a counted currency (matched via InStr on the OCR'd
;  item name). The actual lists live in vars.currency_counter
;  .blacklist_poe1 / .blacklist_poe2, populated once in
;  Init_currency_counter().
;
;  vars.poe_version is blank ("") for PoE1, non-blank for PoE2 -
;  see the Alt-substitution block in CurrencyCounter_LClick().
; ──────────────────────────────────────────────────────────────
CurrencyCounter_IsBlacklisted(name)
{
    local
    global vars

    list := (vars.poe_version = "") ? vars.currency_counter.blacklist_poe1 : vars.currency_counter.blacklist_poe2
    For i, entry in list
        If InStr(name, entry)
            Return 1

    Return 0
}

; ──────────────────────────────────────────────────────────────
;  Groupable check - blacklisted names that may still be staged
;  into vars.currency_counter.group via CurrencyCounter_GroupAdd()
;  (e.g. fossils, so they can be logged via a resonator instead of
;  the normal single-currency pick). Lists live in vars.currency_counter
;  .groupable_poe1 / .groupable_poe2, populated in Init_currency_counter().
; ──────────────────────────────────────────────────────────────
CurrencyCounter_IsGroupable(name)
{
    local
    global vars

    list := (vars.poe_version = "") ? vars.currency_counter.groupable_poe1 : vars.currency_counter.groupable_poe2
    For i, entry in list
        If InStr(name, entry)
            Return 1

    Return 0
}

; ──────────────────────────────────────────────────────────────
;  Horticrafting station
;
;  Screen-check reuses the existing vars.imagesearch data + the
;  existing Screenchecks_ImageSearch() function from screen-checks.ahk
;  (same storage/lookup as e.g. "skilltree"/"atlas") instead of
;  duplicating that logic here. Since it's registered into
;  vars.imagesearch.list/.search in Init_currency_counter(), it also
;  shows up in the existing screen-check settings menu for
;  calibration/reference-image capture like any other check - no
;  separate calibration code needed in this module. A full-screen
;  overlay window is kept here, following the same pattern
;  stash-ninja uses for its window.
;
;  CurrencyCounter_HorticraftingClick() is the entry point meant to
;  be called from the omni-key's click handler (e.g. a method on the
;  omni-key class that calls this function). It runs the screen-check
;  and, if the horticrafting station is on screen, toggles the
;  overlay; otherwise it does nothing.
; ──────────────────────────────────────────────────────────────

; Full-screen overlay covering the game client, toggled on/off each
; call. Unlike a typical click-through overlay, this one is a normal
; interactive window - clicking the lifeforce labels toggles them
; active/inactive, and the amount fields are real editable text boxes.
; Only the CRAFT highlight button forwards its click through to the
; real button underneath (see CurrencyCounter_HorticraftingCraftClick(),
; which does that via ControlClick straight to the game window rather
; than relying on the overlay being click-through).
;
; All coordinates were measured on a 1920x1080 screenshot and are
; expressed as a fraction of vars.client.h so they scale to any
; resolution, same convention as the screen-check region above.
CurrencyCounter_HorticraftingOverlay(mode := "toggle")
{
    local
    global vars, settings
    static hwnd_overlay := 0

	If (mode = "destroy")
	{
		If hwnd_overlay && WinExist("ahk_id " hwnd_overlay)
		{
			LLK_Overlay(hwnd_overlay, "destroy")
			Gui, currency_counter_horticrafting: Destroy
		}
		hwnd_overlay := 0
		Return
	}

    If hwnd_overlay && WinExist("ahk_id " hwnd_overlay)
    {
        LLK_Overlay(hwnd_overlay, "destroy")
        Gui, currency_counter_horticrafting: Destroy
        hwnd_overlay := 0
        Return
    }
	
    Gui, currency_counter_horticrafting: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_overlay"
    Gui, currency_counter_horticrafting: Color, Purple
    WinSet, TransColor, Purple
    Gui, currency_counter_horticrafting: Margin, 0, 0
    Gui, currency_counter_horticrafting: Font, % "s" Round(11 * (vars.client.h / 1080)) " cWhite", Arial
	
	layout := vars.currency_counter.horticrafting_layout
	
    ; ── Lifeforce labels + amount fields ──
    labels := {}, label_bg := {}, amounts := {}
    For i, name in vars.currency_counter.horticrafting_lifeforces
    {
        yRow := layout.rows_y[i]
        active := vars.currency_counter.horticrafting_active[name]

        Gui, currency_counter_horticrafting: Add, Text, % "x" layout.xLabel " y" yRow " w" layout.wLabel " h" layout.hLabel " BackgroundTrans Border Center gCurrencyCounter_HorticraftingLabelClick HWNDhwnd", % vars.currency_counter.horticrafting_abbr[name]
        labels[name] := hwnd
        Gui, currency_counter_horticrafting: Add, Progress, % "xp yp wp hp HWNDhwnd Disabled Background" (active ? "41BB1C" : "Black"), 0
        label_bg[name] := hwnd

        Gui, currency_counter_horticrafting: Add, Edit, % "x" layout.xAmount - 2 " y" yRow " w" layout.wAmount " h" layout.hAmount " Number Center Background1A1A1A cBlack gCurrencyCounter_HorticraftingAmountChange HWNDhwnd", % vars.currency_counter.horticrafting_amounts[name]
        amounts[name] := hwnd
    }

    ; ── CRAFT button (visual frame + transparent clickable area) ──
    xC := layout.craft_rect.x, yC := layout.craft_rect.y, wC := layout.craft_rect.w, hC := layout.craft_rect.h
    craftAccent := "41BB1C"

    ; Inner punch-through (Purple = transparent)
    Gui, currency_counter_horticrafting: Add, Text, % "BackgroundTrans Border x" xC + 4 " y" yC + 4 " w" wC - 8 " h" hC - 8
    Gui, currency_counter_horticrafting: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd BackgroundPurple", 0

    ; Outer accent border
    Gui, currency_counter_horticrafting: Add, Text, % "BackgroundTrans Border x" xC " y" yC " w" wC " h" hC
    Gui, currency_counter_horticrafting: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd Background" craftAccent, 0

    ; Transparent clickable area (no g‑label; the hotkey handles clicks)
    Gui, currency_counter_horticrafting: Add, Text, % "x" xC " y" yC " w" wC " h" hC " BackgroundTrans HWNDhwnd_craft", % " "

    Gui, currency_counter_horticrafting: Show, % "NA x" vars.client.x " y" vars.client.y " w" vars.client.w " h" vars.client.h
    vars.hwnd.currency_counter_horticrafting := {"main": hwnd_overlay, "craft": hwnd_craft, "labels": labels, "label_bg": label_bg, "amounts": amounts}
    LLK_Overlay(hwnd_overlay, "show", 0, "currency_counter_horticrafting")
}

; Fired by the CRAFT highlight button (native click - the overlay is no
; longer click-through). Does the craft bookkeeping first, then forwards
; the click straight to the real CRAFT button underneath by sending it
; directly to the game window (no real cursor movement involved, so it
; works regardless of what's on top on screen).
CurrencyCounter_HorticraftingCraftClick(cHWND := 0)
{
    global vars, settings

    ; ── Get current cursor position (screen coordinates) ──
    MouseGetPos, mouseX, mouseY

    ; ── Retrieve the craft button rectangle (stored in vars) ──
    rect := vars.currency_counter.horticrafting_layout.craft_rect   

    ; ── Check if cursor is inside the button area ──
    If (mouseX < vars.client.x + rect.x)
        || (mouseX > vars.client.x + rect.x + rect.w)
        || (mouseY < vars.client.y + rect.y)
        || (mouseY > vars.client.y + rect.y + rect.h)
        Return   ; not on the craft button - ignore


    ; --- Add counts from active lifeforce labels to the session ---
    For i, name in vars.currency_counter.horticrafting_lifeforces
    {
        If vars.currency_counter.horticrafting_active[name]
        {
            amount := vars.currency_counter.horticrafting_amounts[name] + 0   ; force number
            If (amount > 0)
            {
                ; Ensure currency entry exists
                If !IsObject(vars.currency_counter.currencies[name])
                    vars.currency_counter.currencies[name] := {"count": 0, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}

                ; Add the amount
                vars.currency_counter.currencies[name].count += amount
                CurrencyCounter_SaveCurrency(name)
            }
        }
    }
}

; Fired when a lifeforce label is clicked (native g-label - AHK passes the
; clicked control's HWND as the first parameter automatically). Toggles
; that lifeforce active/inactive - see CurrencyCounter_HorticraftingToggleActive().
CurrencyCounter_HorticraftingLabelClick(cHWND)
{
    global vars

    clicked_name := ""
    For name, hwnd in vars.hwnd.currency_counter_horticrafting.labels
        If (hwnd = cHWND)
        {
            clicked_name := name
            Break
        }
    If (clicked_name = "")
        Return

    CurrencyCounter_HorticraftingToggleActive(clicked_name)
}

; Applies the active/inactive toggle rules and repaints the label colors
; in place (no need to rebuild the whole overlay):
;   - WILD/VIVID/PRIMAL are mutually exclusive; clicking the one that's
;     already active does nothing (one of the three must stay active at
;     all times), clicking a different one switches the active one over.
;   - SACRED/RANCOUR (not in the exclusive list) toggle independently.
CurrencyCounter_HorticraftingToggleActive(name)
{
    global vars

    If LLK_HasVal(vars.currency_counter.horticrafting_exclusive, name)
    {
        If vars.currency_counter.horticrafting_active[name]
            Return ; already the active one of the trio - stays active
        For i, ex_name in vars.currency_counter.horticrafting_exclusive
            vars.currency_counter.horticrafting_active[ex_name] := (ex_name = name) ? 1 : 0
    }
    Else
        vars.currency_counter.horticrafting_active[name] := !vars.currency_counter.horticrafting_active[name]

    For lf_name, hwnd in vars.hwnd.currency_counter_horticrafting.label_bg
    {
        color := vars.currency_counter.horticrafting_active[lf_name] ? "41BB1C" : "Black"
        GuiControl, % "+Background" color, % hwnd
    }
}

; Fired on every keystroke in an amount field (native Edit g-label - AHK
; passes the changed control's HWND as the first parameter automatically).
; Saves the parsed value straight back to horticrafting_amounts.
CurrencyCounter_HorticraftingAmountChange(cHWND)
{
    global vars

    For name, hwnd in vars.hwnd.currency_counter_horticrafting.amounts
        If (hwnd = cHWND)
        {
            vars.currency_counter.horticrafting_amounts[name] := LLK_ControlGet(cHWND) + 0
            Return
        }
}

; Entry point for the omni-key click handler.
CurrencyCounter_HorticraftingClick()
{
    local

    If !Screenchecks_ImageSearch("horticrafting")
	{
	    CurrencyCounter_HorticraftingOverlay("destroy")
	    Return false
	}

    CurrencyCounter_HorticraftingOverlay()
	Return true
}

; ──────────────────────────────────────────────────────────────
;  Allflame Crafting station
;
;  Same conventions as the horticrafting station above: screen-check
;  reuses vars.imagesearch + Screenchecks_ImageSearch() (registered in
;  Init_currency_counter(), reusing the same ini_sc read as
;  horticrafting - no separate calibration code needed here), the
;  overlay is a normal (non click-through) window, and CRAFT uses the
;  same #If-hotkey + manual mouse-rect-check pattern as horticrafting's
;  CRAFT button (see the #If block near the top of this file and
;  CurrencyCounter_AllflameCraftClick() below).
;
;  CurrencyCounter_AllflameClick() is the entry point meant to be
;  called from the omni-key's click handler. It runs the screen-check
;  and, if the Allflame Crafting station is on screen, toggles the
;  overlay; otherwise it does nothing.
; ──────────────────────────────────────────────────────────────

; Full-screen overlay covering the game client, toggled on/off each
; call - same window setup as CurrencyCounter_HorticraftingOverlay().
; Draws a single editable Edit control over the station's own black
; cost box (tracks vars.currency_counter.allflame_currency, "DEAD MAN'S
; SULPHUR") plus a highlighted CRAFT button frame.
;
; All coordinates were measured on a 1920x1080 screenshot and are
; expressed as a fraction of vars.client.h, same convention as the
; screen-check region above.
CurrencyCounter_AllflameOverlay(mode := "toggle")
{
    local
    global vars, settings
    static hwnd_overlay := 0

	If (mode = "destroy")
	{
		If hwnd_overlay && WinExist("ahk_id " hwnd_overlay)
		{
			LLK_Overlay(hwnd_overlay, "destroy")
			Gui, currency_counter_allflame: Destroy
		}
		hwnd_overlay := 0
		Return
	}

    If hwnd_overlay && WinExist("ahk_id " hwnd_overlay)
    {
        LLK_Overlay(hwnd_overlay, "destroy")
        Gui, currency_counter_allflame: Destroy
        hwnd_overlay := 0
        Return
    }

    Gui, currency_counter_allflame: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_overlay"
    Gui, currency_counter_allflame: Color, Purple
    WinSet, TransColor, Purple
    Gui, currency_counter_allflame: Margin, 0, 0
    Gui, currency_counter_allflame: Font, % "s" Round(11 * (vars.client.h / 1080)) " cWhite", Arial

    layout := vars.currency_counter.allflame_layout

    ; ── Editable cost field, overlaid on the station's own black "1200" box ──
    Gui, currency_counter_allflame: Add, Edit, % "x" layout.xAmount " y" layout.yAmount " w" layout.wAmount " h" layout.hAmount " Number Center Background1A1A1A cBlack gCurrencyCounter_AllflameAmountChange HWNDhwnd", % vars.currency_counter.allflame_amount
    hwnd_amount := hwnd

    ; ── CRAFT button (visual frame + transparent clickable area, same
    ;     3-piece pattern as the horticrafting CRAFT button) ──
    xC := layout.craft_rect.x, yC := layout.craft_rect.y, wC := layout.craft_rect.w, hC := layout.craft_rect.h
    craftAccent := "41BB1C"

    ; Inner punch-through (Purple = transparent)
    Gui, currency_counter_allflame: Add, Text, % "BackgroundTrans Border x" xC + 4 " y" yC + 4 " w" wC - 8 " h" hC - 8
    Gui, currency_counter_allflame: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd BackgroundPurple", 0

    ; Outer accent border
    Gui, currency_counter_allflame: Add, Text, % "BackgroundTrans Border x" xC " y" yC " w" wC " h" hC
    Gui, currency_counter_allflame: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd Background" craftAccent, 0

    ; Transparent clickable area (no g-label; the hotkey handles clicks,
    ; same as horticrafting's CRAFT button)
    Gui, currency_counter_allflame: Add, Text, % "x" xC " y" yC " w" wC " h" hC " BackgroundTrans HWNDhwnd_craft", % " "

    Gui, currency_counter_allflame: Show, % "NA x" vars.client.x " y" vars.client.y " w" vars.client.w " h" vars.client.h
    vars.hwnd.currency_counter_allflame := {"main": hwnd_overlay, "craft": hwnd_craft, "amount": hwnd_amount}
    LLK_Overlay(hwnd_overlay, "show", 0, "currency_counter_allflame")
}

; Reads the current cost shown in the station's own black cost box via
; OCR. Same "Exile UI: OCR" spawn + WM_COPYDATA handshake that
; Statlas() uses (see statlas.ahk / modules\_ocr thread.ahk) -
; vars.ocr_comms.text gets filled in by the existing WM_COPYDATA
; receiver elsewhere in the framework, same as it does for Statlas().
; We're just handing it a different clip rect (the cost box instead of
; the map name under the cursor).
;
; Returns the parsed number, or "" if OCR failed/timed out/found no
; digits - the caller falls back to whatever's cached in allflame_amount
; in that case. This blocks for up to ~1s, but that's fine here since
; it runs before CurrencyCounter_AllflameCraftClick() forwards the click
; to the game - see that function for why the ordering matters.
CurrencyCounter_AllflameOCR()
{
    global vars, settings

    layout := vars.currency_counter.allflame_layout
    start := A_TickCount

    Gui, ocr_comms: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border, % "Exile UI: OCR"
    WinSet, Trans, 1
    Gui, ocr_comms: Add, Text,, % "client: " vars.hwnd.poe_client
    . "`nclip: " layout.xOCR "|" layout.yOCR "|" layout.wOCR "|" layout.hOCR "`n"
    . (settings.general.blackbars ? "blackbars: " vars.client.x - vars.monitor.x "|0|" vars.client.w "|" vars.client.h "`n" : "")
    . (settings.general.lang_client = "english" ? "`nenglish" : "")
    Gui, ocr_comms: Show, NA x10000 y10000

    vars.ocr_comms := {}
    Run, % """" A_AhkPath """ """ A_ScriptDir "\modules\_ocr thread.ahk""", % A_ScriptDir, UseErrorLevel

    If ErrorLevel
    {
        Gui, ocr_comms: Destroy
        Return ""
    }

    While !ocr_failed && Blank(vars.ocr_comms.text)
    {
        If (A_TickCount >= start + 1000)
            ocr_failed := 1
        Sleep 25
    }

    Gui, ocr_comms: Destroy

    If ocr_failed || (vars.ocr_comms.text = "OCR failed")
        Return ""

    text := SubStr(vars.ocr_comms.text, InStr(vars.ocr_comms.text, ":") + 2)
    digits := RegExReplace(text, "[^\d]") ; OCR can throw in stray spaces/commas/icon noise - keep just the digits
    Return (digits = "") ? "" : digits + 0
}

; Fired by the CRAFT button's #If hotkey (see near the top of this
; file) - this hotkey consumes the click (no ~) instead of passing it
; straight through, because forwarding it first would let the game
; close/refresh the crafting panel before OCR even gets a chance to
; read it. So the order here matters:
;   1. read the cost via OCR (CurrencyCounter_AllflameOCR()) while the
;      panel is still guaranteed to be open, falling back to whatever's
;      cached in allflame_amount if that fails
;   2. add that cost to the session
;   3. forward the click to the game ourselves, straight after
CurrencyCounter_AllflameCraftClick()
{
    global vars

    ; ── Check if cursor is inside the button area ──
    MouseGetPos, mouseX, mouseY
    rect := vars.currency_counter.allflame_layout.craft_rect

    If (mouseX < vars.client.x + rect.x)
        || (mouseX > vars.client.x + rect.x + rect.w)
        || (mouseY < vars.client.y + rect.y)
        || (mouseY > vars.client.y + rect.y + rect.h)
        Return ; not on the craft button - ignore

    ; --- Read the cost via OCR now, before the click reaches the game ---
    ;ocr_amount := CurrencyCounter_AllflameOCR() ;read is not clear
    amount := (ocr_amount != "") ? ocr_amount : vars.currency_counter.allflame_amount

    ; OCR succeeded - keep the Edit field (our fallback) in sync with
    ; what was actually read, so it stays a sensible fallback value.
    If (ocr_amount != "")
    {
        vars.currency_counter.allflame_amount := ocr_amount
        If vars.hwnd.currency_counter_allflame.amount
            GuiControl, Text, % vars.hwnd.currency_counter_allflame.amount, % ocr_amount
    }

    ; --- Add the cost to the session ---
    amount += 0 ; force number
    If (amount > 0)
    {
        currency_name := vars.currency_counter.allflame_currency

        If !IsObject(vars.currency_counter.currencies[currency_name])
            vars.currency_counter.currencies[currency_name] := {"count": 0, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}

        vars.currency_counter.currencies[currency_name].count += amount
        CurrencyCounter_SaveCurrency(currency_name)
    }
	
	CurrencyCounter_AllflameOverlay("destroy")
}

; Fired on every keystroke in the cost field (native Edit g-label - AHK
; passes the changed control's HWND as the first parameter
; automatically). Saves the parsed value straight back to
; allflame_amount.
CurrencyCounter_AllflameAmountChange(cHWND)
{
    global vars

    vars.currency_counter.allflame_amount := LLK_ControlGet(cHWND) + 0
}

; Entry point for the omni-key click handler.
CurrencyCounter_AllflameClick()
{
    If !Screenchecks_ImageSearch("allflame")
	{
	    CurrencyCounter_AllflameOverlay("destroy")
	    Return false
	}

    CurrencyCounter_AllflameOverlay()
	Return true
}


CurrencyCounter_HorticraftingVisible()
{
    global vars
    hwnd := vars.hwnd.currency_counter_horticrafting.main
    Return hwnd && WinExist("ahk_id " hwnd) ? 1 : 0
}

CurrencyCounter_AllflameVisible()
{
    global vars
    hwnd := vars.hwnd.currency_counter_allflame.main
    Return hwnd && WinExist("ahk_id " hwnd) ? 1 : 0
}

CurrencyCounter_OverlayVisible()
{
    Return CurrencyCounter_HorticraftingVisible() || CurrencyCounter_AllflameVisible()
}

; ──────────────────────────────────────────────────────────────
;  RClick / LClick / Esc  (unchanged from original)
; ──────────────────────────────────────────────────────────────
CurrencyCounter_RClick()
{
    local
    global vars, settings

    If vars.currency_counter.picked
    {
        vars.currency_counter.picked := 0
        vars.currency_counter.name := ""
        vars.currency_counter.group := []
        CurrencyCounter_DrawBar()
        Return
    }

    If GetKeyState("Ctrl", "P")
        Return

    ; Pick currency from item under cursor
    name := CurrencyCounter_ReadItemName(clip)
    If Blank(name)
        Return
    name := Format("{:U}", name)
    If CurrencyCounter_IsBlacklisted(name)
		Return
	If CurrencyCounter_IsGroupable(name)
	{
		CurrencyCounter_GroupAdd(name, clip)
		Return
	}
    vars.currency_counter.picked := 1
    vars.currency_counter.name := name
    If !IsObject(vars.currency_counter.currencies[name])
        vars.currency_counter.currencies[name] := {"count": 0, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}
    CurrencyCounter_DrawBar()
}

; Add a currency name to the staged group and arm "picked" state so
; the usual LClick / Esc hotkeys engage. clip is the raw copied item
; text. For a RESONATOR, we use clip to back-calculate which fossils
; are socketed (see CurrencyCounter_GroupAddResonator below) instead
; of just staging the resonator's own name.
CurrencyCounter_GroupAdd(name, clip := "")
{
    local
    global vars

    If InStr(name, "RESONATOR")
    {
        CurrencyCounter_GroupAddResonator(name, clip)
        Return
    }

    If !IsObject(vars.currency_counter.group)
        vars.currency_counter.group := []

    vars.currency_counter.group.Push(name)
    vars.currency_counter.picked := 1
    vars.currency_counter.name := "" ; group mode - no single held name
    CurrencyCounter_DrawBar()
}

; ──────────────────────────────────────────────────────────────
;  Resonator handling
;
;  Sockets per tier: Primitive 1, Potent 2, Powerful 3, Prime 4
;  (the "Chaotic" prefix doesn't change socket count).
;
;  A resonator's tooltip shows the COMBINED effect of every socketed
;  fossil (its "Reforges a rare item..." block). We brute-force every
;  combination of fossils (from fossils.json, repeats allowed) whose
;  size equals the resonator's socket count, apply the observed
;  cancellation rule (opposite polarity on the same category wipes
;  both lines, e.g. "More Fire" + "No Fire" cancel), and accept the
;  first combo whose resulting line set matches the tooltip exactly.
;
;  This also doubles as the fullness check: a resonator with empty
;  sockets won't have a fossil combo of the FULL socket count that
;  reproduces its (shorter/absent) modifier text, so no match is
;  found and it's not picked up.
; ──────────────────────────────────────────────────────────────
CurrencyCounter_GroupAddResonator(name, clip)
{
    local
    global vars

    sockets := CurrencyCounter_ResonatorSockets(name)
    If !sockets
        Return ; unrecognized tier - ignore

    lines := []
    If RegExMatch(clip, "si)Reforges a rare item with new random modifiers\r?\n(.*?)\r?\n-{2,}", m)
    {
        For i, ln in StrSplit(m1, "`n", "`r")
        {
            ln := Trim(ln)
            If !Blank(ln)
                lines.Push(ln)
        }
    }

    combo := CurrencyCounter_FindFossilCombo(lines, sockets)
    If !IsObject(combo)
        Return ; not full (or unrecognized combo) - do not pick it up

    If !IsObject(vars.currency_counter.group)
        vars.currency_counter.group := []

    For i, fname in combo
        vars.currency_counter.group.Push(Format("{:U}", i))
    vars.currency_counter.group.Push(name) ; log the resonator itself too

    vars.currency_counter.picked := 1
    vars.currency_counter.name := ""
    CurrencyCounter_DrawBar()
}

CurrencyCounter_ResonatorSockets(name)
{
    If InStr(name, "PRIMITIVE")
        Return 1
    If InStr(name, "POTENT")
        Return 2
    If InStr(name, "POWERFUL")
        Return 3
    If InStr(name, "PRIME")
        Return 4
    Return 0
}

; Brute-force search: try every multiset of `count` fossil names (with
; repetition, order-independent) from fossils.json until one reproduces
; observedLines exactly. Returns the matching combo (array of fossil
; names) or "" if none found.
CurrencyCounter_FindFossilCombo(observedLines, count)
{
    local
    global vars

	combo := []
	for i, line in observedLines
	{
		for j, fossil in vars.currency_counter.fossils
		{
			if(combo.HasKey(j))
				continue
			for k, fossil_line in fossil
			{
				if(line == fossil_line)
				{
					lineFound := 1
					combo[j] := true
					break
				}
			}
			if(lineFound)
				break
		}
		lineFound := 0
	}

	if(count != combo.Count())
		Return ""

    Return combo
}


CurrencyCounter_LClick()
{
    local
    global vars, settings

    If !vars.currency_counter.picked
        Return

    ; --- Verify cursor is over a valid item using clipboard ---
    Clipboard := ""
    SendInput, {Blind}^c ; copy item under cursor
    ClipWait, 0.1
    if ErrorLevel
	{
		vars.currency_counter.picked := 0
        vars.currency_counter.name := ""  
        vars.currency_counter.group := []
		CurrencyCounter_DrawBar()
		return ; clipboard empty - no item, do nothing
	}

    ; Check if clipboard contains a valid item (at least "Rarity:" line)
    if !RegExMatch(Clipboard, "i)Rarity:")
	{
		vars.currency_counter.picked := 0
        vars.currency_counter.name := ""  
        vars.currency_counter.group := []
		CurrencyCounter_DrawBar()
		return
	}

    ; --- Group apply: everything staged (e.g. fossils) gets +1. The
    ;     group is NOT cleared here - it stays armed, just like a single
    ;     picked currency, until Shift is released below / in
    ;     CurrencyCounter_CheckShiftRelease(). ---
    If (IsObject(vars.currency_counter.group) && vars.currency_counter.group.Count())
    {
        For i, gname in vars.currency_counter.group
        {
            If !IsObject(vars.currency_counter.currencies[gname])
                vars.currency_counter.currencies[gname] := {"count": 0, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}
            vars.currency_counter.currencies[gname].count += 1
            CurrencyCounter_SaveCurrency(gname)
        }
        vars.currency_counter.last_used := vars.currency_counter.group
    }
    Else
    {
        ; --- Single-currency flow (unchanged) ---
        originalName := vars.currency_counter.name

        ; --- Temporary currency substitution for PoE1 with Alt held ---
        if (vars.poe_version = "" && GetKeyState("Alt", "P"))
        {
            if (originalName = "ORB OF ALTERATION")
                vars.currency_counter.name := "ORB OF AUGMENTATION"
            else if (originalName = "ORB OF ALCHEMY")
                vars.currency_counter.name := "ORB OF SCOURING"
            ; else keep unchanged
        }

        ; --- Use the (possibly substituted) currency name for counting ---
        if(Blank(vars.currency_counter.currencies[vars.currency_counter.name]))
        {
            vars.currency_counter.currencies[vars.currency_counter.name] := {"count": 0, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}
        }
        vars.currency_counter.currencies[vars.currency_counter.name].count += 1
        vars.currency_counter.last_used := vars.currency_counter.name

        CurrencyCounter_SaveCurrency(vars.currency_counter.name)

        ; --- Restore original picked currency name before any state changes ---
        vars.currency_counter.name := originalName
    }

    ; --- Shift handling - shared by both the group and single-name
    ;     cases above; clears (or defers clearing) picked/name/group. ---
    If GetKeyState("Shift", "P")
    {
        vars.currency_counter.drop_on_shift_release := 1
        If !vars.currency_counter.shift_timer
        {
            vars.currency_counter.shift_timer := 1
            SetTimer, CurrencyCounter_CheckShiftRelease, 50
        }
    }
    Else
    {
        vars.currency_counter.picked := 0
        vars.currency_counter.name := ""   ; cleared because no shift held
        vars.currency_counter.group := []
    }

    CurrencyCounter_DrawBar()
}

CurrencyCounter_Esc()
{
    local
    global vars, settings

    vars.currency_counter.picked := 0
    vars.currency_counter.name := ""
    vars.currency_counter.group := []
    CurrencyCounter_DrawBar()
}

CurrencyCounter_CheckShiftRelease()
{
    global vars
    If !vars.currency_counter.drop_on_shift_release
    {
        If vars.currency_counter.shift_timer
        {
            vars.currency_counter.shift_timer := 0
            SetTimer, CurrencyCounter_CheckShiftRelease, Off
        }
        Return
    }
    If !GetKeyState("Shift", "P")
    {
        vars.currency_counter.picked := 0, vars.currency_counter.name := ""
        vars.currency_counter.group := []
        vars.currency_counter.drop_on_shift_release := 0
        CurrencyCounter_DrawBar()
        vars.currency_counter.shift_timer := 0
        SetTimer, CurrencyCounter_CheckShiftRelease, Off
    }
}

; ──────────────────────────────────────────────────────────────
;  Process log lines
; ──────────────────────────────────────────────────────────────
CurrencyCounter_ProcessLog(line)
{
    local
    global vars, settings

    If RegExMatch(line, "i)(?:<colour:[^>]+>)?\{?(omen\s+\S.+?) in your inventory has been consumed\}?", m)
    {
        currency_name := Format("{:U}", Trim(m1))
        If !IsObject(vars.currency_counter.currencies[currency_name])
            vars.currency_counter.currencies[currency_name] := {"count": 0, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}
        vars.currency_counter.currencies[currency_name].count += 1
        CurrencyCounter_SaveCurrency(currency_name)
        CurrencyCounter_DrawBar()
    }
    Else If InStr(line, "Failed to apply item")
    {
        currency_name := vars.currency_counter.last_used
		if(currency_name.Count() > 0)
		{
			Loop, % currency_name.Count()
			{
				currency := currency_name[A_Index]
				if IsObject(vars.currency_counter.currencies[currency])
				{
					if vars.currency_counter.currencies[currency].count > 0
						vars.currency_counter.currencies[currency].count -= 1
					CurrencyCounter_SaveCurrency(currency)
					CurrencyCounter_DrawBar()
				}
			}
		}
        Else if IsObject(vars.currency_counter.currencies[currency_name])
        {
            If vars.currency_counter.currencies[currency_name].count > 0
                vars.currency_counter.currencies[currency_name].count -= 1
            CurrencyCounter_SaveCurrency(currency_name)
            CurrencyCounter_DrawBar()
        }
    }
}

; ──────────────────────────────────────────────────────────────
;  Drag / click handler for the bar overlay
; ──────────────────────────────────────────────────────────────
CurrencyCounter_Click(hotkey)
{
    local
    global vars, settings, Currency_Counter_instance
    static width, height

    check := LLK_HasVal(vars.hwnd.currency_counter, vars.general.cMouse)
    If !check
        Return

    If (check = "drag")
    {
        If (hotkey = 2)
        {
            settings.currency_counter.bar_x := "", settings.currency_counter.bar_y := ""
            IniDelete, % Currency_Counter_instance.config_path, settings, bar-x
            IniDelete, % Currency_Counter_instance.config_path, settings, bar-y
            CurrencyCounter_DrawBar()
            Return
        }
        start := A_TickCount
        While GetKeyState("LButton", "P")
        {
            If (A_TickCount >= start + 250)
            {
                If !width
                {
                    WinGetPos,,, width, height, % "ahk_id " vars.hwnd.currency_counter.main
                    vars.general.drag := 1, gui_name := Gui_Name(vars.hwnd.currency_counter.main)
                }
                LLK_Drag(width, height, xPos, yPos, 1, gui_name, 1)
                Sleep, 1
            }
        }
        vars.general.drag := 0, width := "", height := ""
        If !Blank(xPos) || !Blank(yPos)
        {
            settings.currency_counter.bar_x := xPos, settings.currency_counter.bar_y := yPos
            IniWrite, % xPos, % Currency_Counter_instance.config_path, settings, bar-x
            IniWrite, % yPos, % Currency_Counter_instance.config_path, settings, bar-y
            CurrencyCounter_DrawBar()
        }
        Return
    }
}

; ──────────────────────────────────────────────────────────────
;  Bar overlay  (unchanged structure, keeps existing behaviour)
; ──────────────────────────────────────────────────────────────
CurrencyCounter_DrawBar()
{
    local
    global vars, settings
    static toggle := 0, wait

    If wait
        Return
    wait := 1

    If !settings.features.currency_counter
    {
        LLK_Overlay(vars.hwnd.currency_counter.main, "destroy")
        vars.hwnd.currency_counter := {"main": "", "drag": ""}
        wait := 0
        Return
    }

    toggle := !toggle
    GUI_name := "cc_bar" toggle
    fSize := settings.currency_counter.fSize
    fH := settings.currency_counter.fHeight
    fW := settings.currency_counter.fWidth
    barW := 300
    barH := 30
    dragSz := Floor(fW * 0.6)

    held_name := vars.currency_counter.picked ? vars.currency_counter.name : ""
    If (IsObject(vars.currency_counter.group) && vars.currency_counter.group.Count())
    {
        group_list := ""
		For i, gname in vars.currency_counter.group
		    group_list .= (i = 1 ? "" : " + ") SubStr(gname, 1, 5)
		held_name := group_list " (" vars.currency_counter.group.Count() ")"
    }

    Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwnd_bar"
    Gui, %GUI_name%: Color, Black
    Gui, %GUI_name%: Margin, 0, 0
    Gui, %GUI_name%: Font, % "s" fSize " cWhite", % vars.system.font

    hwnd_old := IsObject(vars.hwnd.currency_counter) ? vars.hwnd.currency_counter.main : ""
    vars.hwnd.currency_counter := {"main": hwnd_bar}

    Gui, %GUI_name%: Add, Progress, % "x0 y0 w" dragSz " h" dragSz " BackgroundWhite HWNDhwnd_drag", 0
    vars.hwnd.currency_counter.drag := hwnd_drag

    Gui, %GUI_name%: Add, Text, % "x0 y0 w" barW " h" barH " Section 0x200 BackgroundTrans Center HWNDhwnd_label" (vars.currency_counter.picked ? "" : " c606060"), % " " held_name " "
    Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack", 0

    Gui, %GUI_name%: Show, % "NA x10000 y10000"
    WinGetPos,,, w, h, % "ahk_id " hwnd_bar

    defaultX := vars.client.x - vars.monitor.x + Floor(vars.client.w * (2/3)) - Floor(w / 2)
    defaultY := vars.client.y - vars.monitor.y + vars.client.h - h - 15
    xPos := !Blank(settings.currency_counter.bar_x) ? settings.currency_counter.bar_x : defaultX
    yPos := !Blank(settings.currency_counter.bar_y) ? settings.currency_counter.bar_y : defaultY

    Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
    LLK_Overlay(hwnd_bar, "show",, GUI_name)
    If hwnd_old
        LLK_Overlay(hwnd_old, "destroy")
    wait := 0
}

; ──────────────────────────────────────────────────────────────
;  Placeholder: read item name from game (integrate with your
;  existing item-name detection / clipboard method)
; ──────────────────────────────────────────────────────────────
CurrencyCounter_ReadItemName(ByRef clip_out := "")
{
    Clipboard := ""
    SendInput, ^c
    ClipWait, 0.2
    if ErrorLevel
        return
    clip := Clipboard
    clip_out := clip
    name := ""
    if RegExMatch(clip, "i)Rarity: Currency\r?\n(.+?)(\r?\n|$)", m)
        name := Trim(m1)
    Return name
}


; ──────────────────────────────────────────────────────────────
;  CurrencyCounter_Logs()
;  Wire in hotkeys.ahk:
;    #If vars.hwnd.cc_logs.main && (vars.general.wMouse = vars.hwnd.cc_logs.main)
;    LButton::CurrencyCounter_Logs2(vars.general.cMouse)
; ──────────────────────────────────────────────────────────────
CurrencyCounter_Logs(cHWND := "")
{
	local
	global vars, settings
	static toggle := 0

	fSize2 := settings.currency_counter.fSize
	LLK_FontDimensions(fSize2, fHeight2, fWidth2)
	LLK_FontDimensions(fSize2 + 4, fHeight3, fWidth3)
	hFont := fHeight2 * 1.5
	max_lines := Floor(vars.monitor.h * 0.75 / hFont)
	If (settings.currency_counter.max_rows > 0)
		max_lines := Min(max_lines, settings.currency_counter.max_rows)
	ssf := settings.currency_counter.ssf
	CurrencyCounter_SyncRates()
	ninja_price_stale_hours := settings.currency_counter.ninja_stale_hours

	; ══════════════════════════════════════════════════════════
	;  TABLE COLUMNS
	;
	;  The layout trick (directly from Maptracker_Logs):
	;
	;  Column 1:  hidden anchor  "Section xs  y+gap  w<width>"
	;             → ControlGetPos gives yEdit/hEdit for the whole table
	;             → all later search-row controls use "xs Section" or "ys"
	;             → header label uses "xs y+-1"
	;             → data rows use "xs" (return to this column's left edge)
	;
	;  Column N>1: hidden anchor  "ys Section  w<width>  h<hEdit>"
	;             → "ys" keeps same Y as col-1 anchor (one header row)
	;             → "Section" sets a new anchor for this column's xs
	;             → search spacer/edit uses "xs Section" (same left as anchor)
	;             → header label uses "xs y+-1"
	;             → data rows use "xs"
	; ══════════════════════════════════════════════════════════
	If ssf
		table := [ ["name", "left", [Lang_Trans("m_cc_col_currency"), "77777777777777777777777777777"]]
			, ["count", "right", [Lang_Trans("m_cc_col_count"), "777777"]] ]
	Else
		table := [ ["name", "left", [Lang_Trans("m_cc_col_currency"), "77777777777777777777777777777"]]
			, ["count", "right", [Lang_Trans("m_cc_col_count"), "777777"]]
			, ["price", "right", [Lang_Trans("m_cc_col_price"), "777777"]]
			, ["pc", "center", [Lang_Trans("m_cc_col_in"), "77777"]]
			, ["ts", "right", [Lang_Trans("m_cc_col_updated"), "7777777777"]]
			, ["total", "right", [Lang_Trans("m_cc_col_total"), "7777777777777"]] ]

	totalColumnsWidth := 0
	totalColWidth := 0
	For col_i, val in table
	{
		header := val.1
		LLK_PanelDimensions(val.3, fSize2, width, height,, 4)
		width := (width < hFont) ? hFont : width
		totalColumnsWidth += width
		If (val.1 = "total")
		{
			totalColWidth := width
		}
	}
	hEdit := hFont ; approximation, or compute exactly using LLK_PanelDimensions on a sample string
	totalWidth := totalColumnsWidth - 1

	; ── Gather entries (currencies with count > 0) ──────────

	entries := []
	kw := vars.cc_logs.keywords["name"]
	For name, entry in vars.currency_counter.currencies
	{
		If !IsObject(entry) || entry.count <= 0
			Continue
		If !Blank(kw) && !InStr(name, kw)
			Continue
		useNinja := (entry.price_updated = 0 || CurrencyCounter_PriceAgeHours(entry.price_updated) >= ninja_price_stale_hours)
		np := useNinja ? CurrencyCounter_NinjaPrice(name) : ""
		entries.Push({"name": name, "entry": entry
			, "eff_price": (np != "") ? np        : entry.price
			, "eff_cur":   (np != "") ? "chaos"   : entry.price_currency
			, "is_ninja":  (np != "")})
	}

	col := vars.cc_logs.sort_col
	asc := vars.cc_logs.sort_asc
	If (col != "")
	{
		Loop, % entries.Count() - 1
		{
			i := A_Index
			Loop, % entries.Count() - i
			{
				j := A_Index
				a := entries[j], b := entries[j+1]
				If (col = "count")
					swap := asc ? a.entry.count > b.entry.count : a.entry.count < b.entry.count
				Else If (col = "price")
				{
					chaosA := CurrencyCounter_ToChaos(a.eff_price, a.eff_cur)
					chaosB := CurrencyCounter_ToChaos(b.eff_price, b.eff_cur)
					swap := asc ? chaosA > chaosB : chaosA < chaosB
				}
				Else If (col = "name")
					swap := asc ? a.name > b.name : a.name < b.name
				Else If (col = "ts")
					swap := asc ? a.entry.price_updated < b.entry.price_updated : a.entry.price_updated > b.entry.price_updated
				Else If (col = "total")
				{
					chaosA := CurrencyCounter_ToChaos(a.eff_price, a.eff_cur) * a.entry.count
					chaosB := CurrencyCounter_ToChaos(b.eff_price, b.eff_cur) * b.entry.count
					swap := asc ? chaosA > chaosB : chaosA < chaosB
				}
				If swap
				{
					temp := entries[j]
					entries[j] := entries[j+1]
					entries[j+1] := temp
				}
			}
		}
	}

	toggle := !toggle, GUI_name := "cc_logs" toggle
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDcc_logs"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, -1, -1
	Gui, %GUI_name%: Font, % "s" fSize2 " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.cc_logs.main
	vars.hwnd.cc_logs := {"main": cc_logs, "toggle": toggle}
	vars.hwnd.cclogs := vars.hwnd.cc_logs ; alias for Gui_HelpToolTip prefix resolution

	; ══════════════════════════════════════════════════════════
	;  Drag box - dynamically adjusts to actual window width
	; ══════════════════════════════════════════════════════════
	border_compensation := (table.Count() - 1) * 1 ; each column adds ~2px border
	closeWidth := fWidth2 * 3
	dragWidth := totalWidth - closeWidth - border_compensation + 2

	Gui, %GUI_name%: Font, % "s" fSize2 - 3 " cWhite", % vars.system.font
	Gui, %GUI_name%: Add, Text, % "w" dragWidth " Border Center 0x200 BackgroundTrans gCurrencyCounter_Logs2 HWNDhwnd_drag", % Lang_Trans("m_cc_window_title")
	vars.hwnd.cc_logs.dragbar := hwnd_drag

	Gui, %GUI_name%: Add, Text, % "x" totalWidth - closeWidth - border_compensation " y-1 w" closeWidth " Border Center 0x200 gCurrencyCounter_Logs2 HWNDhwnd_close", % "x"
	vars.hwnd.cc_logs.close := hwnd_close

	; ══════════════════════════════════════════════════════════
	;  SESSION TABS
	; ══════════════════════════════════════════════════════════
	Gui, %GUI_name%: Font, % "s" fSize2 - 2, % vars.system.font
	Gui, %GUI_name%: Add, Text, x0 y+10 Section Hidden ; invisible anchor
	active_id := settings.currency_counter.active

	settings.currency_counter.spacing := settings.currency_counter.spacing > 0 ? settings.currency_counter.spacing : 10
	visibleCount := settings.currency_counter.visibleCount > 0 ? settings.currency_counter.visibleCount : (ssf ? 2 : 4)

	spacing := settings.currency_counter.spacing
	if(Blank(vars.currency_counter.carousel_index))
		vars.currency_counter.carousel_index := 0

		newSessionButtonWidth := hFont * 2
	itemWidth := (totalWidth - newSessionButtonWidth - (visibleCount + 2) * spacing) / visibleCount
	itemHeight := hFont

	; clamp scroll position (sessions deleted / visible count changed / new session added)
	maxIndex := Max(0, settings.currency_counter.sessions.Count() - visibleCount)
	vars.currency_counter.carousel_index := Max(0, Min(vars.currency_counter.carousel_index, maxIndex))
	carousel := vars.currency_counter.carousel_index

	For key, val in settings.currency_counter.sessions
	{
		If (A_Index <= carousel)
			Continue
		If (A_Index > carousel + visibleCount)
			Break

		slotNum := A_Index - carousel
		xPos := spacing + (slotNum - 1) * (itemWidth + spacing)
		yOpt := (slotNum = 1) ? "ys" : "yp"

		isActive := (key = settings.currency_counter.active)
		bgColor := isActive ? "White" : "1A1A1A"

		Gui, %GUI_name%: Font, % "s" fSize2 - 2 (isActive ? " cBlack" : " cWhite"), % vars.system.font
		Gui, %GUI_name%: Add, Text, % "x" xPos " " yOpt " w" itemWidth " h" itemHeight " Border Center 0x200 BackgroundTrans", % val.name
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background" bgColor " HWNDhwnd", 0
		vars.hwnd.cc_logs["tab_" key] := hwnd ; Progress hwnd, the hotkey's cMouse matches it
	}
	Gui, %GUI_name%: Font, % "s" fSize2 - 2 " cWhite", % vars.system.font

	Gui, %GUI_name%: Font, % "s" fSize2 * 3 " c41BB1C", % vars.system.font
	Gui, %GUI_name%: Add, Text, % "yp x" totalWidth - newSessionButtonWidth - spacing " w" newSessionButtonWidth - spacing " h" itemHeight " Border Center 0x200 gCurrencyCounter_Logs2 HWNDhwnd", % " + "
	Gui, %GUI_name%: Font, % "s" fSize2 " cWhite", % vars.system.font
	vars.hwnd.cc_logs.add_session := vars.hwnd.help_tooltips["cclogs_add session"] := hwnd

	; ══════════════════════════════════════════════════════════
	;  INFO BAR  - image | session label | name edit | delete | spacer | currency picker (right-aligned)
	; ══════════════════════════════════════════════════════════
	Gui, %GUI_name%: Font, % "s" fSize2 " cWhite", % vars.system.font

	; Hidden anchor to measure hEdit for the whole info bar row
	Gui, %GUI_name%: Add, Text, % "xs Section BackgroundTrans Hidden Border HWNDhwnd x-1 y+-1 w" fHeight2, % " "
	ControlGetPos,, yEdit,, hEdit,, % "ahk_id " hwnd

	; Hidden default button (keeps Enter key behaviour)
	Gui, %GUI_name%: Add, Button, % "xp yp wp hp Hidden Default gCurrencyCounter_Logs2 HWNDhwnd_defbtn", ok
	vars.hwnd.cc_logs.filter_button := hwnd_defbtn

	imgSize := fHeight2
	; ── "Session:" label (also larger, clearly visible) ───────
	labelWidth := fWidth2 * 8
	Gui, %GUI_name%: Add, Text, % "xs Section y+0 Border 0x200 Center BackgroundTrans cWhite w" labelWidth " h" imgSize, % Lang_Trans("m_cc_session_label")

	; ── Session image (larger) ─────────────────────────────────
	; Gui, %GUI_name%: Add, Text, % "ys yp Border 0x200 Center c404040 w" imgSize " h" imgSize, % "IMG"
	; Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0
	; vars.hwnd.cc_logs.session_img := hwnd

	; ── Name edit field ───────────────────────────────────────
	editWidth := fWidth2 * 16
	Gui, %GUI_name%: Add, Edit, % "ys yp cBlack gCurrencyCounter_Logs2 HWNDhwnd_name_edit w" editWidth " h" imgSize, % settings.currency_counter.sessions[active_id].name
	vars.hwnd.cc_logs.name_edit := hwnd_name_edit

	; ── Accept button (X) with progress bar ───────────────────
	accSize := imgSize
	Gui, %GUI_name%: Add, Text, % "ys yp Border 0x200 Center c41BB1C gCurrencyCounter_Logs2 HWNDhwnd w" accSize " h" accSize, % " + "
	vars.hwnd.help_tooltips["cclogs_accept btn"] := hwnd
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed HWNDhwnd range0-500", 0
	vars.hwnd.cc_logs.accept_btn := hwnd

	; ── Delete button (X) with progress bar ───────────────────
	delSize := accSize / 2
	Gui, %GUI_name%: Add, Text, % "x+" delSize /2 " ys+" delSize /2 "yp Border 0x200 Center cCC3333 gCurrencyCounter_Logs2 HWNDhwnd w" delSize " h" delSize, % "X"
	vars.hwnd.help_tooltips["cclogs_del btn"] := hwnd
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed HWNDhwnd range0-500", 0
	vars.hwnd.cc_logs.del_btn := hwnd

	pickerImgSize := imgSize * 1.5

	; ── Currency picker (only if not SSF) - placed at far right edge ──
	If !ssf
	{
		pickerWidth := totalColWidth
		pickerX := totalWidth - pickerWidth - table.Count() + 3
		halfH := imgSize
		colW := halfH
		midW := pickerWidth - colW * 2

		border := ""
		txt := ""
		; ── Ninja fetch button + age label (only if ninja prices enabled) ──
		If (settings.currency_counter.ninja_prices && settings.features.stash)
		{
			; Calculate oldest timestamp among all stash tabs
			oldest_ts := 0
			if IsObject(vars.stash) && IsObject(vars.stash.tabs)
			{
				For tab in vars.stash.tabs
					if IsObject(vars.stash[tab]) && vars.stash[tab].timestamp
					{
						ts := vars.stash[tab].timestamp
						if (oldest_ts = 0 || ts < oldest_ts)
							oldest_ts := ts
					}
			}

			; Format age string and determine colour
			if (oldest_ts = 0)
			{
				age_string := "--"
				age_color := "White"
			}
			else
			{
				hours := CurrencyCounter_PriceAgeHours(oldest_ts)
				if (hours >= 24)
					age_string := Floor(hours / 24) "d"
				else if (hours >= 1)
					age_string := Floor(hours) "h"
				else
				{
					minutes := Floor(hours * 60)
					age_string := (minutes >= 1) ? minutes "m" : "now"
				}
				; Colour: red if at warning threshold or older, otherwise lime
				age_color := (hours >= settings.currency_counter.price_warn_hours) ? "Red" : "Lime"
			}

			; Dimensions
			fetchBtnW := halfH * 2

			; Original position of the button (now used for the age label)
			labelX := pickerX - fetchBtnW - 1
			; New button position: one width to the left
			fetchX := labelX - fetchBtnW - 1

			; 1) Fetch button (moved left)
			Gui, %GUI_name%: Add, Text
				, % "x" fetchX " yp-" pickerImgSize - imgSize - 1
				. " 0x200 Border Center cFF8800 gCurrencyCounter_Logs2 HWNDhwnd"
				. " w" fetchBtnW " h" halfH
				, % "N"
			vars.hwnd.cc_logs.ninja_fetch_btn := vars.hwnd.help_tooltips["cclogs_ninja fetch"] := hwnd

			; 2) Age label (at original button position, with dynamic colour)
			Gui, %GUI_name%: Add, Text
				, % "x" labelX " yp 0x200 Border Center c" age_color " HWNDhwnd"
				. " w" fetchBtnW " h" halfH
				, % age_string
			vars.hwnd.help_tooltips["cclogs_ninja age"] := hwnd
		}

		; ── Row 1: chaos → divine ─────────────────────────────
		tsC := settings.currency_counter.chaos_div_updated
		colorC := " c" (settings.currency_counter.chaos_div_src = "ninja" ? "FF8800" : (Blank(tsC) ? "808080" : CurrencyCounter_RateColor(tsC)))

		Gui, %GUI_name%: Add, Text, % "x" pickerX " yp-" pickerImgSize - imgSize " Border 0x200 Center cC89B3C w" colW " h" halfH, % Lang_Trans("m_cc_abbr_chaos")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0
		Gui, %GUI_name%: Add, Text, % "ys yp Border 0x200 Center gCurrencyCounter_Logs2 HWNDhwnd" colorC " w" midW " h" halfH, % CurrencyCounter_DecimalToFraction(settings.currency_counter.chaos_div,1000)
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0
		vars.hwnd.cc_logs.ratio_chaos_btn := vars.hwnd.help_tooltips["cclogs_ratio chaos"] := hwnd
		Gui, %GUI_name%: Add, Text, % "ys yp Border 0x200 Center cC89B3C w" colW " h" halfH, % Lang_Trans("m_cc_abbr_divine")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0

		; ── Row 2: exalt → divine ─────────────────────────────
		tsE := settings.currency_counter.exalt_div_updated
		colorE := " c" (settings.currency_counter.exalt_div_src = "ninja" ? "FF8800" : (Blank(tsE) ? "808080" : CurrencyCounter_RateColor(tsE)))

		; Force new row by stepping down from picker start
		Gui, %GUI_name%: Add, Text, % "x" pickerX " y+-1 Border 0x200 Center cC89B3C w" colW " h" halfH, % Lang_Trans("m_cc_abbr_exalt")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled Background1A1A1A HWNDhwnd", 0
		Gui, %GUI_name%: Add, Text, % "x" pickerX + colW - 1 " yp Border 0x200 Center gCurrencyCounter_Logs2 HWNDhwnd" colorE " w" midW " h" halfH, % CurrencyCounter_DecimalToFraction(settings.currency_counter.exalt_div,1000)
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled Background1A1A1A HWNDhwnd", 0
		vars.hwnd.cc_logs.ratio_exalt_btn := vars.hwnd.help_tooltips["cclogs_ratio exalt"] := hwnd
		Gui, %GUI_name%: Add, Text, % "x" pickerX + colW + midW - 2 " yp Border 0x200 Center cC89B3C w" colW " h" halfH, % Lang_Trans("m_cc_abbr_divine")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled Background1A1A1A HWNDhwnd", 0

	}
	; ══════════════════════════════════════════════════════════
	;  TABLE  - search, headers, data rows
	; ══════════════════════════════════════════════════════════

	row_count := Min(entries.Count(), max_lines)

	For col_i, val in table
	{
		header := val.1
		LLK_PanelDimensions(val.3, fSize2, width, height,, 4)
		width := (width < hFont) ? hFont : width

		Gui, %GUI_name%: Font, % "s" fSize2

		; ── Search / spacer row (above header) ──────────────────
		; col 1:     "Search" + "X"  →  xs Section anchor
		; col total: "Total" label + icon placeholder (ys Section)
		; others:    blank spacer (ys Section)
		If (col_i = 1)
		{
			; Hidden dummy to measure hEdit for the whole table
			yOffset := ssf ? 0 : -(pickerImgSize - imgSize)
			Gui, %GUI_name%: Add, Text, % "Section xs BackgroundTrans Hidden Border HWNDhwnd x-1 y+" yOffset " w" width, % " "
			ControlGetPos,, yEdit,, hEdit,, % "ahk_id " hwnd

			; Search Edit (Section anchor for col 1) + add-currency + X reset flush right
			; Search Edit (Section anchor for col 1) + add-currency + X reset flush right
			Gui, %GUI_name%: Add, Edit, % "xs Section cBlack gCurrencyCounter_Logs2 HWNDhwnd_search w" width - hEdit * 2 " h" hEdit ( (pCheck := vars.cc_logs.keywords["name"]) != "" ? " cGreen" : "" ), % (pCheck != "" ? pCheck : vars.currency_counter.name)
			vars.hwnd.cc_logs.search_name := hwnd_search
			Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans Center gCurrencyCounter_Logs2 HWNDhwnd c41BB1C 0x200 x+0 w" hEdit " h" hEdit, % "+"
			vars.hwnd.cc_logs.add_currency_btn := vars.hwnd.help_tooltips["cclogs_add currency"] := hwnd
			Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans Center gCurrencyCounter_Logs2 HWNDhwnd cRed 0x200 x+0 w" hEdit " h" hEdit, % "X"
			vars.hwnd.cc_logs.filter_reset := vars.hwnd.help_tooltips["cclogs_filter reset"] := hwnd
		}
		Else If (header = "total")
		{
			; "Total" label in the spacer row - IS the Section anchor (ys Section).
			; Width covers just the value column; icon is placed separately after.
			Gui, %GUI_name%: Add, Text, % "ys Section BackgroundTrans Border w" width " h" hEdit " Center cWhite HWNDhwnd gCurrencyCounter_Logs2", % Lang_Trans("m_cc_col_total") " "
			vars.hwnd.cc_logs.total_label := hwnd
		}
		Else
		{
			; Blank spacer IS the Section anchor for this column
			Gui, %GUI_name%: Add, Text, % "ys Section BackgroundTrans Border w" width " h" hEdit, % " "
		}

		; ── Header label: xs y+-1 snaps to column anchor ────────
		; For "total": show computed value instead of column name.
		Gui, %GUI_name%: Font, % "s" fSize2 + 4
		If (header = "total")
		{
			Gui, %GUI_name%: Add, Text, % "xs y+-1 BackgroundTrans Border Center HWNDhwnd cC89B3C w" width, % CurrencyCounter_ComputeTotal(entries)
			vars.hwnd.cc_logs.total_value := hwnd
			Gui, %GUI_name%: Add, Text, % "xs y+-1 BackgroundTrans Hidden HWNDhwnd w1 h1", % ""
		}
		Else
		{
			Gui, %GUI_name%: Font, % "s" fSize2 - 2
			Gui, %GUI_name%: Add, Text, % "xs y+-1 BackgroundTrans Hidden HWNDhwnd w" width, % val.3.1
			ControlGetPos,,, , textH,, % "ahk_id " hwnd
			offset := Floor((fHeight3 - textH) / 2)
			Gui, %GUI_name%: Add, Text, % "xp yp Border BackgroundTrans HWNDhwnd_border wp h" fHeight3, % ""
			Gui, %GUI_name%: Add, Text, % "xp yp+" offset " BackgroundTrans Center 0x200 HWNDhwnd_col w" width, % val.3.1
			Gui, %GUI_name%: Add, Progress, % "xp yp-" offset " wp h" fHeight3 " Disabled BackgroundBlack HWNDhwnd", 0
			Gui, %GUI_name%: Font, % "s" fSize2 + 4
		}
		vars.hwnd.cc_logs["col_" header] := hwnd_col

		; ── Data rows ────────────────────────────────────────
		Gui, %GUI_name%: Font, % "s" fSize2
		Loop, % row_count
		{
			ri := A_Index
			item := entries[ri]
			name := item.name
			entry := item.entry
			isNinja := item.is_ninja
			effPrice := item.eff_price
			effCur := item.eff_cur
			bg := Mod(ri, 2) ? "131313" : "1A1A1A"

			If (header = "name")
				cell_text := " " name, color := "", gLabel := " gCurrencyCounter_Logs2"
			Else If (header = "count")
				cell_text := entry.count " ", color := "", gLabel := " gCurrencyCounter_Logs2"
			Else If (header = "price")
			{
				If isNinja
					cell_text := CurrencyCounter_FormatPrice(effPrice) " ", color := " cFF8800", gLabel := " gCurrencyCounter_Logs2"
				Else
					cell_text := (entry.price > 0) ? CurrencyCounter_FormatPrice(entry.price) " " : "- ", color := " c" CurrencyCounter_PriceColor(entry.price_updated), gLabel := " gCurrencyCounter_Logs2"
			}
			Else If (header = "pc")
				cell_text := " " (isNinja ? Lang_Trans("m_cc_abbr_chaos") : (entry.price > 0 ? CurrencyCounter_CurAbbr(entry.price_currency) : "-")) " ", color := " c808080", gLabel := " gCurrencyCounter_Logs2"
			Else If (header = "ts")
				cell_text := CurrencyCounter_FormatAge(entry.price_updated) " ", color := " c" CurrencyCounter_PriceColor(entry.price_updated), gLabel := " gCurrencyCounter_Logs2"
			Else If (header = "total")
			{
				If (effPrice > 0 && entry.count > 0)
				{
					chaos := CurrencyCounter_ToChaos(effPrice, effCur) * entry.count
					cell_text := Round(CurrencyCounter_FromChaos(chaos, settings.currency_counter.display_cur), 1) " " CurrencyCounter_CurAbbr(settings.currency_counter.display_cur) " "
					color := isNinja ? " cA35200" : (CurrencyCounter_PriceAgeHours(entry.price_updated) >= settings.currency_counter.price_warn_hours ? " cFF3333" : " cFFA500"), gLabel := ""
				}
				Else
				{
					cell_text := "- "
					color := " c808080", gLabel := ""
				}
			}

			Gui, %GUI_name%: Add, Text, % "xs Border 0x200 BackgroundTrans " val.2 " w" width . gLabel . color " h" hFont, % cell_text
			Gui, %GUI_name%: Add, Progress, % "xp yp w" width " hp Border Disabled Background" bg " HWNDhwnd0 ", 0
			vars.hwnd.cc_logs[header "_" name] := hwnd0
		}

		; Empty-state row (first column only)
		If (col_i = 1) && !entries.Count()
		{
			Gui, %GUI_name%: Font, % "s" fSize2 " c404040", % vars.system.font
			Gui, %GUI_name%: Add, Text, % "xs y+0 BackgroundTrans w" width " h" hFont " 0x200", % " No currencies used in this session."
		}
	}

	; ── Position & show ──────────────────────────────────────
	showPos := (vars.cc_logs.x != "") ? "x" vars.cc_logs.x " y" vars.cc_logs.y : "xCenter yCenter"
	Gui, %GUI_name%: Show, % showPos " AutoSize", % Lang_Trans("m_cc_window_bar")
	; Redirect focus to a non-interactive control so the name Edit
	; doesn't steal keyboard input on every redraw.
	ControlFocus,, % "ahk_id " vars.hwnd.cc_logs.dragbar
	LLK_Overlay(cc_logs, "show", 0, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

; ──────────────────────────────────────────────────────────────
;  CurrencyCounter_Logs2(cHWND)  -  unified click handler
; ──────────────────────────────────────────────────────────────
CurrencyCounter_Logs2(cHWND)
{
	local
	global vars, settings, Currency_Counter_instance

	; ── Edit field notifications ──────────────────────────────
	If (cHWND = vars.hwnd.cc_logs.name_edit)
	{
		input := LLK_ControlGet(cHWND)
		id := settings.currency_counter.active
		If !IsObject(settings.currency_counter.sessions[id])
			settings.currency_counter.sessions[id] := {img: "", name: input}
		Else
			settings.currency_counter.sessions[id].name := input
		vars.currency_counter.session_name := input
		CurrencyCounter_SaveIndex()
		Return
	}

	If (cHWND = vars.hwnd.cc_logs.search_name)
	{
		input := LLK_ControlGet(cHWND)
		vars.cc_logs.keywords["name"] := input
		GuiControl, % "+cBlack", % cHWND
		GuiControl, movedraw, % cHWND
		Return
	}

	; ── Named control dispatch ────────────────────────────────
	check := LLK_HasVal(vars.hwnd.cc_logs, cHWND)

	Switch check
	{
	Case "close":
		KeyWait, LButton
		KeyWait, RButton
		LLK_Overlay(vars.hwnd.cc_logs.main, "destroy")
		vars.hwnd.cc_logs := {"main": ""}
		Return

	Case "add_currency_btn":
		KeyWait, LButton
		static add_cur_confirm := 0, add_cur_confirm_ts := 0
		GuiControlGet, label,, % vars.hwnd.cc_logs.search_name
		label := Format("{:U}", Trim(label))
		If (label == "")
			Return
		If add_cur_confirm && (A_TickCount - add_cur_confirm_ts > 3000)
			add_cur_confirm := 0
		If !add_cur_confirm
		{
			add_cur_confirm := 1, add_cur_confirm_ts := A_TickCount
			LLK_ToolTip(Lang_Trans("m_cc_confirm_add_pre") " """ label """ " Lang_Trans("m_cc_confirm_add_post"), 3,,,, "Yellow")
			Return
		}
		add_cur_confirm := 0, add_cur_confirm_ts := 0
		If !IsObject(vars.currency_counter.currencies[label])
		{
			vars.currency_counter.currencies[label] := {"count": 1, "price": 0.0, "price_currency": CurrencyCounter_DefaultCurrency(), "price_updated": 0}
			CurrencyCounter_SaveCurrency(label)
		}
		Else If (vars.currency_counter.currencies[label].count = 0)
		{
			vars.currency_counter.currencies[label].count := 1
			CurrencyCounter_SaveCurrency(label)
		}
		CurrencyCounter_Logs()
		Return

	Case "filter_reset":
		KeyWait, LButton
		KeyWait, RButton
		vars.cc_logs.keywords := {}
		If vars.hwnd.cc_logs.search_price
			GuiControl,, % vars.hwnd.cc_logs.search_price, % ""
		CurrencyCounter_Logs()
		Return

	Case "dragbar":
		While GetKeyState("LButton", "P") ;dragging the window
		{
			WinGetPos, xWin, yWin, wWin, hWin, % "ahk_id " vars.hwnd.cc_logs.main
			MouseGetPos, xMouse, yMouse
			While GetKeyState("LButton", "P")
			{
				LLK_Drag(wWin, hWin, xPos, yPos, 1,vars.hwnd.cc_logs.main,, xMouse - xWin, yMouse - yWin)
				sleep 1
			}
			KeyWait, LButton
			WinGetPos, xPos, yPos, w, h, % "ahk_id " vars.hwnd.cc_logs.main
			vars.cc_logs.x := xPos, vars.cc_logs.y := yPos, vars.general.drag := 0
			IniWrite, % xPos, % Currency_Counter_instance.config_path, settings, logs-x
			IniWrite, % yPos, % Currency_Counter_instance.config_path, settings, logs-y
			Return
		}
		Return

	Case "filter_button":
		CurrencyCounter_Logs()
		Return

	Case "total_value":
		KeyWait, LButton
		order := ["chaos", "divine", "exalt"]
		cur := settings.currency_counter.display_cur
		next := order[2] ; default if cur not found
		Loop, % order.Count()
			If (order[A_Index] = cur)
			{
				next := order[Mod(A_Index, order.Count()) + 1]
				Break
			}
		settings.currency_counter.display_cur := next
		IniWrite, % next, % Currency_Counter_instance.config_path, settings, display-currency
		CurrencyCounter_Logs()
		Return

	Case "session_img":
		KeyWait, LButton
		; TODO: image picker
		Return

	Case "ninja_fetch_btn":
		KeyWait, LButton
		If !(settings.currency_counter.ninja_prices && settings.features.stash)
			Return
		For tab in vars.stash.tabs
		{
			LLK_ToolTip(tab,2)
			Stash_PriceFetch(tab)

		}
		CurrencyCounter_Logs()
		Return

	Case "ratio_chaos_btn":
		KeyWait, LButton
		CurrencyCounter_RatioEdit(cHWND, "chaos")
		Return

	Case "ratio_exalt_btn":
		KeyWait, LButton
		CurrencyCounter_RatioEdit(cHWND, "exalt")
		Return

	Case "add_session":
		KeyWait, LButton
		CurrencyCounter_NewSession()
		vars.currency_counter.carousel_index := 99999 ; clamped to the last page in Logs()
		CurrencyCounter_Logs()
		Return

	Case "accept_btn":
		KeyWait, LButton
		GuiControlGet, newName,, % vars.hwnd.cc_logs.name_edit
		newName := Trim(newName)
		If !Blank(newName)
		{
			settings.currency_counter.sessions[settings.currency_counter.active].name := newName
			CurrencyCounter_SaveIndex()
		}
		; Unfocus the edit by stealing focus to a non-interactive control
		ControlFocus,, % "ahk_id " vars.hwnd.cc_logs.dragbar
		CurrencyCounter_Logs()
		Return

	Case "del_btn":
		KeyWait, LButton
		static del_confirm := 0, del_confirm_ts := 0
		If settings.currency_counter.sessions.Count() <= 1
		{
			LLK_ToolTip(Lang_Trans("m_cc_error_last_session"), 2,,,, "Red")
			del_confirm := 0, del_confirm_ts := 0
			Return
		}
		If del_confirm && (A_TickCount - del_confirm_ts > 3000)
			del_confirm := 0
		If !del_confirm
		{
			del_confirm := 1, del_confirm_ts := A_TickCount
			LLK_ToolTip(Lang_Trans("m_cc_confirm_delete"), 3,,,, "Yellow")
			Return
		}
		del_confirm := 0, del_confirm_ts := 0
		active := settings.currency_counter.active
		; Find next session, fall back to previous
		next_id := "", prev_id := "", found := 0
		For key in settings.currency_counter.sessions
		{
			If found && next_id = ""
				next_id := key
			If (key = active)
				found := 1
			If !found
				prev_id := key
		}
		fallback := next_id != "" ? next_id : prev_id
		CurrencyCounter_DeleteSession(active)
		If !Blank(fallback)
			CurrencyCounter_SetActive(fallback)
		CurrencyCounter_Logs()
		Return
	}

	; ── Session tab click ─────────────────────────────────────
	If InStr(check, "tab_")
	{
		id := SubStr(check, 5)
		KeyWait, LButton
		If (id != settings.currency_counter.active)
		{
			CurrencyCounter_SetActive(id)
			CurrencyCounter_Logs()
		}
		Return
	}

	; ── Price cell click - inline edit overlay ────────────────
	If InStr(check, "price_")
	{
		currency_name := SubStr(check, 7)
		If (vars.system.click = 1)
			CurrencyCounter_PriceEdit(cHWND, currency_name)
		Return
	}

	; ── Count cell click - inline edit overlay ────────────────
	If InStr(check, "count_")
	{
		currency_name := SubStr(check, 7)
		If (vars.system.click = 1)
			CurrencyCounter_CountEdit(cHWND, currency_name)
		Return
	}

	If InStr(check, "pc_")
	{
		name := SubStr(check, 4)
		order := ["chaos", "divine", "exalt"]
		cur := vars.currency_counter.currencies[name].price_currency
		next := order[1]
		Loop, % order.Count()
			If (order[A_Index] = cur)
			{
				next := order[Mod(A_Index, order.Count()) + 1]
				Break
			}
		vars.currency_counter.currencies[name].price_currency := next
		CurrencyCounter_SaveCurrency(name)
		CurrencyCounter_Logs()
		Return
	}

	If InStr(check, "col_")
	{
		col := SubStr(check, 5)
		If (vars.cc_logs.sort_col = col)
			vars.cc_logs.sort_asc := !vars.cc_logs.sort_asc
		Else
		{
			vars.cc_logs.sort_col := col
			vars.cc_logs.sort_asc := 0
		}
		CurrencyCounter_Logs()
		Return
	}

	if(vars.hwnd.cc_logs.total_label = cHWND)
	{
		col := "total"
		If (vars.cc_logs.sort_col = col)
			vars.cc_logs.sort_asc := !vars.cc_logs.sort_asc
		Else
		{
			vars.cc_logs.sort_col := col
			vars.cc_logs.sort_asc := 0
		}
		CurrencyCounter_Logs()
		Return
	}

}

; ──────────────────────────────────────────────────────────────
;  CurrencyCounter_CurPicker  -  3-icon currency selector
;  Appears at the icon position, one row above the table.
;  Clicking any option sets display_cur and closes itself.
;  Wire: already handled via "display_cur_icon" in Logs2.
; ──────────────────────────────────────────────────────────────
CurrencyCounter_CurPicker(cHWND)
{
	local
	global vars, settings
	static toggle := 0

	; Options: id, label shown in picker
	options := [["chaos", "c"], ["divine", "d"], ["exalt", "e"]]

	fSize2 := settings.currency_counter.fSize2
	LLK_FontDimensions(fSize2, fHeight2, fWidth2)
	hFont := fHeight2 * 1.5

	; Get icon position in client-area coords, then add parent GUI screen pos
	ControlGetPos, cx, cy, cw,, % "ahk_id " cHWND
	WinGetPos, gx, gy,,, % "ahk_id " vars.hwnd.cc_logs.main
	px := gx + cx + cw // 2 ; horizontal centre of icon (for centring the picker over it)
	py := gy + cy ; top edge of icon in screen coords

	toggle := !toggle, pName := "cc_cur_picker" toggle
	Gui, %pName%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwnd_picker"
	Gui, %pName%: Color, Black
	Gui, %pName%: Margin, -1, -1
	Gui, %pName%: Font, % "s" fSize2 + 4 " cWhite", % vars.system.font
	vars.hwnd.cc_cur_picker := {"main": hwnd_picker}

	; 3 icon cells side by side, same size as the icon (hFont*2 square)
	icon_side := hFont * 2
	For i, opt in options
	{
		id := opt.1
		label := opt.2
		color := (id = settings.currency_counter.display_cur) ? " cLime" : " cC89B3C"
		pos := (i = 1) ? "Section xs" : "ys"

		; Pic when assets exist; Text placeholder for now
		; Swap this line for: Gui, %pName%: Add, Pic, ...
		Gui, %pName%: Add, Text, % pos " Border BackgroundTrans Center gCurrencyCounter_CurPickerClick HWNDhwnd 0x200" color " w" icon_side " h" icon_side, % label
		vars.hwnd.cc_cur_picker["opt_" id] := hwnd
		Gui, %pName%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0
	}

	; Show flush with the top of the icon, horizontally centred on it
	Gui, %pName%: Show, % "NA x10000 y10000"
	WinGetPos,,, pw,, % "ahk_id " hwnd_picker
	; Centre picker horizontally on the icon, place just above it.
	; Subtract 1 to compensate for the -1 GUI margin (border sits outside client area).
	Gui, %pName%: Show, % "NA x" px - pw // 2 " y" py - icon_side - 1
	LLK_Overlay(hwnd_picker, "show", 0, pName)
}

CurrencyCounter_CurPickerClick()
{
	local
	global vars, settings, Currency_Counter_instance

	cHWND := A_GuiControl ; hwnd of the clicked Text control
	check := LLK_HasVal(vars.hwnd.cc_cur_picker, cHWND)
	If !InStr(check, "opt_")
		Return
	KeyWait, LButton
	chosen := SubStr(check, 5) ; strip "opt_"
	settings.currency_counter.display_cur := chosen
	IniWrite, % chosen, % Currency_Counter_instance.config_path, settings, display-currency
	LLK_Overlay(vars.hwnd.cc_cur_picker.main, "destroy")
	vars.hwnd.cc_cur_picker := {"main": ""}
	CurrencyCounter_Logs()
	Return
}

; ──────────────────────────────────────────────────────────────
;  CurrencyCounter_PriceEdit  -  tiny overlay Edit on the cell
; ──────────────────────────────────────────────────────────────
CurrencyCounter_PriceEdit(cHWND, currency_name)
{
	local
	global vars, settings
	static toggle := 0

	KeyWait, LButton
	entry := vars.currency_counter.currencies[currency_name]
	If !IsObject(entry)
		Return

	WinGetPos, xCtrl, yCtrl, wCtrl, hCtrl, % "ahk_id " cHWND

	toggle := !toggle, eName := "cc_price_edit" toggle
	Gui, %eName%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_edit"
	Gui, %eName%: Color, 101010
	Gui, %eName%: Margin, 1, 1
	Gui, %eName%: Font, % "s" settings.currency_counter.fSize2 " cBlack", % vars.system.font

	; Determine initial display value
	initialText := ""
	If (entry.price > 0 && IsNumber(entry.price))
		initialText := CurrencyCounter_DecimalToFraction(entry.price + 0)
	Else
	{
		np := CurrencyCounter_NinjaPrice(currency_name)
		If (np != "")
			initialText := CurrencyCounter_DecimalToFraction(np + 0)
	}

	Gui, %eName%: Add, Edit, % "w" wCtrl - 2 " h" hCtrl - 2 " Background202020 HWNDhwnd_input", % initialText
	Gui, %eName%: Add, Button, % "Default Hidden gCurrencyCounter_PriceEditSave HWNDhwnd_ok", ok
	vars.hwnd.cc_price_edit := {"main": hwnd_edit, "input": hwnd_input, "name": currency_name}
	Gui, %eName%: Show, % "NA x" xCtrl " y" yCtrl
	ControlFocus,, % "ahk_id " hwnd_input
	; Select all text for easy replacement
	ControlSend,, ^{a}, % "ahk_id " hwnd_input

	While WinActive("ahk_id " hwnd_edit)
		Sleep, 10

	CurrencyCounter_PriceEditCommit()
	Gui, %eName%: Destroy
}

CurrencyCounter_PriceEditSave:
	CurrencyCounter_PriceEditCommit()
	Gui, cc_price_edit1: Destroy
	Gui, cc_price_edit2: Destroy
Return

CurrencyCounter_PriceEditCommit()
{
	local
	global vars, settings

	hwnd := vars.hwnd.cc_price_edit.input
	cname := vars.hwnd.cc_price_edit.name
	If !hwnd || !cname
		Return
	raw := StrReplace(LLK_ControlGet(hwnd), ",", ".")
	raw := Trim(raw)

	; Check for fraction format "XX/YY"
	If InStr(raw, "/")
	{
		; Split numerator and denominator
		parts := StrSplit(raw, "/")
		If (parts.Length() = 2)
		{
			num := Trim(parts[1])
			den := Trim(parts[2])
			; Both must be numbers and denominator > 0
			If IsNumber(num) && IsNumber(den) && (den + 0 > 0)
			{
				price := (num + 0) / (den + 0)
				If (price >= 0)
				{
					vars.currency_counter.currencies[cname].price := price
					vars.currency_counter.currencies[cname].price_updated := A_NowUTC
					CurrencyCounter_SaveCurrency(cname)
				}
			}
		}
	}
	Else ; Decimal format
	{
		If IsNumber(raw) && (raw + 0 >= 0)
		{
			vars.currency_counter.currencies[cname].price := raw + 0
			vars.currency_counter.currencies[cname].price_updated := A_NowUTC
			CurrencyCounter_SaveCurrency(cname)
		}
	}

	vars.hwnd.cc_price_edit := {"main": "", "input": "", "name": ""}
	CurrencyCounter_DrawBar()
	CurrencyCounter_Logs()
}

; ──────────────────────────────────────────────────────────────
;  CurrencyCounter_CountEdit  -  tiny overlay Edit on count cell
; ──────────────────────────────────────────────────────────────
CurrencyCounter_CountEdit(cHWND, currency_name)
{
	local
	global vars, settings
	static toggle := 0

	KeyWait, LButton
	entry := vars.currency_counter.currencies[currency_name]
	If !IsObject(entry)
		Return

	WinGetPos, xCtrl, yCtrl, wCtrl, hCtrl, % "ahk_id " cHWND

	toggle := !toggle, eName := "cc_count_edit" toggle
	Gui, %eName%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_edit"
	Gui, %eName%: Color, 101010
	Gui, %eName%: Margin, 1, 1
	Gui, %eName%: Font, % "s" settings.currency_counter.fSize2 " cBlack", % vars.system.font

	Gui, %eName%: Add, Edit, % "w" wCtrl - 2 " h" hCtrl - 2 " Background202020 Number HWNDhwnd_input", % entry.count
	Gui, %eName%: Add, Button, % "Default Hidden gCurrencyCounter_CountEditSave HWNDhwnd_ok", ok
	vars.hwnd.cc_count_edit := {"main": hwnd_edit, "input": hwnd_input, "name": currency_name}
	Gui, %eName%: Show, % "NA x" xCtrl " y" yCtrl
	ControlFocus,, % "ahk_id " hwnd_input
	ControlSend,, ^{a}, % "ahk_id " hwnd_input

	While WinActive("ahk_id " hwnd_edit)
		Sleep, 10

	CurrencyCounter_CountEditCommit()
	Gui, %eName%: Destroy
}

CurrencyCounter_CountEditSave:
	CurrencyCounter_CountEditCommit()
	Gui, cc_count_edit1: Destroy
	Gui, cc_count_edit2: Destroy
Return

CurrencyCounter_CountEditCommit()
{
	local
	global vars, settings

	hwnd  := vars.hwnd.cc_count_edit.input
	cname := vars.hwnd.cc_count_edit.name
	If !hwnd || !cname
		Return
	raw := Trim(LLK_ControlGet(hwnd))
	; Strip anything that isn't a digit (Number style already blocks most)
	raw := RegExReplace(raw, "[^\d]", "")
	If raw != "" && IsNumber(raw)
	{
		vars.currency_counter.currencies[cname].count := raw + 0
		CurrencyCounter_SaveCurrency(cname)
	}
	vars.hwnd.cc_count_edit := {"main": "", "input": "", "name": ""}
	CurrencyCounter_DrawBar()
	CurrencyCounter_Logs()
}

; Convert decimal to closest fraction XX/YY with denominator up to maxDenom (default 100)
CurrencyCounter_DecimalToFraction(decimal, maxDenom := 100)
{
	if (decimal = 0)
		return "0/1"
	bestNum := 0, bestDenom := 1, bestError := Abs(decimal)
	Loop % maxDenom
	{
		denom := A_Index
		num := Round(decimal * denom)
		error := Abs(decimal - num/denom)
		if (error < bestError)
		{
			bestError := error
			bestNum := num
			bestDenom := denom
		}
	}
	; Simplify by GCD
	g := CurrencyCounter_GCD(bestNum, bestDenom)
	bestNum //= g
	bestDenom //= g
	return bestDenom "/" bestNum
}

CurrencyCounter_GCD(a, b)
{
	while b
		t := b, b := Mod(a, b), a := t
	return Abs(a)
}

; ──────────────────────────────────────────────────────────────
;  Helpers
; ──────────────────────────────────────────────────────────────
CurrencyCounter_PriceAgeHours(ts)
{
	local
	If !ts || !IsNumber(ts)
		Return 0
	diff := A_NowUTC
	EnvSub, diff, % ts, minutes
	Return diff / 60
}

; ──────────────────────────────────────────────────────────────
;  CurrencyCounter_NinjaPrice  -  look up chaos price from stash-ninja
;  Returns "" if not available or feature not enabled.
; ──────────────────────────────────────────────────────────────
CurrencyCounter_NinjaPrice(name, ByRef ts := "")
{
	local
	global vars, settings

	If !(settings.currency_counter.ninja_prices && settings.features.stash && IsObject(vars.stash))
		Return ""
	StringLower, needle, name ; stash-ninja keys are lowercase
	For tab in vars.stash.tabs
	{
		If !IsObject(vars.stash[tab])
			Continue
		If IsObject(vars.stash[tab][needle]) && IsObject(vars.stash[tab][needle].prices)
		{
			price := vars.stash[tab][needle].prices.1 ; slot 1 is always chaos
			ts := vars.stash[tab].timestamp
			Return IsNumber(price) && price > 0 ? price : ""
		}
	}
	Return ""
}

; Fills chaos/div and exalt/div from poe.ninja when the manual rate is missing or stale.
; chaos_div = divines per chaos, exalt_div = divines per exalt (same units as the manual entry).
CurrencyCounter_SyncRates()
{
	local
	global vars, settings, Currency_Counter_instance

	cc := settings.currency_counter
	If (vars.poe_version != "") || !(cc.ninja_prices && settings.features.stash)
		Return
	divPrice := CurrencyCounter_NinjaPrice("DIVINE ORB", tsDiv) ; chaos per divine
	If (divPrice = "")
		Return
	exPrice := CurrencyCounter_NinjaPrice("EXALTED ORB", tsEx) ; chaos per exalt
	cfg := Currency_Counter_instance.config_path, changed := 0

	; ── chaos -> divine ──
	ts := cc.chaos_div_updated
	If (cc.chaos_div_src = "ninja") || !ts || CurrencyCounter_PriceAgeHours(ts) >= cc.rate_stale_hours
	{
		newVal := 1 / divPrice
		newTs := tsDiv ? tsDiv : (cc.chaos_div_src = "ninja" && ts ? ts : A_NowUTC)
		If (cc.chaos_div_src != "ninja") || (Abs(newVal - cc.chaos_div) > 0.0000001) || (cc.chaos_div_updated != newTs)
		{
			cc.chaos_div := newVal, cc.chaos_div_updated := newTs, cc.chaos_div_src := "ninja", changed := 1
			IniWrite, % newVal, % cfg, settings, chaos-div
			IniWrite, % newTs, % cfg, settings, chaos-div-updated
			IniWrite, ninja, % cfg, settings, chaos-div-src
		}
	}

	; ── exalt -> divine ──
	If (exPrice != "")
	{
		ts := cc.exalt_div_updated
		If (cc.exalt_div_src = "ninja") || !ts || CurrencyCounter_PriceAgeHours(ts) >= cc.rate_stale_hours
		{
			newVal := exPrice / divPrice
			newTs := tsEx ? tsEx : (cc.exalt_div_src = "ninja" && ts ? ts : A_NowUTC)
			If (cc.exalt_div_src != "ninja") || (Abs(newVal - cc.exalt_div) > 0.0000001) || (cc.exalt_div_updated != newTs)
			{
				cc.exalt_div := newVal, cc.exalt_div_updated := newTs, cc.exalt_div_src := "ninja", changed := 1
				IniWrite, % newVal, % cfg, settings, exalt-div
				IniWrite, % newTs, % cfg, settings, exalt-div-updated
				IniWrite, ninja, % cfg, settings, exalt-div-src
			}
		}
	}

	If changed
		CurrencyCounter_UpdateExaltRate()
}

CurrencyCounter_PriceColor(ts)
{
	local
	global settings
	h := CurrencyCounter_PriceAgeHours(ts)
	warn  := settings.currency_counter.price_warn_hours
	stale := settings.currency_counter.price_stale_hours
	If (h >= stale)
		Return "CC3333"
	If (h >= warn)
		Return Format("{:02X}{:02X}00", Round(180 + 75 * (h-warn)/(stale-warn)), Round(170 * (1-(h-warn)/(stale-warn))))
	Return "4A9E4A"
}

CurrencyCounter_RateColor(ts)
{
	local
	global settings
	h := CurrencyCounter_PriceAgeHours(ts)
	warn  := settings.currency_counter.rate_warn_hours
	stale := settings.currency_counter.rate_stale_hours
	If (h >= stale)
		Return "CC3333"
	If (h >= warn)
		Return Format("{:02X}{:02X}00", Round(180 + 75 * (h-warn)/(stale-warn)), Round(170 * (1-(h-warn)/(stale-warn))))
	Return "4A9E4A"
}

CurrencyCounter_FormatAge(ts)
{
	local
	If !ts || !IsNumber(ts)
		Return "-"
	h := CurrencyCounter_PriceAgeHours(ts)
	If (h > 24)
		Return Floor(h / 24) "d"
	If (h >= 1)
		Return Floor(h) "h " Floor((h - Floor(h)) * 60) "m"
	Return Floor(h * 60) "m"
}

CurrencyCounter_CurAbbr(id)
{
	Return (id = "divine") ? Lang_Trans("m_cc_abbr_divine") : (id = "exalt") ? Lang_Trans("m_cc_abbr_exalt") : Lang_Trans("m_cc_abbr_chaos")
}

CurrencyCounter_ToChaos(price, price_currency)
{
	local
	global vars, settings
	If (price_currency = "chaos")
		Return price
	If (price_currency = "divine")
		Return (settings.currency_counter.chaos_div > 0) ? price / settings.currency_counter.chaos_div : 0
	If (price_currency = "exalt")
		Return (vars.currency_counter.exalt_chaos_rate > 0) ? price * vars.currency_counter.exalt_chaos_rate : 0
	Return price
}

CurrencyCounter_FromChaos(chaos, target)
{
	local
	global vars, settings
	If (target = "chaos")
		Return chaos
	If (target = "divine")
		Return chaos * settings.currency_counter.chaos_div
	If (target = "exalt")
		Return (vars.currency_counter.exalt_chaos_rate > 0) ? chaos / vars.currency_counter.exalt_chaos_rate : 0
	Return chaos
}

CurrencyCounter_ComputeTotal(entries)
{
	local
	global vars, settings
	chaos := 0
	For i, item in entries
		If item.eff_price > 0
			chaos += CurrencyCounter_ToChaos(item.eff_price, item.eff_cur) * item.entry.count
	Return Round(CurrencyCounter_FromChaos(chaos, settings.currency_counter.display_cur), 1) " " CurrencyCounter_CurAbbr(settings.currency_counter.display_cur)
}

CurrencyCounter_ShiftCarousel(direction)
{
	local
	global vars, settings

	; only act when the mouse is over a session tab
	check := LLK_HasVal(vars.hwnd.cc_logs, vars.general.cMouse)
	If !InStr(check, "tab_")
		Return

	visibleCount := settings.currency_counter.visibleCount > 0 ? settings.currency_counter.visibleCount : (settings.currency_counter.ssf ? 2 : 4)
	maxIndex := Max(0, settings.currency_counter.sessions.Count() - visibleCount)
	idx := Max(0, Min(vars.currency_counter.carousel_index + (direction = "up" ? -1 : 1), maxIndex))
	If (idx = vars.currency_counter.carousel_index)
		Return ; already at the edge, skip the redraw

	vars.currency_counter.carousel_index := idx
	CurrencyCounter_Logs()
}

; Format a number to show at most 4 decimal places, removing trailing zeros
CurrencyCounter_FormatPrice(price)
{
	if (price = "")
		return ""
	; Round to 4 decimal places
	rounded := Round(price, 4)
	; Convert to string and trim trailing zeros and decimal point if needed
	str := rounded + 0.0 ; force numeric then string conversion
	; Remove trailing zeros after decimal
	if InStr(str, ".")
	{
		while SubStr(str, 0) = "0"
			str := SubStr(str, 1, -1)
		if SubStr(str, 0) = "."
			str := SubStr(str, 1, -1)
	}
	return str
}

CurrencyCounter_SortCount(asc, a, b)
{
	Return asc ? (a.entry.count - b.entry.count) : (b.entry.count - a.entry.count)
}

CurrencyCounter_RatioEdit(cHWND, which)
{
	local
	global vars, settings
	static toggle := 0

	KeyWait, LButton
	WinGetPos, xCtrl, yCtrl, wCtrl, hCtrl, % "ahk_id " cHWND

	toggle := !toggle, eName := "cc_ratio_edit" toggle
	Gui, %eName%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_edit"
	Gui, %eName%: Color, 101010
	Gui, %eName%: Margin, 1, 1
	Gui, %eName%: Font, % "s" settings.currency_counter.fSize2 " cBlack", % vars.system.font

	storedVal := (which = "chaos") ? settings.currency_counter.chaos_div : settings.currency_counter.exalt_div
	initialText := (storedVal > 0) ? CurrencyCounter_DecimalToFraction(storedVal, 1000) : ""
	Gui, %eName%: Add, Edit, % "w" wCtrl - 2 " h" hCtrl - 2 " Background202020 HWNDhwnd_input", % initialText
	Gui, %eName%: Add, Button, % "Default Hidden gCurrencyCounter_RatioEditSaveBtn HWNDhwnd_ok", ok
	vars.hwnd.cc_ratio_edit := {"main": hwnd_edit, "input": hwnd_input, "which": which}
	Gui, %eName%: Show, % "NA x" xCtrl " y" yCtrl
	ControlFocus,, % "ahk_id " hwnd_input
	ControlSend,, ^{a}, % "ahk_id " hwnd_input

	While WinActive("ahk_id " hwnd_edit)
		Sleep, 10

	; Read value BEFORE destroying
	raw := Trim(LLK_ControlGet(hwnd_input))
	CurrencyCounter_RatioEditCommit(raw)
	Gui, %eName%: Destroy
}

CurrencyCounter_RatioEditSaveBtn:
	raw := Trim(LLK_ControlGet(vars.hwnd.cc_ratio_edit.input))
	CurrencyCounter_RatioEditCommit(raw)
	Gui, cc_ratio_edit1: Destroy
	Gui, cc_ratio_edit2: Destroy
Return

CurrencyCounter_RatioEditCommit(raw)
{
	local
	global vars, settings, Currency_Counter_instance

	which := vars.hwnd.cc_ratio_edit.which
	If !which
		Return
	raw := Trim(raw)

	; Parse XX/YY fraction format
	If InStr(raw, "/")
	{
		parts := StrSplit(raw, "/")
		If (parts.Length() = 2 && IsNumber(Trim(parts[1])) && IsNumber(Trim(parts[2])) && (Trim(parts[2]) + 0 > 0))
			val := (Trim(parts[2]) + 0) / (Trim(parts[1]) + 0)
		Else
		{
			vars.hwnd.cc_ratio_edit := {"main": "", "input": "", "which": ""}
			Return
		}
	}
	Else If IsNumber(raw) && (raw + 0 > 0)
		val := 1 / (raw + 0)
	Else
	{
		vars.hwnd.cc_ratio_edit := {"main": "", "input": "", "which": ""}
		Return
	}
	If (which = "chaos")
	{
		settings.currency_counter.chaos_div := val
		settings.currency_counter.chaos_div_updated := A_NowUTC
		settings.currency_counter.chaos_div_src := ""
		IniWrite, % val, % Currency_Counter_instance.config_path, settings, chaos-div
		IniWrite, % A_NowUTC, % Currency_Counter_instance.config_path, settings, chaos-div-updated
		IniDelete, % Currency_Counter_instance.config_path, settings, chaos-div-src
	}
	Else
	{
		settings.currency_counter.exalt_div := val
		settings.currency_counter.exalt_div_updated := A_NowUTC
		settings.currency_counter.exalt_div_src := ""
		IniWrite, % val, % Currency_Counter_instance.config_path, settings, exalt-div
		IniWrite, % A_NowUTC, % Currency_Counter_instance.config_path, settings, exalt-div-updated
		IniDelete, % Currency_Counter_instance.config_path, settings, exalt-div-src
	}
	vars.hwnd.cc_ratio_edit := {"main": "", "input": "", "which": ""}
	CurrencyCounter_UpdateExaltRate()
	CurrencyCounter_Logs()
}

CurrencyCounter_UpdateExaltRate()
{
	local
	global vars, settings
	vars.currency_counter.exalt_chaos_rate := (settings.currency_counter.chaos_div > 0 && settings.currency_counter.exalt_div > 0)
		? settings.currency_counter.exalt_div / settings.currency_counter.chaos_div
		: 1
}

;================SETTINGS START============
; HWND naming (all under vars.hwnd.settings):
;   currency_counter_enable / _ssf / _ninja
;   currency_counter_<id>_minus / _val / _plus   (id = rows, font, spacing, vis, ninja, pwarn, pstale, rwarn, rstale)
; Tooltip keys are unchanged ("settings_currency_counter ...", "|" suffixes for minus/val/plus).

Settings_currency_counter()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.x_anchor
	cButtons := settings.general.cButtons, slop := settings.general.slop
	cc := settings.currency_counter

	Gui, %GUI%: Add, Text, % "Section x" x_anchor " y" vars.settings.ySelection " BackgroundTrans", % ""

	; ── Enable ────────────────────────────────────────────────
	Gui_Label(GUI, "Section xs ys gSettings_currency_counter2", " " Lang_Trans("m_cc_enable") " "
		, "settings_currency_counter enable", "hwnd.settings.currency_counter_enable", slop,,, cButtons, settings.features.currency_counter)

	If !settings.features.currency_counter
		Return

	; ── General ───────────────────────────────────────────────
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing " BackgroundTrans", % Lang_Trans("global_general")
	Gui, %GUI%: Font, norm

	Gui_Label(GUI, "Section xs gSettings_currency_counter2", " " Lang_Trans("m_cc_ssf") " "
		, "settings_currency_counter ssf", "hwnd.settings.currency_counter_ssf", slop,,, cButtons, cc.ssf)

	Settings_CC_Stepper(GUI, "Max table rows:", "settings_currency_counter max rows", "rows", (cc.max_rows > 0 ? cc.max_rows : "auto"), 5)

	; ── UI ────────────────────────────────────────────────────
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing " BackgroundTrans", % Lang_Trans("global_ui")
	Gui, %GUI%: Font, norm

	Settings_CC_Stepper(GUI, Lang_Trans("global_font"), "settings_currency_counter font-size", "font", cc.fSize)
	Settings_CC_Stepper(GUI, Lang_Trans("m_cc_tab_spacing"), "settings_currency_counter spacing", "spacing", cc.spacing)
	Settings_CC_Stepper(GUI, Lang_Trans("m_cc_visible_sessions"), "settings_currency_counter visible sessions", "vis", Settings_CC_Display("visibleCount"))

	If cc.ssf
		Return

	; ── poe.ninja ─────────────────────────────────────────────
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing " BackgroundTrans", % Lang_Trans("m_cc_ninja_section")
	Gui, %GUI%: Font, norm

	If (ninjaEnabled := settings.features.stash)
		Gui_Label(GUI, "Section xs gSettings_currency_counter2", " " Lang_Trans("m_cc_ninja_prices") " "
			, "settings_currency_counter ninja", "hwnd.settings.currency_counter_ninja", slop,,, cButtons, cc.ninja_prices)
	Else
		Gui_Label(GUI, "Section xs", " " Lang_Trans("m_cc_ninja_prices") " "
			, "settings_currency_counter ninja", "hwnd.settings.currency_counter_ninja", slop,,, cButtons, [0, "808080"])

	If (cc.ninja_prices && ninjaEnabled)
		Settings_CC_Stepper(GUI, Lang_Trans("m_cc_ninja_stale"), "settings_currency_counter ninja stale", "ninja", cc.ninja_stale_hours)

	; ── Price age thresholds ──────────────────────────────────
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing " BackgroundTrans", % Lang_Trans("m_cc_price_age")
	Gui, %GUI%: Font, norm
	Settings_CC_Stepper(GUI, Lang_Trans("m_cc_age_warn"), "settings_currency_counter price warn", "pwarn", cc.price_warn_hours)
	Settings_CC_Stepper(GUI, Lang_Trans("m_cc_age_stale"), "settings_currency_counter price stale", "pstale", cc.price_stale_hours, 3, 1)

	; ── Exchange rate age thresholds ──────────────────────────
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing " BackgroundTrans", % Lang_Trans("m_cc_rate_age")
	Gui, %GUI%: Font, norm
	Settings_CC_Stepper(GUI, Lang_Trans("m_cc_age_warn"), "settings_currency_counter rate warn", "rwarn", cc.rate_warn_hours)
	Settings_CC_Stepper(GUI, Lang_Trans("m_cc_age_stale"), "settings_currency_counter rate stale", "rstale", cc.rate_stale_hours, 3, 1)
}

; One "label  -  N  +" row, same look as the font-size rows in Settings_general().
; tip = base tooltip key; the minus/value/plus controls get tip "|", "||", "|||".
Settings_CC_Stepper(GUI, label, tip, id, value, wValueChars := 3, sameRow := 0)
{
	local
	global vars, settings

	cButtons := settings.general.cButtons, fWidth := settings.general.fWidth, fHeight := settings.general.fHeight
	Gui_Label(GUI, (sameRow ? "ys x+" fWidth : "Section xs") " gSettings_currency_counter2", " " label " ", tip,, [1, 0, 1, 0])
	Gui_Label(GUI, "ys x+0 w" fHeight " Center gSettings_currency_counter2", "-", tip "|", "hwnd.settings.currency_counter_" id "_minus",,,, cButtons)
	Gui_Label(GUI, "ys x+0 w" wValueChars * fWidth " Center gSettings_currency_counter2", value, tip "||", "hwnd.settings.currency_counter_" id "_val",,,, cButtons)
	Gui_Label(GUI, "ys x+0 w" fHeight " Center gSettings_currency_counter2", "+", tip "|||", "hwnd.settings.currency_counter_" id "_plus", [0, 1, 0, 1],,, cButtons)
}

; ── helpers for the stepper logic ─────────────────────────────
Settings_CC_Bounds(key, ByRef lo, ByRef hi)
{
	local
	global settings
	cc := settings.currency_counter

	Switch key
	{
		Case "max_rows":
			lo := 0, hi := 999
		Case "fSize":
			lo := 6, hi := 99
		Case "spacing":
			lo := 2, hi := 20
		Case "visibleCount":
			lo := 1, hi := 8
		Case "ninja_stale_hours":
			lo := 1, hi := 24
		Case "price_warn_hours":
			lo := 1, hi := cc.price_stale_hours - 1
		Case "price_stale_hours":
			lo := cc.price_warn_hours + 1, hi := 999
		Case "rate_warn_hours":
			lo := 1, hi := cc.rate_stale_hours - 1
		Case "rate_stale_hours":
			lo := cc.rate_warn_hours + 1, hi := 999
		Default:
			lo := 0, hi := 999
	}
}

Settings_CC_Default(key)
{
	local
	global settings

	Switch key
	{
		Case "max_rows", "visibleCount":
			Return 0 ; auto
		Case "fSize":
			Return settings.general.fSize
		Case "spacing":
			Return 10
		Case "ninja_stale_hours", "price_warn_hours", "rate_warn_hours":
			Return 3
		Case "price_stale_hours", "rate_stale_hours":
			Return 6
	}
	Return 0
}

Settings_CC_Display(key)
{
	local
	global settings
	cc := settings.currency_counter

	If (key = "max_rows")
		Return (cc.max_rows > 0 ? cc.max_rows : "auto")
	If (key = "visibleCount")
		Return (cc.visibleCount > 0 ? cc.visibleCount : (cc.ssf ? 2 : 4))
	Return cc[key]
}

Settings_CC_Refresh()
{
	local
	global vars, Currency_Counter_instance

	Currency_Counter_instance.Settings_Open("refresh")
	If WinExist("ahk_id " vars.hwnd.cc_logs.main)
		CurrencyCounter_Logs()
}

Settings_currency_counter2(cHWND)
{
	local
	global vars, settings, Currency_Counter_instance

	h := vars.hwnd.settings, cc := settings.currency_counter, cfg := Currency_Counter_instance.config_path

	; ── Toggles (Gui_Label has no checked state -> flip the stored value) ──
	If (cHWND = h.currency_counter_enable)
	{
		KeyWait, LButton
		IniWrite, % (settings.features.currency_counter := !settings.features.currency_counter), % cfg, settings, enabled
		If settings.features.currency_counter
			CurrencyCounter_DrawBar()
		Else
			LLK_Overlay(vars.hwnd.currency_counter.main, "destroy")
		Currency_Counter_instance.Settings_Open("refresh")
		Return
	}
	If (cHWND = h.currency_counter_ssf)
	{
		KeyWait, LButton
		IniWrite, % (cc.ssf := !cc.ssf), % cfg, settings, ssf mode
		Settings_CC_Refresh()
		Return
	}
	If (cHWND = h.currency_counter_ninja)
	{
		KeyWait, LButton
		IniWrite, % (cc.ninja_prices := !cc.ninja_prices), % cfg, settings, ninja-prices
		Settings_CC_Refresh()
		Return
	}

	; ── -/N/+ steppers: hold -/+ to repeat, click the value to reset to default ──
	defs := [["max_rows", "max-rows", "rows"], ["fSize", "font-size", "font"], ["spacing", "spacing", "spacing"]
		, ["visibleCount", "visible-sessions", "vis"], ["ninja_stale_hours", "ninja-stale-hours", "ninja"]
		, ["price_warn_hours", "price-warn-hours", "pwarn"], ["price_stale_hours", "price-stale-hours", "pstale"]
		, ["rate_warn_hours", "rate-warn-hours", "rwarn"], ["rate_stale_hours", "rate-stale-hours", "rstale"]]

	For index, def in defs
	{
		key := def.1, ini := def.2, id := "currency_counter_" def.3
		hMinus := h[id "_minus"], hPlus := h[id "_plus"], hVal := h[id "_val"]

		If (cHWND = hMinus) || (cHWND = hPlus)
		{
			delta := (cHWND = hPlus) ? 1 : -1
			While GetKeyState("LButton", "P")
			{
				Settings_CC_Bounds(key, lo, hi)
				cur := (key = "visibleCount" && !(cc.visibleCount > 0)) ? Settings_CC_Display(key) : cc[key]
				cc[key] := Max(lo, Min(hi, cur + delta))
				GuiControl, Text, % hVal, % Settings_CC_Display(key)
				Sleep, 150
			}
		}
		Else If (cHWND = hVal)
		{
			KeyWait, LButton
			cc[key] := Settings_CC_Default(key)
		}
		Else Continue

		If (key = "fSize")
		{
			LLK_FontDimensions(cc.fSize, fH, fW)
			cc.fHeight := fH, cc.fWidth := fW
		}
		If InStr("max_rows,visibleCount", key) && !(cc[key] > 0)
			IniDelete, % cfg, settings, % ini
		Else
			IniWrite, % cc[key], % cfg, settings, % ini
		Settings_CC_Refresh()
		Return
	}
}
;================SETTINGS END============