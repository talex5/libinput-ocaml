(** Keyboard key code.
    
    See {{: https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h }} *)

type t = private int

val of_int : int -> t
val of_uint32 : Unsigned.UInt32.t -> t
val to_uint32 : t -> Unsigned.UInt32.t
val pp : t Fmt.t
