type t = C.Types.Config.status

let or_fail = function
  | `Success -> ()
  | x -> failwith (C.Functions.Config.status_to_str x)
