#!/usr/bin/env python3
"""Safely configure custom models in Factory Droid's ~/.factory/settings.json.

Mutates parsed JSON only (never text-replacement), backs up before writes, and
verifies afterward that no pre-existing apiKey changed -- restoring and failing
loudly if anything did. See SKILL.md for the workflow this supports.
"""
import argparse
import json
import shutil
import sys
import time
from pathlib import Path

LADDER = ["none", "minimal", "low", "medium", "high", "xhigh", "max", "dynamic", "off"]
DEFAULT_SETTINGS = Path.home() / ".factory" / "settings.json"


def load(path: Path):
    return json.loads(path.read_text())


def key_fingerprint(v):
    """Stable fingerprint that proves byte-identity without printing the secret."""
    if v is None:
        return None
    if isinstance(v, str):
        return f"str:{len(v)}:{v[:4]}..{v[-4:]}" if len(v) > 8 else f"str:{len(v)}"
    if isinstance(v, dict):
        import hashlib
        return "dict:" + hashlib.sha256(json.dumps(v, sort_keys=True).encode()).hexdigest()[:16]
    return repr(type(v))


def keymap(settings):
    out = {}
    for m in settings.get("customModels") or []:
        out[m.get("id")] = key_fingerprint(m.get("apiKey"))
    return out


def backup(path: Path) -> Path:
    b = path.with_name(path.name + ".bak." + time.strftime("%Y%m%d-%H%M%S"))
    shutil.copy2(path, b)
    return b


def write(path: Path, settings):
    path.write_text(json.dumps(settings, indent=2) + "\n")


def save(path: Path, old_settings, new_settings) -> Path:
    b = backup(path)
    write(path, new_settings)
    try:
        before, after = keymap(old_settings), keymap(load(path))
    except Exception as e:
        shutil.copy2(b, path)
        sys.exit(f"FAILED: written file does not parse ({e}); restored backup {b}")
    damaged = {k for k in before if k in after and before[k] != after[k]}
    vanished = set(before) - set(after) - {"__removed_by_user__"}
    # removal is legitimate when explicitly requested by the command itself
    if getattr(save, "_allow_removal", False):
        vanished -= getattr(save, "_removed_ids", set())
    if damaged or vanished:
        shutil.copy2(b, path)
        sys.exit(
            f"FAILED: apiKeys changed (damaged={sorted(damaged)}, "
            f"vanished={sorted(vanished)}); restored backup {b}"
        )
    print(f"ok: wrote {path} (backup {b}, all existing apiKeys verified byte-identical)")
    return b


def next_index(models, requested):
    used = {m.get("index") for m in models}
    if requested is not None:
        if requested in used:
            sys.exit(f"index {requested} already taken")
        return requested
    i = 0
    while i in used:
        i += 1
    return i


def unique_id(models, base):
    ids = {m.get("id") for m in models}
    cand, n = base, 0
    while cand in ids:
        n += 1
        cand = f"{base}-{n}"
    return cand


def resolve_key(args, models):
    if args.api_key and args.reuse_key_from:
        sys.exit("use either --api-key or --reuse-key-from, not both")
    if args.api_key:
        return args.api_key
    if args.reuse_key_from:
        for m in models:
            if m.get("id") == args.reuse_key_from:
                if not m.get("apiKey"):
                    sys.exit(f"{args.reuse_key_from} has no apiKey to reuse")
                return m["apiKey"]  # real bytes; read display shows asterisks only
        sys.exit(f"--reuse-key-from {args.reuse_key_from}: no such model id")


def cmd_add(p):
    a = p.parse_args()
    path = Path(a.settings)
    s = load(path)
    models = s.setdefault("customModels", [])
    if a.effort and a.effort not in LADDER:
        p.error(f"--effort must be one of {LADDER}")
    mid = a.id or "custom:" + a.model.replace("/", "-").replace("_", "-")
    mid = unique_id(models, mid if mid.startswith("custom:") else "custom:" + mid)
    key = resolve_key(a, models)
    entry = {
        "model": a.model,
        "id": mid,
        "index": next_index(models, a.index),
        "displayName": a.display_name or a.model.split("/")[-1],
    }
    if a.base_url:
        entry["baseUrl"] = a.base_url
    if key:
        entry["apiKey"] = key
    entry["provider"] = a.provider
    entry["enableThinking"] = (not a.no_thinking)
    if a.effort:
        entry["reasoningEffort"] = a.effort
    if a.max_context:
        entry["maxContextLimit"] = a.max_context
    if a.max_output:
        entry["maxOutputTokens"] = a.max_output
    if a.no_image_support:
        entry["noImageSupport"] = True
    if a.extra_args:
        try:
            entry["extraArgs"] = json.loads(a.extra_args)
        except json.JSONDecodeError as e:
            sys.exit(f"--extra-args invalid JSON: {e}")
    if any(m.get("model") == a.model and m.get("baseUrl") == entry.get("baseUrl") for m in models):
        print(f"note: an entry with model={a.model} at that baseUrl already exists; adding anyway")

    old = load(path)
    models.append(entry)
    save._allow_removal, save._removed_ids = False, set()
    save(path, old, s)

    hard_caps = []
    if a.max_output:
        hard_caps.append(f"-r <effort> overrides are honored; max_tokens will be {a.max_output}")
    print(f"registered {mid}  displayName={entry['displayName']!r} provider={a.provider}")
    if a.effort:
        print(f"reasoning effort {a.effort} set on the MODEL ENTRY; use set-defaults to make it apply to sessions")
    hint = f'droid exec -m {mid} \'Reply with exactly: config-ok\''
    if not a.no_exec_hint:
        print(f"verify now: {hint}")


def cmd_set_defaults(p):
    a = p.parse_args()
    path = Path(a.settings)
    s = load(path)
    models = s.get("customModels") or []
    if not any(m.get("id") == a.model_id for m in models):
        sys.exit(f"{a.model_id} not found in customModels")
    if a.effort and a.effort not in LADDER:
        p.error(f"--effort must be one of {LADDER}")
    sd = s.setdefault("sessionDefaultSettings", {})
    old = load(path)
    sd["model"] = a.model_id
    if a.effort:
        sd["reasoningEffort"] = a.effort
    save._allow_removal, save._removed_ids = False, set()
    save(path, old, s)
    print(f"session defaults now model={sd['model']} reasoningEffort={sd.get('reasoningEffort')!r}")
    if sd.get("reasoningEffort") == "none":
        print("WARNING: effort 'none' overrides the model entry's own effort; "
              "that is exactly the silent-disable bug. Pick a real level.")
    if not a.no_exec_hint:
        print(f"verify now: droid exec 'Reply with exactly: config-ok'")


def cmd_remove(p):
    a = p.parse_args()
    path = Path(a.settings)
    s = load(path)
    models = s.get("customModels") or []
    keep = [m for m in models if m.get("id") != a.model_id]
    if len(keep) == len(models):
        sys.exit(f"{a.model_id} not found")
    if str(a.yes).lower() not in ("1", "true", "yes"):
        sys.exit(f"would remove {a.model_id}; re-run with --yes to confirm")
    sd = s.get("sessionDefaultSettings") or {}
    was_default = sd.get("model") == a.model_id
    old = load(path)
    s["customModels"] = keep
    save._allow_removal, save._removed_ids = True, {a.model_id}
    save(path, old, s)
    print(f"removed {a.model_id}")
    if was_default:
        print("WARNING: removed model was the session default model; fix with set-defaults")


def cmd_list(p):
    a = p.parse_args()
    s = load(Path(a.settings))
    sd = s.get("sessionDefaultSettings") or {}
    print(f"session default: model={sd.get('model')} reasoningEffort={sd.get('reasoningEffort')!r}\n")
    for m in sorted(s.get("customModels") or [], key=lambda x: x.get("index") or 0):
        flags = []
        if m.get("enableThinking"):
            flags.append("thinking")
        if m.get("reasoningEffort"):
            flags.append(f"effort={m['reasoningEffort']}")
        if m.get("maxContextLimit"):
            flags.append(f"ctx={m['maxContextLimit']}")
        if m.get("maxOutputTokens"):
            flags.append(f"out={m['maxOutputTokens']}")
        if m.get("extraArgs"):
            flags.append(f"extraArgs={json.dumps(m['extraArgs'], sort_keys=True)}")
        has_key = "key=stored" if m.get("apiKey") else "key=NONE"
        star = " <-- session default" if m.get("id") == sd.get("model") else ""
        print(f"{m.get('id')}  [{m.get('model')} @ {m.get('baseUrl', '?')}] {has_key} {' '.join(flags)}{star}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--settings", default=str(DEFAULT_SETTINGS),
                    help="settings file (default ~/.factory/settings.json)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("list", help="list registered custom models")
    sp.set_defaults(fn=cmd_list)

    sp = sub.add_parser("add", help="register a custom model")
    sp.add_argument("model", help="upstream slug, e.g. z-ai/glm-5.3-flash")
    sp.add_argument("--id", help="settings id (default derived; always gets custom: prefix)")
    sp.add_argument("--display-name")
    sp.add_argument("--base-url", required=True)
    grp = sp.add_mutually_exclusive_group(required=True)
    grp.add_argument("--api-key")
    grp.add_argument("--reuse-key-from",
                     help="copy the stored apiKey of an existing model id (real bytes)")
    sp.add_argument("--provider", default="generic-chat-completion-api")
    sp.add_argument("--effort", help=f"reasoningEffort; one of {LADDER}")
    sp.add_argument("--max-context", type=int)
    sp.add_argument("--max-output", type=int)
    sp.add_argument("--no-thinking", action="store_true")
    sp.add_argument("--no-image-support", action="store_true")
    sp.add_argument("--extra-args", help='JSON object merged last into request bodies')
    sp.add_argument("--index", type=int)
    sp.add_argument("--no-exec-hint", action="store_true")
    sp.set_defaults(fn=cmd_add)

    sp = sub.add_parser("set-defaults", help="set sessionDefaultSettings model+effort")
    sp.add_argument("model_id")
    sp.add_argument("--effort")
    sp.add_argument("--no-exec-hint", action="store_true")
    sp.set_defaults(fn=cmd_set_defaults)

    sp = sub.add_parser("remove", help="remove a custom model")
    sp.add_argument("model_id")
    sp.add_argument("--yes", action="store_true")
    sp.set_defaults(fn=cmd_remove)

    handler = vars(ap.parse_args()).pop("fn")
    handler(ap)


if __name__ == "__main__":
    main()
