(* Entry: bun run check — _generated/src/check_ml.js. Fixtures, envelope
   roundtrip, checkbox edits, live route tests. *)

module F = Js_shims.Fs
module P = Js_shims.Path
module H = Hono
module J = Views.Json
module E = Envelope

open Domain

let failures : string list ref = ref []

let assert_ cond msg = if not cond then failures := !failures @ [ msg ]

let eq_string (a : string) (b : string) msg =
  if a <> b then failures := !failures @ [ msg ^ ": " ^ a ^ " !== " ^ b ]

let field (json : Js.Json.t) k =
  match Js.Json.decodeObject json with
  | None -> None
  | Some d -> Js.Dict.get d k

let str_field json k = match field json k with Some v -> Js.Json.decodeString v | None -> None

let get_json json k =
  match field json k with Some v -> v | None -> Js.Json.null

let get_str json k = match str_field json k with Some s -> s | None -> ""

let get_bool json k =
  match field json k with
  | Some v -> Option.value ~default:false (Js.Json.decodeBoolean v)
  | None -> false

let first_visual_kind (env : Js.Json.t) =
  match field env "visuals" with
  | Some v -> (
      match Js.Json.decodeArray v with
      | Some vs when Array.length vs > 0 -> str_field vs.(0) "kind"
      | _ -> None)
  | None -> None

let rec json_array_to_list (a : Js.Json.t array) acc i =
  if i >= Array.length a then List.rev acc
  else json_array_to_list a (a.(i) :: acc) (i + 1)

let json_list json =
  match Js.Json.decodeArray json with
  | Some a -> json_array_to_list a [] 0
  | None -> []

(* --- sync checks on the pure core --- *)

let sync_checks () =
  let fixtures = Paths.fixtures_dir () in
  let constitution_text = F.read_file_sync (P.join2 fixtures "constitution.md") in
  let spec_text = F.read_file_sync (P.join4 fixtures "specs" "000-check-fixture" "spec.md") in
  let tasks_text = F.read_file_sync (P.join4 fixtures "specs" "000-check-fixture" "tasks.md") in
  let plan_text = F.read_file_sync (P.join4 fixtures "specs" "000-check-fixture" "plan.md") in

  let constitution = Speckit.parse_constitution constitution_text in
  assert_ (constitution.Speckit.title <> "") "constitution has a title";
  assert_
    (not (Speckit.contains constitution.Speckit.body "memory/decisions"))
    "constitution is not a memory dump";

  let feature =
    Speckit.assemble_feature
      { fi_slug = "000-check-fixture";
        fi_spec_md = spec_text;
        fi_plan_md = Some plan_text;
        fi_tasks_md = Some tasks_text;
        fi_siblings = [];
        fi_gate_failing = false }
  in
  eq_string
    (status_to_string feature.status)
    "in-progress"
    "fixture feature is in-progress";
  eq_string
    (match feature.horizon with Some h -> horizon_to_string h | None -> "null")
    "now"
    "fixture horizon from frontmatter";
  assert_ (List.length feature.tasks >= 3) "parsed tasks";
  assert_
    (List.length feature.tasks > 0 && (List.nth feature.tasks 0).is_done)
    "T001 checked";
  assert_
    (List.exists (fun t -> t.id = "T003" && t.parallel) feature.tasks)
    "[P] task";

  let specified =
    Speckit.assemble_feature
      { fi_slug = "002-x";
        fi_spec_md = "# X\n\nwhy\n";
        fi_plan_md = None;
        fi_tasks_md = None;
        fi_siblings = [];
        fi_gate_failing = false }
  in
  eq_string (status_to_string specified.status) "specified" "no plan → specified";
  eq_string (horizon_to_string specified.inferred_horizon) "next" "specified infers next";

  let done_now =
    Speckit.assemble_feature
      { fi_slug = "009-done"
      ; fi_spec_md = "---\nhorizon: now\n---\n\n# Done\n"
      ; fi_plan_md = Some "# Plan\n\n## Constitution Check\n\n- [x] ok\n"
      ; fi_tasks_md = Some "- [x] T001 finished\n"
      ; fi_siblings = []
      ; fi_gate_failing = false
      }
  in
  eq_string (status_to_string done_now.status) "done" "all tasks → done";
  eq_string
    (horizon_to_string done_now.inferred_horizon)
    "later"
    "Done + horizon: now → Later";

  (* a specified feature owns no tasks, so the summary must still name it *)
  let specified_summary = Context_gen.build_summary [ specified ] [] "now" in
  assert_
    (Speckit.contains specified_summary "## Needs a plan")
    "summary has a Needs a plan section";
  assert_
    (Speckit.contains specified_summary "002-x")
    "summary names the unplanned feature";
  assert_
    (not (Speckit.contains specified_summary "## Ready queue\n- none\n"))
    "empty ready queue falls through to Needs a plan";
  let planned_summary = Context_gen.build_summary [ feature ] [] "now" in
  assert_
    (Speckit.contains planned_summary "## Needs a plan\n- none")
    "nothing unplanned says none";

  (* bytes, not code points: an em dash is three bytes wide *)
  assert_ (String.length "—" = 3) "OCaml literals are byte strings";

  let parsed = Speckit.parse_tasks_markdown tasks_text "000-check-fixture" in
  assert_ (parsed.Speckit.edges <> []) "task order produces edges";

  let flipped = Speckit.set_task_checkbox tasks_text "T002" true in
  (match flipped with
   | Ok md ->
       assert_ (Speckit.contains md "- [x] T002") "T002 now checked";
       assert_ (Speckit.contains md "- [ ] T003") "T003 untouched"
   | Error e -> failures := !failures @ [ "checkbox edit ok: " ^ e ]);
  let back =
    match flipped with
    | Ok md -> Speckit.set_task_checkbox md "T002" false
    | Error _ -> flipped
  in
  (match back with
   | Ok md -> assert_ (Speckit.contains md "- [ ] T002") "checkbox restore"
   | Error e -> failures := !failures @ [ "checkbox restore: " ^ e ]);

  let classify m = Envelope.classify ~slugs:[ "000-check-fixture" ] m in
  let kind_of m =
    match classify m with
    | E.Summary -> "summary"
    | E.Roadmap -> "roadmap"
    | E.Backlog -> "backlog"
    | E.Blocked -> "blocked"
    | E.Constitution -> "constitution"
    | E.Graph -> "graph"
    | E.Spec _ -> "spec"
    | E.Task_ref _ -> "task"
    | E.Memory _ -> "memory"
  in
  eq_string (kind_of "what should we work on?") "summary" "morning → summary";
  eq_string (kind_of "what's blocked") "blocked" "blocked";
  eq_string (kind_of "show the roadmap") "roadmap" "roadmap";
  eq_string (kind_of "backlog please") "backlog" "backlog";
  eq_string (kind_of "constitution") "constitution" "constitution";
  eq_string (kind_of "000-check-fixture") "spec" "slug → spec";
  eq_string (kind_of "look at T012 in 000-check-fixture") "task" "task ref";
  eq_string (kind_of "why did we decide that") "memory" "memory";

  let catalog =
    Views.catalog_of [ feature ]
      ~constitution:
        (Some
           { Views.c_title = constitution.Speckit.title;
             c_excerpt =
               String.sub constitution.Speckit.body 0
                 (min 200 (String.length constitution.Speckit.body));
             c_body = constitution.Speckit.body })
      ~memory_hits:[]
  in
  let envelope_json m =
    Envelope.encode_envelope (Envelope.envelope_for (classify m) catalog)
  in
  let morning = envelope_json "what should we work on?" in
  (match first_visual_kind morning with
   | Some k -> eq_string k "summary" "named surface summary"
   | None -> failures := !failures @ [ "named surface summary: no visuals" ]);
  let blocked_env = envelope_json "what's blocked" in
  (match first_visual_kind blocked_env with
   | Some k -> eq_string k "blocked" "named surface blocked"
   | None -> failures := !failures @ [ "named surface blocked: no visuals" ]);

  let round = Envelope.decode_envelope morning in
  (match round with
   | E.Decode_err e -> failures := !failures @ [ "envelope roundtrip ok: " ^ e ]
   | Decode_ok env -> (
       match env.E.e_visuals with
       | v :: _ -> eq_string v.E.v_kind "summary" "roundtrip kind"
       | [] -> failures := !failures @ [ "roundtrip kind: no visuals" ]));

  (* 002-memory-notes#T020/T030 — reviewed is deny-closed. *)
  let note_md status =
    "---\nas_of: 2026-08-28\nsource: human\nconfidence: high\n"
    ^ status
    ^ "---\n\n# Title\n\nbody\n"
  in
  let note_of path status = Memory_ml.parse_memory_note path (note_md status) in
  let reviewed path status = Memory_ml.is_reviewed (note_of path status) in
  assert_ (reviewed "memory/conventions/ok.md" "status: active\n") "active convention is reviewed";
  assert_ (not (reviewed "memory/conventions/ok.md" "")) "missing status is not reviewed";
  assert_
    (not (reviewed "memory/decisions/p.md" "status: proposal\n"))
    "proposal is not reviewed";
  assert_
    (not (reviewed "memory/regressions/r.md" "status: rejected\n"))
    "rejected is not reviewed";
  assert_
    (not (reviewed "memory/conventions/s.md" "status: superseded\n"))
    "superseded is not reviewed";
  assert_
    (not (reviewed "memory/sessions/x.md" "status: proposal\n"))
    "session is not reviewed";
  assert_
    (not (reviewed "memory/orphan.md" "status: active\n"))
    "outside trees is not reviewed";
  assert_
    ((note_of "memory/conventions/x.md" "").Memory_ml.status = None)
    "missing status is None";
  assert_
    ((note_of "memory/conventions/x.md" "status: potato\n").Memory_ml.status = None)
    "unknown status is None";
  eq_string (Memory_ml.status_label None) "unknown" "status_label none"

(* --- live app on a tmp project --- *)

let write_note root tree name body =
  let dir = P.join3 root "memory" tree in
  F.mkdir_p dir;
  F.write_file_sync (P.join2 dir name) body

let make_tmp_project () =
  let tmp =
    P.join2 (Js_shims.Os.tmpdir ())
      ("dash-check-" ^ Js_shims.Crypto.random_uuid ())
  in
  F.mkdir_p (P.join3 tmp ".specify" "memory");
  F.mkdir_p (P.join3 tmp "specs" "000-check-fixture");
  F.write_file_sync (P.join4 tmp ".specify" "memory" "constitution.md")
    (F.read_file_sync (P.join2 (Paths.fixtures_dir ()) "constitution.md"));
  F.write_file_sync (P.join4 tmp "specs" "000-check-fixture" "spec.md")
    (F.read_file_sync (P.join4 (Paths.fixtures_dir ()) "specs" "000-check-fixture" "spec.md"));
  F.write_file_sync (P.join4 tmp "specs" "000-check-fixture" "plan.md")
    (F.read_file_sync (P.join4 (Paths.fixtures_dir ()) "specs" "000-check-fixture" "plan.md"));
  F.write_file_sync (P.join4 tmp "specs" "000-check-fixture" "tasks.md")
    (F.read_file_sync (P.join4 (Paths.fixtures_dir ()) "specs" "000-check-fixture" "tasks.md"));
  write_note tmp "conventions" "testing.md"
    "---\nas_of: 2026-08-28\nsource: human\nconfidence: high\nstatus: active\n---\n\n# Testing the overlay\n\nFTS should find this convention. Point at the constitution; do not copy it.\n";
  write_note tmp "sessions" "proposal.md"
    "---\nas_of: 2026-08-28\nsource: session/check\nconfidence: low\nstatus: proposal\n---\n\n# Session proposal\n\nSESSIONONLYTOKEN must not be a fact.\n";
  write_note tmp "decisions" "pending.md"
    "---\nas_of: 2026-08-28\nsource: human\nconfidence: medium\nstatus: proposal\n---\n\n# Pending decision\n\nPROPOSALONLYTOKEN must not be a fact.\n";
  write_note tmp "regressions" "dead.md"
    "---\nas_of: 2026-08-28\nsource: human\nconfidence: high\nstatus: rejected\n---\n\n# Rejected regression\n\nREJECTEDONLYTOKEN must not be a fact.\n";
  write_note tmp "conventions" "old.md"
    "---\nas_of: 2026-08-28\nsource: human\nconfidence: high\nstatus: superseded\n---\n\n# Old convention\n\nSUPERSEDEDONLYTOKEN must not be a fact.\n";
  write_note tmp "conventions" "bare.md"
    "---\nas_of: 2026-08-28\nsource: human\nconfidence: high\n---\n\n# Bare convention\n\nNOSTATUSTOKEN must not be a fact.\n";
  ignore (Rebuild.rebuild_all tmp);
  tmp

let finish () =
  if !failures <> [] then begin
    Js_shims.Console.error "check failed:";
    List.iter (fun f -> Js_shims.Console.error (" - " ^ f)) (List.rev !failures);
    Js_shims.Process.exit 1
  end;
  Js_shims.Console.log "check ok";
  Js_shims.Process.exit 0

let _ =
  sync_checks ();
  let tmp = make_tmp_project () in
  let app = App.create_app tmp in
  let open Js.Promise in
  H.request_get_p app "/health" |> then_ H.res_json
  |> then_
       (fun health ->
         assert_ (get_bool health "ok") "health ok";
         let count =
           match field health "specs" with
           | Some specs -> (
               match field specs "count" with
               | Some v -> int_of_float (Js.Json.decodeNumber v |> Option.value ~default:0.0)
               | None -> 0)
           | None -> 0
         in
         assert_ (count >= 1) "health specs count";
         let empty =
           match field health "specs" with Some specs -> get_bool specs "empty" | None -> true
         in
         assert_ (not empty) "not empty-specs";
         H.request_get_p app "/" |> then_ H.res_text)
  |> then_
       (fun home ->
         assert_ (Speckit.contains home "000-check-fixture") "overview lists fixture spec";
         assert_ (Speckit.contains home "What should we work on?") "overview shows generated summary";
         H.request_get_p app "/specs/INDEX.md" |> then_ H.res_bytes)
  |> then_
       (fun index_wire ->
         assert_
           (not (Speckit.contains index_wire "\xc3\xa2\xc2\x80"))
           "no double-encoded UTF-8 on the wire";
         assert_
           (Speckit.contains index_wire "Router only — load one spec folder")
           "em dash reaches the wire as UTF-8";
         H.request_get_p app "/specs" |> then_ H.res_text)
  |> then_
       (fun specs_page ->
         assert_ (Speckit.contains specs_page "000-check-fixture") "GET /specs lists directories";
         H.request_get_p app "/specs/000-check-fixture" |> then_ H.res_text)
  |> then_
       (fun detail ->
         assert_ (Speckit.contains detail "spec.md" || Speckit.contains detail "Example") "spec body";
         assert_ (Speckit.contains detail "T001") "tasks render";
         H.request_post_p app "/api/chat" "{\"message\":\"what should we work on?\"}" |> then_ H.res_json)
  |> then_
       (fun chat_summary ->
         eq_string
           (match first_visual_kind chat_summary with Some k -> k | None -> "")
           "summary"
           "POST chat morning";
         H.request_post_p app "/api/chat" "{\"message\":\"what's blocked\"}" |> then_ H.res_json)
  |> then_
       (fun chat_blocked ->
         eq_string
           (match first_visual_kind chat_blocked with Some k -> k | None -> "")
           "blocked"
           "POST chat blocked";
         H.request_get_p app "/api/backlog" |> then_ H.res_json)
  |> then_
       (fun before ->
         let has_t002 =
           json_list (get_json before "items")
           |> List.exists (fun item -> get_str item "ref" = "000-check-fixture#T002")
         in
         assert_ has_t002 "T002 starts open";
         H.request_post_p app "/api/task" "{\"ref\":\"000-check-fixture#T002\",\"done\":true}" |> then_ H.res_json)
  |> then_
       (fun toggled ->
         assert_ (get_bool toggled "ok") "task toggle ok";
         H.request_get_p app "/api/backlog" |> then_ H.res_json)
  |> then_
       (fun after ->
         let still_t002 =
           json_list (get_json after "items")
           |> List.exists (fun item -> get_str item "ref" = "000-check-fixture#T002")
         in
         assert_ (not still_t002) "T002 left the backlog after toggle + sync";
         let tasks_after = F.read_file_sync (P.join4 tmp "specs" "000-check-fixture" "tasks.md") in
         assert_ (Speckit.contains tasks_after "- [x] T002") "checkbox written to tasks.md";
         let index_md = F.read_file_bytes (P.join3 tmp "specs" "INDEX.md") in
         assert_
           (not (Speckit.contains index_md "\xc3\xa2\xc2\x80"))
           "no double-encoded UTF-8 on disk in INDEX.md";
         assert_
           (Speckit.contains index_md "Router only — load one spec folder")
           "INDEX.md em dash survives the write";
         H.request_post_p app "/api/chat" "{\"message\":\"any decision or convention?\"}" |> then_ H.res_json)
  |> then_
       (fun mem ->
         eq_string
           (match first_visual_kind mem with Some k -> k | None -> "")
           "memory"
           "memory visual";
         H.request_get_p app "/memory" |> then_ H.res_text)
  |> then_
       (fun memory_page ->
         assert_ (Speckit.contains memory_page "Testing the overlay") "reviewed convention on /memory";
         assert_ (Speckit.contains memory_page "active") "/memory shows status";
         assert_ (not (Speckit.contains memory_page "SESSIONONLYTOKEN")) "session token absent from /memory";
         assert_ (not (Speckit.contains memory_page "PROPOSALONLYTOKEN")) "proposal token absent from /memory";
         assert_ (not (Speckit.contains memory_page "REJECTEDONLYTOKEN")) "rejected token absent from /memory";
         assert_ (not (Speckit.contains memory_page "SUPERSEDEDONLYTOKEN")) "superseded token absent from /memory";
         assert_ (not (Speckit.contains memory_page "NOSTATUSTOKEN")) "missing-status token absent from /memory";
         H.request_get_p app "/api/memory?q=overlay" |> then_ H.res_json)
  |> then_
       (fun overlay_hits ->
         let hits = json_list (get_json overlay_hits "hits") in
         assert_ (hits <> []) "FTS finds the active convention";
         H.request_get_p app "/api/memory?q=SESSIONONLYTOKEN" |> then_ H.res_json)
  |> then_
       (fun session_hits ->
         let hits = json_list (get_json session_hits "hits") in
         assert_ (hits = []) "FTS misses the session token";
         H.request_get_p app "/api/memory?q=PROPOSALONLYTOKEN" |> then_ H.res_json)
  |> then_
       (fun proposal_hits ->
         let hits = json_list (get_json proposal_hits "hits") in
         assert_ (hits = []) "FTS misses the proposal token";
         H.request_get_p app "/api/memory?q=REJECTEDONLYTOKEN" |> then_ H.res_json)
  |> then_
       (fun rejected_hits ->
         let hits = json_list (get_json rejected_hits "hits") in
         assert_ (hits = []) "FTS misses the rejected token";
         H.request_get_p app "/api/memory?q=SUPERSEDEDONLYTOKEN" |> then_ H.res_json)
  |> then_
       (fun superseded_hits ->
         let hits = json_list (get_json superseded_hits "hits") in
         assert_ (hits = []) "FTS misses the superseded token";
         H.request_get_p app "/api/memory?q=NOSTATUSTOKEN" |> then_ H.res_json)
  |> then_
       (fun bare_hits ->
         let hits = json_list (get_json bare_hits "hits") in
         assert_ (hits = []) "FTS misses the missing-status token";
         Js.Promise.resolve (finish ()))
  |> catch (fun e ->
         let msg = Option.value (Js_shims.exn_message e) ~default:"unknown JS error" in
         Js_shims.Console.error ("check crashed: " ^ msg);
         Js_shims.Process.exit 1)
