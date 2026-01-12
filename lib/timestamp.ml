type t = int64

let to_seconds t = Int64.to_float t /. 1e6

let pp f t = Fmt.pf f "%.6f" (to_seconds t)
