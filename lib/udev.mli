(** Minimal bindings to libudev to avoid an external dependency for simple uses of libinput. *)

type t = [`Udev] Ctypes.structure Ctypes.ptr

val create : unit -> t
(** Create a new udev context (with the "udev_new" C call).

    When the GC finaliser runs, the context will be unref'd. *)
