(* Reviewed notes — not constitution, not specs. *)

type kind =
  | Decision
  | Regression
  | Convention
  | Session
  | Other

type status =
  | Active
  | Superseded
  | Rejected
  | Proposal

type note =
  { path : string
  ; title : string
  ; as_of : string option
  ; supersedes : string option
  ; source : string option
  ; confidence : string option
  ; status : status
  ; kind : kind
  ; body : string
  }

let kind_to_string = function
  | Decision -> "decision"
  | Regression -> "regression"
  | Convention -> "convention"
  | Session -> "session"
  | Other -> "other"
;;

let status_to_string = function
  | Active -> "active"
  | Superseded -> "superseded"
  | Rejected -> "rejected"
  | Proposal -> "proposal"
;;

let normalize_status = function
  | Some "active" -> Active
  | Some "superseded" -> Superseded
  | Some "rejected" -> Rejected
  | Some "proposal" -> Proposal
  | _ -> Active
;;

let normalize_confidence = function
  | Some ("high" | "medium" | "low") as v -> v
  | _ -> None
;;

let basename path =
  match String.rindex_opt path '/' with
  | Some i -> String.sub path (i + 1) (String.length path - i - 1)
  | None -> path
;;

let kind_from_path path =
  if Speckit.contains path "/decisions/"
  then Decision
  else if Speckit.contains path "/regressions/"
  then Regression
  else if Speckit.contains path "/conventions/"
  then Convention
  else if Speckit.contains path "/sessions/"
  then Session
  else Other
;;

let is_session_path path = kind_from_path path = Session

(* Skip sessions by default when indexing FTS. *)
let should_index ?(include_sessions = false) path =
  if Speckit.ends_with ".gitkeep" path
  then false
  else if Speckit.ends_with "memory/README.md" path
  then false
  else if not (Speckit.ends_with ".md" path)
  then false
  else if is_session_path path && not include_sessions
  then false
  else true
;;

let excerpt ?(n = 240) body =
  let flat = Speckit.trim (String.concat " " (Speckit.lines_of body)) in
  (* collapse internal whitespace runs *)
  let b = Buffer.create (String.length flat) in
  let n_flat = String.length flat in
  for i = 0 to n_flat - 1 do
    let c = flat.[i] in
    if c = '\n' || c = '\t' || c = '\r'
    then Buffer.add_char b ' '
    else Buffer.add_char b c
  done;
  let flat = Buffer.contents b in
  if String.length flat <= n then flat else Speckit.trim (String.sub flat 0 n) ^ "…"
;;

let parse_memory_note path text =
  let attrs, body = Speckit.parse_frontmatter text in
  let a key = Speckit.attr attrs key in
  let status = normalize_status (Option.map String.lowercase_ascii (a "status")) in
  let confidence =
    normalize_confidence (Option.map String.lowercase_ascii (a "confidence"))
  in
  let title =
    match Speckit.first_heading body with
    | Some h -> h
    | None ->
      (match a "title" with
       | Some t -> t
       | None -> basename path)
  in
  { path
  ; title
  ; as_of = a "as_of"
  ; supersedes =
      (match a "supersedes" with
       | Some "" -> None
       | v -> v)
  ; source =
      (match a "source" with
       | Some "" -> None
       | v -> v)
  ; confidence
  ; status
  ; kind = kind_from_path path
  ; body
  }
;;
