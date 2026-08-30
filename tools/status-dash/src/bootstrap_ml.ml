(* Entry: bun run _generated/Bootstrap.js — zero-touch bootstrap *)

module F = Js_shims.Fs
module P = Js_shims.Path

let () =
  let cwd = Js_shims.Process.cwd () in
  Js_shims.Process.chdir (Paths.tool_root ());
  (try Js_shims.Child_process.exec_sync "bun install"
   with e ->
     Js_shims.Console.error ("bun install failed: " ^ Printexc.to_string e);
     Js_shims.Process.exit 1);
  let root = Paths.resolve_project_root () in
  ignore cwd;
  let paths = Paths.paths_for root in
  F.mkdir_p paths.Paths.dash;
  let db =
    try
      let db = Overlay.open_db paths.Paths.db in
      Overlay.apply_migrations db;
      Some db
    with e ->
      Js_shims.Console.error ("sqlite migration failed: " ^ Printexc.to_string e);
      Js_shims.Process.exit 1
  in
  ignore db;
  if not (F.exists_sync paths.Paths.specs) then F.mkdir_p paths.Paths.specs;
  F.mkdir_p (P.dirname paths.Paths.constitution);
  if not (F.exists_sync paths.Paths.constitution) then
    F.write_file_sync paths.Paths.constitution (Paths.constitution_stub ());
  if not (F.exists_sync paths.Paths.memory) then F.mkdir_p paths.Paths.memory;
  let indexed = Rebuild.rebuild_all root in
  let boot =
    String.concat
      "\n"
      [ "# Bootstrap";
        "";
        "project_root: " ^ root;
        "specs: " ^ string_of_int indexed.Rebuild.rb_features;
        ( "constitution: "
        ^ (if F.exists_sync paths.Paths.constitution then "present" else "missing") );
        "overlay: ok";
        "memory_notes: " ^ string_of_int indexed.Rebuild.rb_memory_notes;
        "generated_js: committed _generated/ (Melange optional)";
        "generated_at: " ^ indexed.Rebuild.rb_generated_at;
        "";
        "No interactive prompts. Files are the writings.";
        "" ]
  in
  F.write_file_sync paths.Paths.bootstrap_md boot;
  Js_shims.Console.log ("bootstrapped " ^ root);
  Js_shims.Process.exit 0
