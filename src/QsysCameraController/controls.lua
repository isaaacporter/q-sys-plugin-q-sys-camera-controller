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

  -- Imaging / Exposure ---------------------------------------------------------
  -- Integer value fields mirrored from the active camera.
  local numFields = {
    {name = "img.brightness", min = 0,  max = 14},
    {name = "exp.comp",       min = -7, max = 7}
  }
  for _, n in ipairs(numFields) do
    table.insert(ctrls, {
      Name = n.name,
      ControlType = "Knob",
      ControlUnit = "Integer",
      Min = n.min,
      Max = n.max,
      DefaultValue = 0,
      Count = 1,
      UserPin = true,
      PinStyle = "Both"
    })
  end

  -- Imaging / White Balance ----------------------------------------------------
  -- Named to match the native QSC camera controls they drive.
  -- Choices are mirrored from the active camera at runtime.
  table.insert(ctrls, {
    Name = "wb.awb.mode",
    ControlType = "Text",
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })
  table.insert(ctrls, {
    Name = "wb.one.push.trigger",
    ControlType = "Button",
    ButtonType = "Trigger",
    Count = 1,
    UserPin = true,
    PinStyle = "Input"
  })

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
