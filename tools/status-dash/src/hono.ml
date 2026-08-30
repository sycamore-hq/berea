(* Minimal Hono bindings (hono on bun) + Bun.serve. *)

module Shims = Js_shims

type hono
type res
type req_t
type ctx

external make_hono : unit -> hono = "Hono" [@@mel.new] [@@mel.module "hono"]
external on_get : hono -> string -> (ctx -> res) -> unit = "get" [@@mel.send]

external on_post : hono -> string -> (ctx -> res Js.Promise.t) -> unit = "post"
[@@mel.send]

external hono_fetch : hono -> req_t -> res Js.Promise.t = "fetch" [@@mel.send]
external req : ctx -> req_t = "req" [@@mel.get]
external param_raw : req_t -> string -> string = "param" [@@mel.send]

let param ctx name = param_raw (req ctx) name
external query_param : req_t -> string -> string option = "query" [@@mel.send]
[@@mel.return undefined_to_opt]
external json_body : req_t -> Js.Json.t Js.Promise.t = "json" [@@mel.send]
external json_resp : ctx -> Js.Json.t -> res = "json" [@@mel.send]
external json_status : ctx -> Js.Json.t -> int -> res = "json" [@@mel.send]
external html_resp : ctx -> string -> res = "html" [@@mel.send]
external text_resp : ctx -> string -> res = "text" [@@mel.send]
external text_status : ctx -> string -> int -> res = "text" [@@mel.send]

external html_status : ctx -> string -> int -> res = "html" [@@mel.send]

external header : ctx -> string -> string -> unit = "header" [@@mel.send]

external body_resp : ctx -> string -> res = "body" [@@mel.send]

(* query param with a default; c.req.query(name) yields string | undefined *)
let query_default ctx name default =
  match query_param (req ctx) name with
  | Some v -> v
  | None -> default

(* c.text(body, status, { headers: { "content-type": ... } }) *)
external text_headers : ctx -> string -> int -> < .. > Js.t -> res = "text" [@@mel.send]

let markdown_resp ctx body =
  let headers = Shims.str_obj [ ("content-type", "text/markdown; charset=utf-8") ] in
  text_headers ctx body 200 (Shims.unsafe_obj [ ("headers", Obj.magic headers) ])

(* app.request(path, init) — used by the check suite *)
external request : hono -> string -> < .. > Js.t -> res = "request" [@@mel.send]

external promise_resolve : res -> res Js.Promise.t = "resolve" [@@mel.scope "Promise"]

(* app.request yields Response for sync handlers and a Promise for async
   ones; Promise.resolve flattens both *)
let request_get_p app path =
  let init = Js.Obj.empty () in
  promise_resolve (request app path init)

let request_post_p app path body =
  let headers = Shims.str_obj [ ("content-type", "application/json") ] in
  let init = Js.Obj.empty () in
  Shims.set_dyn init "method" "POST";
  Shims.set_dyn init "headers" headers;
  Shims.set_dyn init "body" body;
  promise_resolve (request app path init)

(* Bun.serve *)
external serve : < .. > Js.t -> unit = "serve" [@@mel.scope "Bun"]

(* response body accessors — used by the check suite *)
external res_text : res -> string Js.Promise.t = "text" [@@mel.send]

external res_json : res -> Js.Json.t Js.Promise.t = "json" [@@mel.send]
