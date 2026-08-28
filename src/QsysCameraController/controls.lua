  local fmt = string.format
  local CameraCount = props["Camera Count"].Value
  local NumPresets  = props["Num Presets"].Value

  -- Camera selection -----------------------------------------------------------
  table.insert(ctrls, {
    Name = "active_camera_name",
    ControlType = "Indicator",
    IndicatorType = "Text",
    PinStyle = "Output",
    Count = 1,
    UserPin = true
  })
  -- Hidden, persistent storage for numbered preset coordinates (JSON).
  table.insert(ctrls, {
    Name = "preset_store",
    ControlType = "Text",
    Count = 1,
    UserPin = false
  })
  -- Status indicators
  table.insert(ctrls, {
    Name = "is_moving",
    ControlType = "Indicator",
    IndicatorType = "Led",
    DefaultValue = false,
    Count = 1,
    UserPin = true,
    PinStyle = "Output"
  })
  table.insert(ctrls, {
    Name = "preset_saved",
    ControlType = "Indicator",
    IndicatorType = "Led",
    DefaultValue = false,
    Count = 1,
    UserPin = true,
    PinStyle = "Output"
  })
  table.insert(ctrls, {
    Name = "coordinates",
    ControlType = "Text",
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })

  -- Camera tracking via a router / mediacast router
  table.insert(ctrls, {
    Name = "router_select",
    ControlType = "Text",
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })
  table.insert(ctrls, {
    Name = "router_output",
    ControlType = "Knob",
    ControlUnit = "Integer",
    Min = 1,
    Max = 64,
    DefaultValue = 1,
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })
  table.insert(ctrls, {
    Name = "router_found",
    ControlType = "Indicator",
    IndicatorType = "Led",
    DefaultValue = false,
    Count = 1,
    UserPin = true,
    PinStyle = "Output"
  })
  table.insert(ctrls, {
    Name = "tracked_source",
    ControlType = "Indicator",
    IndicatorType = "Text",
    Count = 1,
    UserPin = true,
    PinStyle = "Output"
  })

  for i = 1, CameraCount do
    table.insert(ctrls, {
      Name = fmt("camera_active_%03d", i),
      ControlType = "Button",
      ButtonType = "Toggle",
      Count = 1,
      UserPin = true,
      PinStyle = "Both"
    })
    table.insert(ctrls, {
      Name = fmt("camera_select_%03d", i),
      ControlType = "Text",
      Count = 1,
      UserPin = true,
      PinStyle = "Both"
    })
    table.insert(ctrls, {
      Name = fmt("camera_found_%03d", i),
      ControlType = "Indicator",
      IndicatorType = "Led",
      DefaultValue = false,
      Count = 1,
      UserPin = true,
      PinStyle = "Output"
    })
  end

  -- Shared Pan / Tilt / Zoom / Focus -------------------------------------------
  -- Built-in icons must be declared on the control (not the layout).
  local ptzButtons = {
    {name = "ptz_up_left",    icon = "Arrow Left-Up"},
    {name = "ptz_tilt_up",    icon = "Arrow Up"},
    {name = "ptz_up_right",   icon = "Arrow Right-Up"},
    {name = "ptz_pan_left",   icon = "Arrow Left"},
    {name = "ptz_pan_right",  icon = "Arrow Right"},
    {name = "ptz_down_left",  icon = "Arrow Left-Down"},
    {name = "ptz_tilt_down",  icon = "Arrow Down"},
    {name = "ptz_down_right", icon = "Arrow Right-Down"},
    {name = "ptz_zoom_in",    icon = "Zoom In"},
    {name = "ptz_zoom_out",   icon = "Zoom Out"},
    {name = "ptz_focus_in",  icon = "Plus"},
    {name = "ptz_focus_out", icon = "Minus"}
  }
  for _, b in ipairs(ptzButtons) do
    local def = {
      Name = b.name,
      ControlType = "Button",
      ButtonType = "Momentary",
      Count = 1,
      UserPin = true,
      PinStyle = "Input"
    }
    if b.icon then def.Icon = b.icon end
    table.insert(ctrls, def)
  end

  -- Home / Privacy -------------------------------------------------------------
  local triggerButtons = {
    {name = "ptz_home", icon = "Home"},
    {name = "ptz_af"},
    {name = "home_save"},
    {name = "privacy_save"}
  }
  for _, b in ipairs(triggerButtons) do
    local def = {
      Name = b.name,
      ControlType = "Button",
      ButtonType = "Trigger",
      Count = 1,
      UserPin = true,
      PinStyle = "Input"
    }
    if b.icon then def.Icon = b.icon end
    table.insert(ctrls, def)
  end

  -- Privacy is a toggle reflecting the camera's privacy mode.
  table.insert(ctrls, {
    Name = "privacy_load",
    ControlType = "Button",
    ButtonType = "Toggle",
    Icon = "Prohibited",
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })

  -- Proxied camera controls ----------------------------------------------------
  -- Emitted from the registry so a control is declared exactly once. Each keeps
  -- the camera's own control name, so the pin lines up with what it drives.
  local KIND_DEF = {
    int       = function(d) return {ControlType = "Knob", ControlUnit = "Integer", Min = d.min, Max = d.max, DefaultValue = d.min, PinStyle = "Both"} end,
    float     = function(d) return {ControlType = "Knob", ControlUnit = "Float",   Min = d.min, Max = d.max, DefaultValue = d.min, PinStyle = "Both"} end,
    text      = function(d) return {ControlType = "Text", PinStyle = "Both"} end,
    bool      = function(d) return {ControlType = "Button", ButtonType = "Toggle", PinStyle = "Both"} end,
    enum      = function(d) return {ControlType = "Text", PinStyle = "Both"} end,
    ro        = function(d) return {ControlType = "Indicator", IndicatorType = "Text", PinStyle = "Output"} end,
    -- A text field the layout presents as a MediaDisplay; the runtime only
    -- feeds it the camera's preview string.
    media     = function(d) return {ControlType = "Text", PinStyle = "Output"} end,
    led       = function(d) return {ControlType = "Indicator", IndicatorType = "Led", DefaultValue = false, PinStyle = "Output"} end,
    status    = function(d) return {ControlType = "Indicator", IndicatorType = "Status", PinStyle = "Output"} end,
    trigger   = function(d) return {ControlType = "Button", ButtonType = "Trigger", PinStyle = "Input"} end,
    -- Momentary rather than Trigger so the lit state can follow <name>.state.
    statetrig = function(d) return {ControlType = "Button", ButtonType = "Momentary", PinStyle = "Both"} end
  }

  local function EmitCamCtl(d)
    local def = KIND_DEF[d.kind](d)
    def.Name = d.name
    def.Count = 1
    def.UserPin = (d.pin ~= false)
    table.insert(ctrls, def)
  end

  for _, d in ipairs(CamCtls) do EmitCamCtl(d) end
  for _, t in ipairs(CamPageTriggers) do EmitCamCtl({name = t.name, kind = "trigger"}) end

  -- Preview overlay pad -------------------------------------------------------
  -- Drives the same camera controls as the main pad, but these are UI-only:
  -- they carry the camera's own control names and no pin.
  local previewPad = {
    {name = "pan.left.tilt.up",    icon = "Arrow Left-Up",    pretty = "Pan Left / Tilt Up"},
    {name = "tilt.up",             icon = "Arrow Up",         pretty = "Tilt Up"},
    {name = "pan.right.tilt.up",   icon = "Arrow Right-Up",   pretty = "Pan Right / Tilt Up"},
    {name = "pan.left",            icon = "Arrow Left",       pretty = "Pan Left"},
    {name = "pan.right",           icon = "Arrow Right",      pretty = "Pan Right"},
    {name = "pan.left.tilt.down",  icon = "Arrow Left-Down",  pretty = "Pan Left / Tilt Down"},
    {name = "tilt.down",           icon = "Arrow Down",       pretty = "Tilt Down"},
    {name = "pan.right.tilt.down", icon = "Arrow Right-Down", pretty = "Pan Right / Tilt Down"},
    {name = "zoom.in",             icon = "Zoom In",          pretty = "Zoom In"},
    {name = "zoom.out",            icon = "Zoom Out",         pretty = "Zoom Out"}
  }
  for _, b in ipairs(previewPad) do
    table.insert(ctrls, {
      Name = b.name,
      ControlType = "Button",
      ButtonType = "Momentary",
      Icon = b.icon,
      Count = 1,
      UserPin = false
    })
  end

  -- Numbered presets (tap = recall, hold = save). The button itself lights
  -- (its .Boolean is driven) when the camera is at that stored position.
  for p = 1, NumPresets do
    table.insert(ctrls, {
      Name = fmt("preset_%03d", p),
      ControlType = "Button",
      ButtonType = "Momentary",
      Count = 1,
      UserPin = true,
      PinStyle = "Both"
    })
  end
