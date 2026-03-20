open Event0

type ty = [
  | `Tablet_pad_button of [`Tablet_pad_button] t
  | `Tablet_pad_ring of [`Tablet_pad_ring] t
  | `Tablet_pad_strip of [`Tablet_pad_strip] t
  | `Tablet_pad_key of [`Tablet_pad_key] t
  | `Tablet_pad_dial of [`Tablet_pad_dial] t
]

type any = [
  | `Tablet_pad_button
  | `Tablet_pad_ring
  | `Tablet_pad_strip
  | `Tablet_pad_key
  | `Tablet_pad_dial
]

let ev t =
  match C.Functions.Event.Tablet_pad.get_event (use t) with
  | Some kev -> kev
  | None -> failwith "Not a tablet-pad event!"

module F = C.Functions.Event.Tablet_pad

let get_time t = F.get_time_usec (ev t)
let get_ring_position t = F.get_ring_position (ev t)
let get_ring_number t = F.get_ring_number (ev t)
let get_ring_source t = F.get_ring_source (ev t)
let get_strip_position t = F.get_strip_position (ev t)
let get_strip_number t = F.get_strip_number (ev t)
let get_strip_source t = F.get_strip_source (ev t)
let get_button_number t = F.get_button_number (ev t)
let get_button_state t = F.get_button_state (ev t)
let get_key t = F.get_key (ev t)
let get_key_state t = F.get_key_state (ev t)

let get_dial_delta_v120 t =
  match F.get_dial_delta_v120 with
  | Some f -> f (ev t)
  | None -> failwith "Requires libinput 1.26 or later"

let get_dial_number t =
  match F.get_dial_number with
  | Some f -> f (ev t)
  | None -> 0

let get_mode t = F.get_mode (ev t)

let get_mode_group t =
  let cptr = F.get_mode_group (ev t) in
  C.Functions.Mode_group.ref cptr;
  Context0.import_mode_group t.context cptr

let pp f e =
  Fmt.pf f "{@[<v>time = %a;@;...}"
    Timestamp.pp (get_time e)

let pp_payload f = function
  | `Tablet_pad_button e -> pp f e
  | `Tablet_pad_ring e -> pp f e
  | `Tablet_pad_strip e -> pp f e
  | `Tablet_pad_key e -> pp f e
  | `Tablet_pad_dial e -> pp f e
