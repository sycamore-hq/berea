(* Spec-kit documents, not a ticket schema. Optional fields are [option]. *)

type horizon =
  | Now
  | Next
  | Later

type priority =
  | Critical
  | High
  | Medium
  | Low

type feature_status =
  | Specified
  | Planned
  | In_progress
  | Done
  | Blocked

type ref_ =
  { slug : string option
  ; task_id : string option
  }

type task =
  { id : string
  ; title : string
  ; is_done : bool
  ; parallel : bool
  ; story : string option
  ; points : int option
  ; rank : int option
  ; priority : priority option
  ; status_tag : string option
  ; phase : string option
  ; spec_slug : string
  ; depends_on : string list
  ; body : string
  ; line : int
  }

type edge =
  { edge_from : string
  ; edge_to : string
  ; edge_kind : string
  }

type feature =
  { slug : string
  ; title : string
  ; horizon : horizon option
  ; priority : priority option
  ; spec_md : string
  ; spec_raw : string
  ; plan_md : string option
  ; tasks_md : string option
  ; tasks : task list
  ; constitution_gate_failing : bool
  ; siblings : string list
  ; wiki_links : ref_ list
  ; status : feature_status
  ; inferred_horizon : horizon
  }

type spec_card =
  { slug : string
  ; title : string
  ; horizon : horizon
  ; priority : priority option
  ; status : feature_status
  ; open_tasks : int
  ; total_tasks : int
  }

type task_card =
  { card_ref : string
  ; card_title : string
  ; card_done : bool
  ; card_spec_slug : string
  ; card_priority : priority option
  }

type card =
  | Spec_card of spec_card
  | Task_card of task_card

type blocked_item =
  { card : card
  ; why : string
  ; kind : string
  }

type graph_node =
  { node_id : string
  ; node_kind : string
  ; node_title : string
  ; node_status : string
  }

type graph_edge =
  { g_edge_from : string
  ; g_edge_to : string
  ; g_edge_kind : string
  }

type graph =
  { nodes : graph_node list
  ; edges : graph_edge list
  }

let horizon_to_string = function
  | Now -> "now"
  | Next -> "next"
  | Later -> "later"
;;

let horizon_of_string = function
  | "now" -> Some Now
  | "next" -> Some Next
  | "later" -> Some Later
  | _ -> None
;;

let priority_to_string = function
  | Critical -> "critical"
  | High -> "high"
  | Medium -> "medium"
  | Low -> "low"
;;

let priority_of_string = function
  | "critical" -> Some Critical
  | "high" -> Some High
  | "medium" -> Some Medium
  | "low" -> Some Low
  | _ -> None
;;

let status_to_string = function
  | Specified -> "specified"
  | Planned -> "planned"
  | In_progress -> "in-progress"
  | Done -> "done"
  | Blocked -> "blocked"
;;

let make_ref slug task_id =
  match task_id with
  | None -> slug
  | Some id -> slug ^ "#" ^ id
;;

let parse_ref ref_ =
  let n = String.length ref_ in
  let rec start i = if i < n && ref_.[i] = '/' then start (i + 1) else i in
  let rec stop i = if i >= 0 && ref_.[i] = '/' then stop (i - 1) else i in
  let a = start 0
  and b = stop (n - 1) in
  if a > b
  then { slug = None; task_id = None }
  else (
    let trimmed = String.sub ref_ a (b - a + 1) in
    match String.index_opt trimmed '#' with
    | None -> { slug = Some trimmed; task_id = None }
    | Some i ->
      let slug = String.sub trimmed 0 i in
      let rest = String.sub trimmed (i + 1) (String.length trimmed - i - 1) in
      (match rest with
       | "" -> { slug = Some slug; task_id = None }
       | id -> { slug = Some slug; task_id = Some id }))
;;

let is_digit c = c >= '0' && c <= '9'

let is_word_char c =
  is_digit c || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_'
;;

let is_slug_char c = is_word_char c || c = '-'

let is_feature_slug name =
  let n = String.length name in
  n >= 5
  && is_digit name.[0]
  && is_digit name.[1]
  && is_digit name.[2]
  && name.[3] = '-'
  &&
  let c = name.[4] in
  (is_digit c || (c >= 'a' && c <= 'z'))
  &&
  let rec ok i = i >= n || (is_slug_char name.[i] && ok (i + 1)) in
  ok 5
;;

let spec_card f =
  let open_ = List.fold_left (fun n t -> if t.is_done then n else n + 1) 0 f.tasks in
  { slug = f.slug
  ; title = f.title
  ; horizon = f.inferred_horizon
  ; priority = f.priority
  ; status = f.status
  ; open_tasks = open_
  ; total_tasks = List.length f.tasks
  }
;;

let task_card t =
  { card_ref = make_ref t.spec_slug (Some t.id)
  ; card_title = t.title
  ; card_done = t.is_done
  ; card_spec_slug = t.spec_slug
  ; card_priority = t.priority
  }
;;
