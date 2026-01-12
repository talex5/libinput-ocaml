(** A group of kernel devices making up one physical device. *)

type t = C.Functions.Device_group.t Droppable.t

val equal : t -> t -> bool
