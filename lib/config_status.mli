(** Status codes returned when applying configuration settings. *)

type t = [
  | `Success            (** Config applied successfully  *)
  | `Unsupported        (** Configuration not available on this device *)
  | `Invalid            (** Invalid parameter range *)
]

val or_fail : t -> unit
(** [set ... |> or_fail] raises a suitable exception if the result is not [`Success]. *)
