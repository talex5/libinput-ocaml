module F = C.Functions.Tool

type t = C.Types.Tool.t Ctypes.ptr Droppable.t

module Type = struct
  type t = C.Types.Tool_type.t =
    | Pen
    | Eraser
    | Brush
    | Pencil
    | Airbrush
    | Mouse
    | Lens
    | Totem
    | Unknown of int64

  let pp f = function
    | Pen -> Fmt.string f "Pen"
    | Eraser -> Fmt.string f "Eraser"
    | Brush -> Fmt.string f "Brush"
    | Pencil -> Fmt.string f "Pencil"
    | Airbrush -> Fmt.string f "Airbrush"
    | Mouse -> Fmt.string f "Mouse"
    | Lens -> Fmt.string f "Lens"
    | Totem -> Fmt.string f "Totem"
    | Unknown x -> Fmt.pf f "Unknown %Ld" x
end

let use t = Droppable.use t

let get_type t = F.get_type (use t)

let get_tool_id t =
  match Unsigned.UInt64.to_int64 (F.get_tool_id (use t)) with
  | 0L -> None
  | id -> Some id

let has_pressure t = F.has_pressure (use t)
let has_distance t = F.has_distance (use t)
let has_tilt t = F.has_tilt (use t)
let has_rotation t = F.has_rotation (use t)
let has_slider t = F.has_slider (use t)
let has_size t = F.has_size (use t)
let has_wheel t = F.has_wheel (use t)
let has_button t = F.has_button (use t)
let is_unique t = F.is_unique (use t)

let get_serial t =
  match Unsigned.UInt64.to_int64 (F.get_serial (use t)) with
  | 0L -> None
  | id -> Some id

module Config = struct
  module Setting = C.Functions.Tool.Config.Setting
  type 'a setting = 'a Setting.t

  let set t (k : _ Setting.t) v = k.set (use t) v
  let get t (k : _ Setting.t) = k.get (use t)
  let get_default t (k : _ Setting.t) = k.get_default (use t)

  module Pressure_range = struct
    module F = C.Functions.Tool.Config.Pressure_range

    let is_available t = F.is_available (use t)
    let set t ~min ~max = F.set (use t) min max
    let get_minimum t = F.get_minimum (use t)
    let get_maximum t = F.get_maximum (use t)
    let get_default_minimum t = F.get_default_minimum (use t)
    let get_default_maximum t = F.get_default_maximum (use t)
  end

  module Eraser_button = struct
    module F = C.Functions.Tool.Config.Eraser_button

    module Mode = struct
      type t = C.Types.Eraser_button_mode.t =
        | Default
        | Button
        | Unknown of int64

      let pp f = function
        | Default -> Fmt.string f "Default"
        | Button -> Fmt.string f "Button"
        | Unknown x -> Fmt.pf f "Unknown %Ld" x
    end

    let get_modes t = F.get_modes (use t)
    let mode = F.mode
    let button = F.button
  end
end

let pp f t =
  let features =
    [
      has_pressure, "pressure";
      has_distance, "distance";
      has_tilt, "tilt";
      has_rotation, "rotation";
      has_slider, "slider";
      has_size, "size";
      has_wheel, "wheel";
      is_unique, "unique";
    ] |> List.filter_map (fun (p, name) -> if p t then Some name else None)
  in
  Fmt.pf f "{@[type = %a;@;id = %a;@;features = %a@]}"
    Type.pp (get_type t)
    Fmt.(Dump.option int64) (get_tool_id t)
    Fmt.(list ~sep:(any "+") string) features
