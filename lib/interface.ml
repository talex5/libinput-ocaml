type t = {
  open_restricted : string -> Unix.open_flag list -> (Unix.file_descr, Unix.error) result;
  close_restricted : Unix.file_descr -> unit;
}

let open_direct path flags = Ok (Unix.openfile path flags 0)

let unix_direct = { open_restricted = open_direct; close_restricted = Unix.close }

let major dev = C.Functions.major dev |> Unsigned.UInt.to_int
let minor dev = C.Functions.minor dev |> Unsigned.UInt.to_int
