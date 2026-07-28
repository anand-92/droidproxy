---
name: grok-imagine
version: 1.0.0
description: |
  Generate images via Grok Imagine through DroidProxy (no XAI_API_KEY).
  Use when the user asks to generate, create, draw, or imagine an image,
  illustration, icon, mockup, or similar visual asset and DroidProxy Grok
  OAuth is available. Prefer this over inventing image URLs or base64.
---

# Grok Imagine (via DroidProxy)

Generate images with **Grok Imagine** using the same SuperGrok / X Premium+
OAuth session that powers DroidProxy chat. Auth is injected by the proxy —
do **not** ask for or use an `XAI_API_KEY`.

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
- Do **not** use for vision/understanding of an existing image the user
  already attached (that is chat multimodal, not this skill).

## How it works

```
Droid shell → POST http://localhost:8317/v1/images/generations
           → DroidProxy (OAuth bearer from ~/.cli-proxy-api/grok-cli.json)
           → api.x.ai Grok Imagine
```

Any `model` whose name starts with `grok-` is TLS-forwarded by ThinkingProxy
to `api.x.ai` with the subscription token. Image bodies are not chat payloads;
keep the JSON minimal.

## Generate an image

Default model: `grok-imagine-image` (faster).  
Higher fidelity: `grok-imagine-image-quality` (slower).

### macOS / Linux (base64 → file)

```bash
PROMPT='A red balloon on a wooden table, soft natural light'
OUT="${OUT:-./grok-imagine.jpg}"
MODEL="${MODEL:-grok-imagine-image}"
ASPECT="${ASPECT:-1:1}"

RESP=$(curl -sS http://localhost:8317/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    --arg aspect "$ASPECT" \
    '{model:$model, prompt:$prompt, aspect_ratio:$aspect, response_format:"b64_json"}')")

# Surface API errors clearly
if echo "$RESP" | jq -e '.error // .data[0].b64_json' >/dev/null 2>&1; then
  :
else
  echo "$RESP" >&2
  exit 1
fi

if echo "$RESP" | jq -e '.error' >/dev/null 2>&1; then
  echo "$RESP" | jq -r '.error.message // .error // .' >&2
  exit 1
fi

echo "$RESP" | jq -r '.data[0].b64_json' | base64 -d > "$OUT"
echo "Wrote $OUT"
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

### Windows (PowerShell)

```powershell
$prompt = "A red balloon on a wooden table, soft natural light"
$out = ".\grok-imagine.jpg"
$body = @{
  model = "grok-imagine-image"
  prompt = $prompt
  aspect_ratio = "1:1"
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

## Parameters

| Field | Values | Notes |
|---|---|---|
| `model` | `grok-imagine-image`, `grok-imagine-image-quality` | Must start with `grok-` so the proxy routes to xAI |
| `prompt` | string | Concrete subject, style, lighting; 1–2 sentences |
| `aspect_ratio` | `1:1`, `16:9`, `9:16`, `4:3`, `3:4`, `3:2`, `2:3`, `auto`, … | Optional |
| `response_format` | omit (URL) or `b64_json` | Prefer `b64_json` when saving to the workspace |
| `n` | 1–10 | Multiple variations of the same prompt |
| `resolution` | `1k`, `2k` | Optional; quality model often pairs with `2k` |

## Workflow for the agent

1. Confirm DroidProxy is up (and Grok connected if the first call fails).
2. Craft a clear positive prompt (subject → setting → style → lighting).
3. Choose aspect ratio from the use case (icons `1:1`, banners `16:9`, stories `9:16`).
4. Call `/v1/images/generations` on **localhost:8317** with `Authorization: Bearer dummy-not-used`.
5. Write the image under the project (e.g. `assets/`, `images/`, or path the user named).
6. Report the saved path. Do not invent image content if the request failed.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Connection refused | DroidProxy not running | Launch the app; wait for menu bar icon |
| 401 / “Not logged in to Grok” | No OAuth session | Settings → Connect Grok |
| 401 after long idle | Refresh failed | Reconnect Grok in Settings |
| 403 permission / quota | Tier or subscription gate | Same as chat OAuth; some tiers block API OAuth; BYOK `XAI_API_KEY` is the fallback |
| 404 / wrong host | Hitting api.x.ai directly without key | Always use `http://localhost:8317` |
| Chat model “draws” nothing | User selected Grok chat only | This skill must run; chat does not auto-call Imagine |

## What not to do

- Do **not** register `grok-imagine-image` as a Factory **chat** custom model.
- Do **not** send chat/completions or responses payloads to the image endpoint.
- Do **not** require or paste an `XAI_API_KEY` when DroidProxy Grok OAuth is available.
- Do **not** leave temporary URL-only results undownloaded; save `b64_json` or fetch the URL immediately.
