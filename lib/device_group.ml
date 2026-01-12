module F = C.Functions.Device_group

type t = F.t Droppable.t

let equal = (==)
