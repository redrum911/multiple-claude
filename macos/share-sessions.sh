#!/bin/bash
if [ "$1" = --later ]; then
  /usr/bin/python3 -I -c 'import os, sys, time
if os.fork(): sys.exit()
os.setsid(); time.sleep(30); os.execv(sys.argv[1], sys.argv[1:2])' "$0" </dev/null >/dev/null 2>&1
  exit 0
fi
if [ "$1" = --soon ]; then
  /usr/bin/python3 -I -c 'import fcntl, os, sys, time
if os.fork(): sys.exit()
os.setsid()
f = open(os.path.expanduser("~/.claude/.share-sessions.pending"), "w")
try: fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
except OSError: sys.exit()
time.sleep(5); fcntl.flock(f, fcntl.LOCK_UN); os.execv(sys.argv[1], sys.argv[1:2])' "$0" </dev/null >/dev/null 2>&1
  exit 0
fi
BASE="$HOME/Library/Application Support/Claude"
ROOT="$BASE/claude-code-sessions"
SHARED="$BASE/claude-code-sessions-shared"
[ -d "$ROOT" ] || exit 0
mkdir -p "$SHARED"
shopt -s nullglob
DIRS=("$ROOT"/*/*/ "$HOME"/.claude-instances/*/claude-code-sessions/*/*/)
for d in "${DIRS[@]}"; do
  d="${d%/}"
  [ -L "$d" ] && { rm "$d"; mkdir -p "$d"; }
done
/usr/bin/python3 -I - "$SHARED" "${DIRS[@]}" <<'EOF'
import fcntl, json, os, re, shutil, sys, time
lock = open(os.path.expanduser('~/.claude/.share-sessions.lock'), 'w')
fcntl.flock(lock, fcntl.LOCK_EX)
dirs = [d.rstrip('/') for d in sys.argv[1:]]
def load(p):
    with open(p, encoding='utf-8') as f: return json.load(f)
def save(p, d):
    tmp = os.path.join(os.path.dirname(p), '.%s.%d.tmp' % (os.path.basename(p), os.getpid()))
    with open(tmp, 'w', encoding='utf-8') as f: json.dump(d, f, ensure_ascii=False, separators=(',', ':'))
    os.replace(tmp, p)
key = lambda r: (r.get('lastActivityAt') or 0, bool(r.get('cliSessionId')), bool(r.get('title')))
def quick(p):
    with open(p, 'rb') as f: h = f.read(8192)
    m = re.search(rb'":[\[{]', h); h = h[:m.start()] if m else h
    a = re.search(rb'"lastActivityAt":(\d+)', h)
    if a and re.search(rb'"cliSessionId":"[^"]', h) and re.search(rb'"title":"[^"]', h):
        c = re.search(rb'"cwd":"([^"]*)"', h)
        return (int(a.group(1)), True, True), c.group(1).decode('utf-8', 'replace') if c else ''
    r = load(p)
    return key(r), r.get('cwd') or ''
copies, tombs = {}, {}
for d in dirs:
    for name in os.listdir(d):
        p = os.path.join(d, name)
        if name.startswith('deleted_'): tombs.setdefault(name, p)
        elif name.startswith('local_') and name.endswith('.json'):
            try: copies.setdefault(name, {})[d] = quick(p)
            except Exception: pass
trash = os.path.join(os.path.expanduser('~/.claude/backups/deleted-sessions'), time.strftime('%Y%m%d'))
for name in list(copies):
    t = tombs.get('deleted_' + name[len('local_'):-len('.json')])
    if not t: continue
    try:
        with open(t) as f: at = int(f.read().strip())
    except Exception: continue
    if max(k[0] for k, _ in copies[name].values()) > at: continue
    for d in copies.pop(name):
        dst = os.path.join(trash, '-'.join(x[:8] for x in d.split(os.sep)[-2:]))
        try: os.makedirs(dst, exist_ok=True); shutil.move(os.path.join(d, name), os.path.join(dst, name))
        except Exception: pass
for name, cs in copies.items():
    top = max(k for k, _ in cs.values())
    if not top[1]: continue
    todo = [d for d in dirs if d not in cs or cs[d][0] < top]
    if not todo: continue
    try: best = load(os.path.join(next(d for d in cs if cs[d][0] == top), name))
    except Exception: continue
    for d in todo:
        try:
            rec = best if d not in cs else dict(best, isArchived=load(os.path.join(d, name)).get('isArchived', False))
            save(os.path.join(d, name), rec); cs[d] = (top, best.get('cwd') or '')
        except Exception: pass
for name, src in tombs.items():
    for d in dirs:
        if not os.path.exists(os.path.join(d, name)):
            try: shutil.copy2(src, os.path.join(d, name))
            except Exception: pass
home = os.path.expanduser('~')
projects = os.path.join(home, '.claude', 'projects')
proj = lambda cwd: os.path.join(projects, re.sub(r'[^A-Za-z0-9]', '-', cwd))
scratch = re.compile(r'/scratch-workspaces/[^/]+/[^/]+/scratch-\d{4}-\d{2}-\d{2}-[0-9a-f]{6}$')
for name, cs in copies.items():
    for dd, (k, cwd) in cs.items():
        try:
            if not k[1] or not scratch.search(cwd) or (os.path.isdir(cwd) and os.listdir(cwd)): continue
            p = os.path.join(dd, name); d = load(p); cwd = d.get('cwd') or ''
            if not scratch.search(cwd): continue
            for f in (d['cliSessionId'] + '.jsonl', d['cliSessionId']):
                old, new = os.path.join(proj(cwd), f), os.path.join(proj(home), f)
                if os.path.exists(old) and not os.path.islink(old) and not os.path.exists(new):
                    os.makedirs(proj(home), exist_ok=True); os.rename(old, new); os.symlink(new, old)
            save(p, dict(d, **{k: home for k in ('cwd', 'originCwd', 'gitAnchorsFolderRealpath') if d.get(k) == cwd}))
        except Exception: pass
EOF

exit 0
