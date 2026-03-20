module Capability = struct
  type t = C.Types.Device_capability.t =
    | Keyboard
    | Pointer
    | Touch
    | Tablet_tool
    | Tablet_pad
    | Gesture
    | Switch
    | Unknown of int64
end

module F = C.Functions.Device

type t = {
  context : [`Udev | `Path] Context0.t;
  c : [`Libinput_device] Ctypes.structure Ctypes.ptr Droppable.t;
}

let use t = Droppable.use t.c

let get_context t = t.context
let get_sysname t = F.get_sysname (use t)
let get_name t = F.get_name (use t)
let has_capability t = F.has_capability (use t)

let get_id_bustype t =
  match F.get_id_bustype with
  | Some f -> f (use t)
  | None -> 0

let get_id_product t = F.get_id_product (use t)
let get_id_vendor t = F.get_id_vendor (use t)

let get_output_name t =
  F.get_output_name (use t)
  |> Option.map Ctypes.(coerce (ptr (const char)) string)

let set_seat_logical_name t name =
  match F.set_seat_logical_name (use t) name with
  | 0 -> ()
  | x -> Fmt.failwith "libinput_device_set_seat_logical_name returned error code %d" x

let get_size t =
  let open Ctypes in
  let width = allocate_n double ~count:2 in
  let height = width +@ 1 in
  if F.get_size (use t) width height <> 0 then None
  else (
    Some (!@ width, !@ height)
  )

let import context cptr =
  let c = Context0.import_device context cptr in
  let context = (context :> [`Udev | `Path] Context0.t) in
  { context; c }

let get_seat t =
  let cptr = C.Functions.Device.get_seat (use t) in
  C.Functions.Seat.ref cptr;
  Context0.import_seat t.context cptr

let get_device_group t =
  let cptr = C.Functions.Device.get_device_group (use t) in
  C.Functions.Device_group.ref cptr;
  Context0.import_device_group t.context cptr

let bool_or_error = function
  | 0 -> Ok false
  | 1 -> Ok true
  | -1 -> Error ()
  | x -> Fmt.failwith "Unexpected return value %d" x

let int_or_error x =
  if x = -1 then Error ()
  else Ok x

module Keyboard = struct
  let has_key t x = F.keyboard_has_key (use t) x |> bool_or_error
end

module Pointer = struct
  let has_button t x = F.pointer_has_button (use t) x |> bool_or_error
end

module Switch = struct
  let has_switch t x = F.switch_has_switch (use t) (x :> C.Types.Switch.t) |> bool_or_error
end

module Touch = struct
  let get_touch_count t = F.touch_get_touch_count (use t) |> int_or_error
end

module Tablet_pad = struct
  module F = F.Tablet_pad

  let get_num_mode_groups t = F.get_num_mode_groups (use t)

  let get_mode_group t index =
    F.get_mode_group (use t) index
    |> Option.map (fun cptr ->
        C.Functions.Mode_group.ref cptr;
        Context0.import_mode_group t.context cptr
      )

  let get_num_buttons t = F.get_num_buttons (use t) |> int_or_error

  let get_num_dials t =
    match F.get_num_dials with
    | Some f -> f (use t) |> int_or_error
    | None -> Error ()

  let get_num_rings t = F.get_num_rings (use t) |> int_or_error
  let get_num_strips t = F.get_num_strips (use t) |> int_or_error
  let has_key t x = F.has_key (use t) x |> bool_or_error
end

module Config = struct
  module Setting = C.Functions.Device.Config.Setting
  type 'a setting = 'a Setting.t

  let set t (k : _ Setting.t) v =
    match k with
    | Setting k -> k.set (use t) v
    | Unsupported _ -> `Unsupported

  let get t (k : _ Setting.t) =
    match k with
    | Setting k -> k.get (use t)
    | Unsupported x -> x

  let get_default t (k : _ Setting.t) =
    match k with
    | Setting k -> k.get_default (use t)
    | Unsupported x -> x

  module Tap = struct
    module F = C.Functions.Device.Config.Tap

    let enabled = F.enabled
    let get_finger_count t = F.get_finger_count (use t)
    let button_map = F.button_map
    let drag_enabled = F.drag_enabled
    let drag_lock_enabled = F.drag_lock_enabled
  end

  module Calibration_matrix = struct
    module F = C.Functions.Device.Config.Calibration_matrix
    type matrix = F.matrix

    let is_supported t = F.is_supported (use t)

    let get c =
      let m = F.create_matrix () in
      let ident = F.get c m in
      F.matrix_of_ptr m, ident

    let get_default c =
      let m = F.create_matrix () in
      let ident = F.get_default c m in
      F.matrix_of_ptr m, ident

    let matrix =
      let get c = fst (get c) in
      let get_default c = fst (get_default c) in
      Setting.Setting { set = F.set; get; get_default }

    let get t = get (use t)
    let get_default t = get_default (use t)

    let pp_matrix ppf ((a, b, c), (d, e, f)) =
      Fmt.pf ppf "[%f %f %f@;<1 1>%f %f %f]" a b c d e f
  end

  module Three_finger_drag_state = struct
    module F = C.Functions.Device.Config.Three_finger_drag

    let get_finger_count t =
      match F.get_finger_count with
      | Some fn -> fn (use t)
      | None -> 0

    let enabled = F.enabled
  end

  module Area = struct
    module F = C.Functions.Device.Config.Area
    module A = C.Types.Config.Area_rectangle

    type rectangle = {
      x1 : float;
      y1 : float;
      x2 : float;
      y2 : float;
    }

    let of_c c =
      let open Ctypes in
      {
        x1 = getf c A.x1;
        y1 = getf c A.y1;
        x2 = getf c A.x2;
        y2 = getf c A.y2;
      }

    let to_c { x1; y1; x2; y2 } =
      let open Ctypes in
      let c = make A.t in
      setf c A.x1 x1;
      setf c A.y1 y1;
      setf c A.x2 x2;
      setf c A.y2 y2;
      c

    let rectangle =
      if Config.version > (1, 26) then (
        let set t v = Option.get F.set_rectangle t (Ctypes.addr (to_c v)) in
        let get t = of_c @@ Option.get F.get_rectangle t in
        let get_default t = of_c @@ Option.get F.get_default_rectangle t in
        Setting.Setting { set; get; get_default }
      ) else Setting.Unsupported { x1 = 0.0; y1 = 0.0; x2 = 0.0; y2 = 0.0 }
  end

  module Send_events = struct
    module Mode = C.Types.Config.Send_events_mode
    module F = C.Functions.Device.Config.Send_events
    let get_modes t = F.get_modes (use t)
    let mode = F.mode
  end

  module Accel = struct
    module Profile = C.Types.Config.Accel_profile
    module F = C.Functions.Device.Config.Accel

    let is_available t = F.is_available (use t)
    let speed = F.speed
    let accel_get_profiles t = F.accel_get_profiles (use t)
    let profile = F.profile

    type custom = {
      ty : C.Types.Config.accel_type;
      step : float;
      points : float list;
    }

    let rec accel_set_points c = function
      | [] -> `Success
      | { ty; step; points } :: xs ->
        let points = Ctypes.CArray.of_list Ctypes.double points in
        let npoints = Unsigned.Size_t.of_int points.alength in
        match F.accel_set_points c ty step npoints points.astart with
        | `Success -> accel_set_points c xs
        | err -> err

    let set_accel t v =
      let profile =
        let module T = C.Types.Config.Accel_profile in
        match v with
        | `Flat -> T.flat
        | `Adaptive -> T.adaptive
        | `Custom _ -> T.custom
      in
      match F.accel_create profile with
      | None -> Fmt.failwith "libinput_config_accel_create returned NULL"
      | Some c ->
        Fun.protect ~finally:(fun () -> F.accel_destroy c) @@ fun () ->
        let funcs =
          match v with
          | `Flat | `Adaptive -> []
          | `Custom funcs -> funcs
        in
        match accel_set_points c funcs with
        | `Success -> F.accel_apply (use t) c
        | err -> err
  end

  module Left_handled = struct
    module F = C.Functions.Device.Config.Left_handled
    let is_available t = F.is_available (use t)
    let enabled = F.enabled
  end

  module Click = struct
    module Method = C.Types.Config.Click_method
    module F = C.Functions.Device.Config.Click
    let get_methods t = F.get_methods (use t)
    let meth = F.meth
    let clickfinger_button_map = F.clickfinger_button_map
  end

  module Middle_emulation = struct
    module F = C.Functions.Device.Config.Middle_emulation
    let is_available t = F.is_available (use t)
    let enabled = F.enabled
  end

  module Scroll = struct
    module Method = C.Types.Config.Scroll_method
    module F = C.Functions.Device.Config.Scroll
    let get_methods t = F.get_methods (use t)
    let meth = F.meth
    let button = F.button
    let button_lock = F.button_lock
  end

  module Dwt = struct
    module F = C.Functions.Device.Config.Dwt
    let is_available t = F.is_available (use t)
    let enabled = F.enabled
  end

  module Dwtp = struct
    module F = C.Functions.Device.Config.Dwtp
    let is_available t = F.is_available (use t)
    let enabled = F.enabled
  end

  module Rotation = struct
    module F = C.Functions.Device.Config.Rotation
    let is_available t = F.is_available (use t)
    let angle = F.angle
  end
end

module Led = struct
  type t = int64

  include C.Types.Led

  let none = 0L
  let ( + ) = Int64.logor

  let compose = Option.value compose ~default:none
  let kana = Option.value kana ~default:none
end

let led_update t leds = F.led_update (use t) leds

let pp_size f t =
  match get_size t with
  | None -> ()
  | Some (w, h) -> Fmt.pf f ";@;size = %.1fx%.1fmm" w h

let dump f t =
  Fmt.pf f "{@[sysname = %S;@;name = %S;@;bustype = %#x;@;vendor = %#x;@;product = %#x;@;output = %a;@;seat = %a%a@]}"
    (get_sysname t)
    (get_name t)
    (get_id_bustype t)
    (get_id_vendor t)
    (get_id_product t)
    Fmt.(option ~none:(any "null") (fmt "%S")) (get_output_name t)
    Seat.pp (get_seat t)
    pp_size t

let pp f t =
  Fmt.pf f "{@[sysname = %S;@;name = %S;@;...@]}"
    (get_sysname t)
    (get_name t)
