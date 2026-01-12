type dtor = unit -> unit

type 'a t = {
  (* Wrapped because the context needs to hold a reference to [payload] without
     preventing the outer record from being GC'd. *)
  payload : ('a * ('a -> unit)) option ref;
}

let dtor payload =
  match !payload with
  | None -> ()
  | Some (x, free) ->
    payload := None;
    free x

let make x free =
  let payload = ref (Some (x, free)) in
  let t = { payload } in
  t, (fun () -> dtor payload)

let use t =
  match !(t.payload) with
  | Some (x, _free) -> x
  | None -> invalid_arg "Resource has been destroyed"

let destroy t = dtor t.payload
