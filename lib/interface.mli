(** Callbacks for opening device files.

    libinput does not open file descriptors to devices directly.
    Instead, it calls functions provided by the user of the library. *)

type t = {
  open_restricted : string -> Unix.open_flag list -> (Unix.file_descr, Unix.error) result;
  (** [open_restricted path flags] should attempt to open [path] with the given [flags].

      Currently, [flags] is always {!Unix.O_NONBLOCK}, {!Unix.O_CLOEXEC} and the mode (e.g. {!Unix.O_RDWR}).

      On error, it can either return [Error code] or raise {!Unix.Unix_error}. *)

  close_restricted : Unix.file_descr -> unit;
  (** [close_restricted fd] is used to release a device previously opened with {!open_restricted}. *)
}

val unix_direct : t
(** [unix_direct] is a pair of callbacks using the {!Unix} module to open the files directly.

    This can work in specific cases, but for a normal desktop environment you won't have permission
    to open devices directly will need to use DBus to get access from e.g. systemd-logind. *)

val major : PosixTypes.dev_t -> int
(** [major dev] extracts the major device ID from a [dev_t].

    This is needed when using systemd-logind.
    This is only provided here as a convenience, as it's missing from {!PosixTypes.Dev}. *)

val minor : PosixTypes.dev_t -> int
(** [minor dev] extracts the minor device ID from a [dev_t] (see {!major}). *)
