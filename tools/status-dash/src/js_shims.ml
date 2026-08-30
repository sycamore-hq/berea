(* Thin bindings to node:fs, node:path, node:os, node:child_process,
   process, Date, console. Runs under Bun. *)

(* Melange compiles an OCaml string literal to a JS string with one code
   unit per byte: "\xe2\x80\x94" for "\u{2014}". Every boundary that leaves the
   program must hand those bytes over as bytes. Encode them as UTF-8 text
   instead and each byte is encoded a second time, which is how an em dash
   becomes "\u{c3}\u{a2}\u{c2}\u{80}\u{c2}\u{94}". *)
module Buf = struct
  type t

  external from : string -> string -> t = "from" [@@mel.scope "Buffer"]
  external to_str : t -> string -> string = "toString" [@@mel.send]

  (* byte string -> Buffer holding exactly those bytes *)
  let of_bytes s = from s "latin1"

  (* byte string -> JS text, for sinks that encode as UTF-8 themselves *)
  let to_text s = to_str (of_bytes s) "utf8"
end

module Str = struct
  external starts_with : string -> string -> bool = "startsWith" [@@mel.send]
  external ends_with : string -> string -> bool = "endsWith" [@@mel.send]
  external includes_ : string -> string -> bool = "includes" [@@mel.send]
  external slice2 : string -> int -> int -> string = "slice" [@@mel.send]
  external slice_from : string -> int -> string = "slice" [@@mel.send]
  external index_of : string -> string -> int = "indexOf" [@@mel.send]
  external last_index_of : string -> string -> int = "lastIndexOf" [@@mel.send]
  external lower : string -> string = "toLowerCase" [@@mel.send]
  external upper : string -> string = "toUpperCase" [@@mel.send]
  external trim : string -> string = "trim" [@@mel.send]
  external replace_all : string -> string -> string -> string = "replaceAll" [@@mel.send]
  external char_at : string -> int -> string = "charAt" [@@mel.send]
  external length : string -> int = "length" [@@mel.get]
end

module A = struct
  type 'a t = 'a array

  external length : 'a array -> int = "length" [@@mel.get]
  external get : 'a array -> int -> 'a = "" [@@mel.get_index]
  external map : 'a array -> ('a -> 'b) -> 'b array = "map" [@@mel.send]
  external filter : 'a array -> ('a -> bool) -> 'a array = "filter" [@@mel.send]
  external find : 'a array -> ('a -> bool) -> 'a option = "find" [@@mel.send]
  [@@mel.return undefined_to_opt]
  external join : 'a array -> string -> string = "join" [@@mel.send]
  external for_each : 'a array -> ('a -> unit) -> unit = "forEach" [@@mel.send]
  external flat_map : 'a array -> ('a -> 'b array) -> 'b array = "flatMap" [@@mel.send]
  let of_list l = Array.of_list l

  let to_list a = Array.to_list a
end

(* build a plain JS object from key/value pairs *)
(* dynamic property access on plain JS objects *)
external set_dyn : < .. > Js.t -> string -> 'a -> unit = "" [@@mel.set_index]

external get_dyn : < .. > Js.t -> string -> 'a = "" [@@mel.get_index]

(* build a plain JS object from key/value pairs *)
let str_obj (kvs : (string * string) list) =
  let o = Js.Obj.empty () in
  List.iter (fun (k, v) -> set_dyn o k v) kvs;
  o

let unsafe_obj (kvs : (string * Obj.t) list) =
  let o = Js.Obj.empty () in
  List.iter (fun (k, v) -> set_dyn o k v) kvs;
  o;;

module Date = struct
  type t

  external now : unit -> float = "now" [@@mel.scope "Date"]
  external make : float -> t = "Date" [@@mel.new]
  external to_iso : t -> string = "toISOString" [@@mel.send]

  let now_iso () = to_iso (make (now ()))
end

module Process = struct
  external env_obj : < .. > Js.t = "env" [@@mel.scope "process"]

  external env_get : < .. > Js.t -> string -> string option = ""
  [@@mel.get_index] [@@mel.return undefined_to_opt]

  external argv_arr : string array = "argv" [@@mel.scope "process"]

  external chdir : string -> unit = "chdir" [@@mel.scope "process"]

  external exit : int -> 'a = "exit" [@@mel.scope "process"]

  external cwd : unit -> string = "cwd" [@@mel.scope "process"]

  let env_port () = Option.value (env_get env_obj "PORT") ~default:""

  let env_spec_root () = Option.value (env_get env_obj "SPEC_ROOT") ~default:""

  let argv_1 () =
    if A.length argv_arr > 1 then Some (A.get argv_arr 1) else None
end

external exn_message : 'a -> string option = "message" [@@mel.get]

module Console = struct
  external log_raw : string -> unit = "log" [@@mel.scope "console"]
  external warn_raw : string -> unit = "warn" [@@mel.scope "console"]
  external error_raw : string -> unit = "error" [@@mel.scope "console"]

  let log s = log_raw (Buf.to_text s)
  let warn s = warn_raw (Buf.to_text s)
  let error s = error_raw (Buf.to_text s)
end

module Crypto = struct
  external random_uuid : unit -> string = "randomUUID" [@@mel.scope "crypto"]
end

module Child_process = struct
  external exec_sync : string -> unit = "execSync" [@@mel.module "node:child_process"]
end

module Fs = struct
  external exists_sync : string -> bool = "existsSync" [@@mel.module "node:fs"]
  external read_file_sync_raw : string -> string -> string = "readFileSync"
  [@@mel.module "node:fs"]

  external write_file_sync_raw : string -> string -> string -> unit = "writeFileSync"
  [@@mel.module "node:fs"]

  (* latin1 is the byte-exact codec: one JS code unit per byte, in and out.
     It also makes String.length and String.sub count bytes, which is what
     every parser in speckit.ml already assumes.

     read_file_bytes names that explicitly, so a test can read a file through
     a lens that cannot hide a double encoding the way a matching pair of
     utf8 read and utf8 write does. *)
  let read_file_bytes path = read_file_sync_raw path "latin1"

  let read_file_sync path = read_file_bytes path

  let write_file_sync path contents = write_file_sync_raw path contents "latin1"

  external readdir_sync : string -> string array = "readdirSync" [@@mel.module "node:fs"]

  type stat_t

  external stat_sync : string -> stat_t = "statSync" [@@mel.module "node:fs"]

  external stat_mtime : stat_t -> float = "mtimeMs" [@@mel.get]

  external stat_is_dir : stat_t -> unit -> bool = "isDirectory" [@@mel.send]
  external mkdir_sync : string -> < .. > Js.t -> unit = "mkdirSync" [@@mel.module "node:fs"]

  let recursive = Js.Json.boolean true
  let mkdir_p dir =
    let opts = Js.Obj.empty () in
    set_dyn opts "recursive" true;
    mkdir_sync dir opts
  let mtime_ms path = stat_mtime (stat_sync path)

  let is_dir path = stat_is_dir (stat_sync path) ()
end

module Path = struct
  external join : string array -> string = "join"
  [@@mel.module "node:path"] [@@mel.variadic]

  external resolve : string array -> string = "resolve"
  [@@mel.module "node:path"] [@@mel.variadic]

  external dirname : string -> string = "dirname" [@@mel.module "node:path"]
  external basename : string -> string = "basename" [@@mel.module "node:path"]
  external relative : string -> string -> string = "relative" [@@mel.module "node:path"]
  external sep : string = "sep" [@@mel.module "node:path"]

  let join2 a b = join [| a; b |]
  let join3 a b c = join [| a; b; c |]
  let join4 a b c d = join [| a; b; c; d |]
end

module Os = struct
  external tmpdir : unit -> string = "tmpdir" [@@mel.module "node:os"]
end
