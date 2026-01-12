(** A collection of input devices (e.g. mouse and keyboard) to be used together by one person. *)

type t = C.Functions.Seat.t Droppable.t

val get_physical_name : t -> string
val get_logical_name : t -> string

val pp : t Fmt.t [@@ocaml.toplevel_printer]
