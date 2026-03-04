(** Keyboard key code.
    
    See {{: https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h }} *)

type t = private int

val pp : t Fmt.t

(** {2 Conversions} *)

val of_int : int -> t
val of_uint32 : Unsigned.UInt32.t -> t
val to_uint32 : t -> Unsigned.UInt32.t

(** {2 Common keys} *)

val key_esc : t
val key_enter : t
val key_space : t
val key_tab : t

val key_home : t
val key_end : t

val key_left : t
val key_right : t

val key_up : t
val key_down : t

val key_pageup : t
val key_pagedown : t

val key_backspace : t
val key_delete : t

(** {2 Mouse buttons} *)

val btn_left : t
val btn_right : t
val btn_middle : t
