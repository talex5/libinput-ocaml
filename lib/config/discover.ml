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

let get_version c pkg =
  let args = ["--modversion"; pkg] in
  match C.Process.run c "pkg-config" args with
  | { exit_code = 0; stdout; _ } -> String.trim stdout
  | _ ->
    match C.Process.run c "pkgconf" args with
    | { exit_code = 0; stdout; _ } -> String.trim stdout
    | _ ->
      C.die "Failed to get libinput version"

let () =
  C.main ~name:"checklibinput" (fun c ->
      let conf =
        match C.Pkg_config.get c with
        | None -> failwith "pkg-config is not installed"
        | Some pc ->
          let get = pkgconf pc in
          get "libinput" ++ get "libudev"
      in
      let major, minor = Scanf.sscanf (get_version c "libinput") "%d.%d" (fun a b -> (a, b)) in
      C.Flags.write_lines "config.ml" [Printf.sprintf "let version = (%d, %d)" major minor];
      C.Flags.write_sexp "c_flags.sexp"         conf.cflags;
      C.Flags.write_sexp "c_library_flags.sexp" conf.libs
    )
