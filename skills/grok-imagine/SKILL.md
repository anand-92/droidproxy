---
name: grok-imagine
version: 3.0.0
description: |
  Generate or edit images via Grok Imagine Image 2.0 through DroidProxy
  (no XAI_API_KEY). Use when the user asks to generate, create, draw,
  imagine, or edit an image, illustration, icon, mockup, or similar
  visual asset and DroidProxy Grok OAuth is available. Prefer this over
  inventing image URLs or base64.
---

# Grok Imagine Image 2.0 (via DroidProxy)

Generate and edit images with **`grok-imagine-image-2.0`** using the SuperGrok /
X Premium+ OAuth session that powers DroidProxy chat. This is the current
Imagine image model (text or image → image). Do not use the older
`grok-imagine-image` / `grok-imagine-image-quality` ids unless the user
explicitly asks for them.

Two things you can't guess and that everything else depends on:

- The endpoint is **`http://localhost:8317`**, not `api.x.ai`. DroidProxy
  TLS-forwards any request whose `model` starts with `grok-` and injects the
  OAuth bearer.
- Auth is **`Authorization: Bearer dummy-not-used`**. The real token comes from
  the proxy. Never ask for or use an `XAI_API_KEY`.

Use for generating or editing visual assets. Not for understanding an image the
user already attached — that's chat multimodal, not this skill.

## Prompting

xAI rewrites the prompt with an upsampler before generation, so write a clear
scene rather than a tag soup. If the user gives a detailed prompt or asks you
to use theirs, use it verbatim. Otherwise craft 2–5 sentences of natural prose:

**subject → action/pose → setting → style → composition → lighting/mood → key details**

- Front-load the subject. Give strong high-level direction for mood,
  composition, lighting, and style without specifying every pixel.
- State what to include, not what to exclude. No negative prompts.
- One coherent scene per prompt. Match `aspect_ratio` to the use case:
  icons `1:1`, banners `16:9`, stories `9:16`.
- For **edits**, describe only what changes and what must stay the same.
- For **multi-image edits**, address sources as `<IMAGE_0>`, `<IMAGE_1>`,
  `<IMAGE_2>` in the prompt (max 3). Combining subjects, transferring a style,
  or composing a scene from references is the intended use.
- Ground real people, brands, places, and “current/latest” facts with a web
  search first and put the verified details in the prompt. For a named real
  person, edit from a real reference photo — do not generate the likeness from
  text alone.

## Generate

```bash
RESP=$(curl -sS http://localhost:8317/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "A red balloon on a wooden table, soft natural light" \
    '{model:"grok-imagine-image-2.0", prompt:$p, aspect_ratio:"1:1",
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
or `images` (up to 3 references, addressed as `<IMAGE_0>`, `<IMAGE_1>`,
`<IMAGE_2>` in the prompt) — never both. Each source is JPEG, PNG, or WebP.

```bash
curl -sS http://localhost:8317/v1/images/edits \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-not-used" \
  -d "$(jq -n --arg p "Make it blue-tinted studio lighting" --arg u "$SRC" \
    '{model:"grok-imagine-image-2.0", prompt:$p,
      image:{url:$u, type:"image_url"},
      response_format:"b64_json"}')"
```

The source `url` takes a public HTTPS URL, an xAI `file_id` (on the image
object, mutually exclusive with `url`), or a data URL. For a **local file**
there's no upload step — inline it as a data URL:

```bash
SRC="data:image/jpeg;base64,$(base64 -i ./photo.jpg)"
```

Omit `aspect_ratio` on single-image edits; it follows the source, and setting
it can crop or letterbox. On multi-image edits it follows the first source
unless you override it.

Chain edits by feeding each output back as the next `image`. That is how you
refine, restyle, or correct without starting over.

## Parameters

Source of truth: [Image Generation](https://docs.x.ai/developers/model-capabilities/images/generation),
[Image Editing](https://docs.x.ai/developers/model-capabilities/images/editing),
[Multi-Image Editing](https://docs.x.ai/developers/model-capabilities/images/multi-image-editing),
and the [Images REST API](https://docs.x.ai/developers/rest-api-reference/inference/images).

| Field | Values | Notes |
|---|---|---|
| `model` | `grok-imagine-image-2.0` | Must start with `grok-` or the proxy won't route it. Always send this id. |
| `prompt` | string | See Prompting. Required on edits. |
| `aspect_ratio` | `1:1`, `3:4`, `4:3`, `9:16`, `16:9`, `2:3`, `3:2`, `9:19.5`, `19.5:9`, `9:20`, `20:9`, `1:2`, `2:1`, `auto` | Default `auto` (model picks the ratio). Icons `1:1`, banners `16:9`, stories `9:16`. |
| `resolution` | `1k`, `2k` | Default `1k`. Stay there unless the user asks for print/hi-dpi — `2k` returns much larger files. |
| `quality` | `low`, `medium` | **2.0 only.** Default `medium` when omitted. Do not send `high`, `hd`, or `standard`. Omit unless the user asks for `low`. |
| `response_format` | `url`, `b64_json` | `url` is the default but expires fast — prefer `b64_json` when saving to disk. |
| `n` | 1–10 | Default 1. Same-prompt variations belong in one request via `n`, not parallel calls. |
| `image` / `images` | object or array (max 3) | Edits only. Mutually exclusive. Each item is `{url, type:"image_url"}` or `{file_id}`. |
| `storage_options` | `{filename, expires_after?, public_url?}` | Persists to the xAI Files API; response gains `file_output: {file_id, filename}`. `expires_after` is seconds, max 2592000. |
| `user` | string | Optional end-user id for abuse monitoring. Don't invent one. |

Anything outside these enums returns 422, and OpenAI-only fields (`size`,
`style`, `background`, `output_format`, `quality:"hd"`) return 400 or are
silently ignored. Don't reach for them.

## Response

```json
{"data": [{"b64_json": "...", "mime_type": "image/jpeg", "url": "https://imgen.x.ai/..."}]}
```

Pick the file extension from `mime_type`, not from the prompt or the filename
the user asked for — `1k` usually returns JPEG and `2k` often returns PNG, so a
`.jpg` name on PNG bytes is a real outcome. If that contradicts the name they
gave, save the correct extension and say why. `mime_type` may also be
`image/webp`.

With `response_format: "url"` the URL is temporary (`imgen.x.ai`) — download it
immediately rather than handing it to the user.

## No transparency

Imagine has no alpha channel; output is always opaque JPEG, PNG, or WebP. There
is no API field that changes this, so don't send one.

When someone asks for a transparent PNG:

1. Generate on a flat, uniform background that contrasts with the subject.
2. Key it out locally (PIL, ImageMagick).
3. **Recolor the subject for the background they named, before you finish.**
   Someone asking for transparency has told you where it's going — "over our
   dark header," "on a white card." Keying preserves whatever ink Imagine
   happened to render, which is usually near-black, so a mark destined for a
   dark background comes out invisible. Compare the subject's luminance to the
   target background and invert it if they collide. That's the difference
   between a usable asset and one the user has to send back.
4. Say what you did, and mention the ink color you chose so they can ask for
   the other one.

## Failures

Most errors explain themselves; these three don't:

| Symptom | Fix |
|---|---|
| Connection refused | DroidProxy isn't running — tell the user to launch it |
| 401, or 401 after a long idle | OAuth session dead — Settings → Connect Grok |
| 403 permission / quota | Subscription tier gates API OAuth. A BYOK `XAI_API_KEY` is the only fallback |

On a moderation / safety block, stop. Don't retry and don't paraphrase the
prompt to evade the filter. Tell the user it was blocked and offer a different
direction.

Report the API's own message rather than guessing, and never invent image
content or a URL for a request that failed.
