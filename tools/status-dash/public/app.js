const form = document.getElementById("chat-form");
const out = document.getElementById("chat-out");
const q = document.getElementById("chat-q");

if (form && q && out) {
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const message = q.value.trim();
    if (!message) return;
    out.hidden = false;
    out.textContent = "…";
    const res = await fetch("/api/chat", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        message,
        context: { route: location.pathname },
      }),
    });
    const env = await res.json();
    out.innerHTML = renderEnvelope(env);
  });
}

for (const box of document.querySelectorAll(".task-toggle")) {
  box.addEventListener("change", async () => {
    const ref = box.getAttribute("data-ref");
    await fetch("/api/task", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ ref, done: box.checked }),
    });
    location.reload();
  });
}

function renderEnvelope(env) {
  const visuals = (env.visuals || []).map(renderVisual).join("");
  const cites = (env.citations || [])
    .map((c) => `<code>${escapeHtml(c)}</code>`)
    .join(" ");
  return `<p>${escapeHtml(env.text || "")}</p>${visuals}<p class="muted">${cites}</p>`;
}

function renderVisual(v) {
  const data = v.data || {};
  let inner = "";
  switch (v.kind) {
    case "summary":
      inner = list(
        (data.priority_queue || []).map(
          (t) => `${t.ref} — ${t.title}`,
        ),
      );
      break;
    case "roadmap":
      inner = (data.horizons || [])
        .map(
          (h) =>
            `<h3>${escapeHtml(h.name)}</h3>${list((h.specs || []).map((s) => `${s.slug} (${s.status})`))}`,
        )
        .join("");
      break;
    case "backlog":
      inner = list((data.items || []).map((t) => `${t.ref} — ${t.title}`));
      break;
    case "blocked":
      inner = list(
        (data.items || []).map((i) => `${i.card.ref || i.card.slug}: ${i.why}`),
      );
      break;
    case "spec":
      inner = `<p>${escapeHtml(data.card?.title || "")} · ${escapeHtml(data.card?.status || "")}</p>`;
      break;
    case "task":
      inner = `<p>${escapeHtml(data.card?.title || "")}</p>`;
      break;
    case "graph":
      inner = `<p>${(data.nodes || []).length} nodes, ${(data.edges || []).length} edges</p>`;
      break;
    case "memory":
      inner = list(
        (data.hits || []).map((h) => `${h.path} — ${h.title || h.excerpt || ""}`),
      );
      break;
    case "note_md":
      inner = `<pre>${escapeHtml((data.markdown || "").slice(0, 800))}</pre>`;
      break;
    default:
      inner = `<pre>${escapeHtml(JSON.stringify(data, null, 2).slice(0, 800))}</pre>`;
  }
  return `<section class="visual"><strong>${escapeHtml(v.kind)}</strong> ${escapeHtml(v.title || "")}${inner}</section>`;
}

function list(items) {
  if (!items.length) return `<p class="empty">none</p>`;
  return `<ul>${items.map((i) => `<li>${escapeHtml(i)}</li>`).join("")}</ul>`;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
