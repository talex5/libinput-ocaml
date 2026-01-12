(* libinput resources are mostly ref-counted.
   However, libinput will also free some resources while their count is non-zero;
   see https://bugs.freedesktop.org/show_bug.cgi?id=91872.

   Specifically, when the ref-count for the main context reaches 0, libinput
   immediately destroys devices, tools, etc, even if other users still have a
   reference to them.

   If we free a context while e.g. an event remains allocated, then we'd be stuck:
   - Not destroying the C event would leak memory.
   - Destroying it will try to unref its device, which is already freed and
     will likely cause a segfault.

   Therefore, every C pointer gets wrapped in a Droppable, which can be invalidated:

   - Destroying a context invalidates and frees every resource created from it first.

   - If a resource is GC'd then the finaliser adds it to the context's [free]
     list, which will be processed on the next [dispatch]. This doesn't happen
     immediately because finalisers can run from any thread and libinput isn't
     thread-safe.

   - If a resource is explictly destroyed by the user then the C struct is freed
     immediately and the Droppable invalidated. When the GC runs later, it will
     still add the ID to the free list, and the context will later remove and
     call the destructor (which won't do anything as it's already freed).

   Destroying a context and destroying a resource explicitly both happen from the
   libinput thread and so can't race with each other. Destroying a resource can't
   race with the GC because we still hold a reference while doing the destroy.
   Destroying a context can race with GC, but it doesn't matter because the
   finaliser only adds things to the free list, which will be ignored after
   freeing.

   Also, we'd like to return the same OCaml object for the same C object. e.g.
   we'd like to ensure [Event.get_device e == Event.get_device e].
   Therefore, we maintain a weak hashtable ([resources]) from C addresses to OCaml wrappers.
   If the C pointer we want is in the table then we reuse that one (GC can't be running
   because we got a pointer from the weak hashtable and that strong reference prevents GC). *)

module Weaktbl = Ephemeron.K1.Make(Nativeint)
module Address_map = Map.Make(Nativeint)

type dtor_id = < >              (* A unique ID for every reference count *)

type gc_holder = Any : 'a -> gc_holder

(* A reference-counted resource that depends on a context. *)
type resource =
  | Device_group of C.Types.Device_group.t Ctypes.ptr Droppable.t
  | Device of C.Types.Device.t Ctypes.ptr Droppable.t
  | Seat of C.Types.Seat.t Ctypes.ptr Droppable.t
  | Tool of C.Types.Tool.t Ctypes.ptr Droppable.t
  | Mode_group of C.Types.Mode_group.t Ctypes.ptr Droppable.t

(** @canonical Input.Context.t *)
type _ t = {
  c : C.Types.Libinput.t Ctypes.ptr Droppable.t;

  resources : resource Weaktbl.t;
  (* If libinput returns a pointer we already know, use this to return the original OCaml wrapper
     instead of making a new one. *)

  dtors : (dtor_id, Droppable.dtor) Hashtbl.t;
  (* Resources that need to be destroyed before destroying the context.
     [dtor] is part of [Droppable], but not the whole of it (so doesn't prevent GC).
     Can't use the C address as the key here, since we might need to allocate a new
     Droppable while a previous one is being GC'd. *)

  free : dtor_id list Atomic.t;
  (* Resources in [dtors] that are no longer needed (GC finaliser has run)
     and should be freed from the main thread at the next opportunity.
     This is atomic because it's accessed by the GC finaliser, which may be running
     in a different thread. *)

  mutable log_handler : gc_holder;
  (* Store user log handler here to prevent the GC freeing it.
     The caller needs to hold on to the context in order to call [destroy]
     at the end, so it shouldn't get freed before then. But if it does then the
     user can't call any functions that might produce log output, so it should
     be OK anyway. *)
}

let use t = Droppable.use t.c

let rec enqueue_free t dtor =
  let old = Atomic.get t.free in
  if not @@ Atomic.compare_and_set t.free old (dtor :: old) then enqueue_free t dtor

(* Register new C reference [cptr] as something that needs to be released later. *)
let register_resource t ~free cptr =
  let wrapper, dtor = Droppable.make cptr free in
  let dtor_id = object end in
  Hashtbl.add t.dtors dtor_id dtor;
  let mark_free () = enqueue_free t dtor_id in
  Gc.finalise_last mark_free wrapper;
  wrapper

(* Clear [t.free] and destroy all resources listed there. *)
let process_free_list t =
  let free = Atomic.exchange t.free [] in
  free |> List.iter (fun id ->
      let dtor = Hashtbl.find t.dtors id in
      Hashtbl.remove t.dtors id;
      dtor ()
    )

(* Takes ownership of the C reference [cptr]. *)
let import_device_group t cptr =
  let id = Ctypes.raw_address_of_ptr (Ctypes.to_voidp cptr) in
  match Weaktbl.find_opt t.resources id with
  | Some (Device_group x) ->
    C.Functions.Device_group.unref cptr;
    x
  | Some _ -> assert false
  | None ->
    let x = register_resource t cptr ~free:C.Functions.Device_group.unref in
    Weaktbl.add t.resources id (Device_group x);
    x

(* Takes ownership of the C reference [cptr]. *)
let import_device t cptr =
  let id = Ctypes.raw_address_of_ptr (Ctypes.to_voidp cptr) in
  match Weaktbl.find_opt t.resources id with
  | Some (Device x) ->
    C.Functions.Device.unref cptr;
    x
  | Some _ -> assert false
  | None ->
    let x = register_resource t cptr ~free:C.Functions.Device.unref in
    Weaktbl.add t.resources id (Device x);
    x

(* Takes ownership of the C reference [cptr]. *)
let import_seat t cptr =
  let id = Ctypes.raw_address_of_ptr (Ctypes.to_voidp cptr) in
  match Weaktbl.find_opt t.resources id with
  | Some (Seat x) ->
    C.Functions.Seat.unref cptr;
    x
  | Some _ -> assert false
  | None ->
    let x = register_resource t cptr ~free:C.Functions.Seat.unref in
    Weaktbl.add t.resources id (Seat x);
    x

(* Takes ownership of the C reference [cptr]. *)
let import_tool t cptr =
  let id = Ctypes.raw_address_of_ptr (Ctypes.to_voidp cptr) in
  match Weaktbl.find_opt t.resources id with
  | Some (Tool x) ->
    C.Functions.Tool.unref cptr;
    x
  | Some _ -> assert false
  | None ->
    let x = register_resource t cptr ~free:C.Functions.Tool.unref in
    Weaktbl.add t.resources id (Tool x);
    x

(* Takes ownership of the C reference [cptr]. *)
let import_mode_group t cptr =
  let id = Ctypes.raw_address_of_ptr (Ctypes.to_voidp cptr) in
  match Weaktbl.find_opt t.resources id with
  | Some (Mode_group x) ->
    C.Functions.Mode_group.unref cptr;
    x
  | Some _ -> assert false
  | None ->
    let x = register_resource t cptr ~free:C.Functions.Mode_group.unref in
    Weaktbl.add t.resources id (Mode_group x);
    x

let get_event t =
  match C.Functions.get_event (use t) with
  | None -> None
  | Some e -> Some (register_resource t e ~free:C.Functions.Event.destroy)
