(* Derived, token-capped context. Never hand-edit. *)

open Domain

let chars_per_token = 4
let summary_token_cap = 1000
let board_token_cap = 4000
let estimate_tokens text = (String.length text + chars_per_token - 1) / chars_per_token

let cap_tokens text max_tokens =
  let max_chars = max_tokens * chars_per_token in
  if String.length text <= max_chars
  then text
  else (
    let sliced = String.sub text 0 max_chars in
    let last_nl =
      let rec back i = if i >= 0 && sliced.[i] <> '\n' then back (i - 1) else i in
      back (max_chars - 1)
    in
    let cut =
      if last_nl > max_chars * 6 / 10 then String.sub sliced 0 last_nl else sliced
    in
    Speckit.trim cut ^ "\n\n<!-- truncated -->\n")
;;

let horizon_of_feature (f : feature) =
  match f.horizon with
  | Some h -> h
  | None -> f.inferred_horizon
;;

let open_tasks features =
  List.concat_map (fun f -> List.filter (fun t -> not t.is_done) f.tasks) features
;;

let index_tasks features =
  List.concat_map
    (fun (f : feature) -> List.map (fun t -> make_ref f.slug (Some t.id), t) f.tasks)
    features
;;

let ready_tasks features =
  let by_ref = index_tasks features in
  let lookup ref_ =
    try Some (List.assoc ref_ by_ref) with
    | Not_found -> None
  in
  open_tasks features
  |> List.filter (fun task ->
    List.for_all
      (fun id ->
         match lookup (make_ref task.spec_slug (Some id)) with
         | Some dep -> dep.is_done
         | None -> false)
      task.depends_on)
;;

let blocked_tasks features =
  let by_ref = index_tasks features in
  let dep_done ref_ =
    try (List.assoc ref_ by_ref).is_done with
    | Not_found -> false
  in
  List.concat_map
    (fun feature ->
       let gate =
         if feature.constitution_gate_failing
         then
           [ { card = Spec_card (spec_card feature)
             ; why = "constitution check failing"
             ; kind = "feature"
             }
           ]
         else []
       in
       let unmet =
         List.filter_map
           (fun task ->
              if task.is_done
              then None
              else (
                let waiting =
                  List.filter
                    (fun id -> not (dep_done (make_ref task.spec_slug (Some id))))
                    task.depends_on
                in
                if waiting = []
                then None
                else (
                  let ids =
                    List.map (fun id -> make_ref task.spec_slug (Some id)) waiting
                  in
                  Some
                    { card = Task_card (task_card task)
                    ; why = "waiting on " ^ String.concat ", " ids
                    ; kind = "task"
                    })))
           feature.tasks
       in
       gate @ unmet)
    features
;;

let in_flight features =
  List.filter (fun (f : feature) -> f.status = In_progress || f.status = Blocked) features
;;

type metrics =
  { m_features : int
  ; m_by_status : (string * int) list
  ; m_by_horizon : int * int * int
  ; m_open_tasks : int
  ; m_total_tasks : int
  }

let metrics_of (features : feature list) =
  let by_status =
    List.fold_left
      (fun acc (f : feature) ->
         let k = status_to_string f.status in
         match List.assoc_opt k acc with
         | Some _ -> List.map (fun (a, b) -> if a = k then a, b + 1 else a, b) acc
         | None -> acc @ [ k, 1 ])
      []
      features
  in
  let by_horizon =
    List.fold_left
      (fun (now, next, later) f ->
         match horizon_of_feature f with
         | Now -> now + 1, next, later
         | Next -> now, next + 1, later
         | Later -> now, next, later + 1)
      (0, 0, 0)
      features
  in
  let tasks = List.concat_map (fun (f : feature) -> f.tasks) features in
  { m_features = List.length features
  ; m_by_status = by_status
  ; m_by_horizon = by_horizon
  ; m_open_tasks = List.length (List.filter (fun t -> not t.is_done) tasks)
  ; m_total_tasks = List.length tasks
  }
;;

let build_summary features blocked generated_at =
  let flight = in_flight features in
  let ready = ready_tasks features in
  let metrics = metrics_of features in
  let b = Buffer.create 1024 in
  let add s = Buffer.add_string b s in
  let add_ln s =
    add s;
    add "\n"
  in
  add "<!-- generated: do not edit -->\n";
  add_ln "# What should we work on?";
  add "\n";
  add_ln ("Updated: " ^ generated_at);
  add "\n";
  add_ln "## In flight";
  if flight = []
  then add_ln "- none"
  else
    List.iter
      (fun (f : feature) ->
         let open_ = List.length (List.filter (fun t -> not t.is_done) f.tasks) in
         let next = List.find_opt (fun t -> t.spec_slug = f.slug) ready in
         let next_bit =
           match next with
           | Some t -> " Next ready: " ^ t.id ^ " " ^ t.title
           | None -> ""
         in
         add
           (Printf.sprintf
              "- **%s** (%s, %s) — %d/%d open.%s\n"
              f.slug
              (status_to_string f.status)
              (horizon_to_string (horizon_of_feature f))
              open_
              (List.length f.tasks)
              next_bit))
      flight;
  add "\n";
  add_ln "## Blocked";
  if blocked = []
  then add_ln "- none"
  else
    List.iter
      (fun item ->
         let id =
           match item.card with
           | Spec_card c -> c.slug
           | Task_card c -> c.card_ref
         in
         add_ln ("- " ^ id ^ " — " ^ item.why))
      (let rec take n = function
         | [] -> []
         | x :: rest when n > 0 -> x :: take (n - 1) rest
         | _ -> []
       in
       take 12 blocked);
  add "\n";
  add_ln "## Ready queue";
  if ready = []
  then add_ln "- none"
  else
    List.iteri
      (fun i t ->
         add_ln
           (Printf.sprintf
              "%d. %s — %s"
              (i + 1)
              (make_ref t.spec_slug (Some t.id))
              t.title))
      (let rec take n = function
         | [] -> []
         | x :: rest when n > 0 -> x :: take (n - 1) rest
         | _ -> []
       in
       take 8 ready);
  add "\n";
  let now_specs = List.filter (fun f -> horizon_of_feature f = Now) features in
  add_ln "## Now horizon";
  if now_specs = []
  then add_ln "- none"
  else List.iter (fun (f : feature) -> add_ln ("- " ^ f.slug ^ " — " ^ f.title)) now_specs;
  add "\n";
  let now_n, next_n, later_n = metrics.m_by_horizon in
  add_ln "## Metrics";
  add_ln (Printf.sprintf "- features: %d" metrics.m_features);
  add_ln (Printf.sprintf "- open tasks: %d/%d" metrics.m_open_tasks metrics.m_total_tasks);
  add_ln (Printf.sprintf "- horizon now/next/later: %d/%d/%d" now_n next_n later_n);
  add "\n";
  cap_tokens (Buffer.contents b) summary_token_cap
;;

let build_active features =
  let flight = in_flight features in
  let b = Buffer.create 512 in
  let add s = Buffer.add_string b s in
  add "<!-- generated: do not edit -->\n";
  add "# Active\n\n";
  if flight = []
  then Buffer.add_string b "No specs in flight.\n"
  else
    List.iter
      (fun (f : feature) ->
         add (Printf.sprintf "## %s — %s\n\n" f.slug f.title);
         add
           (Printf.sprintf
              "Status: %s. Horizon: %s.\n\n"
              (status_to_string f.status)
              (horizon_to_string (horizon_of_feature f)));
         add "\n";
         List.iter
           (fun t -> add ("- [ ] " ^ t.id ^ " " ^ t.title ^ "\n"))
           (List.filter (fun t -> not t.is_done) f.tasks);
         add "\n")
      flight;
  cap_tokens (Buffer.contents b) board_token_cap
;;

let build_blocked_md blocked =
  let b = Buffer.create 256 in
  Buffer.add_string b "<!-- generated: do not edit -->\n";
  Buffer.add_string b "# Blocked\n\n";
  if blocked = []
  then Buffer.add_string b "Nothing blocked.\n"
  else (
    List.iter
      (fun item ->
         let id =
           match item.card with
           | Spec_card c -> c.slug
           | Task_card c -> c.card_ref
         in
         Buffer.add_string b ("- **" ^ id ^ "**: " ^ item.why ^ "\n"))
      blocked;
    Buffer.add_string b "\n");
  Buffer.contents b
;;

let build_metrics_md features =
  let m = metrics_of features in
  let now_n, next_n, later_n = m.m_by_horizon in
  let status_lines =
    match m.m_by_status with
    | [] -> "- none"
    | entries ->
      String.concat "\n" (List.map (fun (k, v) -> Printf.sprintf "- %s: %d" k v) entries)
  in
  String.concat
    "\n"
    [ "<!-- generated: do not edit -->"
    ; "# Metrics"
    ; ""
    ; Printf.sprintf "features: %d" m.m_features
    ; Printf.sprintf "open tasks: %d/%d" m.m_open_tasks m.m_total_tasks
    ; ""
    ; "## By status"
    ; status_lines
    ; ""
    ; "## By horizon"
    ; Printf.sprintf "- now: %d" now_n
    ; Printf.sprintf "- next: %d" next_n
    ; Printf.sprintf "- later: %d" later_n
    ; ""
    ]
;;

let build_index features =
  let sorted = List.sort (fun (a : feature) b -> compare a.slug b.slug) features in
  let b = Buffer.create 512 in
  let add s = Buffer.add_string b s in
  add "<!-- generated: do not edit. Router only — load one spec folder. -->\n";
  add "# Specs\n\n";
  add "| ID | Title | Status | Horizon | Tasks | Path |\n";
  add "|---|---|---|---|---|---|\n";
  if sorted = []
  then add "| — | no specs yet | — | — | — | — |\n"
  else
    List.iter
      (fun (f : feature) ->
         let open_ = List.length (List.filter (fun t -> not t.is_done) f.tasks) in
         let title = String.concat "\\|" (String.split_on_char '|' f.title) in
         add
           (Printf.sprintf
              "| %s | %s | %s | %s | %d/%d | [%s](./%s/) |\n"
              f.slug
              title
              (status_to_string f.status)
              (horizon_to_string (horizon_of_feature f))
              open_
              (List.length f.tasks)
              f.slug
              f.slug))
      sorted;
  add "\n";
  add
    "Read `spec.md` (what/why), `plan.md` (how), `tasks.md` (the backlog for that \
     feature).\n\n";
  Buffer.contents b
;;
