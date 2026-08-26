  local fmt = string.format
  local pidx = (props["page_index"] and props["page_index"].Value) or 1
  local CurrentPage = PageNames[pidx]

  local CameraCount = props["Camera Count"].Value
  local NumPresets  = props["Num Presets"].Value

  local fs1  = 11   -- all label text on the native pages is 11pt
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
  local ptzGX, ptzGY = 0, 8
  local ptzGW  = PLUGIN_W
  local padX, padY = ptzGX + 100, ptzGY + 30
  local zoomX  = padX + 3 * hB + 10
  -- Focus In / Out / AF live in the Focus group, as on the native block, so the
  -- Home / Privacy column follows straight after the zoom column.
  local hpX    = zoomX + hB + 20
  local hpLblW, hpIcon, hpSaveW = 46, 32, 32
  -- Pad rows, then Coordinates, then two columns of setup rows and speeds.
  local ptzRow0 = 168          -- first row of the two-column block
  local ptzRowH = 20
  local ptzGH   = (ptzRow0 + 5 * ptzRowH + 8) - ptzGY

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
      Type = "Text", Text = "Pan, Tilt, and\nZoom Controls", FontSize = fs1,
      HTextAlign = "Center", Color = Palette.text,
      Position = {ptzGX + 8, padY + 16}, Size = {90, 48}
    })

    -- 3x3 directional pad with an empty centre (matches the QSC layout)
    local pad = {
      ptz_up_left    = {padX,          padY},
      ptz_tilt_up    = {padX + hB,     padY},
      ptz_up_right   = {padX + 2 * hB, padY},
      ptz_pan_left   = {padX,          padY + hB},
      ptz_pan_right  = {padX + 2 * hB, padY + hB},
      ptz_down_left  = {padX,          padY + 2 * hB},
      ptz_tilt_down  = {padX + hB,     padY + 2 * hB},
      ptz_down_right = {padX + 2 * hB, padY + 2 * hB}
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
    layout["ptz_zoom_in"]  = {PrettyName = "Pan-Tilt-Zoom~Zoom In",  Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {zoomX, padY},      Size = {hB, hB}}
    layout["ptz_zoom_out"] = {PrettyName = "Pan-Tilt-Zoom~Zoom Out", Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {zoomX, padY + hB}, Size = {hB, hB}}

    -- Home / Privacy (icon + red save, as on the native camera)
    local homeY = padY + 6
    local privY = padY + hB + 14
    table.insert(graphics, {Type = "Text", Text = "Home",    FontSize = fs1, HTextAlign = "Right", Color = Palette.text, Position = {hpX, homeY + 4}, Size = {hpLblW, h1}})
    table.insert(graphics, {Type = "Text", Text = "Privacy", FontSize = fs1, HTextAlign = "Right", Color = Palette.text, Position = {hpX, privY + 4}, Size = {hpLblW, h1}})

    layout["ptz_home"]     = {PrettyName = "Pan-Tilt-Zoom~Home",         Legend = "",             Style = "Button", Color = Palette.green_on, OffColor = Palette.green_off, UnlinkOffColor = true, Margin = 2, Position = {hpX + 52,        homeY}, Size = {hpIcon, 32}}
    layout["home_save"]    = {PrettyName = "Pan-Tilt-Zoom~Save Home",    Legend = "Save\nHome",    FontSize = 9, Style = "Button", Color = Palette.Red, Margin = 2, Position = {hpX + 52 + hpIcon + 4, homeY}, Size = {hpSaveW, 32}}
    layout["privacy_load"] = {PrettyName = "Pan-Tilt-Zoom~Privacy Mode", Legend = "",             Style = "Button", Color = Palette.green_on, OffColor = Palette.gray_off, UnlinkOffColor = true, Margin = 2, Position = {hpX + 52,        privY}, Size = {hpIcon, 32}}
    layout["privacy_save"] = {PrettyName = "Pan-Tilt-Zoom~Save Privacy", Legend = "Save\nPrivacy", FontSize = 9, Style = "Button", Color = Palette.Red, Margin = 2, Position = {hpX + 52 + hpIcon + 4, privY}, Size = {hpSaveW, 32}}

    -- Coordinates readout (current ptz.preset position)
    local coordsY = padY + 3 * hB + 8
    table.insert(graphics, {Type = "Text", Text = "Coordinates", FontSize = fs1, HTextAlign = "Right", Color = Palette.text, Position = {4, coordsY - 2}, Size = {100, h1}})
    layout["coordinates"] = {PrettyName = "Pan-Tilt-Zoom~Coordinates", Style = "Text", FontSize = fs1, HTextAlign = "Center", Color = Palette.White, OffColor = Palette.White, UnlinkOffColor = true, Padding = 2, StrokeWidth = 1, Position = {108, coordsY}, Size = {102, 16}}

    -- Two columns of proxied setup rows: toggles on the left, speeds on the
    -- right. Rendered here rather than from CamGroups because this group's
    -- geometry is bespoke (the 3x3 pad sits above it).
    -- A 20pt label box centred on a 16pt control sits 2px higher.
    local function PtzLabel(x, y, w, text)
      table.insert(graphics, {Type = "Text", Text = text, FontSize = fs1,
        HTextAlign = "Right", Color = Palette.text, Position = {x, y - 2}, Size = {w, h1}})
    end
    local function PtzBool(name, pretty, y, x)
      layout[name] = {PrettyName = pretty, Legend = "", Style = "Button",
        Color = Palette.green_on, OffColor = Palette.green_off, UnlinkOffColor = true,
        Margin = 2, Position = {x, y}, Size = {32, 16}}
    end
    local function PtzMeter(name, pretty, y, x, w)
      layout[name] = {PrettyName = pretty, Style = "Text", FontSize = fs1,
        HTextAlign = "Center", Color = Palette.speed_on, OffColor = Palette.meter_off,
        UnlinkOffColor = true, TextColor = Palette.Black, Padding = 2, StrokeWidth = 1,
        Position = {x, y}, Size = {w, 16}}
    end
    local function PtzLed(name, pretty, y, x)
      layout[name] = {PrettyName = pretty, Style = "Indicator", Color = Palette.green_on,
        OffColor = Palette.green_off, UnlinkOffColor = true, StrokeWidth = 1, Margin = 3,
        Position = {x, y}, Size = {16, 16}}
    end

    local lc, rc = 4, 145          -- left / right label columns
    local lcW, rcW = 100, 115
    local lcX, rcX = 108, 265      -- where each column's control starts
    local spdW = 166               -- speed meters

    local r = ptzRow0
    PtzLabel(lc, r, lcW, "Speed By Zoom");  PtzBool("setup.speed.by.zoom", "Pan-Tilt-Zoom~Speed By Zoom", r, lcX)
    PtzLabel(rc, r, rcW, "Pan Speed");      PtzMeter("setup.pan.speed", "Pan-Tilt-Zoom~Pan Speed", r, rcX, spdW)
    r = r + ptzRowH
    PtzLabel(lc, r, lcW, "Recalibrate PTZ")
    layout["ptz.recalibrate"] = {PrettyName = "Pan-Tilt-Zoom~Recalibrate PTZ", Legend = "", Style = "Button",
      Color = Palette.green_on, OffColor = Palette.gray_off, UnlinkOffColor = true,
      Margin = 2, Position = {lcX, r}, Size = {32, 16}}
    PtzLabel(rc, r, rcW, "Tilt Speed");     PtzMeter("setup.tilt.speed", "Pan-Tilt-Zoom~Tilt Speed", r, rcX, spdW)
    r = r + ptzRowH
    PtzLabel(lc, r, lcW, "Ceiling Mount");  PtzBool("setup.ceiling.mount", "Pan-Tilt-Zoom~Ceiling Mount", r, lcX)
    PtzLabel(rc, r, rcW, "Zoom Speed");     PtzMeter("setup.zoom.speed", "Pan-Tilt-Zoom~Zoom Speed", r, rcX, spdW)
    r = r + ptzRowH
    PtzLabel(lc, r, lcW, "Is Moving");      PtzLed("is_moving", "Pan-Tilt-Zoom~Is Moving", r, lcX)
    PtzLabel(rc, r, rcW, "Recall Speed");   PtzMeter("aaaa.setup.snapshot.speed", "Pan-Tilt-Zoom~Recall Speed", r, rcX, spdW)
    r = r + ptzRowH
    PtzLabel(lc, r, lcW, "Move Completed"); PtzLed("move.completed", "Pan-Tilt-Zoom~Move Completed", r, lcX)

    -- Focus group -------------------------------------------------------------
    local focusTop = ptzGY + ptzGH + 12
    local focusGH  = 26 + 18 + hB + 18 + 12
    table.insert(graphics, {
      Type = "GroupBox", Text = "Focus", FontSize = fs1, HTextAlign = "Left",
      Color = Palette.text, StrokeColor = Palette.Black, StrokeWidth = 1,
      CornerRadius = 8, Position = {0, focusTop}, Size = {PLUGIN_W, focusGH}
    })
    -- Mode cluster: AF under "Auto", In/Out under "Manual", as on the native
    -- block. These buttons used to sit beside Zoom in the PTZ group.
    local fBtnY = focusTop + 26 + 16
    local afX, inX, outX = 104, 104 + hB + 6, 104 + 2 * (hB + 6)
    -- Mode / In / Out are column headings above their buttons.
    table.insert(graphics, {Type = "Text", Text = "Mode", FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {afX,  fBtnY - 18}, Size = {hB, h1}})
    table.insert(graphics, {Type = "Text", Text = "In",  FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {inX,  fBtnY - 18}, Size = {hB, h1}})
    table.insert(graphics, {Type = "Text", Text = "Out", FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {outX, fBtnY - 18}, Size = {hB, h1}})
    layout["ptz_af"]        = {PrettyName = "Focus~AF",  Legend = "AF", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {afX,  fBtnY}, Size = {hB, hB}}
    layout["ptz_focus_in"]  = {PrettyName = "Focus~In",  Legend = "",   Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {inX,  fBtnY}, Size = {hB, hB}}
    layout["ptz_focus_out"] = {PrettyName = "Focus~Out", Legend = "",   Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 2, Position = {outX, fBtnY}, Size = {hB, hB}}
    table.insert(graphics, {Type = "Text", Text = "Auto",   FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {afX, fBtnY + hB + 2}, Size = {hB, h1}})
    table.insert(graphics, {Type = "Text", Text = "Manual", FontSize = fs1, HTextAlign = "Center", Color = Palette.text, Position = {inX, fBtnY + hB + 2}, Size = {2 * hB + 6, h1}})

    -- Focus options are all 106x16.
    local foX, foW = 319, 106
    local fy = focusTop + 26
    PtzLabel(200, fy, 115, "Manual Speed")
    PtzMeter("setup.focus.speed", "Focus~Manual Speed", fy, foX, foW)
    fy = fy + ptzRowH
    PtzLabel(200, fy, 115, "AF Sensitivity")
    layout["setup.focus.sensitivity"] = {PrettyName = "Focus~AF Sensitivity", Style = "ComboBox",
      FontSize = fs1, HTextAlign = "Center", Color = Palette.White, Padding = 2,
      StrokeWidth = 1, Position = {foX, fy}, Size = {foW, 16}}
    fy = fy + ptzRowH
    PtzLabel(200, fy, 115, "AF Zone")
    layout["setup.focus.zone"] = {PrettyName = "Focus~AF Zone", Style = "ComboBox",
      FontSize = fs1, HTextAlign = "Center", Color = Palette.White, Padding = 2,
      StrokeWidth = 1, Position = {foX, fy}, Size = {foW, 16}}

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
        CornerRadius = 8, Position = {presetGX, presetTop}, Size = {presetGW, presetGH}
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
    local rowStep = 26
    local ctlH    = 22
    local colGap  = 8
    local colW    = math.floor((PLUGIN_W - 16 - colGap) / 2)
    local lblW2   = 100   -- label width in a two-column group
    local lblW1   = 240   -- label width in a single-column group

    local function ColX(c) return 8 + (c - 1) * (colW + colGap) end

    local function PlaceLabel(x, y, w, text)
      table.insert(graphics, {
        Type = "Text", Text = text, FontSize = fs1, HTextAlign = "Right",
        Color = Palette.text, Position = {x, y + 2}, Size = {w, h1}
      })
    end

    -- int/float render as a text box over a meter fill; ro mirrors the camera's
    -- own formatted string and is drawn dimmed, as the native block draws a
    -- value you cannot set.
    local function PlaceCtl(d, x, y, w)
      if d.kind == "int" or d.kind == "float" then
        layout[d.name] = {PrettyName = d.pretty, Style = "Text", FontSize = fs1,
          HTextAlign = "Center", Color = Palette.meter_on, OffColor = Palette.meter_off,
          UnlinkOffColor = true, TextColor = Palette.White, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "enum" then
        layout[d.name] = {PrettyName = d.pretty, Style = "ComboBox", FontSize = fs1,
          HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "ro" then
        layout[d.name] = {PrettyName = d.pretty, Style = "Text", FontSize = fs1,
          HTextAlign = "Center", Color = Palette.meter_off, OffColor = Palette.meter_off,
          UnlinkOffColor = true, TextColor = Palette.Gray, Padding = 2, StrokeWidth = 1,
          Position = {x, y}, Size = {w, ctlH}}
      elseif d.kind == "text" then
        layout[d.name] = {PrettyName = d.pretty, Style = "Text", FontSize = fs1,
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
        layout[d.name] = {PrettyName = d.pretty, Legend = "", Style = "Button",
          Color = Palette.green_on, OffColor = Palette.green_off, UnlinkOffColor = true,
          Margin = 3, Position = {x, y}, Size = {44, ctlH}}
      elseif d.kind == "trigger" or d.kind == "statetrig" then
        layout[d.name] = {PrettyName = d.pretty, Legend = "", Style = "Button",
          Color = Palette.green_on, OffColor = Palette.gray_off, UnlinkOffColor = true,
          Margin = 3, Position = {x, y}, Size = {math.min(w, 44), ctlH}}
      end
    end

    -- Page-level trigger sits above the first group, as on the native block.
    local y = 8
    for _, t in ipairs(CamPageTriggers) do
      if t.page == CurrentPage then
        PlaceLabel(8, y, PLUGIN_W - 8 - 48 - 12, t.label)
        layout[t.name] = {PrettyName = t.pretty, Legend = "", Style = "Button",
          Color = Palette.green_on, OffColor = Palette.gray_off, UnlinkOffColor = true,
          Margin = 3, Position = {PLUGIN_W - 48, y}, Size = {36, ctlH}}
        y = y + rowStep + 4
      end
    end

    -- Paired-column geometry, used by the IP Streams table.
    local pLblW = 140
    local pColW = 138
    local function PairX(c) return 8 + pLblW + 4 + (c - 1) * (pColW + 4) end

    for _, g in ipairs(CamGroups) do
      if g.page == CurrentPage then
        local gh = 26 + g.rows * rowStep + 8
        table.insert(graphics, {
          Type = "GroupBox", Text = g.name, FontSize = fs1, HTextAlign = "Left",
          Color = Palette.text, StrokeColor = Palette.Black, StrokeWidth = 1,
          CornerRadius = 8, Position = {0, y}, Size = {PLUGIN_W, gh}
        })
        -- Column headings above a paired table.
        if g.headers then
          for c, text in ipairs(g.headers) do
            table.insert(graphics, {
              Type = "Text", Text = text, FontSize = fs1, FontStyle = "Bold",
              HTextAlign = "Center", Color = Palette.text,
              Position = {PairX(c), y + 26}, Size = {pColW, h1}
            })
          end
        end
        for _, d in ipairs(CamCtls) do
          if d.page == CurrentPage and d.group == g.name then
            local ry = y + 26 + (d.row - 1) * rowStep
            if g.style == "pairs" then
              if d.rowlabel then PlaceLabel(8, ry, pLblW, d.rowlabel) end
              local x = d.x and (d.x) or PairX(d.col)
              PlaceCtl(d, x, ry, d.w or pColW)
            elseif g.style == "cols1" then
              if d.label ~= "" then PlaceLabel(8, ry, lblW1, d.label) end
              local x = d.x or (8 + lblW1 + 12)
              PlaceCtl(d, x, ry, d.w or (PLUGIN_W - (8 + lblW1 + 12) - 12))
            else
              local x = ColX(d.col)
              if d.label ~= "" then PlaceLabel(x, ry, lblW2, d.label) end
              PlaceCtl(d, d.x or (x + lblW2 + 4), ry, d.w or (colW - lblW2 - 4))
            end
          end
        end
        y = y + gh + 12
      end
    end

  end
