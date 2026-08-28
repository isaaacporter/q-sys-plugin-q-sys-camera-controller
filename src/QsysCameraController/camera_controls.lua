-- Registry of native camera controls this plugin proxies.
--
-- One table drives everything: GetControls emits a control per entry, the
-- layout places it, and the runtime subscribes, mirrors and writes back. Adding
-- a control to a page is an entry here, not new code in three files.
--
-- name    control name on the camera. Our plugin control carries the SAME name,
--         so a pin lines up with the camera control it drives.
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
--                      <name>.trigger, and the lit state follows <name>.state
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
CamCtls = {
  -- ===== Pan / Tilt / Zoom page (hand-placed inside bespoke group boxes) =====
  {page = "Control", name = "setup.pan.speed", pretty = "Pan-Tilt-Zoom~Pan Speed", label = "Pan Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup.tilt.speed", pretty = "Pan-Tilt-Zoom~Tilt Speed", label = "Tilt Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup.zoom.speed", pretty = "Pan-Tilt-Zoom~Zoom Speed", label = "Zoom Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "aaaa.setup.snapshot.speed", pretty = "Pan-Tilt-Zoom~Recall Speed", label = "Recall Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup.speed.by.zoom", pretty = "Pan-Tilt-Zoom~Speed By Zoom", label = "Speed By Zoom", kind = "bool"},
  {page = "Control", name = "ptz.recalibrate", pretty = "Pan-Tilt-Zoom~Recalibrate PTZ", label = "Recalibrate PTZ", kind = "trigger"},
  {page = "Control", name = "setup.ceiling.mount", pretty = "Pan-Tilt-Zoom~Ceiling Mount", label = "Ceiling Mount", kind = "bool"},
  {page = "Control", name = "move.completed", pretty = "Pan-Tilt-Zoom~Move Completed", label = "Move Completed", kind = "led"},
  {page = "Control", name = "setup.focus.speed", pretty = "Focus~Manual Speed", label = "Manual Speed", kind = "float", min = 0.001, max = 1.0},
  {page = "Control", name = "setup.focus.sensitivity", pretty = "Focus~AF Sensitivity", label = "AF Sensitivity", kind = "enum"},
  {page = "Control", name = "setup.focus.zone", pretty = "Focus~AF Zone", label = "AF Zone", kind = "enum"},

  -- ===== Imaging page =====
  {page = "Imaging", group = "Imaging", col = 1, row = 1,
   name = "img.brightness", pretty = "Imaging~Brightness", label = "Brightness", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "Imaging", col = 2, row = 1,
   name = "img.sharpness", pretty = "Imaging~Sharpness", label = "Sharpness", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "Imaging", col = 1, row = 2,
   name = "img.saturation", pretty = "Imaging~Saturation", label = "Saturation", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "Imaging", col = 2, row = 2,
   name = "img.contrast", pretty = "Imaging~Contrast", label = "Contrast", kind = "int", min = 0, max = 14},

  {page = "Imaging", group = "Exposure", col = 1, row = 1,
   name = "exp.mode", pretty = "Exposure~Mode", label = "Mode", kind = "enum"},
  {page = "Imaging", group = "Exposure", col = 1, row = 3,
   name = "exp.backlight.comp", pretty = "Exposure~Backlight Comp", label = "Backlight Comp", kind = "bool"},
  {page = "Imaging", group = "Exposure", col = 1, row = 4,
   name = "exp.anti.flicker", pretty = "Exposure~Anti-Flicker", label = "Anti-Flicker", kind = "bool"},
  {page = "Imaging", group = "Exposure", col = 2, row = 1,
   name = "exp.comp", pretty = "Exposure~Compensation", label = "Compensation", kind = "int", min = -7, max = 7},
  {page = "Imaging", group = "Exposure", col = 2, row = 2,
   name = "exp.gain.limit", pretty = "Exposure~Gain Limit", label = "Gain Limit", kind = "int", min = 0, max = 15},
  {page = "Imaging", group = "Exposure", col = 2, row = 3,
   name = "exp.dynamic.range", pretty = "Exposure~Dynamic Range", label = "Dynamic Range", kind = "int", min = 0, max = 8},
  -- Aperture and Shutter are type Array on the camera and already return a
  -- display string (f/1.8, 1/60); mirror it rather than inventing a range.
  {page = "Imaging", group = "Exposure", col = 2, row = 4,
   name = "exp.iris", pretty = "Exposure~Aperture", label = "Aperture", kind = "ro"},
  {page = "Imaging", group = "Exposure", col = 2, row = 5,
   name = "exp.shutter", pretty = "Exposure~Shutter", label = "Shutter", kind = "ro"},
  {page = "Imaging", group = "Exposure", col = 2, row = 6,
   name = "exp.gain", pretty = "Exposure~Gain", label = "Gain", kind = "int", min = 0, max = 7},

  {page = "Imaging", group = "White Balance", col = 1, row = 1,
   name = "wb.awb.mode", pretty = "White Balance~Mode", label = "Mode", kind = "enum"},
  {page = "Imaging", group = "White Balance", col = 1, row = 3,
   name = "wb.one.push.trigger", pretty = "White Balance~AWB One Push", label = "AWB One Push", kind = "trigger"},
  {page = "Imaging", group = "White Balance", col = 2, row = 1,
   name = "wb.hue", pretty = "White Balance~Hue", label = "Hue", kind = "int", min = 0, max = 14},
  {page = "Imaging", group = "White Balance", col = 2, row = 2,
   name = "wb.awb.red.gain", pretty = "White Balance~Auto Red Gain", label = "Auto Red Gain", kind = "int", min = 1, max = 255},
  {page = "Imaging", group = "White Balance", col = 2, row = 3,
   name = "wb.awb.blue.gain", pretty = "White Balance~Auto Blue Gain", label = "Auto Blue Gain", kind = "int", min = 1, max = 255},
  {page = "Imaging", group = "White Balance", col = 2, row = 4,
   name = "wb.red.gain", pretty = "White Balance~Manual Red Gain", label = "Manual Red Gain", kind = "int", min = 1, max = 5000},
  {page = "Imaging", group = "White Balance", col = 2, row = 5,
   name = "wb.blue.gain", pretty = "White Balance~Manual Blue Gain", label = "Manual Blue Gain", kind = "int", min = 1, max = 5000},

  {page = "Imaging", group = "Noise Reduction", col = 1, row = 1,
   name = "setup.3d.nr.enable", pretty = "Noise Reduction~3D NR Enable", label = "3D NR Enable", kind = "bool"},
  {page = "Imaging", group = "Noise Reduction", col = 2, row = 1,
   name = "setup.3d.nr.value", pretty = "Noise Reduction~3D NR", label = "3D NR", kind = "int", min = 1, max = 11},

  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 1,
   name = "video.format.imaging.frame.rate", pretty = "Video Format~Imaging Frame Rate", label = "Imaging Frame Rate (Hz)", kind = "enum"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 2,
   name = "setup.hdmi.enable", pretty = "Video Format~SDI/HDMI Enable", label = "SDI/HDMI Enable", kind = "bool"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 3,
   name = "setup.hdmi.mode", pretty = "Video Format~SDI/HDMI Mode", label = "SDI/HDMI Mode", kind = "bool"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 4,
   name = "setup.hdmi.output.format", pretty = "Video Format~SDI/HDMI Format", label = "SDI/HDMI Format", kind = "enum"},
  {page = "Imaging", group = "SDI/HDMI Format", col = 1, row = 5,
   name = "setup.sdi.level", pretty = "Video Format~SDI Level A/B", label = "SDI Level A/B", kind = "bool"},

  -- ===== Auto Framing page =====
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 1,
   name = "autoframe.enable", pretty = "Auto Framing~Enable", label = "Enable", kind = "bool"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 2,
   name = "autoframe.padding", pretty = "Auto Framing~Frame Padding", label = "Frame Padding", kind = "int", min = 1, max = 15},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 3,
   name = "autoframe.deadband", pretty = "Auto Framing~Deadband", label = "Deadband", kind = "int", min = 1, max = 15},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 4,
   name = "autoframe.transition.speed", pretty = "Auto Framing~Transition Speed", label = "Transition Speed", kind = "enum"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 5,
   name = "autoframe.face.count", pretty = "Auto Framing~Face Count Enable", label = "Face Count", kind = "bool"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 5, x = 316, w = 105,
   name = "autoframe.facecount.display", pretty = "Auto Framing~Face Count", label = "", kind = "ro"},
  {page = "Auto Framing", group = "Auto Framing", col = 1, row = 6,
   name = "autoframe.outline.face", pretty = "Auto Framing~Outline Faces Enable", label = "Outline Faces", kind = "bool"},

  -- ===== IP Streams page (paired Preview / Mediacast columns) =====
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 1, x = 216, w = 44,
   name = "ip.streams.preview.enable", pretty = "IP Stream~Preview Stream Enable", label = "", kind = "bool"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 2, rowlabel = "RTSP URL",
   name = "ip.streams.preview.rtsp.url", pretty = "IP Stream~Preview Stream RTSP URL", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 3, rowlabel = "RTP Address",
   name = "ip.streams.preview.rtp.address", pretty = "IP Stream~Preview Stream RTP Address", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 3,
   name = "ip.streams.lbr.rtp.address", pretty = "IP Stream~Mediacast Stream RTP Address", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 4, rowlabel = "Streaming Mode", w = 88,
   name = "ip.streams.preview.streaming.mode", pretty = "IP Stream~Preview Stream Streaming Mode", label = "", kind = "enum"},
  -- No discoverable range for the frame rate, so it stays an editable text
  -- field rather than a meter that would render an invented fill.
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 4, x = 246, w = 44,
   name = "ip.streams.preview.streaming.mode.fps", pretty = "IP Stream~Preview Stream Frame Rate", label = "", kind = "text"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 5, rowlabel = "Video Format",
   name = "ip.streams.preview.video.format", pretty = "IP Stream~Preview Stream Video Format", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 5,
   name = "ip.streams.lbr.video.format", pretty = "IP Stream~Mediacast Stream Video Format", label = "", kind = "ro"},
  {page = "Mediacast Streams", group = "IP Streams", col = 1, row = 6, rowlabel = "Max Bitrate (Mbps)",
   name = "ip.streams.preview.max.bitrate", pretty = "IP Stream~Preview Stream Max Bitrate", label = "", kind = "float", min = 0.5, max = 2.0},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 6,
   name = "ip.streams.lbr.max.bitrate", pretty = "IP Stream~Mediacast Stream Max Bitrate", label = "", kind = "float", min = 1.0, max = 25.0},
  {page = "Mediacast Streams", group = "IP Streams", col = 2, row = 7, rowlabel = "Peak Frame Bitrate",
   name = "peak.frame.bitrate", pretty = "IP Stream~Mediacast Stream Peak Frame Bitrate", label = "", kind = "int", min = 30, max = 120},

  -- ===== Status page =====
  {page = "Status", group = "Status", col = 1, row = 1,
   name = "streaming.network", pretty = "Status~IP Streaming", label = "IP Streaming", kind = "led"},
  {page = "Status", group = "Status", col = 1, row = 1, x = 380, w = 40,
   name = "identify.state.trigger", pretty = "Status~Identify", label = "", kind = "statetrig"},
  {page = "Status", group = "Status", col = 1, row = 2, x = 8, w = 18,
   name = "camera.status.led", pretty = "Status~Status Indicator", label = "", kind = "led"},
  {page = "Status", group = "Status", col = 1, row = 2, x = 34, w = 387,
   name = "camera.status", pretty = "Status~Status Bar", label = "", kind = "status"},

  {page = "Status", group = "Network", col = 1, row = 1,
   name = "ip.address", pretty = "Status~Network IP Address", label = "IP Address", kind = "ro"},
  {page = "Status", group = "Network", col = 1, row = 2,
   name = "network.flow.control", pretty = "Status~Network Flow Control", label = "Flow Control", kind = "bool"},
  {page = "Status", group = "Network", col = 1, row = 3,
   name = "multislice.toggle", pretty = "Status~Network Traffic Shaping", label = "Traffic Shaping", kind = "bool"},

  {page = "Status", group = "Hardware Details", col = 1, row = 1,
   name = "textc.model", pretty = "Status~HW Model", label = "Model", kind = "ro"},
  {page = "Status", group = "Hardware Details", col = 1, row = 2,
   name = "textc.mac", pretty = "Status~HW MAC Address", label = "MAC Address", kind = "ro"},
  {page = "Status", group = "Hardware Details", col = 1, row = 3,
   name = "textc.serial", pretty = "Status~HW S/N", label = "Serial Number", kind = "ro"}
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
  {page = "Imaging",      name = "Exposure",        rows = 6, style = "cols2", y = 91,  h = 135},
  {page = "Imaging",      name = "White Balance",   rows = 5, style = "cols2", y = 242, h = 116},
  {page = "Imaging",      name = "Noise Reduction", rows = 1, style = "cols2", y = 374, h = 40},
  {page = "Imaging",      name = "SDI/HDMI Format", rows = 5, style = "cols1", y = 430, h = 116, w = 432},
  {page = "Auto Framing", name = "Auto Framing",    rows = 6, style = "cols1"},
  {page = "Mediacast Streams",   name = "IP Streams",      rows = 7, style = "pairs",
   headers = {"Preview Stream", "Mediacast Stream"}},
  {page = "Status",       name = "Status",           rows = 2, style = "cols1"},
  {page = "Status",       name = "Network",          rows = 3, style = "cols1"},
  {page = "Status",       name = "Hardware Details", rows = 3, style = "cols1"}
}

-- Page-level trigger buttons that sit above the first group box.
CamPageTriggers = {
  {page = "Imaging", name = "setup.reset.settings", pretty = "Imaging~Reset Cam Settings",
   label = "Reset all Camera settings (Imaging, PTZ, and Focus)"}
}

-- Fast lookup by control name.
CamCtlByName = {}
for _, d in ipairs(CamCtls) do CamCtlByName[d.name] = d end
for _, t in ipairs(CamPageTriggers) do
  CamCtlByName[t.name] = {name = t.name, pretty = t.pretty, kind = "trigger", label = t.label}
end
