include Context0

let keep v ~while_alive =
  Gc.finalise_last (fun () -> ignore (Sys.opaque_identity v)) while_alive

let flags_to_ocaml x =
  let module T = C.Types.Open_flags in
  let has y = x land y <> 0 in
  assert (has T.o_cloexec);
  let access =
    let mode = x land T.o_accmode in
    if mode = T.o_rdonly then Unix.O_RDONLY
    else if mode = T.o_wronly then Unix.O_WRONLY
    else if mode = T.o_rdwr then Unix.O_RDWR
    else Fmt.failwith "Unknown mode %X" mode
  in
  let unknown_flags = x land (lnot (T.o_cloexec lor T.o_nonblock lor T.o_accmode)) in
  if unknown_flags <> 0 then Fmt.epr "WARNING: Unknown open flags: %x@." unknown_flags;
  [access; Unix.O_CLOEXEC]
  @ (if has T.o_nonblock then [Unix.O_NONBLOCK] else [])

external code_of_unix_error : Unix.error -> int = "caml_libinput_code_of_unix_error"
external unix_error_of_code : int -> Unix.error = "caml_libinput_unix_error_of_code"

let unref c =
  match C.Functions.unref c with
  | Some _ -> failwith "libinput_unref failed; something else is holding a reference!"
  | None -> ()

let with_interface { Interface.open_restricted; close_restricted } make =
  let open_restricted path flags _user_data =
    let path = Ctypes.(coerce (ptr char) string) path in
    match open_restricted path (flags_to_ocaml flags) with
    | Ok fd -> (Obj.magic (fd : Unix.file_descr) : int)
    | Error code
    | exception Unix.Unix_error (code, _, _) -> -(code_of_unix_error code)
    | exception ex ->
      let bt = Printexc.get_raw_backtrace () in
      Fmt.epr "WARNING: @[<v>Non-Unix_error exception raised by open_restricted:@,%a@]@." Fmt.exn_backtrace (ex, bt);
      -(code_of_unix_error EFAULT)
  in
  let close_restricted fd _user_data =
    let fd : Unix.file_descr = Obj.magic (fd : int) in
    close_restricted fd
  in
  let interface = Ctypes.make C.Types.Interface.t in
  Ctypes.setf interface C.Types.Interface.open_restricted open_restricted;
  Ctypes.setf interface C.Types.Interface.close_restricted close_restricted;
  let c = make (Ctypes.addr interface) in
  keep (interface, open_restricted, close_restricted) ~while_alive:c;
  let c, _dtor = Droppable.make c unref in       (* ignoring dtor because we just leak on GC for the context itself *)
  { c; dtors = Hashtbl.create 100; free = Atomic.make []; resources = Weaktbl.create 100; log_handler = Any () }

module Udev = struct
  let create interface udev =
    with_interface interface @@ fun interface ->
    let user_data = Ctypes.null in
    match C.Functions.udev_create_context interface user_data udev with
    | None -> failwith "libinput_udev_create_context failed"
    | Some t -> t

  let assign_seat t id =
    match C.Functions.udev_assign_seat (use t) id with
    | 0 -> ()
    | x -> Fmt.failwith "libinput_udev_assign_seat failed (returned %d)" x
end

module Path = struct
  let create interface =
    with_interface interface @@ fun interface ->
    let user_data = Ctypes.null in
    match C.Functions.path_create_context interface user_data with
    | None -> failwith "libinput_path_create_context failed"
    | Some t -> t

  let add_device t path =
    C.Functions.path_add_device (use t) path
    |> Option.map (fun cptr ->
        C.Functions.Device.ref cptr;
        Device.import t cptr
      )

  let remove_device d =
    C.Functions.path_remove_device (Device.use d)
end

module Log = struct
  module Priority = C.Types.Log_priority

  let set_priority t v =
    C.Functions.Log.set_priority (use t) v

  let get_priority t =
    C.Functions.Log.get_priority (use t)

  type handler = Priority.t -> string -> unit

  let set_handler t handler =
    t.log_handler <- Any (t.log_handler, handler);
    C.Functions.Log.set_handler (use t) handler;
    t.log_handler <- Any handler
end

let destroy t =
  (* GC finalisers for resources may run at any point, but they just add the dtor ID
     to t.free, which we ignore. We clear [t.dtors], so if the user does
     (incorrectly) try to interact with [t] in future, the worst that
     will happen is a not-found exception trying to look up the ID. *)
  Weaktbl.clear t.resources;
  Hashtbl.iter (fun _id dtor -> dtor ()) t.dtors;
  Hashtbl.clear t.dtors;
  Droppable.destroy t.c

let dispatch t =
  process_free_list t;
  match C.Functions.dispatch (use t) with
  | 0 -> ()
  | negerrno ->
    raise (Unix.Unix_error (unix_error_of_code (-negerrno), "libinput_dispatch", ""))

let get_fd t =
  C.Functions.get_fd (use t)

let suspend t =
  C.Functions.suspend (use t)

let resume t =
  if not (C.Functions.resume (use t)) then
    failwith "libinput resume failed"
