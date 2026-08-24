  local fmt = string.format
  local pidx = (props["page_index"] and props["page_index"].Value) or 1
  local CurrentPage = PageNames[pidx]

  local CameraCount = props["Camera Count"].Value
  local NumPresets  = props["Num Presets"].Value

  local fs1  = 12
  local h1   = 20
  local hB   = 32
  local rowH = 30

  -- Camera group geometry
  local camGX, camGY = 0, 44
  local camGW = 320
  local rowY0 = camGY + 28
  local footerY = rowY0 + CameraCount * rowH + 8
  local camGH = (footerY + 26) - camGY + 8

  -- Pan / Tilt / Zoom group geometry (styled like the native QSC camera block)
  local ptzGX, ptzGY = camGX + camGW + 14, 44
  local padX, padY = ptzGX + 104, ptzGY + 30
  local zoomX  = padX + 3 * hB + 12
  local focusX = zoomX + hB + 10
  local hpX    = focusX + hB + 24
  local hpLblW, hpIcon, hpSaveW = 50, 28, 92
  local rightEdge = hpX + 52 + hpIcon + 6 + hpSaveW + 12
  local ptzGW  = rightEdge - ptzGX
  local ptzGH  = 30 + 3 * hB + 14 + 30   -- extra row for the Coordinates readout

  if CurrentPage == "Control" then

    -- Title / build info -----------------------------------------------------
    table.insert(graphics, {
      Type = "Text", Text = "Q-SYS Camera Controller", FontSize = 16,
      FontStyle = "Bold", HTextAlign = "Left", Color = Palette.cti_navy,
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
      Fill = Palette.White, StrokeColor = Palette.cti_navy, StrokeWidth = 1,
      CornerRadius = 8, Position = {camGX, camGY}, Size = {camGW, camGH}
    })

    for r = 0, CameraCount - 1 do
      local i = r + 1
      local y = rowY0 + r * rowH
      layout[fmt("camera_active_%03d", i)] = {
        PrettyName = fmt("Cameras~%d Select", i),
        Legend = tostring(i), Style = "Button",
        Color = {0, 210, 70}, OffColor = Palette.cti_navy, UnlinkOffColor = true,
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

    table.insert(graphics, {Type = "Text", Text = "Active", FontSize = fs1, HTextAlign = "Left", Color = Palette.cti_navy, Position = {camGX + 12, footerY + 3}, Size = {48, h1}})
    layout["active_camera_name"] = {
      PrettyName = "Cameras~Active Camera", Style = "Text", FontSize = fs1,
      HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1,
      Position = {camGX + 60, footerY}, Size = {camGW - 72, 26}
    }

    -- Pan / Tilt / Zoom group ------------------------------------------------
    table.insert(graphics, {
      Type = "GroupBox", Text = "Pan / Tilt / Zoom", FontSize = fs1,
      HTextAlign = "Left", Fill = Palette.White, StrokeColor = Palette.cti_navy,
      StrokeWidth = 1, CornerRadius = 8,
      Position = {ptzGX, ptzGY}, Size = {ptzGW, ptzGH}
    })
    table.insert(graphics, {
      Type = "Text", Text = "Pan, Tilt, and\nZoom Controls", FontSize = fs1,
      HTextAlign = "Center", Color = Palette.cti_navy,
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
        Margin = 3, Position = {pos[1], pos[2]}, Size = {hB, hB}
      }
    end

    -- Zoom (magnifier icons)
    table.insert(graphics, {Type = "Text", Text = "Zoom", FontSize = fs1, HTextAlign = "Center", Position = {zoomX - 6, padY - 18}, Size = {hB + 12, h1}})
    layout["ptz_zoom_in"]  = {PrettyName = "Pan-Tilt-Zoom~Zoom In",  Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 3, Position = {zoomX, padY},      Size = {hB, hB}}
    layout["ptz_zoom_out"] = {PrettyName = "Pan-Tilt-Zoom~Zoom Out", Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 3, Position = {zoomX, padY + hB}, Size = {hB, hB}}

    -- Focus (In / Out / AF)
    table.insert(graphics, {Type = "Text", Text = "Focus", FontSize = fs1, HTextAlign = "Center", Position = {focusX - 8, padY - 18}, Size = {hB + 16, h1}})
    layout["ptz_focus_in"]  = {PrettyName = "Focus~In",  Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 3, Position = {focusX, padY},          Size = {hB, hB}}
    layout["ptz_focus_out"] = {PrettyName = "Focus~Out", Legend = "", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 3, Position = {focusX, padY + hB},     Size = {hB, hB}}
    layout["ptz_af"]        = {PrettyName = "Focus~AF",  Legend = "AF", Style = "Button", Color = Palette.White, OffColor = Palette.ptz_off, UnlinkOffColor = true, Margin = 3, Position = {focusX, padY + 2 * hB}, Size = {hB, hB}}

    -- Is Moving status LED
    table.insert(graphics, {Type = "Text", Text = "Moving", FontSize = fs1, HTextAlign = "Left", Color = Palette.cti_navy, Position = {ptzGX + 12, padY + 70}, Size = {50, h1}})
    layout["is_moving"] = {PrettyName = "Pan-Tilt-Zoom~Is Moving", Style = "Indicator", Color = Palette.cti_amber, OffColor = {60, 46, 16}, UnlinkOffColor = true, StrokeWidth = 1, Margin = 2, Position = {ptzGX + 64, padY + 70}, Size = {18, 18}}

    -- Home / Privacy (icon + red save, as on the native camera)
    local homeY = padY + 6
    local privY = padY + hB + 14
    table.insert(graphics, {Type = "Text", Text = "Home",    FontSize = fs1, HTextAlign = "Right", Color = Palette.cti_navy, Position = {hpX, homeY + 4}, Size = {hpLblW, h1}})
    table.insert(graphics, {Type = "Text", Text = "Privacy", FontSize = fs1, HTextAlign = "Right", Color = Palette.cti_navy, Position = {hpX, privY + 4}, Size = {hpLblW, h1}})

    layout["ptz_home"]     = {PrettyName = "Pan-Tilt-Zoom~Home",         Legend = "",             Style = "Button", Color = Palette.green_on, OffColor = Palette.green_off, UnlinkOffColor = true, Margin = 3, Position = {hpX + 52,        homeY}, Size = {hpIcon, 28}}
    layout["home_save"]    = {PrettyName = "Pan-Tilt-Zoom~Save Home",    Legend = "Save Home",    FontSize = 11, Style = "Button", Color = Palette.Red, Margin = 3, Position = {hpX + 52 + hpIcon + 6, homeY}, Size = {hpSaveW, 28}}
    layout["privacy_load"] = {PrettyName = "Pan-Tilt-Zoom~Privacy Mode", Legend = "",             Style = "Button", Color = Palette.green_on, OffColor = Palette.gray_off, UnlinkOffColor = true, Margin = 3, Position = {hpX + 52,        privY}, Size = {hpIcon, 28}}
    layout["privacy_save"] = {PrettyName = "Pan-Tilt-Zoom~Save Privacy", Legend = "Save Privacy", FontSize = 11, Style = "Button", Color = Palette.Red, Margin = 3, Position = {hpX + 52 + hpIcon + 6, privY}, Size = {hpSaveW, 28}}

    -- Coordinates readout (current ptz.preset position)
    local coordsY = padY + 3 * hB + 8
    table.insert(graphics, {Type = "Text", Text = "Coordinates", FontSize = fs1, HTextAlign = "Left", Color = Palette.cti_navy, Position = {ptzGX + 12, coordsY + 2}, Size = {90, h1}})
    layout["coordinates"] = {PrettyName = "Pan-Tilt-Zoom~Coordinates", Style = "Text", FontSize = fs1, HTextAlign = "Center", Color = Palette.White, OffColor = Palette.White, UnlinkOffColor = true, Padding = 2, StrokeWidth = 1, Position = {padX, coordsY}, Size = {200, 22}}

    -- Presets group (right column, under the PTZ block; single row of presets)
    if NumPresets > 0 then
      local presetGX  = ptzGX
      local presetTop = ptzGY + ptzGH + 14
      local btnX0     = presetGX + 12
      local btnRow    = presetTop + 28
      local presetGH  = (btnRow + hB) - presetTop + 10
      local presetGW  = math.max(ptzGW, 24 + NumPresets * hB)

      table.insert(graphics, {
        Type = "GroupBox", Text = "Presets", FontSize = fs1, HTextAlign = "Left",
        Fill = Palette.White, StrokeColor = Palette.cti_navy, StrokeWidth = 1,
        CornerRadius = 8, Position = {presetGX, presetTop}, Size = {presetGW, presetGH}
      })
      table.insert(graphics, {Type = "Text", Text = "tap = recall   hold = save", FontSize = fs1, HTextAlign = "Center", Color = Palette.Gray, Position = {presetGX + 80, presetTop + 2}, Size = {presetGW - 240, h1}})
      table.insert(graphics, {Type = "Text", Text = "Preset Saved", FontSize = fs1, HTextAlign = "Right", Color = Palette.cti_navy, Position = {presetGX + presetGW - 150, presetTop + 2}, Size = {120, h1}})
      layout["preset_saved"] = {PrettyName = "Presets~Saved", Style = "Indicator", Color = Palette.cti_amber, OffColor = {60, 46, 16}, UnlinkOffColor = true, StrokeWidth = 1, Margin = 2, Position = {presetGX + presetGW - 26, presetTop + 4}, Size = {18, 18}}

      for p = 1, NumPresets do
        layout[fmt("preset_%03d", p)] = {
          PrettyName = fmt("Presets~%d", p), Legend = tostring(p),
          Style = "Button", Color = Palette.green_on, OffColor = Palette.ptz_off,
          UnlinkOffColor = true, Margin = 3,
          Position = {btnX0 + (p - 1) * hB, btnRow}, Size = {hB, hB}
        }
      end
    end

    -- Camera Tracking (Router) group, across the bottom ----------------------
    local camBottom = camGY + camGH
    local rightBottom
    if NumPresets > 0 then
      local pTop   = ptzGY + ptzGH + 14
      local btnRow = pTop + 28
      rightBottom = (btnRow + hB) + 10
    else
      rightBottom = ptzGY + ptzGH
    end
    local trackTop = math.max(camBottom, rightBottom) + 14
    local trackGW  = rightEdge
    local tY = trackTop + 26

    table.insert(graphics, {
      Type = "GroupBox", Text = "Camera Router (Optional)", FontSize = fs1, HTextAlign = "Left",
      Fill = Palette.White, StrokeColor = Palette.cti_navy, StrokeWidth = 1,
      CornerRadius = 8, Position = {0, trackTop}, Size = {trackGW, 60}
    })
    table.insert(graphics, {Type = "Text", Text = "Router", FontSize = fs1, HTextAlign = "Left", Color = Palette.cti_navy, Position = {12, tY + 3}, Size = {48, h1}})
    layout["router_select"] = {PrettyName = "Router~Component", Style = "ComboBox", FontSize = fs1, Color = Palette.White, Padding = 2, StrokeWidth = 1, Position = {62, tY}, Size = {258, 24}}
    table.insert(graphics, {Type = "Text", Text = "Output", FontSize = fs1, HTextAlign = "Left", Color = Palette.cti_navy, Position = {332, tY + 3}, Size = {50, h1}})
    layout["router_output"] = {PrettyName = "Router~Output", Style = "Text", Color = Palette.White, OffColor = Palette.White, UnlinkOffColor = true, FontSize = fs1, HTextAlign = "Center", Padding = 2, StrokeWidth = 1, Position = {384, tY}, Size = {56, 24}}
    table.insert(graphics, {Type = "Text", Text = "Source", FontSize = fs1, HTextAlign = "Left", Color = Palette.cti_navy, Position = {452, tY + 3}, Size = {50, h1}})
    layout["tracked_source"] = {PrettyName = "Router~Source", Style = "Text", FontSize = fs1, HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1, Position = {504, tY}, Size = {trackGW - 504 - 40, 24}}
    layout["router_found"] = {PrettyName = "Router~Found", Style = "Indicator", Color = Palette.Green, OffColor = {16, 40, 24}, UnlinkOffColor = true, StrokeWidth = 1, Margin = 2, Position = {trackGW - 28, tY + 3}, Size = {18, 18}}

  elseif CurrentPage == "Imaging" then

    -- Imaging / Exposure / White Balance groups, stacked to mirror the native
    -- QSC camera Imaging block.
    local wbGX = 0
    local grpW = 320
    local lblW = 110
    local valX = wbGX + 12 + lblW + 10
    local valW = grpW - lblW - 44

    -- A label plus an integer value field rendered as a text box with a meter
    -- fill behind it: a Knob laid out as "Text" fills up to its value in Color
    -- and leaves the remainder in OffColor.
    local function ValueRow(name, pretty, label, y)
      table.insert(graphics, {
        Type = "Text", Text = label, FontSize = fs1, HTextAlign = "Right",
        Color = Palette.cti_navy, Position = {wbGX + 12, y + 4}, Size = {lblW, h1}
      })
      layout[name] = {
        PrettyName = pretty, Style = "Text", FontSize = fs1, HTextAlign = "Center",
        Color = Palette.meter_on, OffColor = Palette.meter_off, UnlinkOffColor = true,
        TextColor = Palette.White, Padding = 2, StrokeWidth = 1,
        Position = {valX, y}, Size = {valW, 26}
      }
    end

    local imgGY = 44
    local imgGH = 62
    local expGY = imgGY + imgGH + 14
    local expGH = 62
    local wbGY = expGY + expGH + 14
    local wbGW, wbGH = grpW, 98
    local rowY  = wbGY + 26
    local row2Y = rowY + 32

    -- Title / build info -----------------------------------------------------
    table.insert(graphics, {
      Type = "Text", Text = "Q-SYS Camera Controller", FontSize = 16,
      FontStyle = "Bold", HTextAlign = "Left", Color = Palette.cti_navy,
      Position = {0, 4}, Size = {360, 24}
    })
    table.insert(graphics, {
      Type = "Text", Text = "v" .. PluginInfo.BuildVersion, FontSize = fs1,
      HTextAlign = "Right", Color = Palette.Gray,
      Position = {wbGW - 120, 8}, Size = {120, h1}
    })

    table.insert(graphics, {
      Type = "GroupBox", Text = "Imaging", FontSize = fs1, HTextAlign = "Left",
      Fill = Palette.White, StrokeColor = Palette.cti_navy, StrokeWidth = 1,
      CornerRadius = 8, Position = {wbGX, imgGY}, Size = {grpW, imgGH}
    })
    ValueRow("img.brightness", "Imaging~Brightness", "Brightness", imgGY + 26)

    table.insert(graphics, {
      Type = "GroupBox", Text = "Exposure", FontSize = fs1, HTextAlign = "Left",
      Fill = Palette.White, StrokeColor = Palette.cti_navy, StrokeWidth = 1,
      CornerRadius = 8, Position = {wbGX, expGY}, Size = {grpW, expGH}
    })
    ValueRow("exp.comp", "Exposure~Compensation", "Compensation", expGY + 26)

    table.insert(graphics, {
      Type = "GroupBox", Text = "White Balance", FontSize = fs1, HTextAlign = "Left",
      Fill = Palette.White, StrokeColor = Palette.cti_navy, StrokeWidth = 1,
      CornerRadius = 8, Position = {wbGX, wbGY}, Size = {wbGW, wbGH}
    })
    table.insert(graphics, {
      Type = "Text", Text = "Mode", FontSize = fs1, HTextAlign = "Right",
      Color = Palette.cti_navy, Position = {wbGX + 12, rowY + 4}, Size = {lblW, h1}
    })
    layout["wb.awb.mode"] = {
      PrettyName = "Imaging~AWB Mode", Style = "ComboBox", FontSize = fs1,
      HTextAlign = "Center", Color = Palette.White, Padding = 2, StrokeWidth = 1,
      Position = {wbGX + 12 + lblW + 10, rowY}, Size = {wbGW - lblW - 44, 26}
    }

    table.insert(graphics, {
      Type = "Text", Text = "AWB One Push", FontSize = fs1, HTextAlign = "Right",
      Color = Palette.cti_navy, Position = {wbGX + 12, row2Y + 4}, Size = {lblW, h1}
    })
    layout["wb.one.push.trigger"] = {
      PrettyName = "Imaging~AWB One Push", Legend = "", Style = "Button",
      Color = Palette.green_on, OffColor = Palette.gray_off, UnlinkOffColor = true,
      Margin = 3, Position = {wbGX + 12 + lblW + 10, row2Y}, Size = {56, 28}
    }

  end
