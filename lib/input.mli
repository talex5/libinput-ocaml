(** OCaml bindings for {{: https://gitlab.freedesktop.org/libinput/libinput } libinput}.
    This library is used by e.g. Wayland compositors to support keyboards and mice. *)

(** {2 Contexts} *)

module Context = Context
module Interface = Interface
module Udev = Udev

(** {2 Devices} *)

module Device = Device
module Device_group = Device_group
module Config_status = Config_status
module Seat = Seat

(** {2 Events} *)

module Event = Event
module Timestamp = Timestamp
module Keycode = Keycode

(** {2 Tablets} *)

module Tablet_tool = Tablet_tool
module Mode_group = Mode_group
