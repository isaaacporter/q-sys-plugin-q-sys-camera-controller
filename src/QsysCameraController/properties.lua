table.insert(props, {
  Name = "Camera Count",
  Type = "integer",
  Value = 2,
  Min = 1,
  Max = 16
})
table.insert(props, {
  Name = "Num Presets",
  Type = "integer",
  Value = 6,
  Min = 0,
  Max = 64
})
table.insert(props, {
  Name = "Hold to Save (s)",
  Type = "double",
  Value = 3.0,
  Min = 0.2,
  Max = 10.0
})
table.insert(props, {
  Name = "Debug Print",
  Type = "enum",
  Choices = {"None", "Function Calls", "Tx", "All"},
  Value = "None"
})
