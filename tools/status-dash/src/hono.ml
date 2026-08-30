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
(* ---------- byte-exact bodies ----------

   c.html/c.text/c.json hand the runtime a JS string, and the runtime always
   encodes a string body as UTF-8 no matter what charset the header claims.
   Our strings are already UTF-8 bytes, so that encodes them twice. Handing
   over a Buffer instead puts the bytes on the wire untouched, and charset
   =utf-8 then describes them truthfully. *)

external body_bytes : ctx -> Shims.Buf.t -> int -> < .. > Js.t -> res = "body"
[@@mel.send]

(* c.body(data, status, headers) takes a bare header record; wrapping it in
   { headers } makes Hono iterate the object as a header value. *)
let send ctx mime status body =
  body_bytes ctx
    (Shims.Buf.of_bytes body)
    status
    (Shims.str_obj [ ("content-type", mime) ])

let html_mime = "text/html; charset=utf-8"
let text_mime = "text/plain; charset=utf-8"
let json_mime = "application/json; charset=utf-8"

let html_resp ctx body = send ctx html_mime 200 body
let html_status ctx body status = send ctx html_mime status body
let text_resp ctx body = send ctx text_mime 200 body
let text_status ctx body status = send ctx text_mime status body
let json_resp ctx json = send ctx json_mime 200 (Js.Json.stringify json)
let json_status ctx json status = send ctx json_mime status (Js.Json.stringify json)
let bytes_resp ctx ~mime body = send ctx mime 200 body

(* The mirror image on the way in: c.req.json() decodes the request as UTF-8
   and hands back real code points. Read the raw bytes instead so the string
   that reaches OCaml is a byte string like every other. *)
type array_buffer

external req_array_buffer : req_t -> array_buffer Js.Promise.t = "arrayBuffer"
[@@mel.send]

external buf_of_array_buffer : array_buffer -> Shims.Buf.t = "from"
[@@mel.scope "Buffer"]

external json_parse : string -> Js.Json.t = "parse" [@@mel.scope "JSON"]

let json_body req =
  Js.Promise.(
    req_array_buffer req
    |> then_ (fun ab ->
           resolve
             (json_parse (Shims.Buf.to_str (buf_of_array_buffer ab) "latin1"))))

(* query param with a default; c.req.query(name) yields string | undefined *)
let query_default ctx name default =
  match query_param (req ctx) name with
  | Some v -> v
  | None -> default

let markdown_resp ctx body = send ctx "text/markdown; charset=utf-8" 200 body

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

(* res.text() decodes the body as UTF-8, which turns a double encoding back
   into the byte string it came from and hides the bug. Read the wire bytes. *)
external res_array_buffer : res -> array_buffer Js.Promise.t = "arrayBuffer"
[@@mel.send]

let res_bytes r =
  Js.Promise.(
    res_array_buffer r
    |> then_ (fun ab ->
           resolve (Shims.Buf.to_str (buf_of_array_buffer ab) "latin1")))
