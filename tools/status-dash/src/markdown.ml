(* Small markdown renderer. Wiki links resolve against /specs/. *)

let esc s =
  let b = Buffer.create (String.length s) in
  String.iter
    (fun c ->
      match c with
      | '&' -> Buffer.add_string b "&amp;"
      | '<' -> Buffer.add_string b "&lt;"
      | '>' -> Buffer.add_string b "&gt;"
      | '"' -> Buffer.add_string b "&quot;"
      | '\'' -> Buffer.add_string b "&#39;"
      | c -> Buffer.add_char b c)
    s;
  Buffer.contents b

let esc_attr = esc

let wiki ref_ =
  match String.index_opt ref_ '#' with
  | None ->
      Printf.sprintf "<a class=\"wiki\" href=\"/specs/%s\">%s</a>" (esc_attr ref_) (esc ref_)
  | Some i ->
      let slug = String.sub ref_ 0 i in
      let task = String.sub ref_ (i + 1) (String.length ref_ - i - 1) in
      Printf.sprintf "<a class=\"wiki\" href=\"/specs/%s#%s\">%s</a>" (esc_attr slug)
        (esc_attr task) (esc ref_)

(* --- inline formatting (applied to already-escaped text) --- *)

let replace_wiki s =
  let b = Buffer.create (String.length s) in
  let n = String.length s in
  let rec go i =
    if i >= n then ()
    else if i + 2 <= n && s.[i] = '[' && s.[i + 1] = '[' then (
      match Speckit.find_from s (i + 2) "]]" with
      | Some j ->
          let inner = Speckit.trim (String.sub s (i + 2) (j - i - 2)) in
          Buffer.add_string b (wiki inner);
          go (j + 2)
      | None ->
          Buffer.add_char b s.[i];
          go (i + 1))
    else (
      Buffer.add_char b s.[i];
      go (i + 1))
  in
  go 0;
  Buffer.contents b

let replace_between open_ close_ wrap s =
  (* replace `open_ x close` (x non-empty, no close char inside) with wrap x *)
  let b = Buffer.create (String.length s) in
  let n = String.length s in
  let m = String.length open_ in
  let rec go i =
    if i >= n then ()
    else if i + m <= n && String.sub s i m = open_ then (
      let close_at = ref (-1) in
      let j = ref (i + m) in
      while !j < n && !close_at = -1 do
        if String.length s - !j >= String.length close_
           && String.sub s !j (String.length close_) = close_
        then close_at := !j
        else incr j
      done;
      if !close_at > i + m then (
        let inner = String.sub s (i + m) (!close_at - i - m) in
        Buffer.add_string b (wrap inner);
        go (!close_at + String.length close_))
      else (
        Buffer.add_char b s.[i];
        go (i + 1)))
    else (
      Buffer.add_char b s.[i];
      go (i + 1))
  in
  go 0;
  Buffer.contents b

let replace_md_links s =
  let b = Buffer.create (String.length s) in
  let n = String.length s in
  let rec find_close j =
    if j >= n then -1
    else if s.[j] = ']' then j
    else if s.[j] = '[' then -1
    else find_close (j + 1)
  in
  let rec find_paren_end j =
    if j >= n then -1 else if s.[j] = ')' then j else find_paren_end (j + 1)
  in
  let rec go i =
    if i >= n then ()
    else if s.[i] = '[' then
      let c = find_close (i + 1) in
      if c > i + 1 && c + 1 < n && s.[c + 1] = '(' then
        let pe = find_paren_end (c + 2) in
        if pe > c + 2 then (
          let text = String.sub s (i + 1) (c - i - 1) in
          let href = String.sub s (c + 2) (pe - c - 2) in
          Buffer.add_string b (Printf.sprintf "<a href=\"%s\">%s</a>" href text);
          go (pe + 1))
        else (
          Buffer.add_char b s.[i];
          go (i + 1))
      else (
        Buffer.add_char b s.[i];
        go (i + 1))
    else (
      Buffer.add_char b s.[i];
      go (i + 1))
  in
  go 0;
  Buffer.contents b;;

let inline s =
  s |> esc
  |> replace_wiki
  |> replace_between "`" "`" (fun x -> "<code>" ^ x ^ "</code>")
  |> replace_between "**" "**" (fun x -> "<strong>" ^ x ^ "</strong>")
  |> replace_md_links

(* --- block-level --- *)

let is_blank line = Speckit.trim line = ""

let is_hr line =
  let t = Speckit.trim line in
  let n = String.length t in
  n >= 3
  &&
  let rec dashes i = i >= n || (t.[i] = '-' && dashes (i + 1)) in
  dashes 0

let is_table_line line =
  let t = Speckit.trim line in
  String.length t >= 2 && t.[0] = '|' && t.[String.length t - 1] = '|'
  && Speckit.contains t "|"

let is_list_line line =
  let t = Speckit.trim line in
  Speckit.starts_with "- " t

let is_task_list_line line =
  let t = Speckit.trim line in
  Speckit.starts_with "- [" t
  && String.length t >= 6
  && (t.[3] = ' ' || t.[3] = 'x' || t.[3] = 'X')
  && t.[4] = ']'

let is_break line =
  Speckit.starts_with "#" line
  || is_list_line line
  || is_task_list_line line
  || is_hr line
  || (let t = Speckit.trim line in String.length t > 0 && t.[0] = '|')

let is_comment_start line = Speckit.starts_with "<!--" (Speckit.trim line)

(* table: returns (html, next_index) *)
let table ls start =
  let rec collect i rows =
    if i < List.length ls && is_table_line (List.nth ls i) then
      let raw = Speckit.trim (List.nth ls i) in
      let inner = String.sub raw 1 (String.length raw - 2) in
      let cells =
        String.split_on_char '|' inner |> List.map Speckit.trim
      in
      let is_sep =
        List.for_all
          (fun c ->
            let n = String.length c in
            n >= 1
            &&
            let rec colons j =
              j >= n
              || ((c.[j] = '-' || c.[j] = ':') && colons (j + 1))
            in
            colons 0)
          cells
      in
      collect (i + 1) (if is_sep then rows else rows @ [ cells ])
    else (rows, i)
  in
  let rows, next = collect start [] in
  match rows with
  | [] -> ("", next)
  | head :: body ->
      let tr tag cells =
        "<tr>"
        ^ String.concat ""
            (List.map (fun c -> Printf.sprintf "<%s>%s</%s>" tag (inline c) tag) cells)
        ^ "</tr>"
      in
      let html =
        "<table>" ^ tr "th" head
        ^ String.concat "" (List.map (tr "td") body)
        ^ "</table>"
      in
      (html, next)

(* list: returns (html, next_index) *)
let list ls start =
  let rec collect i items =
    if i >= List.length ls then (items, i)
    else
      let line = List.nth ls i in
      if is_task_list_line line then
        let t = Speckit.trim line in
        let mark = t.[3] in
        let rest = String.sub t 6 (String.length t - 6) in
        collect (i + 1)
          (items
           @ [ Printf.sprintf "<li class=\"task\"><input type=\"checkbox\" disabled %s> %s</li>"
                 (if mark <> ' ' then "checked" else "")
                 (inline rest) ])
      else if is_list_line line then
        let t = Speckit.trim line in
        let rest = String.sub t 2 (String.length t - 2) in
        collect (i + 1) (items @ [ "<li>" ^ inline rest ^ "</li>" ])
      else (items, i)
  in
  let items, next = collect start [] in
  ("<ul>" ^ String.concat "" items ^ "</ul>", next)

let block src =
  let ls = Speckit.lines_of src in
  let len = List.length ls in
  let b = Buffer.create 1024 in
  let nth i = List.nth ls i in
  let out html = Buffer.add_string b (html ^ "\n") in
  let rec go i =
    if i >= len then ()
    else
      let line = nth i in
      if Speckit.starts_with "### " line then (
        out ("<h3>" ^ inline (String.sub line 4 (String.length line - 4)) ^ "</h3>");
        go (i + 1))
      else if Speckit.starts_with "## " line then (
        out ("<h2>" ^ inline (String.sub line 3 (String.length line - 3)) ^ "</h2>");
        go (i + 1))
      else if Speckit.starts_with "# " line then (
        out ("<h1>" ^ inline (String.sub line 2 (String.length line - 2)) ^ "</h1>");
        go (i + 1))
      else if is_hr line then (
        out "<hr>";
        go (i + 1))
      else if is_table_line line then
        let html, next = table ls i in
        out html;
        go next
      else if is_task_list_line line || is_list_line line then
        let html, next = list ls i in
        out html;
        go next
      else if is_blank line then go (i + 1)
      else (
        (* paragraph: consume until blank or break *)
        let para = ref [] in
        let j = ref i in
        while !j < len && not (is_blank (nth !j)) && not (is_break (nth !j)) do
          para := nth !j :: !para;
          incr j
        done;
        out ("<p>" ^ inline (String.concat " " (List.rev !para)) ^ "</p>");
        go !j)
  in
  go 0;
  Buffer.contents b

(* strip HTML comments <!-- ... --> (non-greedy) *)
let strip_comments s =
  let b = Buffer.create (String.length s) in
  let n = String.length s in
  let rec go i =
    if i >= n then ()
    else if i + 4 <= n && String.sub s i 4 = "<!--" then (
      match Speckit.find_from s (i + 4) "-->" with
      | Some j -> go (j + 3)
      | None ->
          Buffer.add_string b (String.sub s i (n - i)))
    else (
      Buffer.add_char b s.[i];
      go (i + 1))
  in
  go 0;
  Buffer.contents b

(* split into fenced and non-fenced parts *)
let split_fences s =
  let n = String.length s in
  let rec go i acc =
    if i >= n then List.rev acc
    else
      match Speckit.find_from s i "```" with
      | None -> List.rev (String.sub s i (n - i) :: acc)
      | Some j ->
          match Speckit.find_from s (j + 3) "```" with
          | None ->
              (* unterminated fence: literal text *)
              List.rev (String.sub s i (n - i) :: acc)
          | Some k ->
              let before = if j > i then [ String.sub s i (j - i) ] else [] in
              go (k + 3) (List.rev_append before (String.sub s j (k + 3 - j) :: acc))
  in
  go 0 []

let fence part =
  (* part: ```lang\ncontent``` *)
  let n = String.length part in
  if n < 6 || not (Speckit.starts_with "```" part) then
    "<pre><code>" ^ esc part ^ "</code></pre>"
  else
    let rest = String.sub part 3 (n - 3) in
    let content =
      match String.index_opt rest '\n' with
      | Some i -> String.sub rest (i + 1) (String.length rest - i - 1)
      | None -> rest
    in
    let content =
      if Speckit.ends_with "```" content then
        String.sub content 0 (String.length content - 3)
      else content
    in
    "<pre><code>" ^ esc content ^ "</code></pre>"

let render_markdown src =
  let text = Speckit.normalize_crlf (strip_comments src) in
  split_fences text
  |> List.map (fun part ->
         if Speckit.starts_with "```" part then fence part else block part)
  |> String.concat ""
