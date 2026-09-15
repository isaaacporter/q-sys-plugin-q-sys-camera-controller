-- Registry of native camera controls this plugin proxies.
--
-- One table drives everything: GetControls emits a control per entry, the
-- layout places it, and the runtime subscribes, mirrors and writes back. Adding
-- a control to a page is an entry here, not new code in three files.
--
-- name    control name, underscore-separated, shared by our plugin control and
--         the camera control it proxies -- so a pin lines up with what it
--         drives, and external control addresses the same name either side.
-- kind    int | float | text | bool | enum | ro | led | status | trigger | statetrig
--           int/float  numeric field drawn as a text box over a meter fill
--           text       editable text field, no meter (used where the camera
--                      exposes no range we can render a fill from)
--           bool       green toggle, as the native block draws it
--           enum       ComboBox; choices are mirrored from the camera
--           ro         read-only readout; mirrors the camera's formatted String
--           led        read-only boolean indicator
--           status     read-only status bar (Q-SYS Status control)
--           trigger    momentary; pulses the camera control
--           statetrig  the camera's "State Trigger" pattern: pressing pulses
--                      <name>_trigger, and the lit state follows <name>_state
-- min/max REQUIRED for int and float -- a proxied control cannot report its own
--         range (reading .Min raises), so it has to be declared here.
-- group   group box the control belongs to. Omitted means the layout places it
--         by hand (the PTZ pad geometry is bespoke), but it is still declared
--         and mirrored from here.
-- col/row 1-based position within the group.
-- x/w     optional overrides, relative to the group, for rows that do not fit
--         the group's normal column grid.
--
-- Ranges below are for the NC-20x60.

-- Normalises a control name to this plugin's own spelling: underscores.
--
-- Two reasons the plugin never uses dots. Q-SYS reads a dot in a *plugin*
-- control name as hierarchy, so "pan.left" and "pan.left.tilt.up" would collide
-- and both vanish from the block. And external control expects underscores: the
-- Crestron QscQsys library (MatKlucznyk/Qsys) sends "pan_left", "img_brightness",
-- "toggle_privacy" and so on, which is exactly this spelling.
--
-- The registry is already written this way, so this is a guard rather than a
-- transform -- it keeps a dotted entry added later from silently missing its
-- control. Anything indexing Controls[] goes through here.
function CtlName(name)
  return (name:gsub("%.", "_"))
end

CamCtls = {
  -- ===== Pan / Tilt / Zoom page (hand-placed inside bespoke group boxes) =====
  {page = "Control", name = "setup_pan_speed", pretty = "Pan-Tilt-Zoom~Pan Speed", label = "Pan Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup_tilt_speed", pretty = "Pan-Tilt-Zoom~Tilt Speed", label = "Tilt Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup_zoom_speed", pretty = "Pan-Tilt-Zoom~Zoom Speed", label = "Zoom Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "aaaa_setup_snapshot_speed", pretty = "Pan-Tilt-Zoom~Recall Speed", label = "Recall Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup_speed_by_zoom", pretty = "Pan-Tilt-Zoom~Speed By Zoom", label = "Speed By Zoom", kind = "bool"},
  {page = "Control", name = "ptz_recalibrate", pretty = "Pan-Tilt-Zoom~Recalibrate PTZ", label = "Recalibrate PTZ", kind = "trigger"},
  {page = "Control", name = "setup_ceiling_mount", pretty = "Pan-Tilt-Zoom~Ceiling Mount", label = "Ceiling Mount", kind = "bool"},
  {page = "Control", name = "move_completed", pretty = "Pan-Tilt-Zoom~Move Completed", label = "Move Completed", kind = "led"},
  {page = "Control", name = "setup_focus_speed", pretty = "Focus~Manual Speed", label = "Manual Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup_focus_sensitivity", pretty = "Focus~Sensitivity", label = "AF Sensitivity", kind = "enum"},
  {page = "Control", name = "setup_focus_zone", pretty = "Focus~AF Zone", label = "AF Zone", kind = "enum"},
  -- The camera hands its preview stream over as a string on this control; our
  -- text field renders it because the layout presents it as a MediaDisplay.
  {page = "Control", name = "preview", pretty = "Preview", label = "Preview", kind = "media"},

  -- ===== Imaging page =====
  {page = "Imaging", group = "Imaging", col = 1, row = 1,
   name = "img_brightness", pretty = "Imaging~Brightness", label = "Brightness", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "Imaging", col = 2, row = 1,
   name = "img_sharpness", pretty = "Imaging~Sharpness", label = "Sharpness", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "Imaging", col = 1, row = 2,
   name = "img_saturation", pretty = "Imaging~Saturation", label = "Saturation", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "Imaging", col = 2, row = 2,
   name = "img_contrast", pretty = "Imaging~Contrast", label = "Contrast", kind = "int", min = 0, max = 14},

  {page = "Imaging", group = "Exposure", col = 1, row = 1,
   name = "exp_mode", pretty = "Exposure~Mode", label = "Mode", kind = "enum"},
  {page = "Imaging", group = "Exposure", col = 1, row = 3,
   name = "exp_backlight_comp", pretty = "Exposure~Backlight Comp", label = "Backlight Comp", kind = "bool"},
  {page = "Imaging", group = "Exposure", col = 1, row = 4,
   name = "exp_anti_flicker", pretty = "Exposure~Anti-Flicker", label = "Anti-Flicker", kind = "bool"},
  {page = "Imaging", group = "Exposure", col = 2, row = 1,
   name = "exp_comp", pretty = "Exposure~Compensation", label = "Compensation", kind = "int", min = -7, max = 7},
  {page = "Imaging", group = "Exposure", col = 2, row = 2,
   name = "exp_gain_limit", pretty = "Exposure~Gain Limit", label = "Gain Limit", kind = "int", min = 0, max = 15},
  {page = "Imaging", group = "Exposure", col = 2, row = 3,
   name = "exp_dynamic_range", pretty = "Exposure~Dynamic Range", label = "Dynamic Range", kind = "int", min = 0, max = 8},
  -- Aperture and Shutter are type Array on the camera and already return a
  -- display string (f/1.8, 1/60); mirror it rather than inventing a range.
  {page = "Imaging", group = "Exposure", col = 2, row = 4,
   name = "exp_iris", pretty = "Exposure~Aperture", label = "Aperture", kind = "ro"},
  {page = "Imaging", group = "Exposure", col = 2, row = 5,
   name = "exp_shutter", pretty = "Exposure~Shutter", label = "Shutter", kind = "ro"},
  {page = "Imaging", group = "Exposure", col = 2, row = 6,
   name = "exp_gain", pretty = "Exposure~Gain", label = "Gain", kind = "int", min = 0, max = 7},

  {page = "Imaging", group = "White Balance", col = 1, row = 1,
   name = "wb_awb_mode", pretty = "White Balance~Mode", label = "Mode", kind = "enum"},
  {page = "Imaging", group = "White Balance", col = 1, row = 3,
   name = "wb_one_push_trigger", pretty = "White Balance~AWB One Push", label = "AWB One Push", kind = "trigger"},
  {page = "Imaging", group = "White Balance", col = 2, row = 1,
   name = "wb_hue", pretty = "White Balance~Hue", label = "Hue", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "White Balance", col = 2, row = 2,
   name = "wb_awb_red_gain", pretty = "White Balance~Auto Red Gain", label = "Auto Red Gain", kind = "int", min = 1, max = 255},
  {page = "Imaging", group = "White Balance", col = 2, row = 3,
   name = "wb_awb_blue_gain", pretty = "White Balance~Auto Blue Gain", label = "Auto Blue Gain", kind = "int", min = 1, max = 255},
  {page = "Imaging", group = "White Balance", col = 2, row = 4,
   name = "wb_red_gain", pretty = "White Balance~Manual Red Gain", label = "Manual Red Gain", kind = "int", min = 1, max = 5000},
  {page = "Imaging", group = "White Balance", col = 2, row = 5,
   name = "wb_blue_gain", pretty = "White Balance~Manual Blue Gain", label = "Manual Blue Gain", kind = "int", min = 1, max = 5000},

  {page = "Imaging", group = "Noise Reduction", col = 1, row = 1,
   name = "setup_3d_nr_enable", pretty = "Noise Reduction~3D NR Enable", label = "3D NR Enable", kind = "bool"},
  {page = "Imaging", group = "Noise Reduction", col = 2, row = 1,
   name = "setup_3d_nr_value", pretty = "Noise Reduction~3D NR", label = "3D NR", kind = "int", min = 1, max = 11},

  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 1,
   name = "video_format_imaging_frame_rate", pretty = "Video Format~Imaging Frame Rate", label = "Imaging Frame Rate (Hz)", kind = "enum"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 2, w = 40,
   name = "setup_hdmi_enable", pretty = "Video Format~SDI/HDMI Enable", label = "SDI/HDMI Enable", kind = "bool"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 3, w = 40,
   name = "setup_hdmi_mode", pretty = "Video Format~SDI/HDMI Mode", label = "SDI/HDMI Mode", kind = "bool",
   legendOn = "SDI", legendOff = "HDMI"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 4,
   name = "setup_hdmi_output_format", pretty = "Video Format~SDI/HDMI Format", label = "SDI/HDMI Format", kind = "enum"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 5, w = 40,
   name = "setup_sdi_level", pretty = "Video Format~SDI Level A/B", label = "SDI Level A/B", kind = "bool",
   legendOn = "A", legendOff = "B"},

  -- ===== Auto Framing page =====
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 1,
   name = "autoframe_enable", pretty = "Auto Framing~Enable", label = "Enable", kind = "bool"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 2,
   name = "autoframe_padding", pretty = "Auto Framing~Frame Padding", label = "Frame Padding", kind = "int", min = 1, max = 15},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 3,
   name = "autoframe_deadband", pretty = "Auto Framing~Deadband", label = "Deadband", kind = "int", min = 1, max = 15},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 4,
   name = "autoframe_transition_speed", pretty = "Auto Framing~Transition Speed", label = "Transition Speed", kind = "enum"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 5,
   name = "autoframe_face_count", pretty = "Auto Framing~Face Count Enable", label = "Face Count", kind = "bool"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 5, x = 167, w = 128,
   name = "autoframe_facecount_display", fill = Palette.ro_grey,
   pretty = "Auto Framing~Face Count", label = "", kind = "ro"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 6,
   name = "autoframe_outline_face", pretty = "Auto Framing~Outline Faces Enable", label = "Outline Faces", kind = "bool"},

  -- ===== IP Streams page (paired Preview / Mediacast columns) =====
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 1, x = 227, w = 40,
   name = "ip_streams_preview_enable", pretty = "IP Stream~Preview Stream~Enable", label = "", kind = "bool",
   legend = "Enable"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 2, rowlabel = "RTSP URL",
   name = "ip_streams_preview_rtsp_url", fill = Palette.ro_grey, pretty = "IP Stream~Preview Stream~RTSP URL", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 3, rowlabel = "RTP Address",
   name = "ip_streams_preview_rtp_address", fill = Palette.ro_grey, pretty = "IP Stream~Preview Stream~RTP Address", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 3,
   name = "ip_streams_lbr_rtp_address", fill = Palette.ro_grey, pretty = "IP Stream~Mediacast Stream~RTP Address", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 4, rowlabel = "Streaming Mode", w = 106,
   name = "ip_streams_preview_streaming_mode", pretty = "IP Stream~Preview Stream~Streaming Mode Format", label = "", kind = "enum"},
  -- No discoverable range for the frame rate, so it stays an editable text
  -- field rather than a meter that would render an invented fill.
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 4, x = 215, w = 26,
   name = "ip_streams_preview_streaming_mode_fps", pretty = "IP Stream~Preview Stream~Streaming Mode Frame Rate", label = "", kind = "text"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 5, rowlabel = "Video Format",
   name = "ip_streams_preview_video_format", fill = Palette.ro_grey, pretty = "IP Stream~Preview Stream~Video Format", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 5,
   name = "ip_streams_lbr_video_format", fill = Palette.ro_grey, pretty = "IP Stream~Mediacast Stream~Video Format", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 6, rowlabel = "Max Bitrate (Mbps)",
   name = "ip_streams_preview_max_bitrate", pretty = "IP Stream~Preview Stream~Max Bitrate", label = "", kind = "float", min = 0.5, max = 2.0},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 6,
   name = "ip_streams_lbr_max_bitrate", pretty = "IP Stream~Mediacast Stream~Max Bitrate", label = "", kind = "float", min = 1.0, max = 25.0},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 7, rowlabel = "Peak Frame Bitrate",
   name = "peak_frame_bitrate", pretty = "IP Stream~Mediacast Stream~Peak Frame Bitrate", label = "", kind = "int", min = 30, max = 120},

  -- ===== Status page =====
  {page = "Status", group = "Status", col = 1, row = 1, x = 103, dy = 4, lblH = 24,
   name = "streaming_network", fill = Palette.led_green, offFill = Palette.led_green_off,
   pretty = "Status~IP Streaming", label = "IP Streaming", kind = "led"},
  {page = "Status", group = "Status", col = 1, row = 1, x = 389, w = 36, h = 24,
   name = "identify_state_trigger", fill = Palette.id_yellow, offFill = Palette.id_yellow_off,
   legend = "ID", pretty = "Status~Identify", label = "", kind = "statetrig"},
  {page = "Status", group = "Status", col = 1, row = 2, x = 4, w = 16, dy = 16,
   name = "camera_status_led", fill = Palette.led_red,
   pretty = "Status~Status Indicator", label = "", kind = "led"},
  {page = "Status", group = "Status", col = 1, row = 2, x = 23, w = 400, h = 32, dy = 8,
   name = "camera_status", fill = Palette.ro_grey, pretty = "Status~Status Bar", label = "", kind = "status"},

  {page = "Status", group = "Network", col = 1, row = 1,
   name = "ip_address", fill = Palette.ro_grey, pretty = "Status~Network IP Address", label = "IP Address", kind = "ro"},
  {page = "Status", group = "Network", col = 1, row = 2,
   name = "network_flow_control", pretty = "Status~Network Flow Control", label = "Flow Control", kind = "bool"},
  {page = "Status", group = "Network", col = 1, row = 3,
   name = "multislice_toggle", pretty = "Status~Network Traffic Shaping", label = "Traffic Shaping", kind = "bool"},

  {page = "Status", group = "Hardware Details", col = 1, row = 1,
   name = "textc_model", fill = Palette.ro_grey, pretty = "Status~HW Model", label = "Model", kind = "ro"},
  {page = "Status", group = "Hardware Details", col = 1, row = 2,
   name = "textc_mac", fill = Palette.ro_grey, pretty = "Status~HW MAC Address", label = "MAC Address", kind = "ro"},
  {page = "Status", group = "Hardware Details", col = 1, row = 3,
   name = "textc_serial", fill = Palette.ro_grey, pretty = "Status~HW S/N", label = "Serial Number", kind = "ro"}
}

-- Group boxes in the order they stack down each page.
--   cols2  label + control in each of two columns (the default)
--   cols1  one right-aligned label column, control to its right
--   pairs  row label at left, then a Preview and a Mediacast column
-- y/h/w are the measured position and size, 4 less than Designer reports
-- because of the plugin's inherent inset. Groups without them stack
-- automatically at 11 + rows*19.
CamGroups = {
  {page = "Imaging",      name = "Imaging",         rows = 2, style = "cols2", y = 16,  h = 59},
  -- Exposure's left column is a wider label over a narrower control than the
  -- Imaging group's, so it carries its own column geometry.
  {page = "Imaging",      name = "Exposure",        rows = 6, style = "cols2", y = 91,  h = 135,
   cols = {{lblX = 4, lblW = 96, ctlX = 103, ctlW = 96},
           {lblX = 202, lblW = 96, ctlX = 301, ctlW = 128}}},
  {page = "Imaging",      name = "White Balance",   rows = 5, style = "cols2", y = 242, h = 116,
   cols = {{lblX = 4, lblW = 96, ctlX = 103, ctlW = 96},
           {lblX = 202, lblW = 96, ctlX = 301, ctlW = 128}}},
  {page = "Imaging",      name = "Noise Reduction", rows = 1, style = "cols2", y = 374, h = 40,
   cols = {{lblX = 4, lblW = 96, ctlX = 103, ctlW = 96},
           {lblX = 202, lblW = 96, ctlX = 301, ctlW = 128}}},
  {page = "Imaging",      name = "SDI/HDMI Format", rows = 5, style = "cols1", y = 430, h = 116, w = 432,
   cols = {{lblX = 4, lblW = 150, ctlX = 158, ctlW = 150}}},
  {page = "Auto Framing", name = "Auto Framing",    rows = 6, style = "cols1",
   y = 0, h = 135, w = 435,
   cols = {{lblX = 4, lblW = 96, ctlX = 103, ctlW = 192}}},
  {page = "Mediacast Streams", name = "IP Streams", rows = 7, style = "pairs",
   y = 0, h = 154, w = 436, lblW = 100,
   -- The Preview heading is narrower than its column, because the Enable
   -- button shares the heading row with it.
   cols = {{ctlX = 107, ctlW = 160, hdrW = 120}, {ctlX = 272, ctlW = 160}},
   headers = {"Preview Stream", "Mediacast Stream"}},
  {page = "Status",       name = "Status",           rows = 2, style = "cols1", y = 0,   h = 83, w = 435, cols = {{lblX = 4, lblW = 96, ctlX = 103, ctlW = 192}}},
  {page = "Status",       name = "Network",          rows = 3, style = "cols1", y = 99,  h = 81, w = 435, cols = {{lblX = 4, lblW = 96, ctlX = 103, ctlW = 128}}},
  {page = "Status",       name = "Hardware Details", rows = 3, style = "cols1", y = 180, h = 78, w = 435, cols = {{lblX = 4, lblW = 112, ctlX = 119, ctlW = 304}}}
}

-- Page-level trigger buttons that sit above the first group box.
CamPageTriggers = {
  {page = "Imaging", name = "setup_reset_settings", pretty = "Imaging~Reset Cam Settings",
   label = "Reset all Camera settings (Imaging, PTZ, and Focus)"}
}

-- Static captions that sit on a row but have no control behind them.
CamTexts = {
  {page = "Mediacast Streams", group = "IP Streams", row = 4, x = 243, w = 26, text = "fps"}
}

-- Fast lookup by control name.
CamCtlByName = {}
for _, d in ipairs(CamCtls) do CamCtlByName[d.name] = d end
for _, t in ipairs(CamPageTriggers) do
  CamCtlByName[t.name] = {name = t.name, pretty = t.pretty, kind = "trigger", label = t.label}
end
