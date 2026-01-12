(** Handles for accessing libinput.

    Create a context using {!Context.Udev.create} or {!Context.Path.create}.

    When done (typically when your program exits), call {!Context.destroy}.
    This is not done automatically from a GC finaliser because destroying a
    context may trigger various actions (such as sending DBus messages) and
    it's good to control when these happen. *)

type +'a t = 'a Context0.t
(** A handle for accessing libinput. *)

(** A context that uses udev to find available devices. *)
module Udev : sig
  val create : Interface.t -> Udev.t -> [> `Udev] t
  (**  This context is inactive until assigned a seat ID with {!assign_seat}.

       Call {!destroy} to release the context when finished (GC will not free it). *)

  val assign_seat : [`Udev] t -> string -> unit
  (** [assign_seat t id] assigns a seat to this libinput context.

      New devices or the removal of existing devices will appear as events during {!dispatch}.

      This call succeeds even if no input devices are currently available on
      this seat, or if devices are available but fail to open (with {!Interface.open_restricted}).

      Devices that do not have the minimum capabilities to be recognized as
      pointer, keyboard or touch device are ignored.
      Such devices and those that failed to open are ignored until the next call to {!resume}.

      This function may only be called once per context. *)
end

(** A context that requires the caller to add and remove devices explicitly. *)
module Path : sig
  val create : Interface.t -> [> `Path] t
  (** [create interface] returns a fresh, empty libinput context.

       Call {!destroy} to release the context when finished (GC will not free it). *)

  val add_device : [`Path] t -> string -> Device.t option
  val remove_device : Device.t -> unit
end

val dispatch : _ t -> unit
(** [dispatch t] reads events from the file descriptors and processes them internally.

    Dispatching does not necessarily queue libinput events.
    This function should be called immediately once data is available on the file
    descriptor returned by {!get_fd}. libinput has a number of
    timing-sensitive features (e.g. tap-to-click); any delay in calling
    [dispatch] may prevent these features from working correctly. *)

val get_fd : _ t -> Unix.file_descr
(** [get_fd t] is the single file descriptor that libinput uses for all events.

    Call {!dispatch} if any events become available on this fd.
    The returned descriptor is valid until {!destroy} is called. *)

val suspend : _ t -> unit
(** Suspend monitoring for new devices and close existing devices.

    This all but terminates libinput but does keep the context
    valid to be resumed with {!resume}. *)

val resume : _ t -> unit
(** Resume a suspended libinput context.

    This re-enables device monitoring and adds existing devices. *)

val destroy : _ t -> unit
(** [destroy t] releases the context and all associated resources.

    Attempting to use devices, events, etc after this will fail. *)

(** Configure log levels. *)
module Log : sig
  module Priority : sig
    type t =
      | Debug
      | Info
      | Error
      | Unknown of int64
  end

  val set_priority : _ t -> Priority.t -> unit
  val get_priority : _ t -> Priority.t

  type handler = Priority.t -> string -> unit

  val set_handler : _ t -> handler -> unit
end
