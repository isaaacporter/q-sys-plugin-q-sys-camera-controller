-- Registry of native camera controls this plugin proxies.
--
-- One table drives everything: GetControls emits a control per entry, the
-- layout places it, and the runtime subscribes, mirrors and writes back. Adding
-- a control to a page is an entry here, not new code in three files.
--
-- name    control name on the camera. Our plugin control carries the SAME name,
--         so a pin lines up with the camera control it drives.
-- kind    int | float | bool | enum | ro | trigger
--           int/float  numeric field drawn as a text box over a meter fill
--           bool       green toggle, as the native block draws it
--           enum       ComboBox; choices are mirrored from the camera
--           ro         read-only readout; mirrors the camera's formatted String
--           trigger    momentary; pulses the camera control
-- min/max REQUIRED for int and float -- a proxied control cannot report its own
--         range (reading .Min raises), so it has to be declared here.
-- group   group box the control belongs to, in page order
-- col/row 1-based position within the group; col 1 is left, col 2 is right
--
-- Ranges below are for the NC-20x60.
CamCtls = {
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
   name = "setup.sdi.level", pretty = "Video Format~SDI Level A/B", label = "SDI Level A/B", kind = "bool"}
}

-- Group boxes in the order they stack down each page, and whether the group
-- uses the two-column split or a single right-aligned column.
CamGroups = {
  {page = "Imaging", name = "Imaging",         rows = 2, cols = 2},
  {page = "Imaging", name = "Exposure",        rows = 6, cols = 2},
  {page = "Imaging", name = "White Balance",   rows = 5, cols = 2},
  {page = "Imaging", name = "Noise Reduction", rows = 1, cols = 2},
  {page = "Imaging", name = "SDI/HDMI Format", rows = 5, cols = 1}
}

-- Page-level trigger buttons that sit above the first group box.
CamPageTriggers = {
  {page = "Imaging", name = "setup.reset.settings", pretty = "Imaging~Reset Cam Settings",
   label = "Reset all Camera settings (Imaging, PTZ, and Focus)"}
}

-- Fast lookup by control name, and the subset needing each treatment.
CamCtlByName = {}
for _, d in ipairs(CamCtls) do CamCtlByName[d.name] = d end
for _, t in ipairs(CamPageTriggers) do
  CamCtlByName[t.name] = {name = t.name, pretty = t.pretty, kind = "trigger", label = t.label}
end
