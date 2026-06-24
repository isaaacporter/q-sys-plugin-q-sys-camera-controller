# Q-SYS Camera Controller

A Q-SYS plugin that controls **camera components already in the design** from a
single shared control surface. Instead of talking to each camera directly, it
proxies its buttons to whichever camera is currently selected, using the Q-SYS
`Component` library. It can also track a video/mediacast router so the
controlled camera follows the routed source.

## Features

- **Expandable camera list** -- a `Camera Count` property (1-16) sets how many
  camera slots are shown.
- **Per-slot drop-down** of every PTZ-capable camera (and USB camera bridge)
  discovered in the design, with a per-slot "found" LED.
- **One shared PTZ surface** (styled like the native QSC camera): pan/tilt with
  diagonals, zoom, focus in/out, **AF**, **Home** (recall + save), **Privacy**
  (toggle + save), an **Is Moving** indicator, and a live
  **Coordinates** field.
- **Numbered presets** (count via `Num Presets`), one button each: **tap to
  recall, hold to save** (hold time via `Hold to Save (s)`). Presets are keyed
  to the camera's source identity. The preset button will highlight when the
  camera is at that stored position, and a **Preset Saved** LED flashes for 3 s
  on each save.
- **Router tracking** -- pick a router and output number; the active camera
  follows the routed input, and selecting a camera routes it to that output
  (bidirectional, index-based).
- **Camera selection** highlights bright green for the active slot; its name is
  echoed in an indicator.

## How discovery works

On load the plugin calls `Component.GetComponents()` and:

- treats a component as a **camera** if its type contains "camera" or "uvc", or
  it exposes a `pan.left` / `tilt.up` / `ptz.preset` / `peripheral.camera.source`
  control (so native PTZ cameras and USB camera bridges are both found);
- treats a component as a **router** if its type contains "router" or it exposes
  a `select.1` control.


## Numbered presets (coordinate based)

Native QSC cameras have no numbered presets, so the plugin stores positions
itself, one button per preset:

- **Tap** a preset button to **recall** -- the stored `ptz.preset` coordinate
  string is written back to the active camera (it moves at its Recall Speed).
- **Hold** a preset button (>= `Hold to Save (s)`) to **save** -- the camera's
  current `ptz.preset` string is captured.
- Presets are **keyed by camera source identity**: a USB bridge reports its
  connected camera in `peripheral.camera.source`, so presets follow the physical
  camera across bridges; native cameras key on their own component name. Each
  camera's bank is initialised to `0 0 0` slots on first use.
- Banks are persisted as JSON in a hidden control that survives core restarts
  and design saves.
- The preset button will highlight when the live coordinate equals the
  stored one (exact match; an unsaved `0 0 0` slot never lights).

## Camera Router (Optional) -- bidirectional, index based

Pick a router in the **Router** drop-down (blank = no tracking) and an **Output**
number (default 1). Tracking is by **index**: camera slot *i* corresponds to
router input *i*.

- **Router -> plugin:** when the output's `select.<n>` value changes to *K*,
  camera slot *K* becomes active.
- **Plugin -> router:** selecting camera *i* writes `select.<n> = i`, routing
  that input to the output.

On bind the plugin first adopts the router's current selection. The Source
readout shows the output's `output.<n>.source.name` for reference. An echo guard
prevents the two directions from fighting, and redundant writes are skipped.

## Required setup

For the plugin to see and drive a component, that component must have **Script
Access** enabled (set *Script Access* to *Script* or *All* in its properties).
Components without script access will not appear in the drop-downs.

For router tracking, arrange the camera slots in the **same order** as the router
inputs (slot *i* = input *i*).

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| Camera Count | integer | 2 | 1-16 camera slots |
| Num Presets | integer | 6 | 0-64 numbered presets (single row) |
| Hold to Save (s) | double | 3 | Hold time to save vs. tap to recall |
| Debug Print | enum | None | None / Function Calls / Tx / All |