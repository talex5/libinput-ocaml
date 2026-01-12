let log_level = Input.Context.Log.Priority.Info
let quit_key = Input.Keycode.of_int 16        (* Q *)

(* Handle one event *)
let handle : Input.Event.ty -> unit = function
  | `Keyboard_key e when Input.Event.Keyboard.get_key e = quit_key ->
    Fmt.pr "%a@." Input.Event.pp e;
    raise Exit
  | `Pointer_motion _ | `Tablet_tool_axis _ -> ()       (* Don't log noisy motion events *)
  | `Pointer_axis _ -> ()                               (* Skip obsolete event *)
  | ty -> Fmt.pr "%a@." Input.Event.pp_ty ty            (* Log all other events *)

(* Handle all events in the queue *)
let rec handle_events ctx =
  match Input.Event.get ctx with
  | None -> ()
  | Some event ->
    handle (Input.Event.get_type event);
    Input.Event.destroy event;  (* Optional; don't bother waiting for GC *)
    handle_events ctx

(* If run with arguments, create a context using those devices.
   Otherwise, create a udev context to use all suitable devices. *)
let create_context () =
  (* For this example, we just try to open device files directly.
     You'll need to make the device files be owned by your own user.
     For a real program, replace this with a DBus call to the seat daemon. *)
  let interface = Input.Interface.unix_direct in
  match List.tl (Array.to_list Sys.argv) with
  | [] ->
    let udev = Input.Udev.create () in
    let ctx = Input.Context.Udev.create interface udev in
    Input.Context.Log.set_priority ctx log_level;
    Input.Context.Udev.assign_seat ctx "seat0";
    ctx
  | devices ->
    let ctx = Input.Context.Path.create interface in
    Input.Context.Log.set_priority ctx log_level;
    devices |> List.iter (fun path ->
        Fmt.pr "Adding device %S@." path;
        match Input.Context.Path.add_device ctx path with
        | None -> Fmt.failwith "Failed to add device %S" path
        | Some _dev -> ()
      );
    ctx

let () =
  let ctx = create_context () in
  Fun.protect ~finally:(fun () -> Input.Context.destroy ctx) @@ fun () ->
  Fmt.pr "Created libinput context@.";
  Input.Context.dispatch ctx;
  handle_events ctx;
  let fd = Input.Context.get_fd ctx in
  Fmt.pr "Waiting for events...@.";
  try
    while true do
      let _ = Unix.select [fd] [] [] (-1.0) in
      Input.Context.dispatch ctx;
      handle_events ctx;
    done
  with Exit ->
    Fmt.pr "Exiting at user request@."
