(* Rebuilds the derived context layer and the FTS index. *)

module F = Js_shims.Fs
module P = Js_shims.Path

type rb_result =
  { rb_features : int
  ; rb_memory_notes : int
  ; rb_parse_errors : Load_tree.parse_error list
  ; rb_summary : string
  ; rb_generated_at : string
  }

let ensure_dash_dir paths =
  F.mkdir_p paths.Paths.dash;
  F.mkdir_p paths.Paths.context
;;

let rebuild_all root =
  let paths = Paths.paths_for root in
  ensure_dash_dir paths;
  let db = Overlay.open_db paths.Paths.db in
  Overlay.apply_migrations db;
  let tree = Load_tree.load_tree paths in
  let blocked = Context_gen.blocked_tasks tree.Load_tree.features in
  let generated_at = Js_shims.Date.now_iso () in
  let summary = Context_gen.build_summary tree.Load_tree.features blocked generated_at in
  F.mkdir_p paths.Paths.context;
  F.write_file_sync (P.join2 paths.Paths.context "summary.md") summary;
  F.write_file_sync
    (P.join2 paths.Paths.context "active.md")
    (Context_gen.build_active tree.Load_tree.features);
  F.write_file_sync
    (P.join2 paths.Paths.context "blocked.md")
    (Context_gen.build_blocked_md blocked);
  F.write_file_sync
    (P.join2 paths.Paths.context "metrics.md")
    (Context_gen.build_metrics_md tree.Load_tree.features);
  F.mkdir_p paths.Paths.specs;
  F.write_file_sync paths.Paths.index_md (Context_gen.build_index tree.Load_tree.features);
  let notes = Load_tree.load_memory_notes paths.Paths.memory in
  Overlay.replace_memory_fts db notes;
  Overlay.insert_snapshot db summary;
  { rb_features = List.length tree.Load_tree.features
  ; rb_memory_notes = List.length notes
  ; rb_parse_errors = tree.Load_tree.parse_errors
  ; rb_summary = summary
  ; rb_generated_at = generated_at
  }
;;

let context_age_s paths =
  let summary = P.join2 paths.Paths.context "summary.md" in
  if not (F.exists_sync summary)
  then None
  else (
    let age = Js_shims.Date.now () -. F.mtime_ms summary in
    Some (int_of_float (age /. 1000.)))
;;

let context_is_stale paths spec_mtime_ms =
  let summary = P.join2 paths.Paths.context "summary.md" in
  if not (F.exists_sync summary) then true else spec_mtime_ms > F.mtime_ms summary +. 1.0
;;
