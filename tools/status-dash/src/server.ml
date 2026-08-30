(* Entry: bun run dev — _generated/src/server.js *)

let () =
  let root = Paths.resolve_project_root () in
  let app : Hono.hono = App.create_app root in
  let port =
    match int_of_string_opt (Js_shims.Process.env_port ()) with
    | Some p when p > 0 -> p
    | _ -> 8787
  in
  Js_shims.Console.log
    (Printf.sprintf "Reading surface http://127.0.0.1:%d  (root %s)" port root);
  let opts = Js.Obj.empty () in
  Js_shims.set_dyn opts "port" port;
  Js_shims.set_dyn opts "hostname" "0.0.0.0";
  Js_shims.set_dyn opts "fetch" (fun req -> Hono.hono_fetch app req);
  Hono.serve opts
