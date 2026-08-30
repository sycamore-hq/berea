(* Server-rendered HTML. Works with JS off for spec and constitution pages. *)

open Domain

let esc = Markdown.esc

let nav_items =
  [ ("/", "Overview");
    ("/roadmap", "Roadmap");
    ("/backlog", "Backlog");
    ("/specs", "Specs");
    ("/constitution", "Constitution");
    ("/graph", "Graph");
    ("/memory", "Memory") ]

let page ~title ~path ~banners ~body =
  let banners =
    List.map (fun b -> "<div class=\"banner\">" ^ b ^ "</div>") banners
    |> String.concat ""
  in
  let nav =
    List.map
      (fun (href, label) ->
        let on = path = href || (href <> "/" && Speckit.starts_with href path) in
        Printf.sprintf "<a href=\"%s\"%s>%s</a>" href
          (if on then " aria-current=\"page\"" else "")
          label)
      nav_items
    |> String.concat ""
  in
  Printf.sprintf
    {|<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%s · Berea</title>
<link rel="stylesheet" href="/static/app.css">
<body>
  <a class="skip" href="#main">Skip to writings</a>
  <header class="mast">
    <p class="mark">Berea</p>
    <p class="verse">They received the word with all readiness of mind, and searched the scriptures daily, whether those things were so.</p>
  </header>
  <div class="shell">
    <nav class="rail">%s</nav>
    <main id="main">
      %s
      %s
    </main>
    <aside class="ask" aria-label="Ask the writings">
      <h2>Ask</h2>
      <form id="chat-form">
        <label class="sr" for="chat-q">Question</label>
        <textarea id="chat-q" name="message" rows="3" placeholder="what should we work on?"></textarea>
        <button type="submit">Ask</button>
      </form>
      <div id="chat-out" class="chat-out" hidden></div>
    </aside>
  </div>
  <script src="/static/app.js" type="module"></script>
</body>
</html>|}
    (esc title) nav banners body

let status_pill status =
  Printf.sprintf "<span class=\"pill %s\">%s</span>" (esc status) (esc status)

let feature_table (cards : spec_card list) empty =
  if cards = [] then "<p class=\"empty\">" ^ esc empty ^ "</p>"
  else
    let rows =
      List.map
        (fun c ->
          Printf.sprintf
            "<tr>\n<td><a href=\"/specs/%s\">%s</a></td>\n<td>%s</td>\n<td>%s</td>\n<td>%s</td>\n<td>%d/%d</td>\n</tr>"
            (esc c.slug) (esc c.slug) (esc c.title)
            (status_pill (status_to_string c.status))
            (match c.horizon with Some h -> esc (horizon_to_string h) | None -> "—")
            c.open_tasks c.total_tasks)
        cards
      |> String.concat ""
    in
    "<table>\n<thead><tr><th>ID</th><th>Title</th><th>Status</th><th>Horizon</th><th>Tasks</th></tr></thead>\n<tbody>"
    ^ rows
    ^ "</tbody>\n</table>"

type task_row = { tr_ref : string; tr_title : string; tr_done : bool; tr_spec : string }

let task_table ?(interactive = false) (items : task_row list) =
  if items = [] then "<p class=\"empty\">No open tasks.</p>"
  else
    let rows =
      List.map
        (fun t ->
          let box =
            if interactive then
              Printf.sprintf
                "<input type=\"checkbox\" class=\"task-toggle\" data-ref=\"%s\"%s>"
                (esc t.tr_ref)
                (if t.tr_done then " checked" else "")
            else if t.tr_done then "☑"
            else "☐"
          in
          let anchor =
            match String.index_opt t.tr_ref '#' with
            | Some i -> String.sub t.tr_ref (i + 1) (String.length t.tr_ref - i - 1)
            | None -> t.tr_ref
          in
          Printf.sprintf
            "<tr id=\"%s\">\n<td>%s</td>\n<td><code>%s</code></td>\n<td>%s</td>\n<td><a href=\"/specs/%s\">%s</a></td>\n</tr>"
            (esc anchor) box (esc t.tr_ref) (esc t.tr_title) (esc t.tr_spec)
            (esc t.tr_spec))
        items
      |> String.concat ""
    in
    "<table>\n<thead><tr><th></th><th>Ref</th><th>Title</th><th>Spec</th></tr></thead>\n<tbody>"
    ^ rows
    ^ "</tbody>\n</table>"

let md_article md = "<article class=\"prose\">" ^ Markdown.render_markdown md ^ "</article>"

let dl rows =
  let items =
    List.map
      (fun (k, v) -> "<div><dt>" ^ k ^ "</dt><dd>" ^ v ^ "</dd></div>")
      rows
    |> String.concat ""
  in
  "<dl class=\"facts\">" ^ items ^ "</dl>"
