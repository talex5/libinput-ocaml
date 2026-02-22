type gc_holder = Any : 'a -> gc_holder

type +_ t
(** @canonical Input.Context.t *)

val make : C.Types.Libinput.t Ctypes.ptr Droppable.t -> _ t

val use : _ t -> C.Types.Libinput.t Ctypes.ptr

val get_event : _ t -> C.Functions.Event.t Droppable.t option

val get_log_handler : _ t -> gc_holder
val set_log_handler : _ t -> gc_holder -> unit

val process_free_list : _ t -> unit

val import_device_group : _ t ->
  C.Functions.Device_group.t ->
  C.Functions.Device_group.t Droppable.t

val import_device : _ t ->
  C.Functions.Device.t ->
  C.Functions.Device.t Droppable.t

val import_seat : _ t ->
  C.Functions.Seat.t ->
  C.Functions.Seat.t Droppable.t

val import_tool : _ t ->
  C.Functions.Tool.t ->
  C.Functions.Tool.t Droppable.t

val import_mode_group : _ t ->
  C.Functions.Mode_group.t ->
  C.Functions.Mode_group.t Droppable.t

val destroy : _ t -> unit
