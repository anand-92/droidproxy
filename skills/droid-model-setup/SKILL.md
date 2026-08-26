---
name: droid-model-setup
description: >
  Configure any third-party model as a custom model in Factory Droid (~/.factory/settings.json):
  resolve specs (context window, max output tokens, reasoning efforts), write a safe config entry,
  set session defaults, and prove the wiring with a live droid exec run and, when needed, an exact
  request-body capture. Fully open-ended: use whenever the user asks to "set X, Y, Z models up for
  a Droid", add/register a custom model, fix a model that ignores its reasoning setting, raise max
  tokens or context for BYOK models, or verify what parameters Droid actually sends. Triggers
  include "set up <model> for droid", "configure droid models", "add custom model",
  "which models does droid support", and "verify my droid model config".
---

# Droid model setup

Turns any OpenAI-compatible (and most Anthropic-compatible) endpoint into a first-class Droid
model. Covers spec lookup, safe writes to `~/.factory/settings.json`, session-default effort
wiring, and empirical verification. Knowledge below was verified Aug 2026 against the real binary
by capturing Droid's outgoing request bodies.

## Workflow for "set X, Y, Z models up for a Droid"

1. **Resolve specs per model** (ask only what cannot be looked up; be agentic otherwise).
   - OpenRouter-hosted model: fetch `https://openrouter.ai/<vendor>/<slug>` — gives context
     window, max completion tokens, supported reasoning efforts, pricing.
   - Other providers: check their docs/API reference for context length and output cap.
   - Note whether thinking/reasoning can be toggled and via which parameter.
2. **Determine endpoint + credentials.**
   - Same provider already registered in settings? Reuse its key with the script's
     `--reuse-key-from <existing-model-id>` (reads the real stored bytes; the asterisks you see in
     file reads are display-only redaction, and Python sees through them).
   - New provider: ask the user for the base URL and API key if genuinely unknown. Defaults:
     OpenRouter `https://openrouter.ai/api/v1`, LM Studio `http://127.0.0.1:1234/v1`,
     llama.cpp/vLLM/Ollama-OpenAI `http://127.0.0.1:<port>/v1`.
   - Provider field: `generic-chat-completion-api` covers every OpenAI-compatible endpoint
     tested (OpenRouter, W&B, LM Studio, MTPLX). `openai` also works for OpenAI-compat APIs.
3. **Write entries with the helper script** (never hand-edit settings.json — see gotchas).
   Model `id` in settings becomes the CLI-facing name: `-m custom:<id>`.
4. **Set session defaults** if the user wants one of them as the daily driver
   (`set-defaults` subcommand sets model + matching reasoningEffort together).
5. **Verify live**, then report exactly what was configured and proven.

## Hard rules

**Never text-edit `~/.factory/settings.json`.** Existing `apiKey` values render as runs of
asterisks inside the agent's file viewer; a string-replacement edit that touches those lines
writes literal asterisks to disk and destroys real keys. Use `scripts/droid_models.py`, which
mutates parsed JSON (untouched values stay byte-identical), backs the file up first, and
afterward diffs every pre-existing key — restoring automatically and failing loudly if anything
changed. If you must edit manually anyway (new top-level keys etc.), anchor edits far away from
apiKey lines, then diff `{id: len(apiKey)}` old-vs-new via Python before declaring success.

**Config is not verification.** A written entry proves nothing. Always finish with:

```bash
droid exec -m custom:<model-id> 'Reply with exactly: config-ok'
```

A successful run also re-proves the API key survived whatever edit preceded it.

## How Droid actually sends requests (wire facts)

Captured exact body for a `generic-chat-completion-api` custom model:

```json
{"model":"<slug>","stream":true,"max_tokens":<N>,"temperature":1,"reasoning_effort":"<effort>"}
```

- **Streaming is always on** (`stream:true` is hardcoded, plus `stream_options.include_usage`);
  there is no settings knob and none needed.
- **No separate thinking object** on this path: `reasoning_effort` alone carries the intent;
  OpenRouter maps it to `reasoning.effort`. Anthropic-style paths instead get
  `reasoning_effort` verbatim plus `budget_tokens` (low 4096, medium 12288,
  high/xhigh 24576, max = uncapped/0).
- **`maxOutputTokens` maps 1:1 to `max_tokens`.** Omit it and Droid falls back to small built-in
  ceilings — always set it to the model's real max completion tokens.
- **Effort ladder:** `none, minimal, low, medium, high, xhigh, max, dynamic, off`.
- **Resolution order beats model entry:** exec `-r/--reasoning-effort` flag > 
  `sessionDefaultSettings.reasoningEffort` > `customModels[].reasoningEffort`. Classic bug:
  model entry says `max`, session default says `none` → sessions run with thinking off. When
  configuring for real use, set BOTH (the script's `set-defaults` does this atomically).
- **`extraArgs` is the escape hatch:** arbitrary JSON merged last into every request body
  (wins over everything). Example: `"extraArgs": {"top_p": 0.9}`. No `--stream` style toggles —
  only body params.

## full schema of a customModel entry

All fields observed in the binary's zod schema (optional unless noted):
`model`* (upstream slug), `id`*, `index`* (unique int — script auto-picks),
`baseUrl`, `apiKey` | `apiKeyHelper`(+`apiKeyHelperTtlMs`), `authMode` ("bearer" for Anthropic
SDK token path), `provider`*, `displayName`, `maxContextLimit`, `maxOutputTokens`,
`enableThinking`, `thinkingMaxTokens`, `reasoningEffort`, `noImageSupport`,
`extraHeaders`, `extraArgs`, `bedrock`, `baseModelId`.

## Verification beyond config-ok

Token counts between efforts are NOT reliable proof of transmission (tiny prompts barely trigger
thinking at any effort). To prove exact request bodies, do a wire capture:

1. Run a tiny dump server that records POST bodies to JSONL and returns a canned chat-completion
   response (a ~30-line Python http.server is enough; return one fixed JSON body and log
   everything).
2. Temporarily register a throwaway entry pointing at it
   (`python3 scripts/droid_models.py add ... --base-url http://127.0.0.1:8899/v1 --api-key test-key`).
3. `droid exec -m custom:dump-test -r max hi` — exec fails on the fake response AFTER capture;
   ignore the failure, read `/tmp/dump_requests.jsonl`.
4. Remove the temp entry (`remove custom:dump-test`) and kill the server.

Post-restart check: Droid has been observed keeping settings intact across restarts, but if a
restart behaves oddly, simply Read settings.json again — if the entries are gone, they are gone;
do not try to reconstruct state from caches or hack around it. Just re-run this skill's add
commands (specs are cheap to re-fetch, keys come from wherever they're stored).

## Helper script

```bash
# from your droidproxy checkout:
S=skills/droid-model-setup/scripts/droid_models.py

python3 $S list                                   # registered custom models
python3 $S add z-ai/glm-5.3-flash \
    --id GLM-5.3-Flash-0 --display-name "GLM 5.3 Flash" \
    --base-url https://openrouter.ai/api/v1 \
    --reuse-key-from custom:some-openrouter-model \
    --effort max --max-context 1048576 --max-output 131072
python3 $S add <slug> --api-key sk-or-v1-...      # explicit key instead
python3 $S add <slug> --extra-args '{"top_p":0.9}'
python3 $S set-defaults custom:GLM-5.3-Flash-0 --effort max   # model+effort together
python3 $S remove custom:<id>
```

Every mutating subcommand: timestamped backup next to the file, atomic-enough single write,
post-write key-integrity assertion with automatic restore on mismatch. Test safely against a
copy with `--settings /tmp/settings-copy.json --no-exec-hint`.

## Reference implementation (GLM 5.3 Flash, Aug 2026)

Worked end-to-end: specs from OpenRouter page (1M context, 131072 max completion,
$0.075/$0.25 per M), entry added via safe mutation, both the model entry AND
`sessionDefaultSettings` set to effort `max`, then verified three ways: config-ok exec run,
key-integrity post-check, and wire capture showing `reasoning_effort:"max"` +
`max_tokens:131072` + `stream:true` in the actual outgoing body.
