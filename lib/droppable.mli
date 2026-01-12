(** A reference to a C struct that can be destroyed. *)

type 'a t

type dtor = unit -> unit
(** A destructor function. *)

val make : 'a -> ('a -> unit) -> 'a t * dtor
(** [let t, dtor = make cptr free] creates a wrapper [t] around [cptr] that will use [free cptr] later to free it.

    [dtor] is a function that marks [t] as invalid and calls the [free] function the first time it is called,
    and does nothing on future calls. [dtor] does not hold a reference to [t], so you can hold on to it
    without preventing any GC finaliser attached to [t] from being triggered. *)

val use : 'a t -> 'a
(** [use t] returns the underlying C pointer, or raises [Invalid_argument] if it has been destroyed. *)

val destroy : 'a t -> unit
(** [destroy t] marks [t] as destroyed and frees it.

    Does nothing if [t] is already destroyed. *)
