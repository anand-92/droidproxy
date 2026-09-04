---
name: gpt-image
version: 1.0.0
description: |
  Generate or edit images via GPT Image 2 (gpt-image-2) through DroidProxy
  Codex OAuth (no OPENAI_API_KEY). Use when the user asks to generate,
  create, draw, or edit an image with GPT, OpenAI, Codex, gpt-image, or
  DALL-E — including transparent PNGs, stickers, cutouts, and campaign
  assets — and DroidProxy Codex OAuth is available. Prefer this over
  inventing image URLs or base64. If they name Grok or Imagine, use
  grok-imagine instead.
---

# GPT Image 2 (via DroidProxy Codex)

Generate and edit images with **`gpt-image-2`** using the ChatGPT / Codex
OAuth session that powers DroidProxy GPT chat. This is the current GPT Image
model (text or image → image). Always send `gpt-image-2`. Do not send older
image ids (`gpt-image-1.5`, `gpt-image-1`, `dall-e-2`, `dall-e-3`) or any
`gpt-5.*` chat id to these endpoints.

Two things you can't guess and that everything else depends on:

- The endpoint is **`http://localhost:8317`**, not `api.openai.com`. ThinkingProxy
  forwards `/v1/images/*` to CLIProxyAPI, which injects the Codex bearer and
  calls OpenAI's Images API. Chat models on `:8317` do **not** generate images.
- Auth is **`Authorization: Bearer dummy-not-used`**. The real token comes from
  the proxy. Never ask for or use an `OPENAI_API_KEY`.

Use for generating or editing visual assets. Not for understanding an image the
user already attached — that's chat multimodal, not this skill.

This is not Grok Imagine. Do not send `aspect_ratio`, `resolution`, or a
`grok-imagine-*` model here.

## Prompting

If the user gives a detailed prompt or asks you to use theirs, use it verbatim.
Otherwise craft 2–5 sentences of natural prose:

**subject → action/pose → setting → style → composition → lighting/mood → key details**

- Front-load the subject. Give strong high-level direction for mood,
  composition, lighting, and style without specifying every pixel.
- State what to include, not what to exclude.
- One coherent scene per prompt. Match `size` to the use case:
  icons `1024x1024`, banners `1536x1024`, stories `1024x1536`.
- For **edits**, describe only what changes and what must stay the same.
- Ground real people, brands, places, and “current/latest” facts with a web
  search first and put the verified details in the prompt. For a named real
  person, edit from a real reference photo — do not generate the likeness from
  text alone.

## Generate

Requests often take 30–70s. Use `--max-time 180`.

```bash
RESP=$(curl -sS --max-time 180 http://localhost:8317/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "A red balloon on a wooden table, soft natural light" \
    '{model:"gpt-image-2", prompt:$p, size:"1024x1024", quality:"low",
      response_format:"b64_json"}')")

if B64=$(printf '%s' "$RESP" | jq -er '.data[0].b64_json' 2>/dev/null); then
  printf '%s' "$B64" | base64 -d > out.png
else
  printf '%s\n' "$RESP" >&2
  exit 1
fi
```

Two things that bite here:

- **Check `.data[0].b64_json` before decoding.** On failure there is no b64
  field, and piping the error body through `base64 -d` writes a corrupt file
  that passes an `ls` check and only reveals itself when someone opens it.
- **Print the raw body on failure.** Codex errors are JSON
  (`usage_limit_reached`, `auth_not_found`, `moderation_blocked`) — the raw
  text is specific and worth reading.

Default `quality` to **`low`**. Raise quality only when the user asks.

## Edit

`POST /v1/images/edits`, same auth and routing. JSON with a data URL — no
upload step, no `file_id`.

```bash
SRC="data:image/png;base64,$(base64 -i ./photo.png)"
curl -sS --max-time 180 http://localhost:8317/v1/images/edits \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "Make it blue-tinted studio lighting" --arg u "$SRC" \
    '{model:"gpt-image-2", prompt:$p, images:[{image_url:$u}],
      response_format:"b64_json"}')"
```

Pick the data-URL mime from the source file (`image/jpeg`, `image/png`,
`image/webp`). Chain edits by feeding each output back as the next
`images[0].image_url`.

Optional `mask.image_url` (PNG with alpha) marks the region to replace. Omit
it for a full-image restyle.

## Parameters

Source of truth for field names: [Image generation](https://developers.openai.com/api/docs/guides/image-generation)
and the [Images API](https://developers.openai.com/api/docs/api-reference/images).
Routing and model ids are DroidProxy / CLIProxyAPI, not `api.openai.com`.

| Field | Values | Notes |
|---|---|---|
| `model` | `gpt-image-2` | Always send this id. Chat ids (`gpt-5.4`, `gpt-5.6-terra`, …) return 400. |
| `prompt` | string | See Prompting. Required on generate and edit. |
| `size` | `1024x1024`, `1024x1536`, `1536x1024` | Square / portrait / landscape. Stick to these three. |
| `quality` | `low`, `medium`, `high` | Default **`low`** on this skill. Do not send `hd`, `standard`, or `auto`. |
| `response_format` | `b64_json`, `url` | CLIProxyAPI defaults to `b64_json`. Always send `b64_json` when saving to disk. |
| `n` | integer | Default 1. Same-prompt variations belong in one request via `n`, not parallel calls. |
| `background` | `auto`, `opaque`, `transparent` | `transparent` needs `output_format` `png` or `webp`. |
| `output_format` | `png`, `jpeg`, `webp` | Omit unless you need transparency (`png`) or a smaller file (`jpeg`/`webp`). |
| `output_compression` | 0–100 | JPEG/WebP only. Omit unless the user asks. |
| `images` | `[{image_url}]` | Edits only. Data URL or https URL. |
| `mask` | `{image_url}` | Edits only. PNG with alpha; transparent pixels are the edit region. |

Grok-only fields (`aspect_ratio`, `resolution`, `image: {url, type:"image_url"}`)
do not belong here. Don't send them.

## Response

```json
{"created": 1713833628, "data": [{"b64_json": "...", "revised_prompt": "..."}],
 "size": "1024x1024", "quality": "low", "output_format": "png"}
```

Pick the file extension from `output_format` when present, otherwise from the
decoded magic bytes (`PNG` / `JFIF` / `RIFF…WEBP`), not from the filename the
user asked for. If that contradicts the name they gave, save the correct
extension and say why.

`url` responses from this proxy may be data URLs, not durable https links —
still prefer `b64_json` and write a file.

## Transparency

Unlike Grok Imagine, GPT Image can emit a real alpha channel. **Only when the
user asks for a transparent image** (PNG with alpha, sticker, cutout, icon on
any background, campaign/presentation asset, print-on-demand design), fetch
[Transparent image assets](https://developers.openai.com/cookbook/examples/multimodal/transparent-image-assets-for-campaigns-and-presentations)
and follow its prompting and parameter patterns for this request. Do not load
it otherwise.

Always send both fields — `background` alone is not enough:

```json
{"background":"transparent","output_format":"png"}
```

The prompt beats the API field. If it describes a backdrop, scene, color,
plinth, or shadow, the model may paint that instead of alpha. Keep the prompt
on an isolated subject and say so: fully transparent alpha, no backdrop, no
rectangle, no plinth, no cast shadow. For charts, ask for a transparent plot
area and no card, frame, or filled panel — not just a transparent silhouette.

Match `size` to the asset: icons/stickers `1024x1024`, product shots
`1024x1536`, charts `1536x1024`. After decoding, confirm a real alpha channel
(RGBA / PNG `tRNS`). If the file is opaque, tighten the prompt and retry once.

If `background:transparent` 400s, generate on a flat, uniform background that
contrasts with the subject and key it out locally (PIL, ImageMagick). Recolor
the subject for the background they named before you finish — a near-black
mark on a dark header is invisible. Say what you did.

## Failures

Most errors explain themselves; these don't:

| Symptom | Fix |
|---|---|
| Connection refused | DroidProxy isn't running — tell the user to launch it |
| `auth_not_found` / no auth for `codex` | Codex not connected, or the account is Free. Settings → Connect Codex. Image gen requires Plus/Pro. |
| `usage_limit_reached` (`plan_type`, `resets_in_seconds`) | Codex image quota is exhausted. Tell the user when it resets. Do not retry in a loop. |
| 401 after a long idle | OAuth session dead — Settings → Connect Codex |
| 400 unsupported model | You sent a chat id. Use `gpt-image-2`. |

On a moderation / safety block (`moderation_blocked`), stop. Don't retry and
don't paraphrase the prompt to evade the filter. Tell the user it was blocked
and offer a different direction.

Report the API's own message rather than guessing, and never invent image
content or a URL for a request that failed.
