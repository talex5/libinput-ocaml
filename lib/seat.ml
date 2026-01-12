module F = C.Functions.Seat

type t = F.t Droppable.t

let use t = Droppable.use t

let get_physical_name t = F.get_physical_name (use t)
let get_logical_name t = F.get_logical_name (use t)

let pp f t =
  Fmt.pf f "{@[physical_name = %S;@;logical_name = %S@]}"
    (get_physical_name t)
    (get_logical_name t)
