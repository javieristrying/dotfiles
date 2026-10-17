#!/usr/bin/env python3
"""Per-task token and cost audit over Claude Code transcripts (~/.claude/projects)."""
import json, glob, os, sys, collections, datetime as dt

# $/MTok: (input, output, cache_read). Writes: 1.25x (5m) / 2x (1h) of input.
PRICES = {
    'claude-fable-5-1': (10, 50, .25), 'claude-fable-5': (10, 50, 1.0),
    'claude-opus-5-5': (4, 20, .20), 'claude-opus-5': (5, 25, .5),
    'claude-opus-4-8': (5, 25, .5), 'claude-opus-4-7': (5, 25, .5), 'claude-opus-4-6': (5, 25, .5),
    'claude-sonnet-5-5': (2, 10, .2), 'claude-sonnet-5': (2, 10, .2), 'claude-sonnet-4-6': (3, 15, .3),
    'claude-haiku-4-5': (1, 5, .1),
}
def price(model):
    for k in sorted(PRICES, key=len, reverse=True):
        if model and model.startswith(k): return PRICES[k]
    return None

since = sys.argv[1] if len(sys.argv) > 1 else '2000'
root = os.path.expanduser('~/.claude/projects')
files = glob.glob(f'{root}/*/*.jsonl') + glob.glob(f'{root}/*/*/subagents/*.jsonl')

tot = collections.defaultdict(lambda: collections.Counter())   # model -> counters
cost = collections.Counter()                                   # billing type -> $
sessions = {}
tool_calls = collections.Counter(); tool_sessions = collections.defaultdict(set)
tool_err = collections.Counter(); tool_images = collections.Counter(); tool_result_chars = collections.Counter()
skills = collections.Counter(); attach = collections.Counter(); attach_chars = collections.Counter()
unknown = collections.Counter()
for f in files:
    sub = '/subagents/' in f
    sid = f.split('/')[-3] if sub else os.path.basename(f)[:-6]
    seen = set(); id2tool = {}
    s = sessions.setdefault(sid, dict(req=0, prompts=0, first=None, cost=0.0, sub_cost=0.0, start=None, models=set()))
    for line in open(f, errors='ignore'):
        try: d = json.loads(line)
        except Exception: continue
        ts = d.get('timestamp', '')
        if ts and ts < since: continue
        t = d.get('type')
        if t == 'attachment':
            a = d.get('attachment', {}); k = a.get('type', '?')
            attach[k] += 1; attach_chars[k] += len(json.dumps(a))
        if t == 'user' and not d.get('isMeta'):
            c = d['message'].get('content')
            if isinstance(c, str):
                if not sub: s['prompts'] += 1
            else:
                for b in c:
                    if b.get('type') == 'tool_result':
                        name = id2tool.get(b.get('tool_use_id'), '?')
                        cont = b.get('content'); cont = cont if isinstance(cont, list) else [{'type':'text','text':str(cont)}]
                        for x in cont:
                            if x.get('type') == 'image': tool_images[name] += 1
                            else: tool_result_chars[name] += len(x.get('text') or '')
                        if b.get('is_error'): tool_err[name] += 1
                    elif b.get('type') == 'text' and not sub and not b['text'].startswith('<'):
                        s['prompts'] += 1
        if t != 'assistant': continue
        m = d['message']; rid = d.get('requestId') or m.get('id')
        for b in m.get('content', []):
            if b.get('type') == 'tool_use':
                n = b['name']; id2tool[b['id']] = n; tool_calls[n] += 1; tool_sessions[n].add(sid)
                if n == 'Skill': skills[b['input'].get('skill')] += 1
        if rid in seen: continue
        seen.add(rid)
        u = m.get('usage') or {}; model = m.get('model')
        if model == '<synthetic>' or not u: continue
        p = price(model)
        if not p: unknown[model] += 1; continue
        cc = u.get('cache_creation') or {}
        w1h = cc.get('ephemeral_1h_input_tokens', 0); w5 = u.get('cache_creation_input_tokens', 0) - w1h
        c = dict(input=u.get('input_tokens', 0), w5=w5, w1h=w1h, read=u.get('cache_read_input_tokens', 0), output=u.get('output_tokens', 0))
        for k, v in c.items(): tot[model][k] += v
        tot[model]['req'] += 1
        dollars = dict(input=c['input']*p[0], w5=c['w5']*p[0]*1.25, w1h=c['w1h']*p[0]*2, read=c['read']*p[2], output=c['output']*p[1])
        for k, v in dollars.items(): cost[('sub' if sub else 'main', k)] += v/1e6
        total = sum(dollars.values())/1e6
        s['sub_cost' if sub else 'cost'] += total; s['models'].add(model)
        if not sub:
            s['req'] += 1
            if s['first'] is None: s['first'] = c['input'] + c['w5'] + c['w1h'] + c['read']; s['start'] = ts

S = [s for s in sessions.values() if s['req']]
grand = sum(cost.values())
print(f'sessions={len(S)} files={len(files)} since={since}  total=${grand:.2f}')
print('\n== tokens by model (M) ==')
for mo, c in sorted(tot.items(), key=lambda x: -x[1]['req']):
    allin = c['input'] + c['w5'] + c['w1h'] + c['read']
    print(f"{mo:22} req={c['req']:6} in={c['input']/1e6:7.2f} w5m={c['w5']/1e6:7.2f} w1h={c['w1h']/1e6:7.2f} read={c['read']/1e6:8.2f} out={c['output']/1e6:6.2f}  hit={c['read']/max(allin,1):.1%}")
print('\n== cost share by agent x billing type ==')
for k, v in sorted(cost.items(), key=lambda x: -x[1]): print(f'{k[0]:5} {k[1]:7} ${v:8.2f} {v/grand:6.1%}')
import statistics as st
print('\n== per session (main thread) ==')
for key in ('req', 'prompts', 'first'):
    vals = [s[key] for s in S]; print(f'{key:8} median={st.median(vals):8.0f} mean={st.mean(vals):9.0f} p90={sorted(vals)[int(.9*len(vals))]:8.0f}')
cs = [s['cost'] + s['sub_cost'] for s in S]
print(f"cost/session median=${st.median(cs):.2f} mean=${st.mean(cs):.2f}; per prompt mean=${sum(cs)/max(1,sum(s['prompts'] for s in S)):.3f}")
print(f"sessions using subagents: {sum(1 for s in S if s['sub_cost'])}/{len(S)}; subagent $ share {sum(s['sub_cost'] for s in S)/max(grand,1e-9):.1%}")
print('\n== tools: calls, %sessions, errors, result chars ==')
for n, k in tool_calls.most_common(40):
    print(f'{n:40} {k:6} {len(tool_sessions[n])/len(S):6.1%} err={tool_err[n]/k:5.1%} resultKtok~={tool_result_chars[n]/4e3:7.0f} imgs={tool_images[n]}')
print('\n== Skill invocations ==', skills.most_common(30))
print('\n== attachments (count, K chars) ==')
for k, v in attach.most_common(25): print(f'{k:35} {v:6} {attach_chars[k]/1e3:8.0f}')
if unknown: print('unpriced models', unknown)

# == cache writes by cause, and cache-read spend by context size ==
causes = collections.Counter(); buckets = collections.Counter()
for f in glob.glob(f'{root}/*/*.jsonl'):
    prev = None; seen = set(); compacted = False
    for line in open(f, errors='ignore'):
        try: d = json.loads(line)
        except Exception: continue
        if d.get('timestamp', '') < since: continue
        if d.get('type') == 'system' and d.get('subtype') == 'compact_boundary': compacted = True
        if d.get('type') != 'assistant': continue
        m = d['message']; rid = d.get('requestId') or m.get('id'); p = price(m.get('model'))
        if rid in seen or not p or not m.get('usage'): continue
        seen.add(rid); u = m['usage']
        ts = dt.datetime.fromisoformat(d['timestamp'].replace('Z', '+00:00'))
        w = u.get('cache_creation_input_tokens', 0); r = u.get('cache_read_input_tokens', 0)
        mult = 2 if (u.get('cache_creation') or {}).get('ephemeral_1h_input_tokens') else 1.25
        gap = (ts - prev[0]).total_seconds() if prev else 0
        c = ('first request' if prev is None else 'incremental <15k' if w < 15000 else 'after compaction' if compacted
             else 'model switch' if prev[1] != m['model'] else 'idle >1h' if gap > 3600 else 'idle 5-60m' if gap > 300
             else 'growth (big tool result)' if r >= prev[2] - 50 else 'prefix break <5m')
        causes[c] += w * p[0] * mult / 1e6; compacted = False
        ctx = r + w + u.get('input_tokens', 0)
        buckets['<100k' if ctx < 1e5 else '100-200k' if ctx < 2e5 else '200-400k' if ctx < 4e5 else '>400k'] += r * p[2] / 1e6
        prev = (ts, m['model'], ctx)
print('\n== cache-write $ by cause ==')
for k, v in causes.most_common(): print(f'{k:26} ${v:8.2f} {v/max(sum(causes.values()),1e-9):6.1%}')
print('\n== cache-read $ by context size ==')
for k in ('<100k', '100-200k', '200-400k', '>400k'): print(f'{k:10} ${buckets[k]:8.2f} {buckets[k]/max(sum(buckets.values()),1e-9):6.1%}')
