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
    Name = "ptz_preset",
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
  -- Every button carries the camera's control name with dots swapped for
  -- underscores (see CtlName), which is also the spelling external control
  -- expects.
  local ptzButtons = {
    {name = "pan_left_tilt_up",    icon = "Arrow Left-Up"},
    {name = "tilt_up",             icon = "Arrow Up"},
    {name = "pan_right_tilt_up",   icon = "Arrow Right-Up"},
    {name = "pan_left",            icon = "Arrow Left"},
    {name = "pan_right",           icon = "Arrow Right"},
    {name = "pan_left_tilt_down",  icon = "Arrow Left-Down"},
    {name = "tilt_down",           icon = "Arrow Down"},
    {name = "pan_right_tilt_down", icon = "Arrow Right-Down"},
    {name = "zoom_in",             icon = "Zoom In"},
    {name = "zoom_out",            icon = "Zoom Out"},
    {name = "focus_far",           icon = "Plus"},   -- Focus In
    {name = "focus_near",          icon = "Minus"}   -- Focus Out
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
    {name = "preset_home_load", icon = "Home"},
    {name = "focus_auto"},
    {name = "preset_home_save_trigger"},
    {name = "preset_private_save_trigger"}
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
    Name = "toggle_privacy",
    ControlType = "Button",
    ButtonType = "Toggle",
    Icon = "Prohibited",
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })

  -- Proxied camera controls ----------------------------------------------------
  -- Emitted from the registry so a control is declared exactly once. Each takes
  -- the camera's own control name via CtlName, so the pin lines up with what it
  -- drives.
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
    def.Name = CtlName(d.name)
    def.Count = 1
    def.UserPin = (d.pin ~= false)
    table.insert(ctrls, def)
  end

  for _, d in ipairs(CamCtls) do EmitCamCtl(d) end
  for _, t in ipairs(CamPageTriggers) do EmitCamCtl({name = t.name, kind = "trigger"}) end

  -- Preview overlay pad -------------------------------------------------------
  -- Drives the same camera controls as the main pad, but these are UI-only:
  -- they carry the camera's own control names and no pin.
  -- Underscored names, NOT the camera's dotted ones: Q-SYS reads a dot as
  -- hierarchy, so "pan.left" and "pan.left.tilt.up" cannot both exist -- the
  -- parent and its children collapse and only four buttons survive.
  local previewPad = {
    {name = "preview_up_left",    icon = "Arrow Left-Up",    pretty = "Pan Left / Tilt Up"},
    {name = "preview_tilt_up",    icon = "Arrow Up",         pretty = "Tilt Up"},
    {name = "preview_up_right",   icon = "Arrow Right-Up",   pretty = "Pan Right / Tilt Up"},
    {name = "preview_pan_left",   icon = "Arrow Left",       pretty = "Pan Left"},
    {name = "preview_pan_right",  icon = "Arrow Right",      pretty = "Pan Right"},
    {name = "preview_down_left",  icon = "Arrow Left-Down",  pretty = "Pan Left / Tilt Down"},
    {name = "preview_tilt_down",  icon = "Arrow Down",       pretty = "Tilt Down"},
    {name = "preview_down_right", icon = "Arrow Right-Down", pretty = "Pan Right / Tilt Down"},
    {name = "preview_zoom_in",    icon = "Zoom In",          pretty = "Zoom In"},
    {name = "preview_zoom_out",   icon = "Zoom Out",         pretty = "Zoom Out"}
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
