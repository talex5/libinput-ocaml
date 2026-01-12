open Event0

type ty = [
  | `Device_added of [`Device_added] t
  | `Device_removed of [`Device_removed] t
]

let pp_payload f _ = Fmt.string f "_"
