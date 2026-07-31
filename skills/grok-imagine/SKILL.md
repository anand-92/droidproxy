---
name: grok-imagine
version: 2.0.0
description: |
  Generate or edit images via Grok Imagine through DroidProxy (no XAI_API_KEY).
  Use when the user asks to generate, create, draw, imagine, or edit an image,
  illustration, icon, mockup, or similar visual asset and DroidProxy Grok
  OAuth is available. Prefer this over inventing image URLs or base64.
---

# Grok Imagine (via DroidProxy)

Generate and edit images with **Grok Imagine** using the SuperGrok / X Premium+
OAuth session that powers DroidProxy chat.

Two things you can't guess and that everything else depends on:

- The endpoint is **`http://localhost:8317`**, not `api.x.ai`. DroidProxy
  TLS-forwards any request whose `model` starts with `grok-` and injects the
  OAuth bearer.
- Auth is **`Authorization: Bearer dummy-not-used`**. The real token comes from
  the proxy. Never ask for or use an `XAI_API_KEY`.

Use for generating or editing visual assets. Not for understanding an image the
user already attached — that's chat multimodal, not this skill.

## Generate

```bash
RESP=$(curl -sS http://localhost:8317/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "A red balloon on a wooden table, soft natural light" \
    '{model:"grok-imagine-image", prompt:$p, aspect_ratio:"1:1",
      resolution:"1k", response_format:"b64_json"}')")

if B64=$(printf '%s' "$RESP" | jq -er '.data[0].b64_json' 2>/dev/null); then
  printf '%s' "$B64" | base64 -d > out.jpg
else
  printf '%s\n' "$RESP" >&2   # errors are plain text, not JSON
  exit 1
fi
```

Two things that bite here:

- **Check `.data[0].b64_json` before decoding.** On failure there is no b64
  field, and piping the error body through `base64 -d` writes a corrupt file
  that passes an `ls` check and only reveals itself when someone opens it.
- **Print the raw body on failure, not `jq '.error.message'`.** Errors come
  back as `text/plain`, so parsing them as JSON discards the useful part. The
  raw text is specific and worth reading — a bad `aspect_ratio` replies
  ``unknown variant `21:9`, expected one of `1:1`, `3:4`, ...``, which tells
  you exactly what to send.

## Edit

`POST /v1/images/edits`, same auth and routing. Pass **either** `image` (single)
or `images` (multi-reference, addressed as `<IMAGE_0>`, `<IMAGE_1>` in the
prompt) — never both.

```bash
curl -sS http://localhost:8317/v1/images/edits \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "Make it blue-tinted studio lighting" --arg u "$SRC" \
    '{model:"grok-imagine-image", prompt:$p, image:{url:$u},
      response_format:"b64_json"}')"
```

The source `url` takes a public HTTPS URL, an xAI `file_id`, or a data URL. For
a **local file** there's no upload step — inline it as a data URL:

```bash
SRC="data:image/jpeg;base64,$(base64 -i ./photo.jpg)"
```

Omit `aspect_ratio` on single-image edits; it's inferred from the source, and
setting it can crop or letterbox. Pass it only for multi-image edits, where
there's no single source to infer from.

## Parameters

| Field | Values | Notes |
|---|---|---|
| `model` | `grok-imagine-image`, `grok-imagine-image-quality` | Must start with `grok-` or the proxy won't route it. Default to the first; reach for `-quality` only when the user signals the output is a final or printed asset |
| `prompt` | string | Subject → setting → style → lighting |
| `aspect_ratio` | `1:1`, `3:4`, `4:3`, `9:16`, `16:9`, `2:3`, `3:2`, `9:19.5`, `19.5:9`, `9:20`, `20:9`, `1:2`, `2:1`, `auto` | Default `auto`. Icons `1:1`, banners `16:9`, stories `9:16` |
| `resolution` | `1k`, `2k` | Default `1k`, and stay there unless the user asks for print/hi-dpi or says "high quality" — `2k` costs more and returns files ~10x larger, which is wasted on an icon or a web asset |
| `response_format` | `url`, `b64_json` | `url` is the default but expires fast — prefer `b64_json` when saving to disk |
| `n` | 1–10 | Default 1 |
| `quality` | `low`, `medium`, `high` | Not OpenAI's `hd`/`standard` |
| `storage_options` | `{filename, expires_after?, public_url?}` | Persists to the xAI Files API; response gains `file_output: {file_id, filename}`. `expires_after` is seconds, max 2592000 |

Anything outside these enums returns 422, and OpenAI-only fields (`size`,
`style`, `background`, `output_format`, `quality:"hd"`) return 400 or are
silently ignored. Don't reach for them.

## Response

```json
{"data": [{"b64_json": "...", "mime_type": "image/jpeg", "url": "https://imgen.x.ai/..."}],
 "usage": {"cost_in_usd_ticks": 200000000}}
```

Pick the file extension from `mime_type`, not from the prompt or the filename
the user asked for — `1k` usually returns JPEG and `2k` often returns PNG, so a
`.jpg` name on PNG bytes is a real outcome. If that contradicts the name they
gave, save the correct extension and say why.

With `response_format: "url"` the URL is temporary — download it immediately
rather than handing it to the user.

## No transparency

Imagine has no alpha channel; output is always opaque JPEG or PNG. There is no
API field that changes this, so don't send one.

When someone asks for a transparent PNG:

1. Generate on a flat, uniform background that contrasts with the subject.
2. Key it out locally (PIL, ImageMagick).
3. **Recolor the subject for the background they named, before you finish.**
   Someone asking for transparency has told you where it's going — "over our
   dark header," "on a white card." Keying preserves whatever ink Imagine
   happened to render, which is usually near-black, so a mark destined for a
   dark background comes out invisible. Compare the subject's luminance to the
   target background and invert it if they collide. It's free once you have the
   alpha mask, and it's the difference between a usable asset and one the user
   has to send back.
4. Say what you did, and mention the ink color you chose so they can ask for
   the other one.

## Failures

Most errors explain themselves; these three don't:

| Symptom | Fix |
|---|---|
| Connection refused | DroidProxy isn't running — tell the user to launch it |
| 401, or 401 after a long idle | OAuth session dead — Settings → Connect Grok |
| 403 permission / quota | Subscription tier gates API OAuth. A BYOK `XAI_API_KEY` is the only fallback |

Report the API's own message rather than guessing, and never invent image
content or a URL for a request that failed.
