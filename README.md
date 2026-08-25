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
| Setup | Cameras, Camera Router (the CTI-specific parts) |
| Pan / Tilt / Zoom | Pan / Tilt / Zoom, Focus, Presets |
| Imaging | Imaging, Exposure, White Balance, Noise Reduction, SDI/HDMI Format |
| Auto Framing | Auto Framing |
| IP Streams | Preview Stream / Mediacast Stream |
| Status | Status, Network, Hardware Details |

Every group box is the full 435px plugin width, matching the native camera
block. Pages other than Setup mirror the native layout.

## The control registry

`camera_controls.lua` declares every native control the plugin proxies -- its
kind, range, page, group and grid position. `GetControls` emits from it, the
layout renders from it, and the runtime subscribes, mirrors and writes back from
it. Adding a control is one entry in one file.

| kind | rendering | behaviour |
|---|---|---|
| `int` / `float` | text box over a meter fill | mirrors `Value` both ways |
| `text` | plain editable field | mirrors `String` both ways |
| `bool` | green toggle | mirrors `Boolean` both ways |
| `enum` | ComboBox | choices mirrored from the camera |
| `ro` | dimmed readout | mirrors the camera's formatted `String`; no handler |
| `led` | indicator | mirrors `Boolean`, read-only |
| `status` | status bar | mirrors the camera's Status control |
| `trigger` | button | pulses the camera control |
| `statetrig` | button | pulses `<name>.trigger`, lights from `<name>.state` |

**Ranges are declared, not discovered.** A proxied control cannot report its own
range -- reading `.Min` on a Control *raises* rather than returning nil -- so
every `int`/`float` carries an explicit min/max for the NC-20x60. Where the
camera already returns a display-ready string (`f/1.8`, `1/60`, `1080p60`,
`60Hz`) the control is `ro` instead and needs no range.

**Grey-out is mirrored, not re-derived.** `IsDisabled` *is* readable on a proxied
control and tracks the camera's own logic, so Aperture greys out when Exposure
Mode is Auto exactly as it does natively. A control the camera does not expose,
and every control while no camera is bound, reads disabled. Changing
`IsDisabled` fires no event, so it is refreshed on bind, on any mode change, and
on a 3s backstop timer.

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

## Not reproduced from the native block

- **The live Preview window.** The native Preview group hosts a video stream; a
  plugin proxying another component via `Component` cannot re-host it. The
  Preview group is therefore omitted rather than shown as an empty frame. Use
  the camera component's own Preview, or a Media Display, alongside this plugin.
- **Focus In / Out / AF buttons** sit with Zoom in the Pan/Tilt/Zoom group
  rather than in the Focus group, which is where this plugin has always drawn
  them. The Focus group holds Manual Speed, AF Sensitivity and AF Zone.
- **PTZ pad pin names** are the plugin's own (`ptz_pan_left`, `ptz_home`, ...)
  rather than the camera's (`pan.left`, `preset.home.load`). Renaming them would
  match the rest of the plugin but would break existing wiring, so it has been
  left alone deliberately.

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
| 1.1.0.0 | Cameras and Camera Router moved to a new Setup page; 435px width |
| 1.1.1.0 | AWB mode falls back to known modes if the camera reports no choices |
| 1.1.2.0 | Grey-out mirrored from the camera's own `IsDisabled` |
| 1.2.0.0 | Control registry introduced; full Imaging page |
| 1.3.0.0 | Pan/Tilt/Zoom, Auto Framing, IP Streams and Status pages |