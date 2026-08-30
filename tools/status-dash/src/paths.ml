(* Project root and derived paths. *)

module P = Js_shims.Path
module F = Js_shims.Fs

type paths =
  { root : string
  ; specs : string
  ; constitution : string
  ; memory : string
  ; dash : string
  ; db : string
  ; context : string
  ; index_md : string
  ; bootstrap_md : string
  }

let resolve_project_root () =
  match Js_shims.Process.env_spec_root () with
  | r when r <> "" -> P.resolve [| r |]
  | _ ->
    let cwd = Js_shims.Process.cwd () in
    let up2 = P.resolve [| cwd; ".."; ".." |] in
    if F.exists_sync up2 && F.exists_sync (P.join2 cwd "package.json")
    then up2
    else P.resolve [| cwd |]
;;

let tool_root () =
  (* the running entry lives under <tool>/_generated/...; walk up to the
     nearest ancestor containing package.json *)
  match Js_shims.Process.argv_1 () with
  | Some script ->
      let rec up dir =
        if F.exists_sync (P.join2 dir "package.json") then dir
        else
          let parent = P.dirname dir in
          if parent = dir then dir else up parent
      in
      up (P.dirname script)
  | None -> P.resolve [| Js_shims.Process.cwd () |]
;;

let paths_for root =
  let dash = P.join2 root ".dash" in
  { root
  ; specs = P.join2 root "specs"
  ; constitution = P.join4 root ".specify" "memory" "constitution.md"
  ; memory = P.join2 root "memory"
  ; dash
  ; db = P.join2 dash "dash.sqlite"
  ; context = P.join2 dash "context"
  ; index_md = P.join3 root "specs" "INDEX.md"
  ; bootstrap_md = P.join2 dash "BOOTSTRAP.md"
  }
;;

let migrations_dir () = P.join2 (tool_root ()) "overlay/migrations"
let public_dir () = P.join2 (tool_root ()) "public"
let fixtures_dir () = P.join2 (tool_root ()) "fixtures"

let constitution_stub () =
  "# Constitution\n\n\
   Replace this stub via `/speckit.constitution`.\n\n\
   Until then: the writings in `specs/` are the work. SQLite is derived.\n\
   There is no second backlog.\n"
;;
