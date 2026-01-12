type 'a t = {
  context : [`Udev | `Path] Context.t;
  e : C.Functions.Event.t Droppable.t;
}

let get context =
  Context0.get_event context
  |> Option.map (fun e -> { context; e })

let use t = Droppable.use t.e

let get_context t = t.context

let destroy e = Droppable.destroy e.e
