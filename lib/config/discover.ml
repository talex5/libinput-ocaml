module C = Configurator.V1

let pkgconf pc package =
  match C.Pkg_config.query pc ~package with
  | None -> failwith (Printf.sprintf "%S is not installed (according to pkg-config)" package)
  | Some conf -> conf

let ( ++ ) x y =
  let open C.Pkg_config in
  {
    cflags = x.cflags @ y.cflags;
    libs = x.libs @ y.libs;
  }

let () =
  C.main ~name:"checklibinput" (fun c ->
      let conf =
        match C.Pkg_config.get c with
        | None -> failwith "pkg-config is not installed"
        | Some pc ->
          let get = pkgconf pc in
          get "libinput" ++ get "libudev"
      in
      C.Flags.write_sexp "c_flags.sexp"         conf.cflags;
      C.Flags.write_sexp "c_library_flags.sexp" conf.libs
    )
