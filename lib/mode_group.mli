(** A mode on a tablet pad is a virtual grouping of functionality. *)

type t = C.Types.Mode_group.t Ctypes.ptr Droppable.t

val get_index : t -> int
val get_num_modes : t -> int
val get_mode : t -> int
val has_button : t -> int -> bool
val has_dial : t -> int -> bool
val has_ring : t -> int -> bool
val has_strip : t -> int -> bool
val button_is_toggle : t -> int -> bool
