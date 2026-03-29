OCaml bindings for [libinput](https://gitlab.freedesktop.org/libinput/libinput).

- [Tutorial](https://roscidus.com/blog/blog/2026/03/28/input-devices/)
- [API documentation](https://talex5.github.io/libinput-ocaml/local/libinput/Input/index.html)

This provides access to almost all of the libinput C API. The missing functions are:

- `libinput_next_event_type`: the OCaml bindings combine the event type and payload,
  so providing this would require exporting a second large type, and it doesn't seem useful.

- The various `*_set_user_data` and `*_get_user_data` functions.
  Attaching data to callbacks is easy in OCaml, and you can use ephemerons to attach extra
  data to things if needed.

- Some `*_get_context` functions, as it's easy to pass the context explicitly in OCaml.

- `libinput_device_get_udev_device` would only be useful with compatible udev bindings.

`examples/simple.ml` shows a simple example of using the library.
For example:

```
$ sudo chown "$USER" /dev/input/event2
$ dune exec -- ./examples/simple.exe /dev/input/event2
Adding device "/dev/input/event2"
libinput info: event2  - Logitech USB Optical Mouse: is tagged by udev as: Mouse
libinput info: event2  - Logitech USB Optical Mouse: device is a pointer
Created libinput context
{type = `Device_added _;
 device = {sysname = "event2"; name = "Logitech USB Optical Mouse";
           bustype = 0x3; vendor = 0x46d; product = 0xc077; output = null;
           seat = {physical_name = "seat0"; logical_name = "default"}}]}
Waiting for events...
{type = `Pointer_button {time = 57416.335901;
                         button = 272;
                         state = `Pressed;
                         seat_key_count = 1};
 device = {sysname = "event2"; name = "Logitech USB Optical Mouse"; ...}]}
{type = `Pointer_button {time = 57416.383910;
                         button = 272;
                         state = `Released;
                         seat_key_count = 0};
 device = {sysname = "event2"; name = "Logitech USB Optical Mouse"; ...}]}
```
