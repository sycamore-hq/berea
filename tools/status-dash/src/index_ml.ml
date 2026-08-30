(* Entry: bun run _generated/Index.js — bun run index *)

let () =
  let root = Paths.resolve_project_root () in
  let result = Rebuild.rebuild_all root in
  Js_shims.Console.log
    (Printf.sprintf "indexed %d features, %d memory notes" result.Rebuild.rb_features
       result.Rebuild.rb_memory_notes);
  List.iter
    (fun (e : Load_tree.parse_error) ->
      Js_shims.Console.warn
        ("parse: " ^ e.Load_tree.err_path ^ ": " ^ e.Load_tree.err_message))
    result.Rebuild.rb_parse_errors
