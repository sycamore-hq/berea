(* Pure parsers for spec-kit files. No JS dependencies. *)

open Domain

(* --- string helpers --- *)

let normalize_crlf s =
  let b = Buffer.create (String.length s) in
  let n = String.length s in
  let rec go i =
    if i >= n
    then Buffer.contents b
    else if s.[i] = '\r'
    then
      if i + 1 < n && s.[i + 1] = '\n'
      then go (i + 1)
      else (
        Buffer.add_char b '\n';
        go (i + 1))
    else (
      Buffer.add_char b s.[i];
      go (i + 1))
  in
  go 0
;;

let lines_of s =
  let rec aux acc i =
    match String.index_from_opt s i '\n' with
    | None -> List.rev (String.sub s i (String.length s - i) :: acc)
    | Some j -> aux (String.sub s i (j - i) :: acc) (j + 1)
  in
  if s = "" then [ "" ] else aux [] 0
;;

let starts_with prefix s =
  let n = String.length prefix in
  String.length s >= n && String.sub s 0 n = prefix
;;

let ends_with suffix s =
  let n = String.length suffix in
  let m = String.length s in
  m >= n && String.sub s (m - n) n = suffix
;;

let contains hay needle =
  let n = String.length needle in
  let rec scan i =
    if i + n > String.length hay
    then false
    else if String.sub hay i n = needle
    then true
    else scan (i + 1)
  in
  scan 0
;;

(* first occurrence of [needle] at or after [from], as an option *)
let find_from s from needle =
  let n = String.length s
  and m = String.length needle in
  let rec scan i =
    if i + m > n
    then None
    else if String.sub s i m = needle
    then Some i
    else scan (i + 1)
  in
  scan (max 0 from)
;;

let trim s =
  let n = String.length s in
  let rec left i =
    if i >= n
    then n
    else (
      match s.[i] with
      | ' ' | '\t' | '\r' | '\n' -> left (i + 1)
      | _ -> i)
  in
  let rec right i =
    if i < 0
    then -1
    else (
      match s.[i] with
      | ' ' | '\t' | '\r' | '\n' -> right (i - 1)
      | _ -> i)
  in
  let l = left 0 in
  let r = right (n - 1) in
  if l > r then "" else String.sub s l (r - l + 1)
;;

let is_space c = c = ' ' || c = '\t'

(* --- frontmatter --- *)

let strip_bom s =
  if String.length s >= 3 && String.sub s 0 3 = "\xef\xbb\xbf"
  then String.sub s 3 (String.length s - 3)
  else s
;;

let unquote value =
  let n = String.length value in
  if
    n >= 2
    && ((value.[0] = '"' && value.[n - 1] = '"')
        || (value.[0] = '\'' && value.[n - 1] = '\''))
  then String.sub value 1 (n - 2)
  else value
;;

let parse_simple_yaml yaml =
  lines_of yaml
  |> List.filter_map (fun raw ->
    let line = trim raw in
    if line = "" || starts_with "#" line
    then None
    else (
      match String.index_opt line ':' with
      | None -> None
      | Some c when c = 0 -> None
      | Some c ->
        let k = trim (String.sub line 0 c) in
        let v = unquote (trim (String.sub line (c + 1) (String.length line - c - 1))) in
        if k = "" then None else Some (k, v)))
;;

let attr (attrs : (string * string) list) key =
  try Some (List.assoc key attrs) with
  | Not_found -> None
;;

let parse_frontmatter text =
  let src = normalize_crlf (strip_bom text) in
  if not (starts_with "---" src)
  then [], src
  else (
    let after = String.sub src 3 (String.length src - 3) in
    let n = String.length after in
    let opens_ok = n = 0 || after.[0] = '\n' in
    let rec find_end i =
      if i >= n
      then None
      else if after.[i] = '\n'
      then (
        let rest_start = i + 1 in
        if rest_start + 3 <= n && String.sub after rest_start 3 = "---"
        then (
          let j = ref (rest_start + 3) in
          while !j < n && (after.[!j] = ' ' || after.[!j] = '\t') do
            incr j
          done;
          if !j >= n || after.[!j] = '\n' then Some i else find_end (i + 1))
        else find_end (i + 1))
      else find_end (i + 1)
    in
    if not opens_ok
    then [], src
    else (
      match find_end 0 with
      | None -> [], src
      | Some end_i ->
        let yaml = String.sub after 0 end_i in
        let yaml =
          if yaml <> "" && yaml.[0] = '\n'
          then String.sub yaml 1 (String.length yaml - 1)
          else yaml
        in
        let rest_start = end_i + 1 in
        let rest = String.sub after rest_start (n - rest_start) in
        let rest = String.sub rest 3 (String.length rest - 3) in
        let rest =
          if rest <> "" && rest.[0] = '\n'
          then String.sub rest 1 (String.length rest - 1)
          else rest
        in
        parse_simple_yaml yaml, rest))
;;

(* --- headings --- *)

let first_heading markdown =
  lines_of markdown
  |> List.find_map (fun line ->
    if starts_with "# " line
    then (
      let rest = trim (String.sub line 2 (String.length line - 2)) in
      if rest = "" then None else Some rest)
    else None)
;;

let is_heading_1_3 line =
  let n = String.length line in
  let rec hashes i = if i < n && line.[i] = '#' then hashes (i + 1) else i in
  let h = hashes 0 in
  h >= 1 && h <= 3 && h < n && line.[h] = ' '
;;

let contains_word_ci hay needle = contains (String.lowercase_ascii hay) needle

(* --- constitution --- *)

type constitution =
  { title : string
  ; body : string
  ; principles : string list
  }

let parse_constitution text =
  let _, body = parse_frontmatter text in
  let title = Option.value (first_heading body) ~default:"Constitution" in
  let principles =
    lines_of body
    |> List.filter_map (fun line ->
      if starts_with "## " line
      then Some (trim (String.sub line 3 (String.length line - 3)))
      else None)
  in
  { title; body; principles }
;;

let has_fail_word s =
  let n = String.length s in
  let rec scan i =
    if i + 4 > n
    then false
    else if String.sub s i 4 = "FAIL"
    then (
      let before_ok = i = 0 || not (is_word_char s.[i - 1]) in
      let after_i = i + 4 in
      let after_ok = after_i >= n || not (is_word_char s.[after_i]) in
      (before_ok && after_ok) || scan (i + 1))
    else scan (i + 1)
  in
  scan 0
;;

let constitution_gate_failing plan_md =
  match plan_md with
  | None -> false
  | Some text ->
    let is_constitution_check line =
      is_heading_1_3 line
      && contains_word_ci line "constitution"
      && contains_word_ci line "check"
    in
    let rec walk in_section = function
      | [] -> false
      | line :: rest ->
        if is_constitution_check line
        then walk true rest
        else if in_section && is_heading_1_3 line
        then walk false rest
        else if not in_section
        then walk false rest
        else if has_fail_word line
        then true
        else if starts_with "- [ ]" (trim line)
        then true
        else walk in_section rest
    in
    walk false (lines_of text)
;;

(* --- tasks --- *)

let parse_task_id s i =
  (* expect T followed by one or more digits at s.[i]; return (id, next) *)
  let n = String.length s in
  if i < n && s.[i] = 'T'
  then (
    let rec digits j = if j < n && is_digit s.[j] then digits (j + 1) else j in
    let j = digits (i + 1) in
    if j > i + 1 then Some (String.sub s i (j - i), j) else None)
  else None
;;

let parse_task_line line _spec_slug _phase =
  let n = String.length line in
  let rec skip_ws i = if i < n && is_space line.[i] then skip_ws (i + 1) else i in
  let i = skip_ws 0 in
  if i < n && line.[i] = '-'
  then (
    let after_dash = skip_ws (i + 1) in
    if
      after_dash + 2 < n
      && line.[after_dash] = '['
      && (line.[after_dash + 1] = ' '
          || line.[after_dash + 1] = 'x'
          || line.[after_dash + 1] = 'X')
      && line.[after_dash + 2] = ']'
    then (
      let mark = line.[after_dash + 1] in
      let after_bracket = skip_ws (after_dash + 3) in
      match parse_task_id line after_bracket with
      | Some (id, after_id) when after_id < n && is_space line.[after_id] ->
        let rest = String.sub line after_id (n - after_id) in
        Some (id, mark <> ' ', rest)
      | _ -> None)
    else None)
  else None
;;

let is_t_tag s =
  let n = String.length s in
  n >= 2
  && s.[0] = 'T'
  &&
  let rec digits i = i >= n || (is_digit s.[i] && digits (i + 1)) in
  digits 1
;;

let split_tag_value s =
  let n = String.length s in
  let rec go i cur acc =
    if i >= n
    then List.rev (if cur = "" then acc else cur :: acc)
    else if is_digit s.[i] || s.[i] = 'T' || s.[i] = ',' || is_space s.[i]
    then go (i + 1) (cur ^ String.make 1 s.[i]) acc
    else go (i + 1) "" (if cur = "" then acc else cur :: acc)
  in
  go 0 "" [] |> List.filter is_t_tag
;;

let find_keyword_ci s kw =
  let low = String.lowercase_ascii s in
  let n = String.length low in
  let m = String.length kw in
  let rec scan i =
    if i + m > n
    then -1
    else if String.sub low i m = kw
    then (
      let before_ok = i = 0 || not (is_word_char low.[i - 1]) in
      let after_i = i + m in
      let after_ok = after_i >= n || not (is_word_char low.[after_i]) in
      if before_ok && after_ok then i else scan (i + 1))
    else scan (i + 1)
  in
  scan 0
;;

(* find "kw" (case-insensitive, word-bounded) preceded by at least one space;
   return (line_start, kw_start) *)
let take_keyword_tag s kw =
  match find_keyword_ci s kw with
  | -1 -> None
  | i when i = 0 -> None
  | i ->
    let rec back j = if j > 0 && is_space s.[j - 1] then back (j - 1) else j in
    let ws_start = back i in
    if ws_start = i then None else Some (ws_start, i)
;;

let drop_range s from upto =
  String.sub s 0 from ^ String.sub s upto (String.length s - upto)
;;

type task_rest =
  { tr_parallel : bool
  ; tr_story : string option
  ; tr_title : string
  ; tr_depends_on : string list
  ; tr_points : int option
  ; tr_rank : int option
  ; tr_priority : priority option
  ; tr_status_tag : string option
  }

let parse_task_rest raw =
  let s0 = trim raw in
  let n0 = String.length s0 in
  let s1, parallel =
    if starts_with "[P]" s0 then trim (String.sub s0 3 (n0 - 3)), true else s0, false
  in
  (* [US\d+] story marker *)
  let s2, story =
    let n = String.length s1 in
    if n >= 4 && s1.[0] = '[' && (s1.[1] = 'U' || s1.[1] = 'u') && s1.[2] = 'S'
    then (
      let rec digits i = if i < n && is_digit s1.[i] then digits (i + 1) else i in
      let j = digits 3 in
      if j < n && s1.[j] = ']'
      then trim (String.sub s1 (j + 1) (n - j - 1)), Some ("US" ^ String.sub s1 3 (j - 3))
      else s1, None)
    else s1, None
  in
  (* depends_on:T001,T002 *)
  let s3, depends_on =
    match take_keyword_tag s2 "depends_on:" with
    | None -> s2, []
    | Some (from, upto) ->
      let after = upto + String.length "depends_on:" in
      let n = String.length s2 in
      let rec value_end j =
        if j < n && (is_digit s2.[j] || s2.[j] = 'T' || s2.[j] = ',' || is_space s2.[j])
        then value_end (j + 1)
        else j
      in
      let vend = value_end after in
      let value = String.sub s2 after (vend - after) in
      trim (drop_range s2 from vend), split_tag_value value
  in
  let take_number_tag s kw =
    match take_keyword_tag s kw with
    | None -> s, None
    | Some (from, upto) ->
      let after = upto + String.length kw in
      let n = String.length s in
      let rec digits j = if j < n && is_digit s.[j] then digits (j + 1) else j in
      let vend = digits after in
      if vend > after
      then
        ( trim (drop_range s from vend)
        , Some (int_of_string (String.sub s after (vend - after))) )
      else s, None
  in
  let s4, points = take_number_tag s3 "points:" in
  let s5, rank = take_number_tag s4 "rank:" in
  (* priority:critical|high|medium|low *)
  let s6, priority =
    match take_keyword_tag s5 "priority:" with
    | None -> s5, None
    | Some (from, upto) ->
      let after = upto + String.length "priority:" in
      let low = String.lowercase_ascii (String.sub s5 after (String.length s5 - after)) in
      (match
         List.find_opt
           (fun w -> starts_with w low)
           [ "critical"; "high"; "medium"; "low" ]
       with
       | Some w ->
         let vend = after + String.length w in
         trim (drop_range s5 from vend), priority_of_string w
       | None -> s5, None)
  in
  (* status:\S+ *)
  let s7, status1 =
    match take_keyword_tag s6 "status:" with
    | None -> s6, None
    | Some (from, upto) ->
      let after = upto + String.length "status:" in
      let n = String.length s6 in
      let rec nonspace j =
        if j < n && not (is_space s6.[j]) then nonspace (j + 1) else j
      in
      let vend = nonspace after in
      if vend > after
      then trim (drop_range s6 from vend), Some (String.sub s6 after (vend - after))
      else s6, None
  in
  (* trailing (blocked|waiting|done) *)
  let s8, paren_status =
    let t = trim s7 in
    let n = String.length t in
    if ends_with ")" t && n >= 3
    then (
      let rec open_paren i = if i >= 0 && t.[i] <> '(' then open_paren (i - 1) else i in
      let op = open_paren (n - 2) in
      if op > 0 && is_space t.[op - 1]
      then (
        let inner = String.lowercase_ascii (String.sub t (op + 1) (n - op - 2)) in
        if inner = "blocked" || inner = "waiting" || inner = "done"
        then trim (String.sub t 0 (op - 1)), Some inner
        else t, None)
      else t, None)
    else t, None
  in
  let status_tag =
    match status1, paren_status with
    | Some st, _ -> Some st
    | None, Some st -> Some st
    | None, None -> None
  in
  { tr_parallel = parallel
  ; tr_story = story
  ; tr_title = trim s8
  ; tr_depends_on = depends_on
  ; tr_points = points
  ; tr_rank = rank
  ; tr_priority = priority
  ; tr_status_tag = status_tag
  }
;;

let dedup_add x xs = if List.mem x xs then xs else xs @ [ x ]

let with_inferred_deps (tasks : task list) =
  let rec go prev_phase_ids phase last_sequential current_phase_ids first_wave = function
    | [] -> []
    | t :: rest ->
      let prev, phase, last_seq, current_ids, first_wave =
        if t.phase <> phase
        then current_phase_ids, t.phase, None, [], true
        else prev_phase_ids, phase, last_sequential, current_phase_ids, first_wave
      in
      let deps = List.fold_left (fun acc d -> dedup_add d acc) t.depends_on [] in
      let deps =
        if first_wave && prev <> []
        then List.fold_left (fun acc id -> dedup_add id acc) deps prev
        else deps
      in
      let deps =
        match last_seq with
        | Some id -> dedup_add id deps
        | None -> deps
      in
      let current_ids = current_ids @ [ t.id ] in
      let last_seq = if t.parallel then last_seq else Some t.id in
      let first_wave = if t.parallel then first_wave else false in
      { t with depends_on = deps } :: go prev phase last_seq current_ids first_wave rest
  in
  go [] None None [] true tasks
;;

type parsed_tasks =
  { tasks : task list
  ; edges : edge list
  }

let parse_tasks_markdown text spec_slug =
  let src = normalize_crlf text in
  let ls = lines_of src in
  let parsed =
    List.mapi
      (fun idx line ->
         let phase =
           if starts_with "## " line
           then Some (trim (String.sub line 3 (String.length line - 3)))
           else None
         in
         phase, line, idx + 1)
      ls
  in
  let rec walk current_phase acc = function
    | [] -> List.rev acc
    | (phase_opt, line, lineno) :: rest ->
      let phase =
        match phase_opt with
        | Some p -> Some p
        | None -> current_phase
      in
      (match parse_task_line line spec_slug phase with
       | Some (id, done_, rest_text) ->
         let r = parse_task_rest rest_text in
         let t =
           { id
           ; title = r.tr_title
           ; is_done = done_
           ; parallel = r.tr_parallel
           ; story = r.tr_story
           ; points = r.tr_points
           ; rank = r.tr_rank
           ; priority = r.tr_priority
           ; status_tag = r.tr_status_tag
           ; phase
           ; spec_slug
           ; depends_on = r.tr_depends_on
           ; body = r.tr_title
           ; line = lineno
           }
         in
         walk phase (t :: acc) rest
       | None -> walk phase acc rest)
  in
  let tasks = with_inferred_deps (walk None [] parsed) in
  let edges =
    List.concat_map
      (fun t ->
         List.map
           (fun dep ->
              { edge_from = make_ref spec_slug (Some dep)
              ; edge_to = make_ref spec_slug (Some t.id)
              ; edge_kind = "depends"
              })
           t.depends_on)
      tasks
  in
  { tasks; edges }
;;

(* --- wiki links --- *)

let extract_wiki_links markdown =
  let n = String.length markdown in
  let rec scan i acc =
    if i + 4 > n
    then List.rev acc
    else if markdown.[i] = '[' && markdown.[i + 1] = '['
    then (
      match String.index_from_opt markdown (i + 2) ']' with
      | Some j when j + 1 < n && markdown.[j + 1] = ']' ->
        let inner = trim (String.sub markdown (i + 2) (j - i - 2)) in
        let r = parse_ref inner in
        let acc =
          match r.slug with
          | Some _ -> r :: acc
          | None -> acc
        in
        scan (j + 2) acc
      | _ -> scan (i + 1) acc)
    else scan (i + 1) acc
  in
  scan 0 []
;;

(* --- feature assembly --- *)

type feature_input =
  { fi_slug : string
  ; fi_spec_md : string
  ; fi_plan_md : string option
  ; fi_tasks_md : string option
  ; fi_siblings : string list
  ; fi_gate_failing : bool
  }

let derive_feature_status ~gate ~plan_md ~(tasks : task list) =
  if gate
  then Blocked
  else (
    let has_plan =
      match plan_md with
      | Some p -> String.length p > 0
      | None -> false
    in
    if not has_plan
    then Specified
    else if tasks = []
    then Planned
    else (
      let done_n = List.fold_left (fun n t -> if t.is_done then n + 1 else n) 0 tasks in
      if done_n = List.length tasks
      then Done
      else if done_n = 0
      then Planned
      else In_progress))
;;

let infer_horizon explicit status =
  match status with
  | Done -> Later
  | In_progress | Blocked ->
    (match explicit with
     | Some h -> h
     | None -> Now)
  | Specified | Planned ->
    (match explicit with
     | Some h -> h
     | None -> Next)
;;

let assemble_feature input =
  let attrs, spec_body = parse_frontmatter input.fi_spec_md in
  let title = Option.value (first_heading spec_body) ~default:input.fi_slug in
  let horizon =
    Option.bind
      (Option.map String.lowercase_ascii (attr attrs "horizon"))
      horizon_of_string
  in
  let priority =
    Option.bind
      (Option.map String.lowercase_ascii (attr attrs "priority"))
      priority_of_string
  in
  let wiki_links = extract_wiki_links input.fi_spec_md in
  let parsed_tasks =
    match input.fi_tasks_md with
    | Some md -> (parse_tasks_markdown md input.fi_slug).tasks
    | None -> []
  in
  let gate = input.fi_gate_failing || constitution_gate_failing input.fi_plan_md in
  let status =
    derive_feature_status ~gate ~plan_md:input.fi_plan_md ~tasks:parsed_tasks
  in
  let inferred_horizon = infer_horizon horizon status in
  { slug = input.fi_slug
  ; title
  ; horizon
  ; priority
  ; spec_md = spec_body
  ; spec_raw = input.fi_spec_md
  ; plan_md = input.fi_plan_md
  ; tasks_md = input.fi_tasks_md
  ; tasks = parsed_tasks
  ; constitution_gate_failing = gate
  ; siblings = input.fi_siblings
  ; wiki_links
  ; status
  ; inferred_horizon
  }
;;

(* --- checkbox edits --- *)

let set_task_checkbox markdown task_id done_ =
  let src = normalize_crlf markdown in
  let ls = lines_of src in
  let try_line line =
    let n = String.length line in
    let rec skip_ws i = if i < n && is_space line.[i] then skip_ws (i + 1) else i in
    let i = skip_ws 0 in
    if i < n && line.[i] = '-'
    then (
      let after_dash = skip_ws (i + 1) in
      if
        after_dash + 2 < n
        && line.[after_dash] = '['
        && (line.[after_dash + 1] = ' '
            || line.[after_dash + 1] = 'x'
            || line.[after_dash + 1] = 'X')
        && line.[after_dash + 2] = ']'
      then (
        let after_bracket = skip_ws (after_dash + 3) in
        if
          String.length line - after_bracket >= String.length task_id
          && String.sub line after_bracket (String.length task_id) = task_id
        then (
          let after_id = after_bracket + String.length task_id in
          let boundary_ok = after_id >= n || not (is_word_char line.[after_id]) in
          if boundary_ok then Some (after_dash + 1) else None)
        else None)
      else None)
    else None
  in
  let mark_index =
    let rec find = function
      | [] -> None
      | line :: rest ->
        (match try_line line with
         | Some idx -> Some idx
         | None -> find rest)
    in
    find ls
  in
  match mark_index with
  | None -> Error ("task " ^ task_id ^ " not found")
  | Some _ ->
    let replaced = ref false in
    let rewritten =
      List.map
        (fun line ->
           if !replaced
           then line
           else (
             match try_line line with
             | None -> line
             | Some idx ->
               let mark = if done_ then 'x' else ' ' in
               replaced := true;
               String.sub line 0 idx
               ^ String.make 1 mark
               ^ String.sub line (idx + 1) (String.length line - idx - 1)))
        ls
    in
    Ok (String.concat "\n" rewritten)
;;
