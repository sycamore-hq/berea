(* Derived overlay: pins, views, chat, snapshots, FTS. SQLite is never a
   copy of the writings. *)

module F = Js_shims.Fs
module P = Js_shims.Path
module D = Js_shims.Date

type db
type stmt

external open_db : string -> db = "Database" [@@mel.new] [@@mel.module "bun:sqlite"]
external run_sql : db -> string -> unit = "run" [@@mel.send]

external run_params : db -> string -> Js.Json.t array -> unit = "run"
[@@mel.send] [@@mel.variadic]

external exec_sql : db -> string -> unit = "exec" [@@mel.send]
external query : db -> string -> stmt = "query" [@@mel.send]
external all_rows : stmt -> 'row array = "all" [@@mel.send]

external all_params : stmt -> Js.Json.t array -> 'row array = "all"
[@@mel.send] [@@mel.variadic]

external get_row : stmt -> 'row option = "get" [@@mel.send]
[@@mel.return undefined_to_opt]

type pin =
  { pin_ref : string
  ; pin_reason : string
  ; pin_pinned_at : string
  }

type pin_row

external pr_ref : pin_row -> string = "ref" [@@mel.get]

external pr_reason : pin_row -> string = "reason" [@@mel.get]

external pr_pinned_at : pin_row -> string = "pinned_at" [@@mel.get]

type memory_hit =
  { hit_path : string
  ; hit_title : string
  ; hit_as_of : string option
  ; hit_status : string
  ; hit_excerpt : string
  ; hit_kind : string
  }



let ping db =
  try
    ignore (get_row (query db "SELECT 1") : int option);
    true
  with
  | _ -> false
;;

type schema_migration_row

external smr_id : schema_migration_row -> string = "id" [@@mel.get]

type hit_row

external hr_path : hit_row -> string = "path" [@@mel.get]

external hr_title : hit_row -> string = "title" [@@mel.get]

external hr_kind : hit_row -> string = "kind" [@@mel.get]

external hr_as_of : hit_row -> string option = "as_of" [@@mel.get]
[@@mel.return undefined_to_opt]

external hr_excerpt : hit_row -> string = "excerpt" [@@mel.get]

let apply_migrations db =
  run_sql
    db
    {|CREATE TABLE IF NOT EXISTS schema_migrations (
      id TEXT PRIMARY KEY,
      applied_at TEXT NOT NULL
    )|};
  let applied =
    all_rows (query db "SELECT id FROM schema_migrations")
    |> Js_shims.A.to_list
    |> List.map (fun (r : schema_migration_row) -> smr_id r)
  in
  let dir = Paths.migrations_dir () in
  let files =
    F.readdir_sync dir
    |> Js_shims.A.to_list
    |> List.filter (fun f -> Js_shims.Str.ends_with f ".sql")
    |> List.sort compare
  in
  List.iter
    (fun file ->
       if not (List.mem file applied)
       then (
         let sql = F.read_file_sync (P.join2 dir file) in
         exec_sql db sql;
         run_params
           db
           "INSERT INTO schema_migrations (id, applied_at) VALUES (?, ?)"
           [| Js.Json.string file; Js.Json.string (D.now_iso ()) |]))
    files
;;

let list_pins db =
  all_rows (query db "SELECT ref, reason, pinned_at FROM pins ORDER BY pinned_at DESC")
  |> Js_shims.A.to_list
  |> List.map (fun (r : pin_row) ->
    { pin_ref = pr_ref r; pin_reason = pr_reason r; pin_pinned_at = pr_pinned_at r })
;;

let upsert_pin db ref_ reason =
  let pinned_at = D.now_iso () in
  run_params
    db
    {|INSERT INTO pins (ref, reason, pinned_at) VALUES (?, ?, ?)
      ON CONFLICT(ref) DO UPDATE SET reason = excluded.reason, pinned_at = excluded.pinned_at|}
    [| Js.Json.string ref_; Js.Json.string reason; Js.Json.string pinned_at |];
  { pin_ref = ref_; pin_reason = reason; pin_pinned_at = pinned_at }
;;

let replace_memory_fts db notes =
  run_sql db "DELETE FROM memory_fts";
  List.iter
    (fun (n : Load_tree.memory_note) ->
       run_params
         db
         "INSERT INTO memory_fts (path, title, body, kind, as_of) VALUES (?, ?, ?, ?, ?)"
         [| Js.Json.string n.note_path
          ; Js.Json.string n.note_title
          ; Js.Json.string n.note_body
          ; Js.Json.string (Memory_ml.kind_to_string n.note_kind)
          ; (match n.note_as_of with
             | Some s -> Js.Json.string s
             | None -> Js.Json.null)
         |])
    notes
;;

let fts_query q =
  let tokens =
    String.to_seq q
    |> Seq.filter_map (fun c ->
      let c = Char.lowercase_ascii c in
      if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || Char.code c > 127
      then Some c
      else Some ' ')
    |> String.of_seq
    |> String.split_on_char ' '
    |> List.filter (fun t -> t <> "")
  in
  match tokens with
  | [] -> "\"\""
  | ts ->
    String.concat
      " OR "
      (List.map (fun t -> "\"" ^ String.concat "" (String.split_on_char '"' t) ^ "\"") ts)
;;

let search_memory ?(limit = 12) db q =
  let query_str = Speckit.trim q in
  if query_str = ""
  then []
  else (
    try
      all_params
        (query
           db
           {|SELECT path, title, kind, as_of,
                   snippet(memory_fts, 2, '', '', 'â¦', 24) AS excerpt
            FROM memory_fts
            WHERE memory_fts MATCH ?
            LIMIT ?|}
        )
        [| Js.Json.string (fts_query query_str); Js.Json.number (float_of_int limit) |]
      |> Js_shims.A.to_list
      |> List.map (fun (r : hit_row) ->
        { hit_path = hr_path r
        ; hit_title = hr_title r
        ; hit_as_of = hr_as_of r
        ; hit_status = "active"
        ; hit_excerpt = hr_excerpt r
        ; hit_kind = hr_kind r
        })
    with
    | _ -> [])
;;

let insert_snapshot db summary_md =
  run_params
    db
    "INSERT INTO snapshots (id, taken_at, summary_md) VALUES (?, ?, ?)"
    [| Js.Json.string (Js_shims.Crypto.random_uuid ())
     ; Js.Json.string (D.now_iso ())
     ; Js.Json.string summary_md
    |]
;;

let insert_thread db id title =
  run_params
    db
    "INSERT OR IGNORE INTO chat_threads (id, title, created_at) VALUES (?, ?, ?)"
    [| Js.Json.string id; Js.Json.string title; Js.Json.string (D.now_iso ()) |]
;;

let insert_message db thread_id role content_json =
  run_params
    db
    "INSERT INTO chat_messages (id, thread_id, role, content_json, created_at) VALUES \
     (?, ?, ?, ?, ?)"
    [| Js.Json.string (Js_shims.Crypto.random_uuid ())
     ; Js.Json.string thread_id
     ; Js.Json.string role
     ; Js.Json.string content_json
     ; Js.Json.string (D.now_iso ())
    |]
;;
