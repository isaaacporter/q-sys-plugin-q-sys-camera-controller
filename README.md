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
- **Imaging page** -- a **White Balance** group with an AWB **Mode** drop-down
  and an **AWB One Push** trigger, both acting on the active camera.
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
  a `select.1` (classic Router / Router with Mixer) or `output.1.select`
  (MediaCast Router) control.


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

## Pages

| Page | Contents |
|---|---|
| Control | Cameras, Pan / Tilt / Zoom, Presets, Camera Router |
| Imaging | Imaging, Exposure, White Balance |

## Imaging -- Imaging and Exposure

| Field | Camera control | Range |
|---|---|---|
| Brightness | `img.brightness` | 0 to 14 |
| Compensation | `exp.comp` | -7 to 7 |

Both are integer value fields rendered as a text box with a meter fill behind
it, and both track the active camera in each direction: type or pin a value to
set the camera, and a change made elsewhere is reflected back. Switching camera
slots re-mirrors from the newly active camera. A camera that does not expose one
of these controls leaves the field untouched rather than zeroing it.

## Imaging -- White Balance

**Mode** is a drop-down bound to the active camera's `wb.awb.mode`. Its choice
list is **mirrored from the camera itself** rather than hardcoded, so whatever
modes that model offers (Auto, Manual, One Push, Indoor, Outdoor, ...) are what
appear. It tracks both ways: changing it sets the camera, and a change made
elsewhere is reflected back. Switching camera slots re-mirrors from the newly
active camera.

**AWB One Push** pulses the active camera's `wb.one.push.trigger` control, the
same one-push auto white balance trigger the native QSC camera Imaging block
exposes.

Both plugin pins carry the native control names (`wb.awb.mode`,
`wb.one.push.trigger`) so they line up with the camera they drive. Cameras that
do not expose a control are skipped silently -- the Mode drop-down simply comes
up empty.

## Camera Router (Optional) -- bidirectional, index based

Pick a router in the **Router** drop-down (blank = no tracking) and an **Output**
number (default 1). Tracking is by **index**: camera slot *i* corresponds to
router input *i*.

- **Router -> plugin:** when the output's select value changes to *K*, camera
  slot *K* becomes active.
- **Plugin -> router:** selecting camera *i* writes *i* to that output's select
  control, routing that input to the output.

**Router control naming is probed, not assumed.** The classic Router and Router
with Mixer name the output-select control `select.<n>`; the MediaCast Router
renamed it to `output.<n>.select`. The plugin tries both forms against the bound
component and re-resolves whenever the router or output number changes, so a
MediaCast Router works without special configuration. The Source readout prefers
`output.<n>.source.name` and otherwise scans the router's control list for a name
carrying "source", "name" and the output index.

On bind the plugin first adopts the router's current selection. An echo guard
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

## Version history

| Version | Change |
|---|---|
| 1.0.0.0 | Initial release |
| 1.0.1.0 | Router output-select naming probed (`select.N` / `output.N.select`) instead of hardcoded |
| 1.0.2.0 | Camera slot interlock fixed -- depth-counted suppression and conditional feedback writes, so two slots can no longer latch lit |
| 1.0.3.0 | Imaging page with White Balance -- AWB Mode + AWB One Push |
| 1.0.4.0 | All feedback writes made conditional -- fixes an unbounded event loop between the Coordinates field and the camera's `ptz.preset` |
| 1.0.5.0 | Imaging page gains Imaging (Brightness) and Exposure (Compensation) groups |
| 1.0.6.0 | White value text on the meter bars; deeper blue fill |