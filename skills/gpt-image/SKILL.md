---
name: gpt-image
version: 1.0.0
description: >
  Generate or edit images with gpt-image-2 through DroidProxy Codex OAuth.
  Use when the user asks to generate, create, draw, or edit an image with
  GPT, OpenAI, Codex, gpt-image, or DALL-E, including transparent PNGs.
---

# GPT Image 2 (via DroidProxy Codex)

POST `http://localhost:8317/v1/images/generations` (or `/edits`) with
`Authorization: Bearer dummy-not-used`. Always send `model: gpt-image-2`.
Never send a chat id (`gpt-5.*`). Never use an `OPENAI_API_KEY`. Chat
models on `:8317` do not generate images.

Use this for generating or editing visual assets, not for understanding an
image the user already attached.

## Generate

Requests often take 30–70s. Use `--max-time 180`. Default `quality` to
`low`; raise it only when the user asks (or for small chart text).

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

Check `.data[0].b64_json` before decoding. On failure print the raw body —
Codex errors are JSON (`usage_limit_reached`, `auth_not_found`,
`moderation_blocked`).

## Edit

Same auth. JSON with a data URL — no upload step, no `file_id`.

```bash
SRC="data:image/png;base64,$(base64 -i ./photo.png)"
curl -sS --max-time 180 http://localhost:8317/v1/images/edits \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "Make it blue-tinted studio lighting" --arg u "$SRC" \
    '{model:"gpt-image-2", prompt:$p, images:[{image_url:$u}],
      response_format:"b64_json"}')"
```

Pick the data-URL mime from the source (`image/jpeg`, `image/png`,
`image/webp`). Optional `mask.image_url` (PNG with alpha) marks the region
to replace. Chain edits by feeding each output back as the next
`images[0].image_url`.

## Prompting

If the user gives a detailed prompt or asks you to use theirs, use it
verbatim. Otherwise: subject → action/pose → setting → style → composition
→ lighting/mood → key details. One scene. State what to include, not what
to exclude. For edits, describe only what changes and what must stay.

Ground named people, brands, places, and “current/latest” facts with a web
search first. For a named real person, edit from a real reference photo —
do not generate the likeness from text alone.

## Parameters

| Field | Values | Notes |
|---|---|---|
| `model` | `gpt-image-2` | Always this id. |
| `prompt` | string | Required on generate and edit. |
| `size` | `1024x1024`, `1024x1536`, `1536x1024` | Square / portrait / landscape. |
| `quality` | `low`, `medium`, `high` | Default `low`. Do not send `hd`, `standard`, or `auto`. |
| `response_format` | `b64_json` | Always send this when saving to disk. |
| `n` | integer | Default 1. Same-prompt variations use `n`, not parallel calls. |
| `background` | `auto`, `opaque`, `transparent` | `transparent` needs `output_format` `png` or `webp`. |
| `output_format` | `png`, `jpeg`, `webp` | Send `png` for transparency. |
| `output_compression` | 0–100 | JPEG/WebP only. Omit unless asked. |
| `images` | `[{image_url}]` | Edits only. Data URL or https URL. |
| `mask` | `{image_url}` | Edits only. PNG with alpha. |

Pick the file extension from `output_format` when present, otherwise from
the decoded magic bytes (`PNG` / `JFIF` / `RIFF…WEBP`).

## Transparency

When the user wants a transparent PNG (sticker, cutout, icon, campaign
asset, slide chart, print design), send both:

```json
{"background":"transparent","output_format":"png"}
```

The prompt beats `background`. If it describes a backdrop, scene, color,
plinth, or shadow, the model paints that instead of alpha. Keep the prompt
on an isolated subject and say so explicitly:

- Isolated object, fully visible, generously padded
- Actual fully transparent alpha
- No backdrop, rectangle, plinth, cast shadow, watermark, or readable label text
- Preserve natural transparency, refraction, and fine material edges (glass, ribbon, fibers)

Size by use: icons/stickers `1024x1024`, product shots `1024x1536`, charts
`1536x1024`. Raise `quality` to `high` when the asset has small text.

**Products / campaign cutouts.** One object. No scene. Ask for fully
transparent alpha around the silhouette. Good for reuse across storefronts
and seasonal backgrounds.

**Charts for dark slides.** Ask for a genuinely transparent background
*and* a transparent plot area — not just a transparent silhouette. No
card, frame, filled panel, title, or grid fill. Specify pale/white labels
and bright series colors so they read on navy or gradient themes. Keep
exact data values in the prompt, then verify labels and proportions
against the source before using the chart.

**Icons, stickers, decorations.** Keep everything outside the tile, die-cut
border, or sprig transparent — including gaps between branches and leaves.
No text, watermark, or drop shadow.

**Print-on-demand.** Generate the artwork and any blank garments as
separate transparent PNGs. Keep open space *inside* the design transparent
too (no white rectangle or badge). Composite locally; do not bake the
print onto the garment in one generation if they need to reuse it.

After decoding, confirm a real alpha channel (RGBA / PNG `tRNS`) and that
some pixels are fully transparent. If the file is opaque, strip backdrop
language from the prompt and retry once.

If `background:transparent` 400s, generate on a flat uniform background
that contrasts with the subject and key it out locally (PIL, ImageMagick).
Recolor the subject for the background they named before you finish — a
near-black mark on a dark header is invisible. Say what you did.

## Failures

| Symptom | Fix |
|---|---|
| Connection refused | DroidProxy isn't running — tell the user to launch it |
| `auth_not_found` / no auth for `codex` | Codex not connected, or the account is Free. Settings → Connect Codex. Image gen requires Plus/Pro. |
| `usage_limit_reached` (`plan_type`, `resets_in_seconds`) | Quota exhausted. Tell the user when it resets. Do not retry in a loop. |
| 401 after a long idle | OAuth session dead — Settings → Connect Codex |
| 400 unsupported model | You sent a chat id. Use `gpt-image-2`. |

On `moderation_blocked`, stop. Don't retry and don't paraphrase the prompt
to evade the filter. Report the API's own message. Never invent image
content or a URL for a request that failed.
