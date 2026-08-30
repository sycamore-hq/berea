(* View-models for HTML and JSON APIs. *)

open Domain

module Json = struct
  let str s = Js.Json.string s
  let int i = Js.Json.number (float_of_int i)
  let float f = Js.Json.number f
  let bool b = Js.Json.boolean b
  let null = Js.Json.null
  let arr (xs : Js.Json.t list) = Js.Json.array (Array.of_list xs)

  let obj kvs =
    let d = Js.Dict.empty () in
    List.iter (fun (k, v) -> Js.Dict.set d k v) kvs;
    Js.Json.object_ d
  ;;

  let opt_str = function
    | Some s -> str s
    | None -> null
  ;;

  let opt_int = function
    | Some i -> int i
    | None -> null
  ;;
end

open Json

let horizon_json = function
  | Some h -> str (horizon_to_string h)
  | None -> null
;;

let priority_json = function
  | Some p -> str (priority_to_string p)
  | None -> null
;;

let spec_card_json c =
  obj
    [ "slug", str c.slug
    ; "title", str c.title
    ; "horizon", horizon_json c.horizon
    ; "priority", priority_json c.priority
    ; "status", str (status_to_string c.status)
    ; "open_tasks", int c.open_tasks
    ; "total_tasks", int c.total_tasks
    ]
;;

let task_card_json c =
  obj
    [ "ref", str c.card_ref
    ; "title", str c.card_title
    ; "done", bool c.card_done
    ; "spec_slug", str c.card_spec_slug
    ; "priority", priority_json c.card_priority
    ]
;;

let task_json (t : task) =
  obj
    [ "id", str t.id
    ; "title", str t.title
    ; "done", bool t.is_done
    ; "parallel", bool t.parallel
    ; "story", opt_str t.story
    ; "points", opt_int t.points
    ; "rank", opt_int t.rank
    ; "priority", priority_json t.priority
    ; "status_tag", opt_str t.status_tag
    ; "phase", opt_str t.phase
    ; "spec_slug", str t.spec_slug
    ; "depends_on", arr (List.map str t.depends_on)
    ; "body", str t.body
    ; "line", int t.line
    ]
;;

let blocked_item_json item =
  let card =
    match item.card with
    | Spec_card c -> spec_card_json c
    | Task_card c -> task_card_json c
  in
  obj [ "card", card; "why", str item.why; "kind", str item.kind ]
;;

let blocked_items_json items = arr (List.map blocked_item_json items)

let roadmap_json features =
  let bucket h =
    List.filter
      (fun (f : feature) ->
         (match f.horizon with
          | Some x -> x
          | None -> f.inferred_horizon)
         = h)
      features
    |> List.map (fun f -> spec_card_json (spec_card f))
  in
  obj
    [ ( "horizons"
      , arr
          [ obj [ "name", str "now"; "specs", arr (bucket Now) ]
          ; obj [ "name", str "next"; "specs", arr (bucket Next) ]
          ; obj [ "name", str "later"; "specs", arr (bucket Later) ]
          ] )
    ]
;;

let backlog_items (features : feature list) =
  List.concat_map (fun f -> List.filter (fun t -> not t.is_done) f.tasks) features
  |> List.map task_card
;;

let backlog_json features =
  obj [ "items", arr (List.map task_card_json (backlog_items features)) ]
;;

type spec_detail =
  { sd_card : spec_card
  ; sd_spec_md : string
  ; sd_plan_md : string option
  ; sd_tasks_md : string option
  ; sd_plan_present : bool
  ; sd_open : int
  ; sd_total : int
  ; sd_feature : feature
  }

let spec_detail_json (d : spec_detail) =
  let tasks = d.sd_feature.tasks in
  obj
    [ "card", spec_card_json d.sd_card
    ; "spec_md", str d.sd_spec_md
    ; "plan_md", opt_str d.sd_plan_md
    ; "tasks_md", opt_str d.sd_tasks_md
    ; "plan_present", bool d.sd_plan_present
    ; "task_counts", obj [ "open", int d.sd_open; "total", int d.sd_total ]
    ; "tasks", arr (List.map task_json tasks)
    ; "siblings", arr (List.map str d.sd_feature.siblings)
    ]
;;

let spec_detail_of_feature (f : feature) =
  let open_ = List.length (List.filter (fun t -> not t.is_done) f.tasks) in
  { sd_card = spec_card f
  ; sd_spec_md = f.spec_md
  ; sd_plan_md = f.plan_md
  ; sd_tasks_md = f.tasks_md
  ; sd_plan_present = f.plan_md <> None
  ; sd_open = open_
  ; sd_total = List.length f.tasks
  ; sd_feature = f
  }
;;

type task_detail =
  { td_card : task_card
  ; td_body : string
  ; td_slug : string
  ; td_blockers : task_card list
  ; td_task : task
  }

let task_detail_json d =
  obj
    [ "card", task_card_json d.td_card
    ; "body", str d.td_body
    ; "spec_slug", str d.td_slug
    ; "blockers", arr (List.map task_card_json d.td_blockers)
    ; "task", task_json d.td_task
    ]
;;

let task_detail_of f t =
  let blockers =
    List.filter_map
      (fun id ->
         match List.find_opt (fun x -> x.id = id) f.tasks with
         | Some dep when not dep.is_done -> Some (task_card dep)
         | _ -> None)
      t.depends_on
  in
  { td_card = task_card t
  ; td_body = t.body
  ; td_slug = f.slug
  ; td_blockers = blockers
  ; td_task = t
  }
;;

let graph_typed (features : feature list) =
  let nodes, edges =
    List.fold_left
      (fun (nodes, edges) (f : feature) ->
         let nodes =
           nodes
           @ [ { node_id = f.slug
               ; node_kind = "spec"
               ; node_title = f.title
               ; node_status = status_to_string f.status
               }
             ]
         in
         let nodes, edges =
           List.fold_left
             (fun (nodes, edges) t ->
                let nodes =
                  nodes
                  @ [ { node_id = make_ref f.slug (Some t.id)
                      ; node_kind = "task"
                      ; node_title = t.title
                      ; node_status = (if t.is_done then "done" else "open")
                      }
                    ]
                in
                let edges =
                  edges
                  @ [ { g_edge_from = f.slug
                      ; g_edge_to = make_ref f.slug (Some t.id)
                      ; g_edge_kind = "contains"
                      }
                    ]
                in
                let edges =
                  edges
                  @ List.map
                      (fun dep ->
                         { g_edge_from = make_ref f.slug (Some dep)
                         ; g_edge_to = make_ref f.slug (Some t.id)
                         ; g_edge_kind = "depends"
                         })
                      t.depends_on
                in
                nodes, edges)
             (nodes, edges)
             f.tasks
         in
         let edges =
           edges
           @ List.filter_map
               (fun (link : Domain.ref_) ->
                  match link.slug with
                  | Some slug when slug <> f.slug ->
                    Some
                      { g_edge_from = f.slug
                      ; g_edge_to =
                          (match link.task_id with
                           | Some tid -> make_ref slug (Some tid)
                           | None -> slug)
                      ; g_edge_kind = "wiki"
                      }
                  | _ -> None)
               f.wiki_links
         in
         nodes, edges)
      ([], [])
      features
  in
{ nodes; edges }

let graph_json features =
  let { nodes; edges } = graph_typed features in
  let node_json n =
    obj
      [ "id", str n.node_id
      ; "kind", str n.node_kind
      ; "title", str n.node_title
      ; "status", str n.node_status
      ]
  in
  let edge_json e =
    obj [ "from", str e.g_edge_from; "to", str e.g_edge_to; "kind", str e.g_edge_kind ]
  in
  obj [ "nodes", arr (List.map node_json nodes); "edges", arr (List.map edge_json edges) ]
;;

let metrics_json features =
  let m = Context_gen.metrics_of features in
  let now_n, next_n, later_n = m.m_by_horizon in
  obj
    [ "features", int m.m_features
    ; "by_status", obj (List.map (fun (k, v) -> k, int v) m.m_by_status)
    ; "by_horizon", obj [ "now", int now_n; "next", int next_n; "later", int later_n ]
    ; "open_tasks", int m.m_open_tasks
    ; "total_tasks", int m.m_total_tasks
    ]
;;

let summary_visual_json features blocked =
  obj
    [ ( "in_flight"
      , arr (List.map (fun f -> spec_card_json (spec_card f)) (Context_gen.in_flight features)) )
    ; "blocked", blocked_items_json blocked
    ; "priority_queue", arr (List.map (fun t -> task_card_json (task_card t)) (Context_gen.ready_tasks features))
    ; "metrics", metrics_json features
    ]
;;

type constitution_info =
  { c_title : string
  ; c_excerpt : string
  ; c_body : string
  }

type catalog =
  { cat_slugs : string list
  ; cat_summary_json : Js.Json.t
  ; cat_in_flight : spec_card list
  ; cat_ready : task_card list
  ; cat_blocked : blocked_item list
  ; cat_roadmap_json : Js.Json.t
  ; cat_roadmap_specs : string list
  ; cat_backlog_json : Js.Json.t
  ; cat_blocked_json : Js.Json.t
  ; cat_graph_json : Js.Json.t
  ; cat_specs : (string * spec_detail) list
  ; cat_tasks : (string * (task_detail * bool)) list
  ; cat_constitution : constitution_info option
  ; cat_memory_hits : Js.Json.t list
  }

let catalog_of (features : feature list) ~constitution ~memory_hits =
  let specs =
    List.map (fun (f : feature) -> f.slug, spec_detail_of_feature f) features
  in
  let tasks =
    List.fold_left
      (fun acc f ->
         List.fold_left
           (fun acc t ->
              let detail = task_detail_of f t in
              let acc = (make_ref f.slug (Some t.id), (detail, false)) :: acc in
              let bare = String.uppercase_ascii t.id in
              let acc =
                match List.assoc_opt bare acc with
                | Some (_, _) ->
                  List.map (fun (k, v) -> if k = bare then k, (fst v, true) else k, v) acc
                | None -> (bare, (detail, false)) :: acc
              in
              acc)
           acc
           f.tasks)
      []
      features
  in
  let blocked = Context_gen.blocked_tasks features in
  { cat_slugs = List.map (fun (f : feature) -> f.slug) features
  ; cat_summary_json = summary_visual_json features blocked
  ; cat_in_flight = List.map spec_card (Context_gen.in_flight features)
  ; cat_ready = List.map task_card (Context_gen.ready_tasks features)
  ; cat_blocked = blocked
  ; cat_roadmap_json = roadmap_json features
  ; cat_roadmap_specs = List.map (fun (f : feature) -> f.slug) features
  ; cat_backlog_json = backlog_json features
  ; cat_blocked_json = obj [ "items", blocked_items_json blocked ]
  ; cat_graph_json = graph_json features
  ; cat_specs = specs
  ; cat_tasks = tasks
  ; cat_constitution = constitution
  ; cat_memory_hits = memory_hits
  }
;;

let find_feature (features : feature list) slug =
  List.find_opt (fun (f : feature) -> f.slug = slug) features

let find_task (features : feature list) ref_ =
  let slug, task_id =
    match String.index_opt ref_ '#' with
    | None ->
      let n = String.length ref_ in
      let looks_like_task =
        n >= 2
        && (ref_.[0] = 'T' || ref_.[0] = 't')
        &&
        let rec digits i = i >= n || (is_digit ref_.[i] && digits (i + 1)) in
        digits 1
      in
      if looks_like_task
      then None, Some (String.uppercase_ascii ref_)
      else Some ref_, None
    | Some i ->
      ( Some (String.sub ref_ 0 i)
      , Some
          (String.uppercase_ascii (String.sub ref_ (i + 1) (String.length ref_ - i - 1)))
      )
  in
  match (slug, task_id) with
  | Some slug, Some tid ->
    let hit_of (f : feature) =
      List.find_opt (fun t -> String.uppercase_ascii t.id = tid) f.tasks
      |> Option.map (fun t -> f, t)
    in
    Option.bind (find_feature features slug) hit_of
  | None, Some tid ->
    let hit_of (f : feature) =
      List.find_opt (fun t -> String.uppercase_ascii t.id = tid) f.tasks
      |> Option.map (fun t -> f, t)
    in
    let hits = List.filter_map hit_of features in
    (match hits with
     | [ hit ] -> Some hit
     | _ -> None)
  | _ -> None;;
