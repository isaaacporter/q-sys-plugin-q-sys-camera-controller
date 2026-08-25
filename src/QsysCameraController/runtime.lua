  local fmt = string.format
  local CameraCount = Properties["Camera Count"].Value
  local NumPresets  = Properties["Num Presets"].Value
  local DebugMode   = Properties["Debug Print"].Value
  local HoldTime    = Properties["Hold to Save (s)"].Value

  local function dbg(...)
    if DebugMode ~= "None" then print("[CamCtrl]", ...) end
  end

  local ok_rj, rapidjson = pcall(require, "rapidjson")
  if not ok_rj or rapidjson == nil then
    rapidjson = rawget(_G, "rapidjson")
    ok_rj = (rapidjson ~= nil)
  end

  -- Each logical button maps to a native QSC camera control name.
  local PTZ_MAP = {
    ptz_pan_left  = "pan.left",
    ptz_pan_right = "pan.right",
    ptz_tilt_up   = "tilt.up",
    ptz_tilt_down = "tilt.down",
    ptz_zoom_in   = "zoom.in",
    ptz_zoom_out  = "zoom.out",
    ptz_focus_in  = "focus.far",   -- Focus In  = focus.far
    ptz_focus_out = "focus.near"   -- Focus Out = focus.near
  }

  -- Diagonals use the dedicated diagonal control, falling back to driving the
  -- two cardinal directions together if a camera lacks it.
  local DIAG_MAP = {
    ptz_up_left    = {ctl = "pan.left.tilt.up",    fallback = {"ptz_tilt_up",   "ptz_pan_left"}},
    ptz_up_right   = {ctl = "pan.right.tilt.up",   fallback = {"ptz_tilt_up",   "ptz_pan_right"}},
    ptz_down_left  = {ctl = "pan.left.tilt.down",  fallback = {"ptz_tilt_down", "ptz_pan_left"}},
    ptz_down_right = {ctl = "pan.right.tilt.down", fallback = {"ptz_tilt_down", "ptz_pan_right"}}
  }

  -- One-shot trigger buttons.
  local TRIGGER_MAP = {
    ptz_home     = "preset.home.load",
    home_save    = "preset.home.save.trigger",
    privacy_save = "preset.private.save.trigger"
  }

  -- Positions are read/written as a coordinate string on this control.
  local COORD_CTRL = "ptz.preset"
  -- Privacy recall toggles this Boolean.
  local PRIVACY_TOGGLE = "toggle.privacy"
  -- Auto white balance mode (a ComboBox on the native camera).
  local WB_MODE = "wb.awb.mode"
  -- The camera normally reports its own Choices; fall back to the known modes so
  -- the combo is never empty on a model that does not.
  local WB_MODE_CHOICES = {"Auto", "Manual", "One Push"}

  local Proxies = {}      -- [slot] = component proxy or nil
  local ActiveIndex = 1
  local Suppress = 0      -- depth counter guarding re-entrant radio writes

  local UpdatePresetHighlights    -- forward declaration (defined below)
  local PresetFbSuppress = false   -- guard while writing preset feedback state
  local CoordFbSuppress = false    -- guard while writing the coordinates readout
  local PrivacyFbSuppress = false  -- guard while writing the privacy toggle state
  local CamFbSuppress = {}         -- [name] = true while writing that control's feedback
  local CamBound = {}              -- [name] = camera currently subscribed for it

  local RouterProxy = nil         -- bound router component, or nil
  local RouterBoundCtl = nil      -- the router control we are subscribed to
  local RouterCtlNames = {}       -- control names present on the bound router
  local RouterSelCtl = nil        -- resolved output-select control for the tracked output
  local RouterSrcCtl = nil        -- resolved routed-source-name control for the tracked output
  local RouteActiveToRouter       -- forward declaration (defined below)
  local RouterApplying = false    -- guard: active change originated from the router

  local function ActiveCam()
    return Proxies[ActiveIndex]
  end

  local function ActiveCamName()
    local sel = Controls[fmt("camera_select_%03d", ActiveIndex)]
    return (sel and sel.String) or ""
  end

  local function HasControl(cam, name)
    local ok, exists = pcall(function() return cam[name] ~= nil end)
    return ok and exists
  end

  -- Write a boolean to a control on the active camera, if it exists.
  local function SetCtl(name, value)
    local cam = ActiveCam()
    if cam == nil then dbg("no active camera") return end
    if not HasControl(cam, name) then dbg("target lacks", name) return end
    local ok, err = pcall(function() cam[name].Boolean = value end)
    if not ok then dbg("error setting", name, err) end
  end

  local function PulseCtl(name)
    SetCtl(name, true)
    SetCtl(name, false)
  end

  local function DriveDiagonal(def, value)
    local cam = ActiveCam()
    if cam == nil then return end
    if HasControl(cam, def.ctl) then
      pcall(function() cam[def.ctl].Boolean = value end)
    else
      for _, logical in ipairs(def.fallback) do
        SetCtl(PTZ_MAP[logical], value)
      end
    end
  end

  -- Reflect the active camera's privacy mode on the toggle button.
  local function UpdatePrivacyNow()
    local cam = ActiveCam()
    local v = false
    if cam and HasControl(cam, PRIVACY_TOGGLE) then
      pcall(function() v = cam[PRIVACY_TOGGLE].Boolean end)
    end
    local ctl = Controls["privacy_load"]
    if ctl then
      PrivacyFbSuppress = true
      if ctl.Boolean ~= v then ctl.Boolean = v end
      PrivacyFbSuppress = false
    end
  end

  -- Mirror one registry control in from the active camera. Every write is
  -- conditional, so a settled control emits no events of its own.
  local function MirrorIn(d)
    local ctl = Controls[d.name]
    if ctl == nil then return end
    local cam = ActiveCam()
    local present = (cam ~= nil) and HasControl(cam, d.name)
    CamFbSuppress[d.name] = true
    if present then
      if d.kind == "int" or d.kind == "float" then
        local v; pcall(function() v = cam[d.name].Value end)
        if v ~= nil and ctl.Value ~= v then ctl.Value = v end
      elseif d.kind == "bool" then
        local v; pcall(function() v = cam[d.name].Boolean end)
        if v ~= nil and ctl.Boolean ~= v then ctl.Boolean = v end
      elseif d.kind == "enum" then
        local ch, s
        pcall(function() ch = cam[d.name].Choices end)
        pcall(function() s  = cam[d.name].String end)
        if (ch == nil or #ch == 0) and d.name == WB_MODE then ch = WB_MODE_CHOICES end
        ctl.Choices = ch or {}
        if s ~= nil and ctl.String ~= s then ctl.String = s end
      elseif d.kind == "ro" then
        -- Aperture, Shutter and friends already arrive formatted (f/1.8, 1/60).
        local s; pcall(function() s = cam[d.name].String end)
        if s ~= nil and ctl.String ~= s then ctl.String = s end
      end
    end
    -- Grey-out follows the camera. A control it does not expose, and every
    -- control while no camera is bound, reads disabled -- which is how the
    -- native block shows a setting that does not apply.
    local want = true
    if present then
      local ok, v = pcall(function() return cam[d.name].IsDisabled end)
      if ok and v ~= nil then want = v else want = false end
    end
    if ctl.IsDisabled ~= want then ctl.IsDisabled = want end
    CamFbSuppress[d.name] = false
  end

  local function MirrorAll()
    for _, d in ipairs(CamCtls) do MirrorIn(d) end
  end

  -- IsDisabled raises no event, so re-read it periodically to catch grey-out
  -- driven by camera controls the plugin has not subscribed to.
  local function RefreshDisabled()
    local cam = ActiveCam()
    for _, d in ipairs(CamCtls) do
      local ctl = Controls[d.name]
      if ctl ~= nil then
        local want = true
        if cam ~= nil and HasControl(cam, d.name) then
          local ok, v = pcall(function() return cam[d.name].IsDisabled end)
          if ok and v ~= nil then want = v else want = false end
        end
        if ctl.IsDisabled ~= want then ctl.IsDisabled = want end
      end
    end
  end

  -- IsDisabled raises no event, so poll slowly to catch changes driven by
  -- controls the plugin has not subscribed to.
  local DisabledTimer = Timer.New()
  DisabledTimer.EventHandler = function() RefreshDisabled() end

  -- ===== Preset store (per camera component name) =====
  -- Persisted as JSON in the hidden "preset_store" control so it survives core
  -- restarts and design saves. Shape: { [cameraName] = { ["0"]="coord", ... } }
  local PresetStore = {}

  local function LoadStore()
    PresetStore = {}
    local raw = Controls["preset_store"] and Controls["preset_store"].String or ""
    if raw ~= "" and ok_rj then
      local ok, decoded = pcall(rapidjson.decode, raw)
      if ok and type(decoded) == "table" then PresetStore = decoded end
    end
  end

  local function SaveStore()
    if not (Controls["preset_store"] and ok_rj) then return end
    local ok, encoded = pcall(rapidjson.encode, PresetStore)
    if ok then Controls["preset_store"].String = encoded end
  end

  -- Preset-saved indicator: flash high for 3s on every save.
  local PresetSavedTimer = Timer.New()
  PresetSavedTimer.EventHandler = function()
    PresetSavedTimer:Stop()
    local ctl = Controls["preset_saved"]
    if ctl and ctl.Boolean then ctl.Boolean = false end
  end
  local function FlashPresetSaved()
    local ctl = Controls["preset_saved"]
    if ctl and not ctl.Boolean then ctl.Boolean = true end
    PresetSavedTimer:Start(3)
  end

  -- Presets are keyed by the camera's *source* identity, not the component
  -- name: a USB bridge reports its connected camera in "peripheral.camera.source",
  -- so presets follow the physical camera. Native cameras key on their own name.
  local function ActiveCamKey()
    local cam = ActiveCam()
    if cam ~= nil and HasControl(cam, "peripheral.camera.source") then
      local s
      pcall(function() s = cam["peripheral.camera.source"].String end)
      if s ~= nil and s ~= "" then return s end
    end
    return ActiveCamName()
  end

  -- Ensure a preset bank exists for the active camera (default "0 0 0").
  local function CheckCamera()
    local key = ActiveCamKey()
    if key == "" then return end
    local bank = PresetStore[key]
    if bank == nil then
      bank = {}
      PresetStore[key] = bank
    end
    local changed = false
    for p = 1, NumPresets do
      if bank[tostring(p)] == nil then bank[tostring(p)] = "0 0 0"; changed = true end
    end
    if changed then SaveStore() end
  end

  -- Tap: recall the stored position.
  local function PresetRecallTap(p)
    local cam = ActiveCam()
    if cam == nil or not HasControl(cam, COORD_CTRL) then return end
    local key = ActiveCamKey()
    local coord = PresetStore[key] and PresetStore[key][tostring(p)]
    if coord ~= nil then
      pcall(function() cam[COORD_CTRL].String = coord end)
      dbg("recall preset", p, key, coord)
    end
  end

  -- Hold: store the current position.
  local function PresetHoldSave(p)
    local cam = ActiveCam()
    if cam == nil or not HasControl(cam, COORD_CTRL) then return end
    CheckCamera()
    local key = ActiveCamKey()
    local coord
    pcall(function() coord = cam[COORD_CTRL].String end)
    if coord ~= nil and PresetStore[key] ~= nil then
      PresetStore[key][tostring(p)] = coord
      SaveStore()
      dbg("save preset", p, key, coord)
    end
    FlashPresetSaved()
    if UpdatePresetHighlights then UpdatePresetHighlights() end
  end

  local function UpdateActiveName()
    local ctl = Controls["active_camera_name"]
    local want = ActiveCamName()
    if ctl and ctl.String ~= want then ctl.String = want end
  end

  -- Active-camera feedback: Is Moving LED, Coordinates readout, and preset
  -- recall highlighting all follow the currently selected camera.
  local MovingBoundCam = nil
  local CoordBoundCam = nil
  local SrcBoundCam = nil
  local PrivBoundCam = nil

  local function UpdateMovingNow()
    local cam = ActiveCam()
    local v = false
    if cam and HasControl(cam, "is.moving") then
      pcall(function() v = cam["is.moving"].Boolean end)
    end
    local ctl = Controls["is_moving"]
    if ctl and ctl.Boolean ~= v then ctl.Boolean = v end
  end

  local function CurrentCoords()
    local cam = ActiveCam()
    if cam and HasControl(cam, COORD_CTRL) then
      local s
      local ok = pcall(function() s = cam[COORD_CTRL].String end)
      if ok then return s end
    end
    return nil
  end

  local function UpdateCoordinatesNow()
    if Controls["coordinates"] then
      local want = CurrentCoords() or ""
      CoordFbSuppress = true
      if Controls["coordinates"].String ~= want then Controls["coordinates"].String = want end
      CoordFbSuppress = false
    end
  end

  -- Light the LED of each preset whose stored coordinate equals the live position.
  UpdatePresetHighlights = function()
    local cur = CurrentCoords()
    local store = PresetStore[ActiveCamKey()] or {}
    PresetFbSuppress = true
    for p = 1, NumPresets do
      local btn = Controls[fmt("preset_%03d", p)]
      if btn ~= nil then
        local saved = store[tostring(p)]
        local want = (cur ~= nil and cur ~= "" and saved ~= nil and saved ~= "" and saved ~= "0 0 0" and saved == cur)
        -- conditional for the same reason as the slot radio: a redundant write
        -- can echo back as an event and restart this update
        if btn.Boolean ~= want then btn.Boolean = want end
      end
    end
    PresetFbSuppress = false
  end

  local function BindActiveFeedback()
    if MovingBoundCam ~= nil and HasControl(MovingBoundCam, "is.moving") then
      pcall(function() MovingBoundCam["is.moving"].EventHandler = nil end)
    end
    MovingBoundCam = nil
    if CoordBoundCam ~= nil and HasControl(CoordBoundCam, COORD_CTRL) then
      pcall(function() CoordBoundCam[COORD_CTRL].EventHandler = nil end)
    end
    CoordBoundCam = nil
    if SrcBoundCam ~= nil and HasControl(SrcBoundCam, "peripheral.camera.source") then
      pcall(function() SrcBoundCam["peripheral.camera.source"].EventHandler = nil end)
    end
    SrcBoundCam = nil
    if PrivBoundCam ~= nil and HasControl(PrivBoundCam, PRIVACY_TOGGLE) then
      pcall(function() PrivBoundCam[PRIVACY_TOGGLE].EventHandler = nil end)
    end
    PrivBoundCam = nil
    for _, d in ipairs(CamCtls) do
      local prev = CamBound[d.name]
      if prev ~= nil and HasControl(prev, d.name) then
        pcall(function() prev[d.name].EventHandler = nil end)
      end
      CamBound[d.name] = nil
    end
    local cam = ActiveCam()
    if cam ~= nil then
      if HasControl(cam, "peripheral.camera.source") then
        pcall(function()
          cam["peripheral.camera.source"].EventHandler = function()
            CheckCamera()
            UpdatePresetHighlights()
          end
        end)
        SrcBoundCam = cam
      end
      if HasControl(cam, PRIVACY_TOGGLE) then
        pcall(function()
          cam[PRIVACY_TOGGLE].EventHandler = function() UpdatePrivacyNow() end
        end)
        PrivBoundCam = cam
      end
      -- Subscribe to every registry control on this camera only. An enum is a
      -- mode control, and a mode change is what drives the camera's grey-out
      -- logic, so re-read the whole page when one changes.
      for _, d in ipairs(CamCtls) do
        if d.kind ~= "trigger" and HasControl(cam, d.name) then
          pcall(function()
            cam[d.name].EventHandler = function()
              if d.kind == "enum" then MirrorAll() else MirrorIn(d) end
            end
          end)
          CamBound[d.name] = cam
        end
      end
      if HasControl(cam, "is.moving") then
        pcall(function()
          cam["is.moving"].EventHandler = function(ctl)
            local out = Controls["is_moving"]
            if out and out.Boolean ~= ctl.Boolean then out.Boolean = ctl.Boolean end
          end
        end)
        MovingBoundCam = cam
      end
      if HasControl(cam, COORD_CTRL) then
        pcall(function()
          cam[COORD_CTRL].EventHandler = function()
            UpdateCoordinatesNow()
            UpdatePresetHighlights()
          end
        end)
        CoordBoundCam = cam
      end
    end
    UpdateMovingNow()
    UpdateCoordinatesNow()
    UpdatePrivacyNow()
    MirrorAll()
    CheckCamera()
    UpdatePresetHighlights()
  end

  local function RebuildProxy(i)
    local sel = Controls[fmt("camera_select_%03d", i)]
    local found = Controls[fmt("camera_found_%03d", i)]
    local name = sel and sel.String or ""
    if name ~= "" then
      local ok, comp = pcall(Component.New, name)
      if ok and comp ~= nil then
        Proxies[i] = comp
        if found and not found.Boolean then found.Boolean = true end
        dbg("bound slot", i, "->", name)
        return
      end
    end
    Proxies[i] = nil
    if found and found.Boolean then found.Boolean = false end
  end

  local function DiscoverCameras()
    local list = {}
    local ok, comps = pcall(Component.GetComponents)
    if not ok or comps == nil then
      dbg("Component.GetComponents failed")
      return list
    end
    for _, c in ipairs(comps) do
      local isCam = false
      if type(c.Type) == "string" then
        local t = string.lower(c.Type)
        if string.find(t, "camera", 1, true) or string.find(t, "uvc", 1, true) then isCam = true end
      end
      if not isCam then
        local ok2, ctrls = pcall(function() return Component.GetControls(Component.New(c.Name)) end)
        if ok2 and ctrls ~= nil then
          for _, ctl in ipairs(ctrls) do
            local n = ctl.Name
            if n == "pan.left" or n == "tilt.up"
               or n == "ptz.preset" or n == "peripheral.camera.source" then
              isCam = true
              break
            end
          end
        end
      end
      if isCam then table.insert(list, c.Name) end
    end
    table.sort(list)
    dbg("found", #list, "cameras")
    return list
  end

  local function RefreshCameraLists()
    local list = DiscoverCameras()
    for i = 1, CameraCount do
      local sel = Controls[fmt("camera_select_%03d", i)]
      if sel ~= nil then
        local choices = {}
        for _, n in ipairs(list) do table.insert(choices, n) end
        local cur = sel.String
        if cur ~= nil and cur ~= "" then
          local present = false
          for _, n in ipairs(choices) do if n == cur then present = true break end end
          if not present then table.insert(choices, cur) end
        end
        sel.Choices = choices
        RebuildProxy(i)
      end
    end
    UpdateActiveName()
  end

  -- Drive the slot radio so exactly one button is lit. Every write is
  -- conditional: Q-Sys fires EventHandler on script writes, so an
  -- unconditional write re-triggers this radio and, when Q-Sys delivers that
  -- event after the Suppress window closes, the handler fights back and two
  -- slots latch on. Writing only on change means a settled radio emits no
  -- events at all, which is what makes it converge.
  local function WriteActiveButtons(i)
    Suppress = Suppress + 1
    for j = 1, CameraCount do
      local b = Controls[fmt("camera_active_%03d", j)]
      local want = (j == i)
      if b ~= nil and b.Boolean ~= want then b.Boolean = want end
    end
    Suppress = Suppress - 1
  end

  local function SetActiveIndex(i)
    ActiveIndex = i
    WriteActiveButtons(i)
    UpdateActiveName()
    BindActiveFeedback()
    if RouteActiveToRouter then RouteActiveToRouter() end
    dbg("active camera slot", i)
  end

  -- ===== Router tracking =====
  -- The active camera follows the source routed to a chosen router output.
  local function RouterOutputNum()
    local n = (Controls["router_output"] and Controls["router_output"].Value) or 1
    n = math.floor(n)
    if n < 1 then n = 1 end
    return n
  end

  -- Router components disagree on control naming: the classic Router and
  -- Router with Mixer expose "select.N", while the MediaCast Router renamed
  -- the same control to "output.N.select". Resolve the name against the bound
  -- component instead of assuming either form.
  local SELECT_FORMS = {"select.%d", "output.%d.select"}

  -- Snapshot the bound router's control names so a renamed readout can be
  -- matched by pattern rather than guessed.
  local function IndexRouterControls()
    RouterCtlNames = {}
    if RouterProxy == nil then return end
    local ok, ctrls = pcall(function() return Component.GetControls(RouterProxy) end)
    if not ok or ctrls == nil then return end
    for _, ctl in ipairs(ctrls) do
      if type(ctl.Name) == "string" then table.insert(RouterCtlNames, ctl.Name) end
    end
    table.sort(RouterCtlNames)
    dbg("router controls:", table.concat(RouterCtlNames, " "))
  end

  local function ResolveSelectCtl(out)
    for _, form in ipairs(SELECT_FORMS) do
      local name = fmt(form, out)
      if HasControl(RouterProxy, name) then return name end
    end
    return nil
  end

  -- Routed-source-name readout: the classic name first, then any control on
  -- this router whose name carries "source", "name" and the output index.
  local function ResolveSourceNameCtl(out)
    local classic = fmt("output.%d.source.name", out)
    if HasControl(RouterProxy, classic) then return classic end
    local tok = "." .. out .. "."
    for _, name in ipairs(RouterCtlNames) do
      local lower = string.lower(name)
      if string.find(lower, "source", 1, true)
         and string.find(lower, "name", 1, true)
         and string.find("." .. lower .. ".", tok, 1, true) then
        return name
      end
    end
    return nil
  end

  local function ResolveRouterCtls()
    RouterSelCtl = nil
    RouterSrcCtl = nil
    if RouterProxy == nil then return end
    local out = RouterOutputNum()
    RouterSelCtl = ResolveSelectCtl(out)
    RouterSrcCtl = ResolveSourceNameCtl(out)
    if RouterSelCtl == nil then
      dbg("router exposes no output-select control for output", out)
    else
      dbg("router output", out, "select control", RouterSelCtl)
    end
  end

  -- Router output select (Integer input index) drives the active slot.
  local function ApplyRouterTracking()
    if RouterProxy == nil then return end
    local k, src
    if RouterSelCtl ~= nil then pcall(function() k   = RouterProxy[RouterSelCtl].Value end) end
    if RouterSrcCtl ~= nil then pcall(function() src = RouterProxy[RouterSrcCtl].String end) end
    local srcCtl = Controls["tracked_source"]
    if srcCtl and srcCtl.String ~= (src or "") then srcCtl.String = src or "" end
    if k ~= nil then
      k = math.floor(k)
      if k >= 1 and k <= CameraCount and k ~= ActiveIndex then
        RouterApplying = true   -- this change came from the router; don't route back
        SetActiveIndex(k)
        RouterApplying = false
      end
    end
  end

  -- Route the active camera to the output: slot index == router input index.
  RouteActiveToRouter = function()
    if RouterApplying or RouterProxy == nil then return end
    if RouterSelCtl == nil then ResolveRouterCtls() end
    local selCtl = RouterSelCtl
    if selCtl ~= nil then
      pcall(function()
        if math.floor((RouterProxy[selCtl].Value or -1)) ~= ActiveIndex then
          RouterProxy[selCtl].Value = ActiveIndex
        end
      end)
      dbg("routed output", RouterOutputNum(), "-> input", ActiveIndex)
    end
  end

  local function UnbindRouter()
    if RouterProxy ~= nil and RouterBoundCtl ~= nil and HasControl(RouterProxy, RouterBoundCtl) then
      pcall(function() RouterProxy[RouterBoundCtl].EventHandler = nil end)
    end
    RouterBoundCtl = nil
  end

  local function BindRouter()
    UnbindRouter()
    if RouterProxy == nil then
      RouterSelCtl = nil
      RouterSrcCtl = nil
      return
    end
    ResolveRouterCtls()
    local selCtl = RouterSelCtl
    if selCtl ~= nil then
      pcall(function()
        RouterProxy[selCtl].EventHandler = function() ApplyRouterTracking() end
      end)
      RouterBoundCtl = selCtl
    end
    ApplyRouterTracking()
  end

  local function RebuildRouterProxy()
    UnbindRouter()
    RouterProxy = nil
    local sel = Controls["router_select"]
    local name = sel and sel.String or ""
    if name ~= "" then
      local ok, comp = pcall(Component.New, name)
      if ok and comp ~= nil then RouterProxy = comp end
    end
    IndexRouterControls()
    local foundCtl = Controls["router_found"]
    if foundCtl and foundCtl.Boolean ~= (RouterProxy ~= nil) then foundCtl.Boolean = (RouterProxy ~= nil) end
    local srcCtl = Controls["tracked_source"]
    if RouterProxy == nil and srcCtl and srcCtl.String ~= "" then srcCtl.String = "" end
    BindRouter()
  end

  -- Find router / mediacast-router components in the design.
  local function DiscoverRouters()
    local list = {}
    local ok, comps = pcall(Component.GetComponents)
    if not ok or comps == nil then return list end
    for _, c in ipairs(comps) do
      local isR = false
      if type(c.Type) == "string" and string.find(string.lower(c.Type), "router", 1, true) then
        isR = true
      end
      if not isR then
        local ok2, ctrls = pcall(function() return Component.GetControls(Component.New(c.Name)) end)
        if ok2 and ctrls ~= nil then
          for _, ctl in ipairs(ctrls) do
            -- "select.1" = classic Router; "output.1.select" = MediaCast Router
            if ctl.Name == "select.1" or ctl.Name == "output.1.select" then isR = true break end
          end
        end
      end
      if isR then table.insert(list, c.Name) end
    end
    table.sort(list)
    return list
  end

  local function RefreshRouterList()
    local sel = Controls["router_select"]
    if sel == nil then return end
    local list = DiscoverRouters()
    local cur = sel.String
    if cur ~= nil and cur ~= "" then
      local present = false
      for _, n in ipairs(list) do if n == cur then present = true break end end
      if not present then table.insert(list, cur) end
    end
    table.insert(list, 1, "")  -- blank option = no tracking
    sel.Choices = list
    RebuildRouterProxy()
  end

  -- ===== Event handlers =====
  if Controls["router_select"] ~= nil then
    Controls["router_select"].EventHandler = function() RebuildRouterProxy() end
  end
  if Controls["router_output"] ~= nil then
    Controls["router_output"].EventHandler = function() BindRouter() end
  end

  for i = 1, CameraCount do
    local sel = Controls[fmt("camera_select_%03d", i)]
    local act = Controls[fmt("camera_active_%03d", i)]
    if sel ~= nil then
      sel.EventHandler = function()
        RebuildProxy(i)
        if i == ActiveIndex then UpdateActiveName(); BindActiveFeedback(); if RouteActiveToRouter then RouteActiveToRouter() end end
      end
    end
    if act ~= nil then
      act.EventHandler = function(ctl)
        if Suppress > 0 then return end
        if ctl.Boolean then
          SetActiveIndex(i)
        else
          -- A slot went low. Never force THIS slot back high: that fights the
          -- radio write and latches two slots on. Re-assert the real active
          -- slot instead -- idempotent, so a correct radio settles silently
          -- and pressing the active slot simply re-lights it.
          WriteActiveButtons(ActiveIndex)
        end
      end
    end
  end

  for name, target in pairs(PTZ_MAP) do
    local ctl = Controls[name]
    if ctl ~= nil then
      ctl.EventHandler = function(c) SetCtl(target, c.Boolean) end
    end
  end

  for name, def in pairs(DIAG_MAP) do
    local ctl = Controls[name]
    if ctl ~= nil then
      ctl.EventHandler = function(c) DriveDiagonal(def, c.Boolean) end
    end
  end

  for name, target in pairs(TRIGGER_MAP) do
    local ctl = Controls[name]
    if ctl ~= nil then
      ctl.EventHandler = function() PulseCtl(target) end
    end
  end

  if Controls["privacy_load"] ~= nil then
    Controls["privacy_load"].EventHandler = function(ctl)
      if PrivacyFbSuppress then return end
      SetCtl(PRIVACY_TOGGLE, ctl.Boolean)
    end
  end

  -- Operator edits go back to the active camera. Read-only entries have no
  -- handler at all, so nothing can be typed into a value the camera owns.
  local function WriteOut(d, c)
    if CamFbSuppress[d.name] then return end
    if d.kind == "trigger" then PulseCtl(d.name) return end
    local cam = ActiveCam()
    if cam == nil or not HasControl(cam, d.name) then return end
    if d.kind == "int" or d.kind == "float" then
      pcall(function() if cam[d.name].Value ~= c.Value then cam[d.name].Value = c.Value end end)
    elseif d.kind == "bool" then
      pcall(function() if cam[d.name].Boolean ~= c.Boolean then cam[d.name].Boolean = c.Boolean end end)
    elseif d.kind == "enum" then
      pcall(function() if cam[d.name].String ~= c.String then cam[d.name].String = c.String end end)
    end
  end

  for _, d in ipairs(CamCtls) do
    local ctl = Controls[d.name]
    if ctl ~= nil and d.kind ~= "ro" then
      ctl.EventHandler = function(c) WriteOut(d, c) end
    end
  end

  for _, t in ipairs(CamPageTriggers) do
    local ctl = Controls[t.name]
    if ctl ~= nil then
      ctl.EventHandler = function() PulseCtl(t.name) end
    end
  end

  if Controls["ptz_af"] ~= nil then
    Controls["ptz_af"].EventHandler = function() PulseCtl("focus.auto") end
  end

  -- Editing the Coordinates field writes the position to the active camera.
  if Controls["coordinates"] ~= nil then
    Controls["coordinates"].EventHandler = function(ctl)
      if CoordFbSuppress then return end
      local cam = ActiveCam()
      if cam ~= nil and HasControl(cam, COORD_CTRL) then
        pcall(function()
          if cam[COORD_CTRL].String ~= ctl.String then cam[COORD_CTRL].String = ctl.String end
        end)
      end
    end
  end

  -- Tap = recall; hold = save the moment the hold time elapses (while held).
  local Saved = {}
  local Countdown = {}
  for p = 1, NumPresets do
    local btn = Controls[fmt("preset_%03d", p)]
    if btn ~= nil then
      Saved[p] = false
      Countdown[p] = Timer.New()
      Countdown[p].EventHandler = function()
        Countdown[p]:Stop()
        PresetHoldSave(p)   -- fires as soon as the hold completes
        Saved[p] = true
      end
      btn.EventHandler = function(ctl)
        if PresetFbSuppress then return end   -- ignore highlight-driven writes
        if ctl.Boolean then
          Saved[p] = false
          Countdown[p]:Start(HoldTime)
        else
          Countdown[p]:Stop()
          if not Saved[p] then PresetRecallTap(p) end
          Saved[p] = false
          UpdatePresetHighlights()
        end
      end
    end
  end

  -- ===== Initialise =====
  DisabledTimer:Start(3)
  LoadStore()
  RefreshCameraLists()

  local initActive = 1
  for j = 1, CameraCount do
    local b = Controls[fmt("camera_active_%03d", j)]
    if b ~= nil and b.Boolean then initActive = j break end
  end
  SetActiveIndex(initActive)

  RefreshRouterList()  -- may override the active camera if a router is tracking
