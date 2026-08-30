(* Deterministic chat intent + ChatEnvelope codec. *)

open Domain
open Views

type intent =
  | Summary
  | Roadmap
  | Backlog
  | Blocked
  | Constitution
  | Graph
  | Spec of string
  | Task_ref of string
  | Memory of string

type visual =
  { v_kind : string
  ; v_title : string
  ; v_data : Js.Json.t
  }

type envelope =
  { e_text : string
  ; e_visuals : visual list
  ; e_citations : string list
  }

let get_field (d : Js.Json.t Js.Dict.t) k =
  match Js.Dict.get d k with Some v -> Some v | None -> None

let as_string = function
  | Some v -> Js.Json.decodeString v
  | None -> None

(* --- classification --- *)

let contains_ci hay needle = Speckit.contains (String.lowercase_ascii hay) needle

let word_at s i n =
  let n_total = String.length s in
  let before_ok = i = 0 || not (is_word_char s.[i - 1]) in
  let after_i = i + n in
  let after_ok = after_i >= n_total || not (is_word_char s.[after_i]) in
  before_ok && after_ok
;;

let contains_word_ci hay needle =
  let low = String.lowercase_ascii hay in
  let n = String.length low in
  let m = String.length needle in
  let rec scan i =
    if i + m > n
    then false
    else if String.sub low i m = needle && word_at low i m
    then true
    else scan (i + 1)
  in
  scan 0
;;

let is_punct c =
  match c with
  | '?' | '!' | '.' | ',' | ';' | ':' -> true
  | _ -> false
;;

(* token check for "now" / "next": surrounded by start/space and
   space/end/punctuation *)
let standalone_word q w =
  let n = String.length q in
  let m = String.length w in
  let rec scan i =
    if i + m > n
    then false
    else if String.sub q i m = w
    then (
      let before_ok = i = 0 || q.[i - 1] = ' ' in
      let j = i + m in
      let after_ok = j >= n || q.[j] = ' ' || is_punct q.[j] in
      (before_ok && after_ok) || scan (i + 1))
    else scan (i + 1)
  in
  scan 0
;;

let find_slug_in_text message slugs =
  let known = List.find_opt (fun s -> contains_word_ci message s) slugs in
  match known with
  | Some _ as found -> found
  | None ->
    (* scan for \b\d{3}-[a-z0-9][a-z0-9-]*\b *)
    let n = String.length message in
    let low = String.lowercase_ascii message in
    let rec scan i =
      if i + 4 > n
      then None
      else if
        is_digit low.[i]
        && is_digit low.[i + 1]
        && is_digit low.[i + 2]
        && low.[i + 3] = '-'
        && (i = 0 || not (is_word_char low.[i - 1]))
      then (
        let c = low.[i + 4] in
        if is_digit c || (c >= 'a' && c <= 'z')
        then (
          let rec take j = if j < n && is_word_char low.[j] then take (j + 1) else j in
          let j = take (i + 4) in
          let slug = String.sub low i (j - i) in
          if word_at low i (j - i) then Some slug else scan j)
        else scan (i + 1))
      else scan (i + 1)
    in
    scan 0
;;

let find_task_in_text message =
  let n = String.length message in
  let low = String.lowercase_ascii message in
  let rec scan i =
    if i + 4 > n
    then None
    else if
      low.[i] = 't'
      && is_digit low.[i + 1]
      && is_digit low.[i + 2]
      && is_digit low.[i + 3]
      && (i = 0 || not (is_word_char low.[i - 1]))
    then (
      let rec take j = if j < n && is_digit low.[j] then take (j + 1) else j in
      let j = take (i + 1) in
      if j >= n || not (is_word_char low.[j])
      then Some (String.uppercase_ascii (String.sub low i (j - i)))
      else scan j)
    else scan (i + 1)
  in
  scan 0
;;

let classify ~slugs message =
  if contains_word_ci message "blocked"
  then Blocked
  else if contains_word_ci message "constitution"
  then Constitution
  else if
    contains_ci message "why did we"
    || contains_word_ci message "decision"
    || contains_word_ci message "regression"
    || contains_word_ci message "memory"
  then Memory message
  else (
    let slug = find_slug_in_text message slugs in
    let task_id = find_task_in_text message in
    match task_id with
    | Some id ->
      Task_ref
        (match slug with
         | Some s -> s ^ "#" ^ id
         | None -> id)
    | None ->
      (match slug with
       | Some s -> Spec s
       | None ->
         if contains_ci message "what should we" || contains_ci message "what should i"
         then Summary
         else if
           contains_word_ci message "roadmap"
           || contains_word_ci message "horizon"
           || standalone_word (String.lowercase_ascii message) "now"
           || (standalone_word (String.lowercase_ascii message) "next"
               && contains_word_ci message "horizon")
         then Roadmap
         else if contains_word_ci message "backlog" || contains_word_ci message "tasks"
         then Backlog
         else if contains_word_ci message "graph"
         then Graph
         else Summary))
;;

(* --- envelope building --- *)

let visual kind title data = { v_kind = kind; v_title = title; v_data = data }

let make_envelope text visuals citations =
  let rec unique acc = function
    | [] -> List.rev acc
    | x :: rest -> if List.mem x acc then unique acc rest else unique (x :: acc) rest
  in
  { e_text = text; e_visuals = visuals; e_citations = unique [] citations }
;;

let resolve_task ref_ (cat : catalog) =
  let exact ref_ =
    match List.assoc_opt ref_ cat.cat_tasks with
    | Some (d, false) -> Some d
    | _ -> None
  in
  match exact ref_ with
  | Some d -> Some d
  | None ->
    let upper = String.uppercase_ascii ref_ in
    (match exact upper with
     | Some d -> Some d
     | None ->
       (match String.index_opt ref_ '#' with
        | Some i ->
          let slug = String.sub ref_ 0 i in
          let id =
            String.uppercase_ascii (String.sub ref_ (i + 1) (String.length ref_ - i - 1))
          in
          exact (slug ^ "#" ^ id)
        | None -> None))
;;

let morning_text (cat : catalog) =
  let flight = cat.cat_in_flight in
  let ready = cat.cat_ready in
  let blocked = cat.cat_blocked in
  if flight = [] && ready = []
  then "No specs in flight. Specify something, or pick a next-horizon writing to plan."
  else (
    let next =
      match ready with
      | [] -> None
      | t :: _ -> Some t
    in
    let next_bit =
      match next with
      | Some t -> " Next ready task: " ^ t.card_ref ^ " — " ^ t.card_title ^ "."
      | None -> ""
    in
    let block_bit =
      if blocked = [] then "" else " " ^ string_of_int (List.length blocked) ^ " blocked."
    in
    let flight_str =
      match List.map (fun c -> c.slug) flight with
      | [] -> "none"
      | slugs -> String.concat ", " slugs
    in
    "In flight: " ^ flight_str ^ "." ^ next_bit ^ block_bit)
;;

let blocked_citations (cat : catalog) =
  List.filter_map
    (fun item ->
       match item.card with
       | Spec_card c -> Some c.slug
       | Task_card c -> Some c.card_ref)
    cat.cat_blocked
;;

let memory_hit_paths hits =
  List.filter_map
    (fun h ->
       match Js.Json.decodeObject h with
       | None -> None
       | Some d -> as_string (get_field d "path"))
    hits
;;

let envelope_for (intent : intent) (cat : catalog) : envelope =
  match intent with
  | Blocked ->
    make_envelope
      "Blocked items from constitution gates and unmet task order."
      [ visual "blocked" "Blocked" cat.cat_blocked_json ]
      (blocked_citations cat)
  | Constitution ->
    let constitution =
      match cat.cat_constitution with
      | Some c -> c
      | None ->
        { c_title = "Constitution"; c_excerpt = "Constitution is the gate."; c_body = "" }
    in
    make_envelope
      (if constitution.c_excerpt <> ""
       then constitution.c_excerpt
       else "Constitution is the gate.")
      [ visual
          "note_md"
          (if constitution.c_title <> "" then constitution.c_title else "Constitution")
          (Json.obj
             [ "markdown", Json.str constitution.c_body
             ; "path", Json.str ".specify/memory/constitution.md"
             ])
      ]
      [ ".specify/memory/constitution.md" ]
  | Memory query ->
    let hits = cat.cat_memory_hits in
    make_envelope
      (if hits <> []
       then "Memory hits for \xe2\x80\x9c" ^ query ^ "\xe2\x80\x9d."
       else
         "No reviewed memory matched. Constitution is still citable; it is not copied \
          into memory/.")
      [ visual "memory" "Memory" (Json.obj [ "hits", Json.arr hits ]) ]
      (memory_hit_paths hits)
  | Task_ref ref_ ->
    (match resolve_task ref_ cat with
     | None -> make_envelope ("No task " ^ ref_ ^ " in the writings.") [] []
     | Some d ->
       make_envelope
         (d.td_card.card_ref ^ " — " ^ d.td_card.card_title)
         [ visual "task" d.td_card.card_ref (task_detail_json d) ]
         [ d.td_slug; d.td_card.card_ref ])
  | Spec slug ->
    (match List.assoc_opt slug cat.cat_specs with
     | None -> make_envelope ("No spec " ^ slug ^ ".") [] []
     | Some d ->
       make_envelope
         (d.sd_card.slug
          ^ " — "
          ^ d.sd_card.title
          ^ " ("
          ^ status_to_string d.sd_card.status
          ^ ")")
         [ visual "spec" d.sd_card.slug (spec_detail_json d) ]
         [ d.sd_card.slug ])
  | Roadmap ->
    make_envelope
      "Specs grouped by horizon (now / next / later)."
      [ visual "roadmap" "Roadmap" cat.cat_roadmap_json ]
      cat.cat_roadmap_specs
  | Backlog ->
    make_envelope
      "Open tasks across specs, in file order."
      [ visual "backlog" "Backlog" cat.cat_backlog_json ]
      (List.map (fun t -> t.card_ref) cat.cat_ready)
  | Graph ->
    make_envelope
      "Task order and wiki links from the writings."
      [ visual "graph" "Graph" cat.cat_graph_json ]
      cat.cat_slugs
  | Summary ->
    make_envelope
      (morning_text cat)
      [ visual "summary" "What should we work on?" cat.cat_summary_json ]
      (List.map (fun c -> c.slug) cat.cat_in_flight)
;;

(* --- codec --- *)

let is_visual_kind kind =
  List.mem
    kind
    [ "summary"
    ; "roadmap"
    ; "backlog"
    ; "spec"
    ; "task"
    ; "graph"
    ; "blocked"
    ; "memory"
    ; "note_md"
    ]
;;

let encode_envelope (e : envelope) : Js.Json.t =
  Json.obj
    [ "text", Json.str e.e_text
    ; ( "visuals"
      , Json.arr
          (List.map
             (fun v ->
                Json.obj
                  [ "kind", Json.str v.v_kind
                  ; "title", Json.str v.v_title
                  ; "data", v.v_data
                  ])
             e.e_visuals) )
    ; "citations", Json.arr (List.map Json.str e.e_citations)
    ]
;;

type decode_result =
  | Decode_ok of envelope
  | Decode_err of string

let get_field (d : Js.Json.t Js.Dict.t) k =
  match Js.Dict.get d k with
  | Some v -> Some v
  | None -> None
;;

let as_string = function
  | Some v -> Js.Json.decodeString v
  | None -> None
;;

let decode_envelope (json : Js.Json.t) : decode_result =
  match Js.Json.decodeObject json with
  | None -> Decode_err "not an object"
  | Some d ->
    (match as_string (get_field d "text") with
     | None -> Decode_err "text must be a string"
     | Some text ->
       (match
          Js.Json.decodeArray
            (get_field d "visuals" |> Option.value ~default:(Js.Json.array [||]))
        with
        | None -> Decode_err "visuals must be an array"
        | Some visuals_arr ->
          let decode_visual (v : Js.Json.t) =
            match Js.Json.decodeObject v with
            | None -> Error "visual must be an object"
            | Some vd ->
              (match as_string (get_field vd "kind") with
               | None -> Error "visual kind must be a string"
               | Some kind ->
                 if not (is_visual_kind kind)
                 then Error ("unknown visual kind: " ^ kind)
                 else (
                   match as_string (get_field vd "title") with
                   | None -> Error "visual title must be a string"
                   | Some title ->
                     let data =
                       match get_field vd "data" with
                       | Some data -> data
                       | None -> Js.Json.object_ (Js.Dict.empty ())
                     in
                     Ok (visual kind title data)))
          in
          let result =
            Array.fold_left
              (fun acc v ->
                 match acc, decode_visual v with
                 | Error e, _ -> Error e
                 | Ok acc, Ok v -> Ok (v :: acc)
                 | Ok _, Error e -> Error e)
              (Ok [])
              visuals_arr
          in
          (match result with
           | Error e -> Decode_err e
           | Ok visuals_rev ->
             let visuals = List.rev visuals_rev in
             let citations_opt =
               match get_field d "citations" with
               | None -> Some []
               | Some c ->
                 (match Js.Json.decodeArray c with
                  | None -> None
                  | Some arr ->
                    let rec to_strs i acc =
                      if i >= Array.length arr
                      then Some (List.rev acc)
                      else (
                        match Js.Json.decodeString arr.(i) with
                        | Some s -> to_strs (i + 1) (s :: acc)
                        | None -> None)
                    in
                    to_strs 0 [])
             in
             (match citations_opt with
              | None -> Decode_err "citations must be an array"
              | Some citations ->
                Decode_ok { e_text = text; e_visuals = visuals; e_citations = citations }))))
;;
