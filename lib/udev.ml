type t = C.Types.Udev.t Ctypes.ptr

let create () =
  match C.Functions.Udev.create () with
  | None -> failwith "udev_new failed (returned NULL)"
  | Some x ->
    Gc.finalise C.Functions.Udev.unref x;
    x
