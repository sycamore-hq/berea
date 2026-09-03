(* Loads the spec tree, constitution, and memory notes from disk. *)

module F = Js_shims.Fs
module P = Js_shims.Path

type parse_error =
  { err_path : string
  ; err_message : string
  }

type constitution_info =
  { present : bool
  ; const_path : string
  ; const_title : string
  ; const_body : string
  ; const_principles : string list
  }

type loaded_tree =
  { features : Domain.feature list
  ; tree_constitution : constitution_info
  ; parse_errors : parse_error list
  ; spec_mtime_ms : float
  }

type memory_note =
  { note_path : string
  ; note_title : string
  ; note_as_of : string option
  ; note_status : Memory_ml.status option
  ; note_body : string
  ; note_kind : Memory_ml.kind
  }

let missing_constitution const_path =
  { present = false
  ; const_path
  ; const_title = "Constitution"
  ; const_body = ""
  ; const_principles = []
  }
;;

let load_constitution const_path errs =
  if not (F.exists_sync const_path)
  then missing_constitution const_path
  else (
    try
      let text = F.read_file_sync const_path in
      let parsed = Speckit.parse_constitution text in
      { present = true
      ; const_path
      ; const_title = parsed.title
      ; const_body = parsed.body
      ; const_principles = parsed.principles
      }
    with
    | e ->
      errs := !errs @ [ { err_path = const_path; err_message = Printexc.to_string e } ];
      missing_constitution const_path)
;;

let is_spec_dir name =
  let n = String.length name in
  n >= 4
  && Domain.is_digit name.[0]
  && Domain.is_digit name.[1]
  && Domain.is_digit name.[2]
  && name.[3] = '-'
;;

let is_dir path = F.is_dir path

let load_tree paths =
  let errs = ref [] in
  let constitution = load_constitution paths.Paths.constitution errs in
  if not (F.exists_sync paths.Paths.specs)
  then
    { features = []
    ; tree_constitution = constitution
    ; parse_errors = !errs
    ; spec_mtime_ms = 0.0
    }
  else (
    let dirs =
      F.readdir_sync paths.Paths.specs
      |> Js_shims.A.to_list
      |> List.filter (fun name ->
        let p = P.join2 paths.Paths.specs name in
        try is_dir p with
        | _ -> false)
      |> List.filter is_spec_dir
      |> List.sort compare
    in
    let features, max_mtime, errs_final =
      List.fold_left
        (fun (features, mtime, errs) slug ->
           let dir = P.join2 paths.Paths.specs slug in
           let spec_path = P.join2 dir "spec.md" in
           if not (F.exists_sync spec_path)
           then
             ( features
             , mtime
             , errs @ [ { err_path = spec_path; err_message = "missing spec.md" } ] )
           else (
             try
               let spec_md = F.read_file_sync spec_path in
               let mtime = Float.max mtime (F.mtime_ms spec_path) in
               let plan_path = P.join2 dir "plan.md" in
               let tasks_path = P.join2 dir "tasks.md" in
               let plan_md =
                 if F.exists_sync plan_path
                 then Some (F.read_file_sync plan_path)
                 else None
               in
               let mtime =
                 match plan_md with
                 | Some _ -> Float.max mtime (F.mtime_ms plan_path)
                 | None -> mtime
               in
               let tasks_md =
                 if F.exists_sync tasks_path
                 then Some (F.read_file_sync tasks_path)
                 else None
               in
               let mtime =
                 match tasks_md with
                 | Some _ -> Float.max mtime (F.mtime_ms tasks_path)
                 | None -> mtime
               in
               let entries = F.readdir_sync dir |> Js_shims.A.to_list in
               let siblings =
                 List.filter
                   (fun n -> n <> "spec.md" && n <> "plan.md" && n <> "tasks.md")
                   entries
               in
               let feature =
                 Speckit.assemble_feature
                   { fi_slug = slug
                   ; fi_spec_md = spec_md
                   ; fi_plan_md = plan_md
                   ; fi_tasks_md = tasks_md
                   ; fi_siblings = siblings
                   ; fi_gate_failing = false
                   }
               in
               feature :: features, mtime, errs
             with
             | e ->
               ( features
               , mtime
               , errs @ [ { err_path = spec_path; err_message = Printexc.to_string e } ] )))
        ([], 0.0, !errs)
        dirs
    in
    { features = List.rev features
    ; tree_constitution = constitution
    ; parse_errors = errs_final
    ; spec_mtime_ms = max_mtime
    })
;;

let walk_md dir =
  let rec go acc dir =
    let entries = F.readdir_sync dir in
    Array.fold_left
      (fun acc name ->
         let p = P.join2 dir name in
         if
           try is_dir p with
           | _ -> false
         then go acc p
         else if Js_shims.Str.ends_with name ".md"
         then p :: acc
         else acc)
      acc
      entries
  in
  go [] dir
;;

let to_loaded_note (note : Memory_ml.note) =
  { note_path = note.path
  ; note_title = note.title
  ; note_as_of = note.as_of
  ; note_status = note.status
  ; note_body = note.body
  ; note_kind = note.kind
  }
;;

let parse_if_indexed ~include_sessions path abs =
  if not (Memory_ml.should_index ~include_sessions path)
  then None
  else Some (Memory_ml.parse_memory_note path (F.read_file_sync abs))
;;

let load_one ~include_sessions memory_root abs =
  let path = "memory/" ^ P.relative memory_root abs in
  match parse_if_indexed ~include_sessions path abs with
  | Some note when Memory_ml.keep_loaded ~include_sessions note ->
    Some (to_loaded_note note)
  | Some _ | None -> None
;;

let load_memory_notes ?(include_sessions = false) memory_root =
  if not (F.exists_sync memory_root)
  then []
  else List.filter_map (load_one ~include_sessions memory_root) (walk_md memory_root)
;;
