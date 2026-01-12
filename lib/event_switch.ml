open Event0

type ty = [
  | `Switch_toggle of [`Switch_toggle] t
]

type any = [`Switch_toggle]

module Type = struct
  let pp f = function
    | `Lid -> Fmt.string f "Lid"
    | `Tablet_mode -> Fmt.string f "Tablet_mode"
    | `Unknown x -> Fmt.pf f "Unknown %Ld" x
end

let ev t =
  match C.Functions.Event.Switch.get_event (use t) with
  | Some ev -> ev
  | None -> failwith "Not a switch event!"

module F = C.Functions.Event.Switch

let get_time t = F.get_time_usec (ev t)

let get_type t = F.get_switch (ev t)
let get_state t = F.get_switch_state (ev t)

let pp_payload f (`Switch_toggle e) =
  Fmt.pf f "{@[<v>time = %a;@;switch = %a;@;switch_state = %s@]}"
    Timestamp.pp (get_time e)
    Type.pp (get_type e)
    (match get_state e with `Off -> "`Off" | `On -> "`On")
