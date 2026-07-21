
Class CurrencyCounterAddon
{
	__New(name) ; name is loaded from the JSON file
	{
		this.name := name, this.settings := {}, this.hwnd := {}
		this.addon_path := "add-ons\" name  ; path to the add-on's folder
		this.config_path := this.addon_path "\config" vars.poe_version ".ini" ; vars.poe_version is blank for PoE1 and " 2" for PoE2 // split into separate configs not necessarily required

		If !FileExist(this.config_path)
			IniWrite, % "", % this.config_path, settings
		ini := IniBatchRead(this.config_path)

		this.settings.fSize := (ini.UI.font ? ini.UI.font : settings.general.fSize)
		LLK_FontDimensions(this.settings.fSize, h, w), this.settings.fWidth := w, this.settings.fHeight := h ; get approx. dimensions for font width and height (optional)
		this.settings.hotkey_stats := ini.settings["hotkey stats"]
		this.Init()
	}

	Hotkeys() ; called when a customizable hotkey is pressed
	{

	}

    Init()
    {
		If !Blank(this.settings.hotkey_stats) && (key := Hotkeys_Convert(this.settings.hotkey_stats)) ; function converts key-names to scan-codes and also checks validity
		{
			func := ObjBindMethod(this, "Hotkeys")
			Hotkey, IfWinActive, ahk_group poe_window
			Hotkey, % key, % func, on
		}
        Currency_Counter_instance := this
        Init_currency_counter()
    }

    LogRead(log_text)
    {
        CurrencyCounter_ProcessLog(log_text)
    }

    Settings_menu(mode := "") ; called when clicking the cogwheel-icon in the "add-ons" section of the settings menu
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

    OmniClick()
    {
        CurrencyCounter_HorticraftingClick()
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
    settings.currency_counter.active := !Blank(check := ini.settings["active"]) ? check : 0

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

    ; Fossil name -> array of effect description lines
    vars.currency_counter.fossils := {}
    If FileExist(Currency_Counter_instance.addon_path "\data\english\fossils.json")
    {
        FileRead, raw_fossils, % Currency_Counter_instance.addon_path "\data\english\fossils.json"
        vars.currency_counter.fossils := IsObject(check := Json.Load(raw_fossils)) ? check : {}
    }

    ; Horticrafting station screen-check – reuses the existing image-check
    ; machinery from screen-checks.ahk (vars.imagesearch + Screenchecks_
    ; ImageSearch()) instead of duplicating that logic here. Registering
    ; it into vars.imagesearch.list/.search also means it shows up in the
    ; existing screen-check settings menu for calibration, same as any
    ; other check – no separate calibration code needed in this module.
    ;
    ; NOTE: this still needs a reference image at
    ;   img\Recognition (<height>p)\GUI\horticrafting<poe_version>.bmp
    ; captured once through that existing calibration UI. checks.x/y/w/h
    ; below was measured on a 1920x1080 screenshot ("HORTIC" out of the
    ; "HORTICRAFTING" title, x1 483 y1 183 x2 568 y2 213) and is expressed
    ; as a fraction of vars.client.h (same scaling convention as e.g.
    ; runeshaping/runeshaping2 below) so it lands in the right spot at
    ; any resolution, not just 1080p.
    ini_sc := IniBatchRead("ini" vars.poe_version "\screen checks (" vars.client.h "p).ini")
    vars.imagesearch.list.horticrafting := 1
    If !LLK_HasVal(vars.imagesearch.search, "horticrafting")
        vars.imagesearch.search.Push("horticrafting")
    parse := StrSplit(ini_sc.horticrafting["last coordinates"], ",")
    vars.imagesearch.horticrafting := {"check": 0, "x1": parse.1, "y1": parse.2, "x2": parse.3, "y2": parse.4}
    vars.imagesearch.checks.horticrafting := {"x": Round(vars.client.h * (483/1080)), "y": Round(vars.client.h * (183/1080)), "w": Round(vars.client.h * (85/1080)), "h": Round(vars.client.h * (30/1080))}

    vars.hwnd.currency_counter := {"main": "", "drag": ""}
    vars.hwnd.currency_counter_table := {"main": ""}
    vars.hwnd.currency_counter_horticrafting := {"main": ""}
    vars.cc_logs := {"sort_col": "", "sort_asc": 1, "x": settings.currency_counter.logs_x, "y": settings.currency_counter.logs_y, "keywords": {}}

    CurrencyCounter_UpdateExaltRate()

    ; Cache icon image (placeholder path – replace with real asset)
    If FileExist("img\GUI\currency\blessed.png")
        vars.pics.currency_counter := {"icon": LLK_ImageCache("img\GUI\currency\blessed.png")}
    Else
        vars.pics.currency_counter := {"icon": ""}
    If !Blank(settings.currency_counter.active)
    {
        CurrencyCounter_SetActive(settings.currency_counter.active)
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
;  Currency blacklist check – names that must never be "picked
;  up" as a counted currency (matched via InStr on the OCR'd
;  item name). The actual lists live in vars.currency_counter
;  .blacklist_poe1 / .blacklist_poe2, populated once in
;  Init_currency_counter().
;
;  vars.poe_version is blank ("") for PoE1, non-blank for PoE2 –
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
;  Groupable check – blacklisted names that may still be staged
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
;  calibration/reference-image capture like any other check – no
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

; Full-screen click-through overlay covering the game client, toggled
; on/off each call. Currently empty – controls get added later.
CurrencyCounter_HorticraftingOverlay()
{
    local
    global vars, settings
    static hwnd_overlay := 0

    If hwnd_overlay && WinExist("ahk_id " hwnd_overlay)
    {
        LLK_Overlay(hwnd_overlay, "destroy")
        Gui, currency_counter_horticrafting: Destroy
        hwnd_overlay := 0
        Return
    }

    Gui, currency_counter_horticrafting: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x20 +E0x02000000 +E0x00080000 HWNDhwnd_overlay"
    Gui, currency_counter_horticrafting: Color, Purple
    WinSet, TransColor, Purple
    Gui, currency_counter_horticrafting: Margin, 0, 0

    ; Currently empty – overlay content to be added in a later pass.

    Gui, currency_counter_horticrafting: Show, % "NA x" vars.client.x " y" vars.client.y " w" vars.client.w " h" vars.client.h
    vars.hwnd.currency_counter_horticrafting := {"main": hwnd_overlay}
    LLK_Overlay(hwnd_overlay, "show", 0, "currency_counter_horticrafting")
}

; Entry point for the omni-key click handler.
CurrencyCounter_HorticraftingClick()
{
    local

    If !Screenchecks_ImageSearch("horticrafting")
        Return

    CurrencyCounter_HorticraftingOverlay()
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
        vars.currency_counter.currencies[name] := {"count": 0, "price": 0.0, "price_currency": "exalt", "price_updated": 0}
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
    vars.currency_counter.name := "" ; group mode – no single held name
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
        Return ; unrecognized tier – ignore

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
        Return ; not full (or unrecognized combo) – do not pick it up

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
		return ; clipboard empty – no item, do nothing
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
    ;     group is NOT cleared here – it stays armed, just like a single
    ;     picked currency, until Shift is released below / in
    ;     CurrencyCounter_CheckShiftRelease(). ---
    If (IsObject(vars.currency_counter.group) && vars.currency_counter.group.Count())
    {
        For i, gname in vars.currency_counter.group
        {
            If !IsObject(vars.currency_counter.currencies[gname])
                vars.currency_counter.currencies[gname] := {"count": 0, "price": 0.0, "price_currency": "exalt", "price_updated": 0}
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
            vars.currency_counter.currencies[vars.currency_counter.name] := {"count": 0, "price": 0.0, "price_currency": "exalt", "price_updated": 0}
        }
        vars.currency_counter.currencies[vars.currency_counter.name].count += 1
        vars.currency_counter.last_used := vars.currency_counter.name

        CurrencyCounter_SaveCurrency(vars.currency_counter.name)

        ; --- Restore original picked currency name before any state changes ---
        vars.currency_counter.name := originalName
    }

    ; --- Shift handling – shared by both the group and single-name
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
            vars.currency_counter.currencies[currency_name] := {"count": 0, "price": 0.0, "price_currency": "exalt", "price_updated": 0}
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
	;  Drag box – dynamically adjusts to actual window width
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
	picWidth := itemWidth ; Adjust this ratio as needed
	gap := 5
	firstItemAdded := false

	Loop % visibleCount {
		idx := A_Index
		xPos := (idx-1)*(itemWidth + spacing)

		; Picture: left side                   ; top aligned within the element
		picH := itemHeight - 2 ; a little smaller to avoid edge clipping

		; Text: right side, vertically centered
		txtX := xPos + picWidth + gap
		txtW := itemWidth - picWidth - gap

		yOpt := !firstItemAdded ? "ys" : "yp"

		For key, val in settings.currency_counter.sessions
		{
			if(A_Index <= vars.currency_counter.carousel_index)
				continue
			if(A_Index > vars.currency_counter.carousel_index + visibleCount)
				break

			slotNum := A_Index - vars.currency_counter.carousel_index
			xPos := spacing + (slotNum - 1) * (itemWidth + spacing)
			yOpt := (slotNum = 1) ? "ys" : "yp"

			isActive := (key = settings.currency_counter.active)
			textColor := isActive ? " cBlack" : " cWhite"
			bgColor := isActive ? "White" : "1A1A1A"

			if(!Blank(val.img))
			{
				Gui, %GUI_name%: Add, Text, % "x" xPos " " yOpt " w" itemWidth " h" itemHeight " Border Center 0x200 BackgroundTrans", % val.name
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background" bgColor " HWNDhwnd", 0
				vars.hwnd.cc_logs["tab_" key] := hwnd
			}
			Else
			{
				Gui, %GUI_name%: Font, % "s" fSize2 - 2 (isActive ? " cBlack" : " cWhite"), % vars.system.font
				Gui, %GUI_name%: Add, Text, % "x" xPos " " yOpt " w" itemWidth " h" itemHeight " Border Center 0x200 BackgroundTrans", % val.name
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background" bgColor " HWNDhwnd", 0
				vars.hwnd.cc_logs["tab_" key] := hwnd ; store Progress hwnd, hotkey sends cMouse which will match it
				Gui, %GUI_name%: Font, % "s" fSize2 - 2 " cWhite", % vars.system.font
			}
		}
	}

	Gui, %GUI_name%: Font, % "s" fSize2 * 3 " c41BB1C", % vars.system.font
	Gui, %GUI_name%: Add, Text, % "yp x" totalWidth - newSessionButtonWidth - spacing " w" newSessionButtonWidth - spacing " h" itemHeight " Border Center 0x200 gCurrencyCounter_Logs2 HWNDhwnd", % " + "
	Gui, %GUI_name%: Font, % "s" fSize2 " cWhite", % vars.system.font
	vars.hwnd.cc_logs.add_session := vars.hwnd.help_tooltips["cclogs_add session"] := hwnd

	; ══════════════════════════════════════════════════════════
	;  INFO BAR  – image | session label | name edit | delete | spacer | currency picker (right-aligned)
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

	; ── Currency picker (only if not SSF) – placed at far right edge ──
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
		colorC := " c" (Blank(tsC) ? "808080" : CurrencyCounter_RateColor(tsC))

		Gui, %GUI_name%: Add, Text, % "x" pickerX " yp-" pickerImgSize - imgSize " Border 0x200 Center cC89B3C w" colW " h" halfH, % Lang_Trans("m_cc_abbr_chaos")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0
		Gui, %GUI_name%: Add, Text, % "ys yp Border 0x200 Center gCurrencyCounter_Logs2 HWNDhwnd" colorC " w" midW " h" halfH, % CurrencyCounter_DecimalToFraction(settings.currency_counter.chaos_div,1000)
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0
		vars.hwnd.cc_logs.ratio_chaos_btn := vars.hwnd.help_tooltips["cclogs_ratio chaos"] := hwnd
		Gui, %GUI_name%: Add, Text, % "ys yp Border 0x200 Center cC89B3C w" colW " h" halfH, % Lang_Trans("m_cc_abbr_divine")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Background1A1A1A HWNDhwnd", 0

		; ── Row 2: exalt → divine ─────────────────────────────
		tsE := settings.currency_counter.exalt_div_updated
		colorE := " c" (Blank(tsE) ? "808080" : CurrencyCounter_RateColor(tsE))

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
	;  TABLE  – search, headers, data rows
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
			; "Total" label in the spacer row – IS the Section anchor (ys Section).
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
;  CurrencyCounter_Logs2(cHWND)  –  unified click handler
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
			vars.currency_counter.currencies[label] := {"count": 1, "price": 0.0, "price_currency": "exalt", "price_updated": 0}
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

	; ── Price cell click – inline edit overlay ────────────────
	If InStr(check, "price_")
	{
		currency_name := SubStr(check, 7)
		If (vars.system.click = 1)
			CurrencyCounter_PriceEdit(cHWND, currency_name)
		Return
	}

	; ── Count cell click – inline edit overlay ────────────────
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
;  CurrencyCounter_CurPicker  –  3-icon currency selector
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
;  CurrencyCounter_PriceEdit  –  tiny overlay Edit on the cell
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
			If IsNumber(num) && IsNumber(den) && (num + 0 > 0)
			{
				price := (den + 0) / (num + 0)
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
;  CurrencyCounter_CountEdit  –  tiny overlay Edit on count cell
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
;  CurrencyCounter_NinjaPrice  –  look up chaos price from stash-ninja
;  Returns "" if not available or feature not enabled.
; ──────────────────────────────────────────────────────────────
CurrencyCounter_NinjaPrice(name)
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
			Return IsNumber(price) && price > 0 ? price : ""
		}
	}
	Return ""
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

	; Only act when mouse is over a session tab
	check := LLK_HasVal(vars.hwnd.cc_logs, vars.general.cMouse)
	If !InStr(check, "tab_")
		Return

	maxIndex := settings.currency_counter.sessions.Count() - settings.currency_counter.visibleCount

	idx := vars.currency_counter.carousel_index
	idx += (direction = "up") ? -1 : 1
	if (idx < 0)
		vars.currency_counter.carousel_index := 0
	else if (idx > maxIndex)
		vars.currency_counter.carousel_index := maxIndex
	else
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
		IniWrite, % val, % Currency_Counter_instance.config_path, settings, chaos-div
		IniWrite, % A_NowUTC, % Currency_Counter_instance.config_path, settings, chaos-div-updated
	}
	Else
	{
		settings.currency_counter.exalt_div := val
		settings.currency_counter.exalt_div_updated := A_NowUTC
		IniWrite, % val, % Currency_Counter_instance.config_path, settings, exalt-div
		IniWrite, % A_NowUTC, % Currency_Counter_instance.config_path, settings, exalt-div-updated
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
Settings_currency_counter()
{
    local
    global vars, settings

    GUI      := "settings_menu" vars.settings.GUI_toggle
    x_anchor := vars.settings.x_anchor

    Gui, %GUI%: Add, Text, % "Section x" x_anchor " y" vars.settings.ySelection, % ""

    ; ── Enable ────────────────────────────────────────────────
    Gui, %GUI%: Add, Checkbox, % "xs y+" vars.settings.spacing " Section gSettings_currency_counter2 HWNDhwnd Checked" settings.features.currency_counter
        , % Lang_Trans("m_cc_enable")
    vars.hwnd.settings.currency_counter_enable := vars.hwnd.help_tooltips["settings_currency_counter enable"] := hwnd

    If !settings.features.currency_counter
    {
        Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default HWNDhwnd gSettings_currency_counter2", OK
        Return
    }

    ; ── General ───────────────────────────────────────────────
    Gui, %GUI%: Font, bold underline
    Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % Lang_Trans("global_general")
    Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default HWNDhwnd gSettings_currency_counter2", OK
    Gui, %GUI%: Font, norm
    vars.hwnd.settings.currency_counter_apply := hwnd

    Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_currency_counter2 HWNDhwnd Checked" settings.currency_counter.ssf
        , % Lang_Trans("m_cc_ssf")
    vars.hwnd.settings.currency_counter_ssf := vars.hwnd.help_tooltips["settings_currency_counter ssf"] := hwnd

    ; Max table rows  –/N/+
    maxRowsDisplay := settings.currency_counter.max_rows > 0 ? settings.currency_counter.max_rows : "auto"
    Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+" vars.settings.spacing/2, % "Max table rows:"
    vars.hwnd.help_tooltips["settings_currency_counter max rows"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
    vars.hwnd.settings.currency_counter_rowminus := vars.hwnd.help_tooltips["settings_currency_counter max rows|"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*4, % maxRowsDisplay
	vars.hwnd.settings.currency_counter_rowcount := vars.hwnd.help_tooltips["settings_currency_counter max rows||"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
    vars.hwnd.settings.currency_counter_rowplus := vars.hwnd.help_tooltips["settings_currency_counter max rows|||"] := hwnd

    ; ── UI ────────────────────────────────────────────────────
    Gui, %GUI%: Font, bold underline
    Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % Lang_Trans("global_ui")
    Gui, %GUI%: Font, norm

    ; Font size  –/N/+
    Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % Lang_Trans("global_font")
    vars.hwnd.help_tooltips["settings_currency_counter font-size"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
    vars.hwnd.settings.currency_counter_fminus := vars.hwnd.help_tooltips["settings_currency_counter font-size|"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % settings.currency_counter.fSize
    vars.hwnd.settings.currency_counter_fsize := vars.hwnd.help_tooltips["settings_currency_counter font-size||"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
    vars.hwnd.settings.currency_counter_fplus := vars.hwnd.help_tooltips["settings_currency_counter font-size|||"] := hwnd

    ; Tab spacing  –/N/+
    Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+" vars.settings.spacing/2, % Lang_Trans("m_cc_tab_spacing")
    vars.hwnd.help_tooltips["settings_currency_counter spacing"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
    vars.hwnd.settings.currency_counter_sminus := vars.hwnd.help_tooltips["settings_currency_counter spacing|"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % settings.currency_counter.spacing
    vars.hwnd.settings.currency_counter_spacing := vars.hwnd.help_tooltips["settings_currency_counter spacing||"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
    vars.hwnd.settings.currency_counter_splus := vars.hwnd.help_tooltips["settings_currency_counter spacing|||"] := hwnd

    ; Visible sessions  –/N/+ [reset]
    visDefault := settings.currency_counter.ssf ? 2 : 4
    visCur := settings.currency_counter.visibleCount > 0 ? settings.currency_counter.visibleCount : visDefault
    Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+" vars.settings.spacing/2, % Lang_Trans("m_cc_visible_sessions")
    vars.hwnd.help_tooltips["settings_currency_counter visible sessions"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
    vars.hwnd.settings.currency_counter_vminus := vars.hwnd.help_tooltips["settings_currency_counter visible sessions|"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % visCur
    vars.hwnd.settings.currency_counter_vcount := vars.hwnd.help_tooltips["settings_currency_counter visible sessions||"] := hwnd
    Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
    vars.hwnd.settings.currency_counter_vplus := vars.hwnd.help_tooltips["settings_currency_counter visible sessions|||"] := hwnd

    ; ── poe.ninja ─────────────────────────────────────────────
    If !settings.currency_counter.ssf
    {
        Gui, %GUI%: Font, bold underline
        Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % Lang_Trans("m_cc_ninja_section")
        Gui, %GUI%: Font, norm

        ninjaEnabled := settings.features.stash
        If ninjaEnabled
        {
            Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_currency_counter2 HWNDhwnd Checked" settings.currency_counter.ninja_prices
                , % Lang_Trans("m_cc_ninja_prices")
            vars.hwnd.settings.currency_counter_ninja := vars.hwnd.help_tooltips["settings_currency_counter ninja"] := hwnd
        }
        Else
        {
            Gui, %GUI%: Add, Checkbox, % "xs Section Disabled HWNDhwnd Checked" settings.currency_counter.ninja_prices, % ""
            vars.hwnd.settings.currency_counter_ninja := hwnd
            Gui, %GUI%: Add, Text, % "ys x+0 c808080 HWNDhwnd", % Lang_Trans("m_cc_ninja_prices")
            vars.hwnd.help_tooltips["settings_currency_counter ninja"] := hwnd
        }

        If (settings.currency_counter.ninja_prices && ninjaEnabled)
        {
            Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+" vars.settings.spacing/2, % Lang_Trans("m_cc_ninja_stale")
            vars.hwnd.help_tooltips["settings_currency_counter ninja stale"] := hwnd
            Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
            vars.hwnd.settings.currency_counter_nminus := vars.hwnd.help_tooltips["settings_currency_counter ninja stale|"] := hwnd
            Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % settings.currency_counter.ninja_stale_hours
            vars.hwnd.settings.currency_counter_nstale := vars.hwnd.help_tooltips["settings_currency_counter ninja stale||"] := hwnd
            Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
            vars.hwnd.settings.currency_counter_nplus := vars.hwnd.help_tooltips["settings_currency_counter ninja stale|||"] := hwnd
        }

        ; ── Price age thresholds ───────────────────────────────
        Gui, %GUI%: Font, bold underline
        Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % Lang_Trans("m_cc_price_age")
        Gui, %GUI%: Font, norm

        Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % Lang_Trans("m_cc_age_warn")
        vars.hwnd.help_tooltips["settings_currency_counter price warn"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
        vars.hwnd.settings.currency_counter_pwarnminus := vars.hwnd.help_tooltips["settings_currency_counter price warn|"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % settings.currency_counter.price_warn_hours
        vars.hwnd.settings.currency_counter_pwarn := vars.hwnd.help_tooltips["settings_currency_counter price warn||"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
        vars.hwnd.settings.currency_counter_pwarnplus := vars.hwnd.help_tooltips["settings_currency_counter price warn|||"] := hwnd

        Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+" vars.settings.spacing/2, % Lang_Trans("m_cc_age_stale")
        vars.hwnd.help_tooltips["settings_currency_counter price stale"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
        vars.hwnd.settings.currency_counter_pstaleminus := vars.hwnd.help_tooltips["settings_currency_counter price stale|"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % settings.currency_counter.price_stale_hours
        vars.hwnd.settings.currency_counter_pstale := vars.hwnd.help_tooltips["settings_currency_counter price stale||"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
        vars.hwnd.settings.currency_counter_pstaleplus := vars.hwnd.help_tooltips["settings_currency_counter price stale|||"] := hwnd

        ; ── Exchange rate age thresholds ───────────────────────
        Gui, %GUI%: Font, bold underline
        Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % Lang_Trans("m_cc_rate_age")
        Gui, %GUI%: Font, norm

        Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % Lang_Trans("m_cc_age_warn")
        vars.hwnd.help_tooltips["settings_currency_counter rate warn"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
        vars.hwnd.settings.currency_counter_rwarnminus := vars.hwnd.help_tooltips["settings_currency_counter rate warn|"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % settings.currency_counter.rate_warn_hours
        vars.hwnd.settings.currency_counter_rwarn := vars.hwnd.help_tooltips["settings_currency_counter rate warn||"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
        vars.hwnd.settings.currency_counter_rwarnplus := vars.hwnd.help_tooltips["settings_currency_counter rate warn|||"] := hwnd

        Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+" vars.settings.spacing/2, % Lang_Trans("m_cc_age_stale")
        vars.hwnd.help_tooltips["settings_currency_counter rate stale"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "–"
        vars.hwnd.settings.currency_counter_rstaleminus := vars.hwnd.help_tooltips["settings_currency_counter rate stale|"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*3, % settings.currency_counter.rate_stale_hours
        vars.hwnd.settings.currency_counter_rstale := vars.hwnd.help_tooltips["settings_currency_counter rate stale||"] := hwnd
        Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/4 " Center Border gSettings_currency_counter2 HWNDhwnd w" settings.general.fWidth*2, % "+"
        vars.hwnd.settings.currency_counter_rstaleplus := vars.hwnd.help_tooltips["settings_currency_counter rate stale|||"] := hwnd
    }
}

Settings_currency_counter2(cHWND)
{
    local
    global vars, settings, Currency_Counter_instance

    If (cHWND = vars.hwnd.settings.currency_counter_enable)
	{
	    IniWrite, % (settings.features.currency_counter := LLK_ControlGet(cHWND))
	        , % Currency_Counter_instance.config_path, settings, enabled
	    If settings.features.currency_counter
		{
	        CurrencyCounter_DrawBar()
		}
	    Else
	        LLK_Overlay(vars.hwnd.currency_counter.main, "destroy")
		;Settings_menu("addons_" Currency_Counter_instance.name) ; fallback
	    Currency_Counter_instance.Settings_menu("refresh")
	    Return
	}
    If (cHWND = vars.hwnd.settings.currency_counter_ssf)
    {
        IniWrite, % (settings.currency_counter.ssf := LLK_ControlGet(cHWND))
            , % Currency_Counter_instance.config_path, settings, ssf mode
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_rowminus) || (cHWND = vars.hwnd.settings.currency_counter_rowplus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_rowplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.max_rows := Max(0, settings.currency_counter.max_rows + delta)
            GuiControl, Text, % vars.hwnd.settings.currency_counter_rowcount
                , % (settings.currency_counter.max_rows > 0 ? settings.currency_counter.max_rows : "auto")
            Sleep, 150
        }
        If (settings.currency_counter.max_rows > 0)
            IniWrite, % settings.currency_counter.max_rows, % Currency_Counter_instance.config_path, settings, max-rows
        Else
            IniDelete, % Currency_Counter_instance.config_path, settings, max-rows
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_fminus) || (cHWND = vars.hwnd.settings.currency_counter_fplus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_fplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.fSize := Max(6, settings.currency_counter.fSize + delta)
            GuiControl, Text, % vars.hwnd.settings.currency_counter_fsize, % settings.currency_counter.fSize
            Sleep, 150
        }
        LLK_FontDimensions(settings.currency_counter.fSize, h, w)
        settings.currency_counter.fHeight := h, settings.currency_counter.fWidth := w
        IniWrite, % settings.currency_counter.fSize, % Currency_Counter_instance.config_path, settings, font-size
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_sminus) || (cHWND = vars.hwnd.settings.currency_counter_splus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_splus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.spacing := Max(2, Min(20, settings.currency_counter.spacing + delta))
            GuiControl, Text, % vars.hwnd.settings.currency_counter_spacing, % settings.currency_counter.spacing
            Sleep, 150
        }
        IniWrite, % settings.currency_counter.spacing, % Currency_Counter_instance.config_path, settings, spacing
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_vminus) || (cHWND = vars.hwnd.settings.currency_counter_vplus)
    {
        visDefault := settings.currency_counter.ssf ? 2 : 4
        delta := (cHWND = vars.hwnd.settings.currency_counter_vplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            cur := settings.currency_counter.visibleCount > 0 ? settings.currency_counter.visibleCount : visDefault
            settings.currency_counter.visibleCount := Max(1, Min(8, cur + delta))
            GuiControl, Text, % vars.hwnd.settings.currency_counter_vcount, % settings.currency_counter.visibleCount
            Sleep, 150
        }
        IniWrite, % settings.currency_counter.visibleCount, % Currency_Counter_instance.config_path, settings, visible-sessions
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_nminus) || (cHWND = vars.hwnd.settings.currency_counter_nplus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_nplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.ninja_stale_hours := Max(1, Min(24, settings.currency_counter.ninja_stale_hours + delta))
            GuiControl, Text, % vars.hwnd.settings.currency_counter_nstale, % settings.currency_counter.ninja_stale_hours
            Sleep, 150
        }
        IniWrite, % settings.currency_counter.ninja_stale_hours, % Currency_Counter_instance.config_path, settings, ninja-stale-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_ninja)
    {
        IniWrite, % (settings.currency_counter.ninja_prices := LLK_ControlGet(cHWND))
            , % Currency_Counter_instance.config_path, settings, ninja-prices
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }

	; ── Reset on middle‑click ─────────────────────────────────
	If (cHWND = vars.hwnd.settings.currency_counter_rowcount) {
	    ; default = 0  (auto)
	    settings.currency_counter.max_rows := 0
	    IniDelete, % Currency_Counter_instance.config_path, settings, max-rows
	    Currency_Counter_instance.Settings_menu("refresh")
	    If WinExist("ahk_id " vars.hwnd.cc_logs.main)
	        CurrencyCounter_Logs()
	    Return
	}
	If (cHWND = vars.hwnd.settings.currency_counter_fsize) {
	    ; default = general font size
	    settings.currency_counter.fSize := settings.general.fSize
	    IniWrite, % settings.currency_counter.fSize, % Currency_Counter_instance.config_path, settings, font-size
	    LLK_FontDimensions(settings.currency_counter.fSize, h, w)
	    settings.currency_counter.fHeight := h, settings.currency_counter.fWidth := w
	    Currency_Counter_instance.Settings_menu("refresh")
	    If WinExist("ahk_id " vars.hwnd.cc_logs.main)
	        CurrencyCounter_Logs()
	    Return
	}
	If (cHWND = vars.hwnd.settings.currency_counter_spacing) {
	    ; default = 10
	    settings.currency_counter.spacing := 10
	    IniWrite, % settings.currency_counter.spacing, % Currency_Counter_instance.config_path, settings, spacing
	    Currency_Counter_instance.Settings_menu("refresh")
	    If WinExist("ahk_id " vars.hwnd.cc_logs.main)
	        CurrencyCounter_Logs()
	    Return
	}
	If (cHWND = vars.hwnd.settings.currency_counter_vcount) {
	    ; default = 0  (auto: 2 for SSF, 4 for trade)
	    settings.currency_counter.visibleCount := 0
	    IniDelete, % Currency_Counter_instance.config_path, settings, visible-sessions
	    Currency_Counter_instance.Settings_menu("refresh")
	    If WinExist("ahk_id " vars.hwnd.cc_logs.main)
	        CurrencyCounter_Logs()
	    Return
	}
	If (cHWND = vars.hwnd.settings.currency_counter_nstale) {
	    settings.currency_counter.ninja_stale_hours := 3
	    IniWrite, % settings.currency_counter.ninja_stale_hours, % Currency_Counter_instance.config_path, settings, ninja-stale-hours
	    Currency_Counter_instance.Settings_menu("refresh")
	    If WinExist("ahk_id " vars.hwnd.cc_logs.main)
	        CurrencyCounter_Logs()
	    Return
	}
    If (cHWND = vars.hwnd.settings.currency_counter_pwarnminus) || (cHWND = vars.hwnd.settings.currency_counter_pwarnplus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_pwarnplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.price_warn_hours := Max(1, Min(settings.currency_counter.price_stale_hours - 1, settings.currency_counter.price_warn_hours + delta))
            GuiControl, Text, % vars.hwnd.settings.currency_counter_pwarn, % settings.currency_counter.price_warn_hours
            Sleep, 150
        }
        IniWrite, % settings.currency_counter.price_warn_hours, % Currency_Counter_instance.config_path, settings, price-warn-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_pwarn)
    {
        settings.currency_counter.price_warn_hours := 6
        IniWrite, % settings.currency_counter.price_warn_hours, % Currency_Counter_instance.config_path, settings, price-warn-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_pstaleminus) || (cHWND = vars.hwnd.settings.currency_counter_pstaleplus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_pstaleplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.price_stale_hours := Max(settings.currency_counter.price_warn_hours + 1, settings.currency_counter.price_stale_hours + delta)
            GuiControl, Text, % vars.hwnd.settings.currency_counter_pstale, % settings.currency_counter.price_stale_hours
            Sleep, 150
        }
        IniWrite, % settings.currency_counter.price_stale_hours, % Currency_Counter_instance.config_path, settings, price-stale-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_pstale)
    {
        settings.currency_counter.price_stale_hours := 12
        IniWrite, % settings.currency_counter.price_stale_hours, % Currency_Counter_instance.config_path, settings, price-stale-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_rwarnminus) || (cHWND = vars.hwnd.settings.currency_counter_rwarnplus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_rwarnplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.rate_warn_hours := Max(1, Min(settings.currency_counter.rate_stale_hours - 1, settings.currency_counter.rate_warn_hours + delta))
            GuiControl, Text, % vars.hwnd.settings.currency_counter_rwarn, % settings.currency_counter.rate_warn_hours
            Sleep, 150
        }
        IniWrite, % settings.currency_counter.rate_warn_hours, % Currency_Counter_instance.config_path, settings, rate-warn-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_rwarn)
    {
        settings.currency_counter.rate_warn_hours := 6
        IniWrite, % settings.currency_counter.rate_warn_hours, % Currency_Counter_instance.config_path, settings, rate-warn-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_rstaleminus) || (cHWND = vars.hwnd.settings.currency_counter_rstaleplus)
    {
        delta := (cHWND = vars.hwnd.settings.currency_counter_rstaleplus) ? 1 : -1
        While GetKeyState("LButton", "P")
        {
            settings.currency_counter.rate_stale_hours := Max(settings.currency_counter.rate_warn_hours + 1, settings.currency_counter.rate_stale_hours + delta)
            GuiControl, Text, % vars.hwnd.settings.currency_counter_rstale, % settings.currency_counter.rate_stale_hours
            Sleep, 150
        }
        IniWrite, % settings.currency_counter.rate_stale_hours, % Currency_Counter_instance.config_path, settings, rate-stale-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
    If (cHWND = vars.hwnd.settings.currency_counter_rstale)
    {
        settings.currency_counter.rate_stale_hours := 12
        IniWrite, % settings.currency_counter.rate_stale_hours, % Currency_Counter_instance.config_path, settings, rate-stale-hours
        Currency_Counter_instance.Settings_menu("refresh")
        If WinExist("ahk_id " vars.hwnd.cc_logs.main)
            CurrencyCounter_Logs()
        Return
    }
}
;================SETTINGS END============