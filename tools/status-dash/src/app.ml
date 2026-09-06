(* Routes and pages. Hono on Bun. *)

open Domain

module H = Hono
module V = Views
module J = V.Json
module F = Js_shims.Fs
module P = Js_shims.Path

let hit_json_list (hits : Overlay.memory_hit list) =
  List.map
       (fun h ->
         J.obj
           [ ("path", J.str h.Overlay.hit_path);
             ("title", J.str h.Overlay.hit_title);
             ("as_of", J.opt_str h.Overlay.hit_as_of);
             ("status", J.str h.Overlay.hit_status);
             ("excerpt", J.str h.Overlay.hit_excerpt);
             ("kind", J.str h.Overlay.hit_kind) ])
    hits

let string_of_hits hits = J.arr (hit_json_list hits)

let memory_note_item (n : Load_tree.memory_note) =
  "<li><strong>" ^ Html.esc n.note_title ^ "</strong> <code>"
  ^ Html.esc n.note_path
  ^ "</code>\n<span class=\"muted\">"
  ^ Html.esc (Memory_ml.kind_to_string n.note_kind)
  ^ " · "
  ^ Html.esc (Memory_ml.status_label n.note_status)
  ^ " · "
  ^ Html.esc (Option.value n.note_as_of ~default:"")
  ^ "</span>\n<p>"
  ^ Html.esc (Memory_ml.excerpt ~n:200 n.note_body)
  ^ "</p></li>"

let memory_items_html = function
  | [] ->
    "<p class=\"empty\">No reviewed notes. Action agents append <code>memory/sessions/</code> only. Curator proposes the rest.</p>"
  | notes ->
    "<ul>" ^ String.concat "" (List.map memory_note_item notes) ^ "</ul>"

type state = { st_tree : Load_tree.loaded_tree; st_db : Overlay.db }

let horizon_label (f : feature) = horizon_to_string f.inferred_horizon

let parse_errors_json errs =
  J.arr
    (List.map
       (fun (e : Load_tree.parse_error) ->
         J.obj [ ("path", J.str e.Load_tree.err_path); ("message", J.str e.Load_tree.err_message) ])
       errs)

let health_json ~spec_count ~overlay_ok ~context_age_s ~parse_errors =
  let empty = spec_count = 0 in
  J.obj
    [ ("ok", J.bool overlay_ok);
      ("specs", J.obj [ ("count", J.int spec_count); ("empty", J.bool empty) ]);
      ("overlay", J.obj [ ("ok", J.bool overlay_ok) ]);
      ("context_age_s", J.opt_int context_age_s);
      ("parse_errors", parse_errors_json parse_errors);
      ("empty_specs", (if empty then J.bool true else Js.Json.null)) ]

(* decode helpers for POST bodies *)
let body_dict (json : Js.Json.t) = Js.Json.decodeObject json

let body_string (json : Js.Json.t) k =
  match body_dict json with
  | None -> None
  | Some d -> (
      match Js.Dict.get d k with
      | Some v -> Js.Json.decodeString v
      | _ -> None)

let body_bool json k =
  match body_dict json with
  | None -> None
  | Some d -> (
      match Js.Dict.get d k with
      | Some v -> Js.Json.decodeBoolean v
      | _ -> None)

let catch_null (c : H.ctx) (f : Js.Json.t option -> H.res) : H.res Js.Promise.t =
  Js.Promise.(
    H.json_body (H.req c)
    |> then_ (fun body -> Js.Promise.resolve (f (Some body)))
    |> catch (fun _ -> Js.Promise.resolve (f None)))


let ref_has_task ref_ =
  match String.index_opt ref_ '#' with
  | Some i -> i + 1 < String.length ref_
  | None -> false

let graph_of features = Views.graph_typed features

let create_app root =
  let paths = Paths.paths_for root in
  F.mkdir_p paths.Paths.dash;
  let db = Overlay.open_db paths.Paths.db in
  Overlay.apply_migrations db;
  if not (F.exists_sync (P.join2 paths.Paths.context "summary.md")) then
    ignore (Rebuild.rebuild_all root);
  let state = ref { st_tree = Load_tree.load_tree paths; st_db = db } in
  let reload () = state := { st_tree = Load_tree.load_tree paths; st_db = db } in
  let tree () = (!state).st_tree in
  let app = H.make_hono () in

  let banners () =
    let t = tree () in
    let out = ref [] in
    if t.Load_tree.features = [] then
      out :=
        "No specs yet. A mid-day design conversation becomes <code>specs/NNN-slug/spec.md</code>."
        :: !out;
    if t.Load_tree.parse_errors <> [] then
      out :=
        ( "Parse errors: "
        ^ String.concat
            ", "
            (List.map (fun e -> Html.esc e.Load_tree.err_path) t.Load_tree.parse_errors)
        )
        :: !out;
    if Rebuild.context_is_stale paths t.Load_tree.spec_mtime_ms then
      out :=
        "Generated context is stale. <form class=\"inline\" method=\"post\" action=\"/api/sync\"><button>Rebuild</button></form>"
        :: !out;
    if not t.Load_tree.tree_constitution.Load_tree.present then
      out :=
        "Constitution missing. Bootstrap writes a stub; replace via /speckit.constitution."
        :: !out;
    List.rev !out
  in

  let page_html title path body = Html.page ~title ~path ~banners:(banners ()) ~body in

  let sync_json () =
    let result = Rebuild.rebuild_all root in
    reload ();
    J.obj
      [ ("ok", J.bool true);
        ("features", J.int result.Rebuild.rb_features);
        ("memory_notes", J.int result.Rebuild.rb_memory_notes);
        ( "parse_errors",
          parse_errors_json result.Rebuild.rb_parse_errors );
        ("generated_at", J.str result.Rebuild.rb_generated_at) ]
  in

  let chat_route () =
    let t = tree () in
    let features = t.Load_tree.features in
    let constitution = t.Load_tree.tree_constitution in
    fun (message : string) ->
      let excerpt_lines =
        Speckit.lines_of constitution.Load_tree.const_body
        |> (fun ls ->
               let rec take n acc = function
                 | [] -> List.rev acc
                 | x :: rest when n > 0 -> take (n - 1) (x :: acc) rest
                 | _ -> List.rev acc
               in
               take 12 [] ls)
      in
      let excerpt = String.concat "\n" excerpt_lines in
      let slugs = List.map (fun (f : feature) -> f.slug) features in
      let intent = Envelope.classify ~slugs message in
      let memory_hits =
        match intent with
        | Envelope.Memory q -> Overlay.search_memory db q
        | _ -> []
      in
      let constitution_info =
        Views.
          { c_title = constitution.Load_tree.const_title;
            c_excerpt = excerpt;
            c_body = constitution.Load_tree.const_body }
      in
      let catalog =
        Views.catalog_of features ~constitution:(Some constitution_info)
          ~memory_hits:(hit_json_list memory_hits)
      in
      Envelope.encode_envelope (Envelope.envelope_for intent catalog)
  in

  (* ---------- pages ---------- *)

  H.on_get app "/health" (fun c ->
      let t = tree () in
      H.json_resp c
        (health_json ~spec_count:(List.length t.Load_tree.features)
           ~overlay_ok:(Overlay.ping db)
           ~context_age_s:(Rebuild.context_age_s paths)
           ~parse_errors:t.Load_tree.parse_errors));

  H.on_get app "/" (fun c ->
      let t = tree () in
      let features = t.Load_tree.features in
      let blocked = Context_gen.blocked_tasks features in
      let metrics = Context_gen.metrics_of features in
      let in_flight = Context_gen.in_flight features in
      let now_specs =
        List.filter
          (fun (f : feature) -> f.inferred_horizon = Now)
          features
      in
      let summary_path = P.join2 paths.Paths.context "summary.md" in
      let summary_md =
        if F.exists_sync summary_path then F.read_file_sync summary_path else ""
      in
      let pins = Overlay.list_pins db in
      let blocked_items_html =
        if blocked = [] then "<p class=\"empty\">Nothing blocked.</p>"
        else
          "<ul>"
          ^ String.concat
              ""
              (List.map
                 (fun (item : Domain.blocked_item) ->
                   let id =
                     match item.card with
                     | Spec_card sc -> sc.slug
                     | Task_card tc -> tc.card_ref
                   in
                   "<li><code>" ^ Html.esc id ^ "</code> — " ^ Html.esc item.why ^ "</li>")
                 blocked)
          ^ "</ul>"
      in
      let pins_html =
        if pins = [] then "<p class=\"empty\">No pins.</p>"
        else
          "<ul>"
          ^ String.concat
              ""
              (List.map
                 (fun (p : Overlay.pin) ->
                   "<li><code>" ^ Html.esc p.Overlay.pin_ref ^ "</code> — "
                   ^ Html.esc p.Overlay.pin_reason
                   ^ "</li>")
                 pins)
          ^ "</ul>"
      in
      let body =
        "<h1>Overview</h1>\n"
        ^ Html.dl
            [ ("In flight", string_of_int (List.length in_flight));
              ( "Open tasks",
                Printf.sprintf "%d/%d" metrics.Context_gen.m_open_tasks
                  metrics.Context_gen.m_total_tasks );
              ("Blocked", string_of_int (List.length blocked));
              ("Now horizon", string_of_int (List.length now_specs));
              ( "Context age",
                match Rebuild.context_age_s paths with
                | None -> "never built"
                | Some s -> string_of_int s ^ "s" );
              ("Pins", string_of_int (List.length pins)) ]
        ^ "\n<h2>In flight</h2>\n"
        ^ Html.feature_table
            (List.map spec_card in_flight)
            "Nothing in flight."
        ^ "\n<h2>Now</h2>\n"
        ^ Html.feature_table
            (List.map spec_card now_specs)
            "No now-horizon specs."
        ^ "\n<h2>Blocked</h2>\n"
        ^ blocked_items_html
        ^ "\n<h2>Pins</h2>\n"
        ^ pins_html
        ^ "\n<h2>Generated summary</h2>\n"
        ^ ( if summary_md = "" then
              "<p class=\"empty\"><em>Run</em> <code>bun run index</code> or POST /api/sync.</p>"
            else Html.md_article summary_md )
      in
      H.html_resp c (page_html "Overview" "/" body));

  H.on_get app "/roadmap" (fun c ->
      let features = (tree ()).Load_tree.features in
      let sections =
        [ (Domain.Now, "now"); (Domain.Next, "next"); (Domain.Later, "later") ]
        |> List.map (fun (h, name) ->
               let cards =
                 List.filter
                   (fun (f : feature) ->
                     f.inferred_horizon = h)
                   features
                 |> List.map spec_card
               in
               "<h2>" ^ name ^ "</h2>"
               ^ Html.feature_table cards ("No specs on " ^ name ^ "."))
        |> String.concat ""
      in
      H.html_resp c (page_html "Roadmap" "/roadmap" ("<h1>Roadmap</h1>" ^ sections)));

  H.on_get app "/backlog" (fun c ->
      let features = (tree ()).Load_tree.features in
      let items =
        List.map
          (fun (t : Domain.task_card) ->
            { Html.tr_ref = t.card_ref;
              tr_title = t.card_title;
              tr_done = t.card_done;
              tr_spec = t.card_spec_slug })
          (V.backlog_items features)
      in
      let body =
        "<h1>Backlog</h1>\n<p>Open tasks across specs, in the order <code>tasks.md</code> states.</p>\n"
        ^ Html.task_table ~interactive:true items
      in
      H.html_resp c (page_html "Backlog" "/backlog" body));

  H.on_get app "/specs" (fun c ->
      let cards = List.map spec_card (tree ()).Load_tree.features in
      let body =
        "<h1>Specs</h1>\n<p>Router: <a href=\"/specs/INDEX.md\"><code>specs/INDEX.md</code></a> (generated).</p>\n"
        ^ Html.feature_table cards "No specs yet."
      in
      H.html_resp c (page_html "Specs" "/specs" body));

  H.on_get app "/specs/INDEX.md" (fun c ->
      if not (F.exists_sync paths.Paths.index_md) then
        H.text_status c "INDEX.md not generated" 404
      else H.markdown_resp c (F.read_file_sync paths.Paths.index_md));

  H.on_get app "/specs/:slug" (fun c ->
      let slug = H.param c "slug" in
      match V.find_feature (tree ()).Load_tree.features slug with
      | None ->
          H.html_status c
            (page_html "Missing" "/specs" ("<h1>No spec " ^ Html.esc slug ^ "</h1>"))
            404
      | Some feature -> (
          let detail = V.spec_detail_of_feature feature in
          let tasks =
            List.map
              (fun (t : Domain.task) ->
                { Html.tr_ref = make_ref feature.slug (Some t.id);
                  tr_title = t.title;
                  tr_done = t.is_done;
                  tr_spec = feature.slug })
              feature.tasks
          in
          let plan_section =
            match feature.plan_md with
            | Some p -> "\n<h2>plan.md</h2>" ^ Html.md_article p
            | None -> "\n<p class=\"empty\">No plan.md — status is specified.</p>"
          in
          let raw_tasks =
            match feature.tasks_md with
            | Some t ->
                "\n<details><summary>Raw tasks.md</summary>" ^ Html.md_article t ^ "</details>"
            | None -> "\n<p class=\"empty\">No tasks.md.</p>"
          in
          let body =
            "<h1>" ^ Html.esc feature.slug ^ "</h1>\n"
            ^ Html.dl
                [ ("Status", Html.status_pill (status_to_string feature.status));
                  ("Horizon", Html.esc (horizon_label feature));
                  ( "Priority",
                    match feature.priority with
                    | Some p -> Html.esc (priority_to_string p)
                    | None -> "—" );
                  ( "Tasks",
                    Printf.sprintf "%d/%d open" detail.V.sd_open detail.V.sd_total );
                  ( "Plan",
                    if detail.V.sd_plan_present then "present" else "none" ) ]
            ^ "\n<h2>spec.md</h2>\n"
            ^ Html.md_article feature.spec_md
            ^ plan_section
            ^ "\n<h2>tasks.md</h2>\n"
            ^ Html.task_table ~interactive:true tasks
            ^ raw_tasks
          in
          H.html_resp c (page_html feature.slug "/specs" body)));

  H.on_get app "/constitution" (fun c ->
      let con = (tree ()).Load_tree.tree_constitution in
      let body =
        if con.Load_tree.present then
          "<h1>" ^ Html.esc con.Load_tree.const_title ^ "</h1>\n"
          ^ "<p class=\"empty\">Read-only. Amend the file, not this page. Not copied into <code>memory/</code>.</p>\n"
          ^ Html.md_article con.Load_tree.const_body
        else "<h1>Constitution</h1><p>Missing. Bootstrap writes a stub.</p>"
      in
      H.html_resp c (page_html "Constitution" "/constitution" body));

  H.on_get app "/graph" (fun c ->
      let graph = graph_of (tree ()).Load_tree.features in
      let nodes =
        List.map
          (fun (n : Domain.graph_node) ->
            "<li><span class=\"pill\">" ^ Html.esc n.node_kind ^ "</span> <code>"
            ^ Html.esc n.node_id
            ^ "</code> "
            ^ Html.esc n.node_title
            ^ " "
            ^ Html.status_pill n.node_status
            ^ "</li>")
          graph.Domain.nodes
      in
      let edges =
        List.map
          (fun (e : Domain.graph_edge) ->
            "<li><code>" ^ Html.esc e.g_edge_from ^ "</code> → <code>"
            ^ Html.esc e.g_edge_to
            ^ "</code> <span class=\"muted\">"
            ^ Html.esc e.g_edge_kind
            ^ "</span></li>")
          graph.Domain.edges
      in
      let body =
        "<h1>Graph</h1>\n<p>Edges from <code>tasks.md</code> order, phase boundaries, and <code>[[wiki]]</code> links. No side-car relations table.</p>\n<h2>Nodes</h2><ul class=\"graph\">"
        ^ (match nodes with [] -> "<li>none</li>" | ns -> String.concat "" ns)
        ^ "</ul>\n<h2>Edges</h2><ul class=\"graph\">"
        ^ (match edges with [] -> "<li>none</li>" | es -> String.concat "" es)
        ^ "</ul>"
      in
      H.html_resp c (page_html "Graph" "/graph" body));

  H.on_get app "/memory" (fun c ->
      let notes = Load_tree.load_memory_notes paths.Paths.memory in
      let body =
        "<h1>Memory</h1>\n<p>Read-only. Constitution is not copied here; point at it.</p>\n"
        ^ memory_items_html notes
      in
      H.html_resp c (page_html "Memory" "/memory" body));

  (* ---------- static ---------- *)

  H.on_get app "/static/:file" (fun c ->
      let file = H.param c "file" in
      if Speckit.contains file "/" || Speckit.contains file ".." then
        H.text_status c "not found" 404
      else
        let p = P.join2 (Paths.public_dir ()) file in
        if not (F.exists_sync p) then H.text_status c "not found" 404
        else
          let mime =
            if Js_shims.Str.ends_with file ".css" then "text/css; charset=utf-8"
            else if Js_shims.Str.ends_with file ".js" then "text/javascript; charset=utf-8"
            else if Js_shims.Str.ends_with file ".svg" then "image/svg+xml"
            else "application/octet-stream"
          in
          H.bytes_resp c ~mime (F.read_file_sync p));

  (* ---------- json api ---------- *)

  H.on_get app "/api/summary" (fun c ->
      let features = (tree ()).Load_tree.features in
      H.json_resp c (V.summary_visual_json features (Context_gen.blocked_tasks features)));

  H.on_get app "/api/roadmap" (fun c ->
      H.json_resp c (V.roadmap_json (tree ()).Load_tree.features));

  H.on_get app "/api/backlog" (fun c ->
      H.json_resp c (V.backlog_json (tree ()).Load_tree.features));

  H.on_get app "/api/specs" (fun c ->
      H.json_resp c
        (J.arr (List.map (fun f -> V.spec_card_json (spec_card f)) (tree ()).Load_tree.features)));

  H.on_get app "/api/specs/:slug" (fun c ->
      match V.find_feature (tree ()).Load_tree.features (H.param c "slug") with
      | None -> H.json_status c (J.obj [ ("error", J.str "not found") ]) 404
      | Some f -> H.json_resp c (V.spec_detail_json (V.spec_detail_of_feature f)));

  H.on_get app "/api/item/:ref" (fun c ->
      let ref_ = H.param c "ref" in
      let r = Domain.parse_ref ref_ in
      match r.Domain.task_id with
      | Some _ -> (
          match V.find_task (tree ()).Load_tree.features ref_ with
          | Some (f, t) ->
              H.json_resp c
                (J.obj
                   [ ("kind", J.str "task");
                     ("spec", V.spec_card_json (spec_card f));
                     ("task", V.task_json t) ])
          | None -> H.json_status c (J.obj [ ("error", J.str "not found") ]) 404)
      | None -> (
          match r.Domain.slug with
          | Some slug -> (
              match V.find_feature (tree ()).Load_tree.features slug with
              | Some f ->
                  H.json_resp c
                    (J.obj
                       [ ("kind", J.str "spec");
                         ("spec", V.spec_detail_json (V.spec_detail_of_feature f)) ])
              | None -> H.json_status c (J.obj [ ("error", J.str "not found") ]) 404)
          | None -> H.json_status c (J.obj [ ("error", J.str "not found") ]) 404));

  H.on_get app "/api/search" (fun c ->
      let q = String.lowercase_ascii (H.query_default c "q" "") in
      let hits =
        List.concat_map
          (fun (f : feature) ->
            let spec_hits =
              if Speckit.contains f.slug q
                 || Speckit.contains (String.lowercase_ascii f.title) q
              then
                [ J.obj
                    [ ("kind", J.str "spec");
                      ("ref", J.str f.slug);
                      ("title", J.str f.title) ] ]
              else []
            in
            let task_hits =
              List.filter_map
                (fun t ->
                  if Speckit.contains (String.lowercase_ascii t.id) q
                     || Speckit.contains (String.lowercase_ascii t.title) q
                  then
                    Some
                      (J.obj
                         [ ("kind", J.str "task");
                           ("ref", J.str (make_ref f.slug (Some t.id)));
                           ("title", J.str t.title) ])
                  else None)
                f.tasks
            in
            spec_hits @ task_hits)
          (tree ()).Load_tree.features
      in
      H.json_resp c (J.obj [ ("hits", J.arr hits) ]));

  H.on_get app "/api/memory" (fun c ->
      let q = H.query_default c "q" "" in
      H.json_resp c (J.obj [ ("hits", string_of_hits (Overlay.search_memory db q)) ]));

  H.on_get app "/api/pins" (fun c ->
      H.json_resp c
        (J.obj
           [ ( "pins",
               J.arr
                 (List.map
                    (fun (p : Overlay.pin) ->
                      J.obj
                        [ ("ref", J.str p.Overlay.pin_ref);
                          ("reason", J.str p.Overlay.pin_reason);
                          ("pinned_at", J.str p.Overlay.pin_pinned_at) ])
                    (Overlay.list_pins db)) ) ]));

  H.on_get app "/api/metrics" (fun c ->
      H.json_resp c (V.metrics_json (tree ()).Load_tree.features));

  (* ---------- mutations ---------- *)

  let sync_handler c =
    H.json_resp c (sync_json ())
  in

  H.on_post app "/api/sync" (fun c -> Js.Promise.resolve (sync_handler c));
  H.on_post app "/api/index" (fun c -> Js.Promise.resolve (sync_handler c));

  H.on_post app "/api/task" (fun c ->
      catch_null c (fun body ->
          match body with
          | None -> H.json_status c (J.obj [ ("error", J.str "ref required") ]) 400
          | Some body -> (
              match body_string body "ref" with
              | None -> H.json_status c (J.obj [ ("error", J.str "ref required") ]) 400
              | Some ref_ -> (
                  let done_ = match body_bool body "done" with Some b -> b | None -> true in
                  let r = Domain.parse_ref ref_ in
                  match (r.Domain.slug, r.Domain.task_id) with
                  | Some slug, Some task_id -> (
                      let tasks_path = P.join3 paths.Paths.specs slug "tasks.md" in
                      if not (F.exists_sync tasks_path) then
                        H.json_status c (J.obj [ ("error", J.str "tasks.md missing") ]) 404
                      else
                        let current = F.read_file_sync tasks_path in
                        match Speckit.set_task_checkbox current task_id done_ with
                        | Error e -> H.json_status c (J.obj [ ("error", J.str e) ]) 404
                        | Ok markdown ->
                            F.write_file_sync tasks_path markdown;
                            ignore (Rebuild.rebuild_all root);
                            reload ();
                            let features = (tree ()).Load_tree.features in
                            H.json_resp c
                              (J.obj
                                 [ ("ok", J.bool true);
                                   ("changed", J.bool true);
                                   ("ref", J.str ref_);
                                   ("done", J.bool done_);
                                   ("backlog", V.backlog_json features) ]))
                  | _ -> H.json_status c (J.obj [ ("error", J.str "ref must be slug#T0xx") ]) 400))));

  H.on_post app "/api/pins" (fun c ->
      catch_null c (fun body ->
          match body with
          | None -> H.json_status c (J.obj [ ("error", J.str "ref and reason required") ]) 400
          | Some body -> (
              match (body_string body "ref", body_string body "reason") with
              | Some ref_, Some reason ->
                  let pin = Overlay.upsert_pin db ref_ reason in
                  H.json_resp c
                    (J.obj
                       [ ("ok", J.bool true);
                         ( "pin",
                           J.obj
                             [ ("ref", J.str pin.Overlay.pin_ref);
                               ("reason", J.str pin.Overlay.pin_reason);
                               ("pinned_at", J.str pin.Overlay.pin_pinned_at) ] ) ])
              | _ ->
                  H.json_status c (J.obj [ ("error", J.str "ref and reason required") ]) 400)));

  H.on_post app "/api/chat" (fun c ->
      catch_null c (fun body ->
          match body with
          | None -> H.json_status c (J.obj [ ("error", J.str "message required") ]) 400
          | Some body -> (
              match body_string body "message" with
              | None -> H.json_status c (J.obj [ ("error", J.str "message required") ]) 400
              | Some message ->
                  let envelope = chat_route () message in
                  let thread_id =
                    match body_string body "thread_id" with
                    | Some t -> t
                    | None -> Js_shims.Crypto.random_uuid ()
                  in
                  Overlay.insert_thread db thread_id
                    (let m = message in
                     if String.length m > 80 then String.sub m 0 80 else m);
                  Overlay.insert_message db thread_id "user"
                    (Js.Json.stringify
                       (J.obj
                          [ ("message", J.str message);
                            ( "context",
                              match body_dict body with
                              | Some d -> (
                                  match Js.Dict.get d "context" with
                                  | Some ctx -> ctx
                                  | None -> Js.Json.null)
                              | None -> Js.Json.null ) ]));
                  Overlay.insert_message db thread_id "assistant"
                    (Js.Json.stringify envelope);
                  let d =
                    match Js.Json.decodeObject envelope with
                    | Some d -> d
                    | None -> Js.Dict.empty ()
                  in
                  Js.Dict.set d "thread_id" (J.str thread_id);
                  H.json_resp c (Js.Json.object_ d))));

  app

