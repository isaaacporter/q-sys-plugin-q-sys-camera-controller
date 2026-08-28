  local fmt = string.format
  local pidx = (props["page_index"] and props["page_index"].Value) or 1
  local CurrentPage = PageNames[pidx]

  local CameraCount = props["Camera Count"].Value
  local NumPresets  = props["Num Presets"].Value

  local fs1  = 11   -- all label text on the native pages is 11pt
  local fsM  = 9    -- value text inside a meter
  local h1   = 20
  local hB   = 32
  local rowH = 30

  -- The native camera block is 435px wide and every group box fills it.
  local PLUGIN_W  = 435
  local rightEdge = PLUGIN_W

  -- Camera group geometry (Setup page)
  local camGX, camGY = 0, 44
  local camGW = PLUGIN_W
  local rowY0 = camGY + 28
  local footerY = rowY0 + CameraCount * rowH + 8
  local camGH = (footerY + 26) - camGY + 8

  -- Pan / Tilt / Zoom group geometry (styled like the native QSC camera block)
  -- Designer insets the whole plugin by 4px on the top and sides, so every
  -- position here is 4 less than what its properties panel reports.
  local ptzGX, ptzGY = 0, 0
  local ptzGW  = PLUGIN_W
  -- 4-column x 3-row button grid: three pad columns then a zoom column.
  local padX, padY = 74, 20
  local padPitch   = 35
  local zoomX      = padX + 3 * padPitch          -- 179
  -- Home / Privacy: label, icon, then the red save button.
  local hpLblX, hpIconX, hpSaveX = 214, 265, 300
  local hpLblW, hpIcon, hpSaveW  = 48, 32, 32
  -- Left column: 102-wide labels at x=4 with controls at x=109. Coordinates
  -- sits on its own row above the toggles.
  local lblX, lblW = 4, 102
  local ctlX       = 109
  local coordsY    = 125
  local ptzRow0    = 144       -- first toggle row
  local ptzRowH    = 19
  local ptzGH      = 240

  if CurrentPage == "Setup" then

    -- Title / build info -----------------------------------------------------
    table.insert(graphics, {
      Type = "Text", Text = "Q-SYS Camera Controller", FontSize = 16,
      FontStyle = "Bold", HTextAlign = "Left", Color = Palette.text,
      Position = {0, 4}, Size = {360, 24}
    })
    table.insert(graphics, {
      Type = "Text", Text = "v" .. PluginInfo.BuildVersion, FontSize = fs1,
      HTextAlign = "Right", Color = Palette.Gray,
      Position = {rightEdge - 120, 8}, Size = {120, h1}
    })

    -- Camera selection group -------------------------------------------------
    table.insert(graphics, {
      Type = "GroupBox", Text = "Cameras", FontSize = fs1, HTextAlign = "Left",
      Color = Palette.text, StrokeColor = Palette.Black, StrokeWidth = 1,
      CornerRadius = 8, Position = {camGX, camGY}, Size = {camGW, camGH}
    })

    for r = 0, CameraCount - 1 do
      local i = r + 1
      local y = rowY0 + r * rowH
      layout[fmt("camera_active_%03d", i)] = {
        PrettyName = fmt("Cameras~%d Select", i),
        Legend = tostring(i), Style = "Button",
        Color = {0, 210, 70}, OffColor = {13, 59, 102}, UnlinkOffColor = true,
        Margin = 3, Position = {camGX + 8, y}, Size = {26, 26}
      }
      layout[fmt("camera_select_%03d", i)] = {
        PrettyName = fmt("Cameras~%d Component", i),
        Style = "ComboBox", FontSize = fs1, Color = Palette.White,
        Padding = 2, StrokeWidth = 1,
        Position = {camGX + 40, y + 1}, Size = {camGW - 76, 24}
      }
      layout[fmt("camera_found_%03d", i)] = {
        PrettyName = fmt("Cameras~%d Found", i),
        Style = "Indicator", Color = Palette.Green, OffColor = {16, 40, 24},
        UnlinkOffColor = true, StrokeWidth = 1, Margin = 2,
        Position = {camGX + camGW - 28, y + 4}, Size = {18, 18}
      }
    end

    table.insert(graphics, {Type = "Text", Text = "Active", FontSize = fs1, HTextAlign = "Left", Color = Palette.text, Position = {camGX + 12, footerY + 3}, Size = {48, h1}})
    layout["active_camera_name"] = {
      PrettyName = "Cameras~Active Camera", Style = "Text", FontSize = fs1,
      HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1,
      Position = {camGX + 60, footerY}, Size = {camGW - 72, 26}
    }

    -- Camera Router group ----------------------------------------------------
    local trackTop = camGY + camGH + 14
    local tY  = trackTop + 26
    local tY2 = tY + 30

    table.insert(graphics, {
      Type = "GroupBox", Text = "Camera Router (Optional)", FontSize = fs1, HTextAlign = "Left",
      Color = Palette.text, StrokeColor = Palette.Black, StrokeWidth = 1,
      CornerRadius = 8, Position = {0, trackTop}, Size = {PLUGIN_W, 92}
    })
    table.insert(graphics, {Type = "Text", Text = "Router", FontSize = fs1, HTextAlign = "Left", Color = Palette.text, Position = {12, tY + 3}, Size = {48, h1}})
    layout["router_select"] = {PrettyName = "Router~Component", Style = "ComboBox", FontSize = fs1, Color = Palette.White, Padding = 2, StrokeWidth = 1, Position = {62, tY}, Size = {PLUGIN_W - 62 - 40, 24}}
    layout["router_found"] = {PrettyName = "Router~Found", Style = "Indicator", Color = Palette.Green, OffColor = {16, 40, 24}, UnlinkOffColor = true, StrokeWidth = 1, Margin = 2, Position = {PLUGIN_W - 28, tY + 3}, Size = {18, 18}}

    table.insert(graphics, {Type = "Text", Text = "Output", FontSize = fs1, HTextAlign = "Left", Color = Palette.text, Position = {12, tY2 + 3}, Size = {50, h1}})
    layout["router_output"] = {PrettyName = "Router~Output", Style = "Text", Color = Palette.White, OffColor = Palette.White, UnlinkOffColor = true, FontSize = fs1, HTextAlign = "Center", Padding = 2, StrokeWidth = 1, Position = {66, tY2}, Size = {56, 24}}
    table.insert(graphics, {Type = "Text", Text = "Source", FontSize = fs1, HTextAlign = "Left", Color = Palette.text, Position = {132, tY2 + 3}, Size = {50, h1}})
    layout["tracked_source"] = {PrettyName = "Router~Source", Style = "Text", FontSize = fs1, HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1, Position = {186, tY2}, Size = {PLUGIN_W - 186 - 12, 24}}

  elseif CurrentPage == "Control" then

    -- No page title: the native block starts straight into the first group.
    -- Pan / Tilt / Zoom group ------------------------------------------------
    table.insert(graphics, {
      Type = "GroupBox", Text = "Pan / Tilt / Zoom", FontSize = fs1,
      HTextAlign = "Left", Color = Palette.text, StrokeColor = Palette.Black,
      StrokeWidth = 1, CornerRadius = 8,
      Position = {ptzGX, ptzGY}, Size = {ptzGW, ptzGH}
    })
    table.insert(graphics, {
      Type = "Text", Text = "Pan, Tilt,\nand Zoom\nControls", FontSize = fs1,
      HTextAlign = "Right", Color = Palette.text,
      Position = {4, padY}, Size = {65, 102}
    })

    -- 3x3 directional pad with an empty centre (matches the QSC layout)
    local padR2, padR3 = padY + padPitch, padY + 2 * padPitch
    local pad = {
      ptz_up_left    = {padX,                  padY},
      ptz_tilt_up    = {padX + padPitch,       padY},
      ptz_up_right   = {padX + 2 * padPitch,   padY},
      ptz_pan_left   = {padX,                  padR2},
      ptz_pan_right  = {padX + 2 * padPitch,   padR2},
      ptz_down_left  = {padX,                  padR3},
      ptz_tilt_down  = {padX + padPitch,       padR3},
      ptz_down_right = {padX + 2 * padPitch,   padR3}
    }
    local ptzPretty = {
      ptz_up_left    = "Pan-Tilt-Zoom~Pan Left / Tilt Up",
      ptz_tilt_up    = "Pan-Tilt-Zoom~Tilt Up",
      ptz_up_right   = "Pan-Tilt-Zoom~Pan Right / Tilt Up",
      ptz_pan_left   = "Pan-Tilt-Zoom~Pan Left",
      ptz_pan_right  = "Pan-Tilt-Zoom~Pan Right",
      ptz_down_left  = "Pan-Tilt-Zoom~Pan Left / Tilt Down",
      ptz_tilt_down  = "Pan-Tilt-Zoom~Tilt Down",
      ptz_down_right = "Pan-Tilt-Zoom~Pan Right / Tilt Down"
    }
    for name, pos in pairs(pad) do
      layout[name] = {
        PrettyName = ptzPretty[name],
        Legend = "", Style = "Button",
        Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true,
        Margin = 2, Position = {pos[1], pos[2]}, Size = {hB, hB}
      }
    end

    -- Zoom (magnifier icons) -- no column heading, as on the native block
    layout["ptz_zoom_in"]  = {PrettyName = "Pan-Tilt-Zoom~Zoom In",  Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {zoomX, padY},  Size = {hB, hB}}
    layout["ptz_zoom_out"] = {PrettyName = "Pan-Tilt-Zoom~Zoom Out", Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {zoomX, padR2}, Size = {hB, hB}}

    -- Home / Privacy (icon + red save, as on the native camera)
    -- Home on the pad's first row, Privacy on its second; labels centred on the
    -- 32pt buttons, so 8px lower.
    local homeY, privY = padY, padR2
    table.insert(graphics, {Type = "Text", Text = "Home",    FontSize = fs1, HTextAlign = "Right", Color = Palette.text, Position = {hpLblX, homeY + 8}, Size = {hpLblW, 16}})
    table.insert(graphics, {Type = "Text", Text = "Privacy", FontSize = fs1, HTextAlign = "Right", Color = Palette.text, Position = {hpLblX, privY + 8}, Size = {hpLblW, 16}})

    layout["ptz_home"]     = {PrettyName = "Pan-Tilt-Zoom~Home",         Legend = "",             Style = "Button", Color = Palette.btn_green, OffColor = Palette.green_off, UnlinkOffColor = true, Margin = 2, Position = {hpIconX, homeY}, Size = {hpIcon, 32}}
    layout["home_save"]    = {PrettyName = "Pan-Tilt-Zoom~Save Home",    Legend = "Save\nHome",    FontSize = 9, Style = "Button", Color = Palette.Red, Margin = 2, Position = {hpSaveX, homeY}, Size = {hpSaveW, 32}}
    layout["privacy_load"] = {PrettyName = "Pan-Tilt-Zoom~Privacy Mode", Legend = "",             Style = "Button", Color = Palette.btn_green, OffColor = Palette.gray_off, UnlinkOffColor = true, Margin = 2, Position = {hpIconX, privY}, Size = {hpIcon, 32}}
    layout["privacy_save"] = {PrettyName = "Pan-Tilt-Zoom~Save Privacy", Legend = "Save\nPrivacy", FontSize = 9, Style = "Button", Color = Palette.Red, Margin = 2, Position = {hpSaveX, privY}, Size = {hpSaveW, 32}}

    -- Coordinates readout (current ptz.preset position), on its own row above
    -- the toggle rows.
    table.insert(graphics, {Type = "Text", Text = "Coordinates", FontSize = fs1, HTextAlign = "Right", Color = Palette.text, Position = {lblX, coordsY}, Size = {64, 16}})
    layout["coordinates"] = {PrettyName = "Pan-Tilt-Zoom~Coordinates", Style = "Text", FontSize = fsM, HTextAlign = "Center", Color = Palette.White, OffColor = Palette.White, UnlinkOffColor = true, Padding = 1, StrokeWidth = 1, Position = {74, coordsY}, Size = {102, 16}}

    -- Two columns of proxied setup rows: toggles on the left, speeds on the
    -- right. Rendered here rather than from CamGroups because this group's
    -- geometry is bespoke (the 3x3 pad sits above it).
    local function PtzLabel(x, y, w, text)
      table.insert(graphics, {Type = "Text", Text = text, FontSize = fs1,
        HTextAlign = "Right", Color = Palette.text, Position = {x, y}, Size = {w, 16}})
    end
    local function PtzBool(name, pretty, y, x)
      layout[name] = {PrettyName = pretty, Legend = "", Style = "Button",
        Color = Palette.btn_green, OffColor = Palette.green_off, UnlinkOffColor = true,
        Margin = 2, Position = {x, y}, Size = {32, 16}}
    end
    local function PtzMeter(name, pretty, y, x, w)
      layout[name] = {PrettyName = pretty, Style = "Text", FontSize = fsM,
        HTextAlign = "Center", Color = Palette.meter_on, OffColor = Palette.meter_off,
        UnlinkOffColor = true, TextColor = Palette.Black, Padding = 2, StrokeWidth = 1,
        Position = {x, y}, Size = {w, 16}}
    end
    local function PtzLed(name, pretty, y, x)
      layout[name] = {PrettyName = pretty, Style = "Indicator", Color = Palette.green_on,
        OffColor = Palette.green_off, UnlinkOffColor = true, StrokeWidth = 1, Margin = 3,
        Position = {x, y}, Size = {16, 16}}
    end

    -- Left column of toggles, and a separate right column of speed meters that
    -- starts two rows higher -- the speeds run alongside the pad, so they do not
    -- share a row grid with the toggles.
    local spdLblX, spdLblW = 179, 83
    local spdX, spdW       = 265, 166
    local spdRow0          = 106

    local r = ptzRow0
    PtzLabel(lblX, r, lblW, "Speed By Zoom");  PtzBool("setup.speed.by.zoom", "Pan-Tilt-Zoom~Speed By Zoom", r, ctlX)
    r = r + ptzRowH
    PtzLabel(lblX, r, lblW, "Recalibrate PTZ")
    layout["ptz.recalibrate"] = {PrettyName = "Pan-Tilt-Zoom~Recalibrate PTZ", Legend = "", Style = "Button",
      Color = Palette.White, OffColor = Palette.gray_off, UnlinkOffColor = true,
      Margin = 2, Position = {ctlX, r}, Size = {32, 16}}
    r = r + ptzRowH
    PtzLabel(lblX, r, lblW, "Ceiling Mount");  PtzBool("setup.ceiling.mount", "Pan-Tilt-Zoom~Ceiling Mount", r, ctlX)
    r = r + ptzRowH
    PtzLabel(lblX, r, lblW, "Is Moving");      PtzLed("is_moving", "Pan-Tilt-Zoom~Is Moving", r, ctlX)
    r = r + ptzRowH
    PtzLabel(lblX, r, lblW, "Move Completed"); PtzLed("move.completed", "Pan-Tilt-Zoom~Move Completed", r, ctlX)

    local SPEEDS = {
      {"setup.pan.speed",            "Pan-Tilt-Zoom~Pan Speed",    "Pan Speed"},
      {"setup.tilt.speed",           "Pan-Tilt-Zoom~Tilt Speed",   "Tilt Speed"},
      {"setup.zoom.speed",           "Pan-Tilt-Zoom~Zoom Speed",   "Zoom Speed"},
      {"aaaa.setup.snapshot.speed",  "Pan-Tilt-Zoom~Recall Speed", "Recall Speed"}
    }
    for i, s in ipairs(SPEEDS) do
      local sy = spdRow0 + (i - 1) * ptzRowH
      PtzLabel(spdLblX, sy, spdLblW, s[3])
      PtzMeter(s[1], s[2], sy, spdX, spdW)
    end

    -- Focus group -------------------------------------------------------------
    local focusTop = 256                   -- reports as 260
    local focusGH  = 94
    table.insert(graphics, {
      Type = "GroupBox", Text = "Focus", FontSize = fs1, HTextAlign = "Left",
      Color = Palette.text, StrokeColor = Palette.Black, StrokeWidth = 1,
      CornerRadius = 8, Position = {ptzGX, focusTop}, Size = {PLUGIN_W, focusGH}
    })
    -- Mode cluster: AF under "Auto", In/Out under "Manual", as on the native
    -- block. These buttons used to sit beside Zoom in the PTZ group.
    -- Mode / In / Out head their buttons; Auto / Manual caption them.
    local afX, inX, outX = 74, 109, 144
    local fHeadY, fBtnY, fCapY = 276, 295, 330
    table.insert(graphics, {Type = "Text", Text = "Mode", FontSize = fs1, HTextAlign = "Right",  Color = Palette.text, Position = {71,   fHeadY}, Size = {35, 16}})
    table.insert(graphics, {Type = "Text", Text = "In",   FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {inX,  fHeadY}, Size = {hB, 16}})
    table.insert(graphics, {Type = "Text", Text = "Out",  FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {outX, fHeadY}, Size = {hB, 16}})
    layout["ptz_af"]        = {PrettyName = "Focus~AF",  Legend = "AF", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {afX,  fBtnY}, Size = {hB, hB}}
    layout["ptz_focus_in"]  = {PrettyName = "Focus~In",  Legend = "",   Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {inX,  fBtnY}, Size = {hB, hB}}
    layout["ptz_focus_out"] = {PrettyName = "Focus~Out", Legend = "",   Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {outX, fBtnY}, Size = {hB, hB}}
    table.insert(graphics, {Type = "Text", Text = "Auto",   FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {afX, fCapY}, Size = {32, 16}})
    table.insert(graphics, {Type = "Text", Text = "Manual", FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {inX, fCapY}, Size = {67, 16}})

    -- Focus option boxes are 160x16 at x=262, labels 80 wide at x=179.
    local foX, foW = 262, 160
    local function FocusLabel(y, text)
      table.insert(graphics, {Type = "Text", Text = text, FontSize = fs1,
        HTextAlign = "Right", Color = Palette.text, Position = {179, y}, Size = {80, 16}})
    end
    FocusLabel(276, "Manual Speed")
    PtzMeter("setup.focus.speed", "Focus~Manual Speed", 276, foX, foW)
    FocusLabel(295, "AF Sensitivity")
    layout["setup.focus.sensitivity"] = {PrettyName = "Focus~AF Sensitivity", Style = "ComboBox",
      FontSize = fsM, HTextAlign = "Center", Color = Palette.White, Padding = 2,
      StrokeWidth = 1, Position = {foX, 295}, Size = {foW, 16}}
    FocusLabel(314, "AF Zone")
    layout["setup.focus.zone"] = {PrettyName = "Focus~AF Zone", Style = "ComboBox",
      FontSize = fsM, HTextAlign = "Center", Color = Palette.White, Padding = 2,
      StrokeWidth = 1, Position = {foX, 314}, Size = {foW, 16}}

    -- Presets group (right column, under the PTZ block; single row of presets)
    if NumPresets > 0 then
      local presetGX  = ptzGX
      local presetTop = focusTop + focusGH + 12
      local btnX0     = presetGX + 12
      local btnRow    = presetTop + 28
      local presetGW  = PLUGIN_W
      -- Wrap onto as many rows as the 435px width needs.
      local perRow    = math.max(1, math.floor((presetGW - 24) / hB))
      local presetRows = math.ceil(NumPresets / perRow)
      local presetGH  = (btnRow + presetRows * hB) - presetTop + 10

      table.insert(graphics, {
        Type = "GroupBox", Text = "Presets", FontSize = fs1, HTextAlign = "Left",
        Color = Palette.text, StrokeColor = Palette.Black, StrokeWidth = 1,
        CornerRadius = 8, Position = {ptzGX, presetTop}, Size = {presetGW, presetGH}
      })
      table.insert(graphics, {Type = "Text", Text = "tap = recall   hold = save", FontSize = fs1, HTextAlign = "Center", Color = Palette.Gray, Position = {presetGX + 80, presetTop + 2}, Size = {presetGW - 240, h1}})
      table.insert(graphics, {Type = "Text", Text = "Preset Saved", FontSize = fs1, HTextAlign = "Right", Color = Palette.text, Position = {presetGX + presetGW - 150, presetTop + 2}, Size = {120, h1}})
      layout["preset_saved"] = {PrettyName = "Presets~Saved", Style = "Indicator", Color = Palette.cti_amber, OffColor = {60, 46, 16}, UnlinkOffColor = true, StrokeWidth = 1, Margin = 2, Position = {presetGX + presetGW - 26, presetTop + 4}, Size = {18, 18}}

      for p = 1, NumPresets do
        local col = (p - 1) % perRow
        local row = math.floor((p - 1) / perRow)
        layout[fmt("preset_%03d", p)] = {
          PrettyName = fmt("Presets~%d", p), Legend = tostring(p),
          Style = "Button", Color = Palette.green_on, OffColor = Palette.ptz_off,
          UnlinkOffColor = true, Margin = 3,
          Position = {btnX0 + col * hB, btnRow + row * hB}, Size = {hB, hB}
        }
      end
    end

  else

    -- Every remaining page (Imaging, Auto Framing, IP Streams, Status) is
    -- rendered entirely from the registry.
    -- Group boxes and rows are rendered from the CamCtls registry, so the page
    -- is defined by data rather than by positions repeated per control.
    local GRP_W   = 433   -- group boxes on these pages are 433 wide
    local rowStep = 19
    local ctlH    = 16
    -- Two-column grid: label then a 128-wide control in each half.
    local COL = {
      {lblX = 4,   lblW = 64, ctlX = 71,  ctlW = 128},
      {lblX = 202, lblW = 96, ctlX = 301, ctlW = 128}
    }
    local lblW1 = 240     -- label width in a single-column group

    local function PlaceLabel(x, y, w, text)
      table.insert(graphics, {
        Type = "Text", Text = text, FontSize = fs1, HTextAlign = "Right",
        Color = Palette.text, Position = {x, y}, Size = {w, 16}
      })
    end

    -- int/float render as a text box over a meter fill; ro mirrors the camera's
    -- own formatted string and is drawn dimmed, as the native block draws a
    -- value you cannot set.
    local function PlaceCtl(d, x, y, w)
      if d.kind == "int" or d.kind == "float" then
        layout[d.name] = {PrettyName = d.pretty, Style = "Text", FontSize = fsM,
          HTextAlign = "Center", Color = Palette.meter_on, OffColor = Palette.meter_off,
          UnlinkOffColor = true, TextColor = Palette.Black, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "enum" then
        layout[d.name] = {PrettyName = d.pretty, Style = "ComboBox", FontSize = fsM,
          HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "ro" then
        local fill = d.fill or Palette.White
        layout[d.name] = {PrettyName = d.pretty, Style = "Text", FontSize = fsM,
          HTextAlign = "Center", Color = fill, OffColor = fill,
          UnlinkOffColor = true, TextColor = Palette.Black, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "text" then
        layout[d.name] = {PrettyName = d.pretty, Style = "Text", FontSize = fsM,
          HTextAlign = "Center", Color = Palette.White, OffColor = Palette.White,
          UnlinkOffColor = true, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "status" then
        layout[d.name] = {PrettyName = d.pretty, Style = "Text", FontSize = fs1,
          HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "led" then
        layout[d.name] = {PrettyName = d.pretty, Style = "Indicator",
          Color = Palette.Green, OffColor = {16, 40, 24}, UnlinkOffColor = true,
          StrokeWidth = 1, Margin = 2, Position = {x, y + 2}, Size = {18, 18}}
      elseif d.kind == "bool" then
        -- legendOff is the starting caption; the runtime swaps it with the state.
        layout[d.name] = {PrettyName = d.pretty, Legend = d.legend or d.legendOff or "",
          FontSize = fsM, Style = "Button",
          Color = Palette.btn_green, OffColor = Palette.green_off, UnlinkOffColor = true,
          Margin = 2, Position = {x, y}, Size = {d.w or 32, ctlH}}
      elseif d.kind == "statetrig" then
        layout[d.name] = {PrettyName = d.pretty, Legend = "", Style = "Button",
          Color = Palette.btn_green, OffColor = Palette.gray_off, UnlinkOffColor = true,
          Margin = 2, Position = {x, y}, Size = {math.min(w, 32), ctlH}}
      elseif d.kind == "trigger" then
        layout[d.name] = {PrettyName = d.pretty, Legend = "", Style = "Button",
          Color = Palette.White, OffColor = Palette.gray_off, UnlinkOffColor = true,
          Margin = 2, Position = {x, y}, Size = {math.min(w, 32), ctlH}}
      end
    end

    -- Page-level trigger sits above the first group, as on the native block:
    -- a 400-wide label on row 0 with a 32x16 button at x=403.
    local y = 0
    for _, t in ipairs(CamPageTriggers) do
      if t.page == CurrentPage then
        PlaceLabel(0, y, 400, t.label)
        layout[t.name] = {PrettyName = t.pretty, Legend = "", Style = "Button",
          Color = Palette.White, OffColor = Palette.gray_off, UnlinkOffColor = true,
          Margin = 2, Position = {403, y}, Size = {32, 16}}
        y = y + 16
      end
    end

    -- Paired-column geometry, used by the IP Streams table. A pairs group
    -- carries its own columns; this is only the fallback.
    local PAIR_DEFAULT = {{ctlX = 107, ctlW = 120}, {ctlX = 272, ctlW = 160}}
    local function PairCol(g, c) return (g.cols or PAIR_DEFAULT)[c] or PAIR_DEFAULT[c] end

    for _, g in ipairs(CamGroups) do
      if g.page == CurrentPage then
        -- A group with measured y/h/w uses them; the rest stack automatically.
        local gy = g.y or y
        local gh = g.h or (11 + g.rows * rowStep)
        table.insert(graphics, {
          Type = "GroupBox", Text = g.name, FontSize = fs1, HTextAlign = "Left",
          Color = Palette.text, StrokeColor = Palette.Black, StrokeWidth = 1,
          CornerRadius = 8, Position = {0, gy}, Size = {g.w or GRP_W, gh}
        })
        -- Column headings above a paired table.
        if g.headers then
          for c, text in ipairs(g.headers) do
            local cc = PairCol(g, c)
            -- A heading may be narrower than its column (Preview Stream sits
            -- beside the Enable button).
            table.insert(graphics, {
              Type = "Text", Text = text, FontSize = fs1,
              HTextAlign = "Center", Color = Palette.text,
              Position = {cc.hdrX or cc.ctlX, gy + 20}, Size = {cc.hdrW or cc.ctlW, 16}
            })
          end
        end
        for _, d in ipairs(CamCtls) do
          if d.page == CurrentPage and d.group == g.name then
            local ry = gy + 20 + (d.row - 1) * rowStep
            if g.style == "pairs" then
              local cc = PairCol(g, d.col)
              if d.rowlabel then PlaceLabel(4, ry, g.lblW or 100, d.rowlabel) end
              PlaceCtl(d, d.x or cc.ctlX, ry, d.w or cc.ctlW)
            elseif g.style == "cols1" then
              local c = (g.cols and g.cols[1]) or
                        {lblX = 4, lblW = lblW1, ctlX = 4 + lblW1 + 12,
                         ctlW = GRP_W - (4 + lblW1 + 12) - 8}
              if d.label ~= "" then PlaceLabel(c.lblX, ry, c.lblW, d.label) end
              PlaceCtl(d, d.x or c.ctlX, ry, d.w or c.ctlW)
            else
              -- A group may override the default column geometry.
              local c = (g.cols or COL)[d.col]
              if d.label ~= "" then PlaceLabel(c.lblX, ry, c.lblW, d.label) end
              PlaceCtl(d, d.x or c.ctlX, ry, d.w or c.ctlW)
            end
          end
        end
        -- Static captions that belong to a row but have no control of their own.
        for _, t2 in ipairs(CamTexts) do
          if t2.page == CurrentPage and t2.group == g.name then
            table.insert(graphics, {
              Type = "Text", Text = t2.text, FontSize = t2.fs or fs1,
              HTextAlign = t2.align or "Left", Color = Palette.text,
              Position = {t2.x, gy + 20 + (t2.row - 1) * rowStep}, Size = {t2.w, 16}
            })
          end
        end
        y = gy + gh + 12
      end
    end

  end
