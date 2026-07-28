---
name: grok-imagine
version: 1.1.0
description: |
  Generate or edit images via Grok Imagine through DroidProxy (no XAI_API_KEY).
  Use when the user asks to generate, create, draw, imagine, or edit an image,
  illustration, icon, mockup, or similar visual asset and DroidProxy Grok
  OAuth is available. Prefer this over inventing image URLs or base64.
---

# Grok Imagine (via DroidProxy)

Generate and edit images with **Grok Imagine** using the same SuperGrok / X
Premium+ OAuth session that powers DroidProxy chat. Auth is injected by the
proxy — do **not** ask for or use an `XAI_API_KEY`.

ThinkingProxy forwards any request whose JSON `model` starts with `grok-` to
`api.x.ai` with the body unchanged (image payloads are not stripped or rewritten).
All parameters listed below work end-to-end via `http://localhost:8317`.

## Prerequisites

1. **DroidProxy is running** (menu bar icon active; ThinkingProxy on port `8317`).
2. **Grok is connected** in DroidProxy Settings (device-code browser login).
3. Optional: chat model can be anything; image gen does not require selecting
   a Grok chat model in `/model`.

Quick connectivity check:

```bash
curl -sS -o /dev/null -w "%{http_code}" http://localhost:8317/health 2>/dev/null || \
  curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:8317/ 2>/dev/null || \
  echo "proxy-unreachable"
```

If the proxy is down, tell the user to launch DroidProxy and Connect Grok.

## When to use

- User asks to generate / create / draw / imagine an image or visual asset.
- User wants icons, mockups, hero art, sprites, or concept art saved to disk.
- User wants to edit / restyle an existing image (use `/v1/images/edits`).
- Do **not** use for vision/understanding of an existing image the user
  already attached (that is chat multimodal, not this skill).

## How it works

```
Droid shell → POST http://localhost:8317/v1/images/generations  (or /v1/images/edits)
           → DroidProxy (OAuth bearer from ~/.cli-proxy-api/grok-cli.json)
           → api.x.ai Grok Imagine
```

Any `model` whose name starts with `grok-` is TLS-forwarded by ThinkingProxy
to `api.x.ai` with the subscription token. Image bodies are not chat payloads;
keep the JSON minimal and only use supported fields below.

## Generate an image

Default model: `grok-imagine-image` (faster, lower cost).  
Higher fidelity: `grok-imagine-image-quality` (slower, higher cost).

### macOS / Linux (base64 → file)

```bash
PROMPT='A red balloon on a wooden table, soft natural light'
OUT="${OUT:-./grok-imagine.jpg}"
MODEL="${MODEL:-grok-imagine-image}"
ASPECT="${ASPECT:-1:1}"
RESOLUTION="${RESOLUTION:-1k}"

RESP=$(curl -sS http://localhost:8317/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    --arg aspect "$ASPECT" \
    --arg resolution "$RESOLUTION" \
    '{
      model:$model,
      prompt:$prompt,
      aspect_ratio:$aspect,
      resolution:$resolution,
      response_format:"b64_json"
    }')")

# Surface API errors clearly (xAI may return .error as string or object)
if echo "$RESP" | jq -e '.data[0].b64_json' >/dev/null 2>&1; then
  :
else
  echo "$RESP" | jq -r '.error.message // .error // .' >&2
  exit 1
fi

# MIME is usually image/jpeg at 1k; 2k often returns image/png — pick extension from mime_type
MIME=$(echo "$RESP" | jq -r '.data[0].mime_type // "image/jpeg"')
if [ "$MIME" = "image/png" ]; then
  case "$OUT" in *.jpg|*.jpeg) OUT="${OUT%.*}.png" ;; esac
fi

echo "$RESP" | jq -r '.data[0].b64_json' | base64 -d > "$OUT"
echo "Wrote $OUT ($MIME)"
```

### URL response (download promptly — URLs are temporary)

```bash
PROMPT='Mountain landscape at sunrise'
curl -sS http://localhost:8317/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "$PROMPT" \
    '{model:"grok-imagine-image", prompt:$p, aspect_ratio:"16:9"}')" \
  | jq -r '.data[0].url'
```

### Multiple variations (`n`)

```bash
curl -sS http://localhost:8317/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d '{"model":"grok-imagine-image","prompt":"A coffee mug","n":2,"response_format":"b64_json"}' \
  | jq -r '.data[] | .b64_json' | nl | while read -r i b64; do
      echo "$b64" | base64 -d > "mug-$i.jpg"
    done
```

### Windows (PowerShell)

```powershell
$prompt = "A red balloon on a wooden table, soft natural light"
$out = ".\grok-imagine.jpg"
$body = @{
  model = "grok-imagine-image"
  prompt = $prompt
  aspect_ratio = "1:1"
  resolution = "1k"
  response_format = "b64_json"
} | ConvertTo-Json

$resp = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8317/v1/images/generations" `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer dummy-not-used" } `
  -Body $body

if ($resp.error) { throw ($resp.error | ConvertTo-Json -Compress) }
$bytes = [Convert]::FromBase64String($resp.data[0].b64_json)
[IO.File]::WriteAllBytes((Resolve-Path .).Path + "\" + (Split-Path $out -Leaf), $bytes)
Write-Host "Wrote $out"
```

## Edit an image

`POST /v1/images/edits` — same auth/routing. Provide **either** `image` (single)
**or** `images` (multi-reference; refer to them as `<IMAGE_0>`, `<IMAGE_1>`, … in
the prompt). Do not send both.

```bash
# Single-image edit (aspect_ratio is auto-detected from the source — omit it)
curl -sS http://localhost:8317/v1/images/edits \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n \
    --arg prompt "Make it blue-tinted studio lighting" \
    --arg url "https://example.com/source.jpg" \
    '{
      model:"grok-imagine-image",
      prompt:$prompt,
      image:{url:$url},
      response_format:"b64_json"
    }')"
```

Source image `url` may be a public HTTPS URL or a `data:image/...;base64,...` data URL.
`file_id` from xAI Files API is also accepted when available.

## Parameters (`POST /v1/images/generations`)

All of these are accepted by the proxy and by `api.x.ai` (verified live).

| Field | Required | Values | Notes |
|---|---|---|---|
| `model` | yes* | `grok-imagine-image`, `grok-imagine-image-quality` | *Must start with `grok-` so ThinkingProxy routes to xAI |
| `prompt` | yes | string | Subject → setting → style → lighting |
| `aspect_ratio` | no | `1:1`, `3:4`, `4:3`, `9:16`, `16:9`, `2:3`, `3:2`, `9:19.5`, `19.5:9`, `9:20`, `20:9`, `1:2`, `2:1`, `auto` | Default `auto`. Invalid values → HTTP 422 |
| `resolution` | no | `1k`, `2k` | Default `1k`. `2k` is slower/larger; often returns PNG. Invalid → 422 |
| `response_format` | no | `url` (default), `b64_json` | Prefer `b64_json` when saving to disk |
| `n` | no | integer 1–10 | Default 1. Outside range → HTTP 400 |
| `quality` | no | `low`, `medium`, `high` | Optional fidelity knob (not OpenAI’s `hd`). Unknown values → 422 |
| `user` | no | string | End-user id for abuse monitoring; optional |
| `storage_options` | no | object | Persist output in xAI Files API; response includes `file_output` |

### `storage_options` object

| Field | Required | Notes |
|---|---|---|
| `filename` | yes | Stored file name |
| `expires_after` | no | Seconds until auto-expiry; max 2592000 (30 days). Omit = no expiry |
| `public_url` | no | `true` or config object for a public URL; omit = private |

When set, each `data[]` item includes `file_output: { file_id, filename }` alongside
the usual ephemeral `url` / `b64_json`.

## Parameters (`POST /v1/images/edits`)

Same as generation, plus:

| Field | Required | Notes |
|---|---|---|
| `image` | one of | Single source: `{ "url": "..." }` or `{ "file_id": "..." }` |
| `images` | one of | Multi-ref array of the same objects; mutually exclusive with `image` |
| `aspect_ratio` | no | Use for **multi**-image edits. For single-image edits, omit (auto from input) |

## Response shape

```json
{
  "data": [
    {
      "b64_json": "...",
      "mime_type": "image/jpeg",
      "url": "https://imgen.x.ai/...",
      "file_output": { "file_id": "file_...", "filename": "..." }
    }
  ],
  "usage": { "cost_in_usd_ticks": 200000000 }
}
```

- With `response_format: "b64_json"`: `b64_json` + `mime_type` (no `url`).
- With default / `"url"`: `url` + `mime_type` (temporary; download immediately).
- With `storage_options`: also `file_output`.
- `mime_type` is typically `image/jpeg` at `1k`; `2k` often returns `image/png`.
- Choose the file extension from `mime_type`, not from the prompt.

## Not supported (do not send)

| Field / request | Result | Notes |
|---|---|---|
| `size` (OpenAI-style `1024x1024`) | HTTP 400 | Use `aspect_ratio` + `resolution` |
| `quality: "hd"` / `"standard"` | HTTP 422 | Use `low` / `medium` / `high` only |
| Transparent / alpha output | N/A | No alpha channel API. Outputs are opaque JPEG/PNG. Chroma-key + cutout offline if needed |
| `background`, `output_format`, `style` | Ignored or unreliable | Not part of the xAI schema; do not rely on them |
| Aspect ratios outside the enum (e.g. `21:9`) | HTTP 422 | Stick to the table above |
| `resolution: "4k"` | HTTP 422 | Only `1k` / `2k` |

## Workflow for the agent

1. Confirm DroidProxy is up (and Grok connected if the first call fails).
2. Craft a clear positive prompt (subject → setting → style → lighting).
3. Choose `aspect_ratio` from the use case (icons `1:1`, banners `16:9`, stories `9:16`).
4. Prefer `grok-imagine-image` + `resolution: "1k"` + `response_format: "b64_json"` unless the user wants higher quality (`grok-imagine-image-quality` and/or `2k`).
5. Call `/v1/images/generations` (or `/v1/images/edits`) on **localhost:8317** with `Authorization: Bearer dummy-not-used`.
6. Write the image under the project (e.g. `assets/`, `images/`, or path the user named). Match extension to `mime_type`.
7. Report the saved path. Do not invent image content if the request failed.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Connection refused | DroidProxy not running | Launch the app; wait for menu bar icon |
| 401 / “Not logged in to Grok” | No OAuth session | Settings → Connect Grok |
| 401 after long idle | Refresh failed | Reconnect Grok in Settings |
| 403 permission / quota | Tier or subscription gate | Same as chat OAuth; some tiers block API OAuth; BYOK `XAI_API_KEY` is the fallback |
| 400 `Argument not supported: size` | OpenAI `size` field | Use `aspect_ratio` + `resolution` |
| 400 `n` out of range | `n` not in 1–10 | Clamp `n` |
| 422 unknown `aspect_ratio` / `resolution` / `quality` | Invalid enum | Use only values in the tables above |
| 404 / wrong host | Hitting api.x.ai directly without key | Always use `http://localhost:8317` |
| Chat model “draws” nothing | User selected Grok chat only | This skill must run; chat does not auto-call Imagine |

## What not to do

- Do **not** register `grok-imagine-image` as a Factory **chat** custom model.
- Do **not** send chat/completions or responses payloads to the image endpoint.
- Do **not** require or paste an `XAI_API_KEY` when DroidProxy Grok OAuth is available.
- Do **not** leave temporary URL-only results undownloaded; save `b64_json` or fetch the URL immediately.
- Do **not** send OpenAI-only image fields (`size`, `style`, `background`, `quality: "hd"`).
- Do **not** expect transparent backgrounds from Imagine; cut out offline if needed.
