(** Event timestamps, with microsecond precision.

    See {{: https://wayland.freedesktop.org/libinput/doc/latest/timestamps.html }} *)

type t = int64
(** CLOCK_MONOTONIC microseconds (from unspecified base, but typically running time since boot). *)

val to_seconds : t -> float

val pp : t Fmt.t [@@ocaml.toplevel_printer]
