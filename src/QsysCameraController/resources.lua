-- CTI brand colour palette (see cti_brand_preferences.md)
Palette = {
  cti_navy  = {13, 59, 102},   -- CTI Dark Blue  #0D3B66
  cti_teal  = {0, 169, 165},   -- CTI Teal       #00A9A5
  cti_amber = {255, 186, 73},  -- CTI Amber      #FFBA49
  White     = {255, 255, 255},
  Black     = {0, 0, 0},
  Gray      = {128, 128, 128},
  Red       = {200, 40, 40},
  Green     = {40, 180, 80},
  ptz_off   = {124, 124, 124},  -- #7C7C7C
  green_on  = {0, 159, 60},     -- #009F3C
  green_off = {0, 75, 22},      -- #004B16
  gray_off  = {137, 137, 137},  -- #898989
  text      = {51, 51, 51},     -- #ff333333  all label text on the native pages
  meter_on  = {31, 78, 140},    -- #1F4E8C  filled portion of a value meter
  meter_off = {26, 32, 48}      -- #1A2030  unfilled portion
}

-- Pages shown by the plugin
-- Setup is ours; the rest match the native camera block's tabs and order.
PageNames = { "Setup", "Control", "Imaging", "Mediacast Streams", "Status", "Auto Framing" }
