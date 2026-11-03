#!/usr/bin/env python3
"""Behavioral checks of the actual operations board JavaScript; no packages needed."""
import copy
import datetime as dt
import json
from pathlib import Path
import shutil
import subprocess
import sys
import unittest

TEMPLATE = Path(__file__).resolve().parent.parent / 'assets' / 'dashboard.html'
THREAD = '019b1170-8302-7000-8000-123456789abc'
WORKER_THREAD = '019b1170-8302-7000-8000-abcdefabcdef'


def fixture_board():
    now = dt.datetime.now(dt.timezone.utc)
    recent = now.isoformat()
    old = (now - dt.timedelta(minutes=12)).isoformat()
    tasks = {}
    titles = {'running': 'Validate the agent handoff', 'testing': 'Check browser acceptance', 'review': 'Review the frozen candidate'}
    for status in ['done', 'running', 'testing', 'review', 'blocked', 'failed', 'queued', 'cancelled']:
        tasks[status] = dict(id=status, title=titles.get(status, status.capitalize() + ' task'), status=status, owner='Ari / visibility', detail='Preserve exact candidate evidence and verify the native result.\nAll task details remain readable in the inspector.', evidence=['https://example.com/evidence'], updated=old if status in ('running', 'testing', 'review') else recent)
    context = dict(description='Qualify the file-only task board across themes, keyboard navigation and native agent recovery.', model='gpt-6.1-sol', effort='high', agent_id='visibility-worker', codex_thread_id=WORKER_THREAD, agent_url='https://example.com/verified-agent', worktree='/home/michel/projects/codex-playbook', command='python3 -B scripts/test_dashboard_ui.py', last_progress=old, next_checkpoint=recent, blocker='None reported', decision='Keep the native thread identity separate from its coordinator.')
    history = [dict(at=old, kind='session', data={'note': 'Preserved history event ' + str(i)}) for i in range(23)]
    history.append(dict(at=old, kind='task', data={**tasks['running'], 'agent_context': context}))
    active = dict(project='/home/michel/projects/codex-playbook', run='dashboard-redesign', session=THREAD, title='Operations board redesign', status='active', note='Runtime and source acceptance remain separate.', created=old, updated=recent, build='pending', review='pending', release='not_requested', tasks=tasks, history=history)
    idle = copy.deepcopy(active)
    idle.update(project='/home/michel/projects/archive-tools', session='archived-session', title='Retained completed session', status='completed', history=[], tasks={'done': copy.deepcopy(tasks['done'])})
    return dict(schema=1, revision=42, updated=recent, opened=None, sessions={'archived': idle, 'active': active})


def write_fixture(path):
    payload = json.dumps(fixture_board(), ensure_ascii=True).replace('&', '\\u0026').replace('<', '\\u003c').replace('>', '\\u003e')
    Path(path).write_text(TEMPLATE.read_text().replace('__STALE_SECONDS__', '600').replace('"__BOARD_JSON__"', payload))


@unittest.skipUnless(shutil.which('node'), 'UI checks require an available JavaScript runtime')
class DashboardUIBehavior(unittest.TestCase):
    def execute(self, javascript, data=None):
        source = TEMPLATE.read_text()
        helpers = source[source.index('function elapsedSeconds('):source.index('function node(')]
        script = 'const staleSeconds=600;\n' + helpers + '\nconst input=JSON.parse(require("node:fs").readFileSync(0,"utf8"));\n' + javascript
        result = subprocess.run([shutil.which('node'), '-e', script], input=json.dumps(data), text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_context_is_newest_snapshot_only_and_scoped_to_session(self):
        active = fixture_board()['sessions']['active']
        result = self.execute('''
const current=indexContext(input).get('running');
const missing=structuredClone(input);missing.history.push({kind:'task',data:{...input.tasks.running}});
const mismatch=structuredClone(input);mismatch.history.push({kind:'task',data:{...input.history.at(-1).data,owner:'Other owner'}});
const bad=structuredClone(input);bad.history.push({kind:'task',data:{...input.history.at(-1).data,agent_context:{agent_url:'javascript:alert(1)'}}});
const isolated=structuredClone(input);isolated.history=[];
console.log(JSON.stringify({current,missing:indexContext(missing).has('running'),mismatch:indexContext(mismatch).has('running'),bad:indexContext(bad).has('running'),isolated:indexContext(isolated).has('running')}));
''', active)
        self.assertEqual(result['current']['codex_thread_id'], WORKER_THREAD)
        for key in ('missing', 'mismatch', 'bad', 'isolated'):
            self.assertFalse(result[key], key)

    def test_all_core_fields_bind_context_and_partial_context_never_carries(self):
        result = self.execute('''
const rejected=[];
for(const field of ['id','title','status','owner','detail','evidence','updated']){const session=structuredClone(input);session.tasks.running[field]=field==='evidence'?['https://example.com/changed']:'changed';rejected.push(indexContext(session).size===0)}
const partial=structuredClone(input);partial.history.push({kind:'task',data:{...input.tasks.running,agent_context:{effort:'low'}}});
console.log(JSON.stringify({rejected,partial:indexContext(partial).get('running')}));
''', fixture_board()['sessions']['active'])
        self.assertTrue(all(result['rejected']))
        self.assertEqual(result['partial'], {'effort': 'low'})

    def test_project_task_order_filters_and_cancelled_counts(self):
        result = self.execute('''
const sessions=Object.values(input.sessions),projects=projectEntries(sessions),active=sessions.find(s=>s.status==='active'),records=taskRecords([active]);
console.log(JSON.stringify({projects:projects.map(p=>p.project),statuses:records.map(r=>r.task.status),active:filterRecords(records,'active','').length,attention:filterRecords(records,'attention','').length,search:filterRecords(records,'all','HANDOFF').map(r=>r.task.id),done:filterRecords(records,'done','').length,counts:taskCounts(records.map(r=>r.task)),keys:records.map(r=>r.key)}));
''', fixture_board())
        self.assertTrue(result['projects'][0].endswith('codex-playbook'))
        self.assertEqual(result['statuses'], ['running', 'testing', 'review', 'blocked', 'failed', 'queued', 'done', 'cancelled'])
        self.assertEqual((result['active'], result['attention'], result['done']), (3, 5, 1))
        self.assertEqual(result['search'], ['running'])
        self.assertEqual((result['counts']['total'], result['counts']['remaining'], result['counts']['cancelled']), (7, 6, 1))
        self.assertEqual(len(set(result['keys'])), 8)

    def test_unicode_context_limit_counts_codepoints_and_empty_board_is_supported(self):
        result = self.execute("console.log(JSON.stringify({within:validContext({description:'😀'.repeat(4000)}),over:validContext({description:'😀'.repeat(4001)}),projects:projectEntries([]),tasks:taskRecords([]),counts:taskCounts([])}));")
        self.assertTrue(result['within'])
        self.assertFalse(result['over'])
        self.assertEqual(result['projects'], [])
        self.assertEqual(result['tasks'], [])
        self.assertEqual(result['counts']['total'], 0)
        self.assertEqual(result['counts']['remaining'], 0)

    def test_agent_urls_threads_and_context_are_validated_without_inference(self):
        result = self.execute(r'''
const urls=['https://example.com/agent','https://user:pass@example.com/agent','javascript:alert(1)','http://example.com/agent','https://example.com/a b','https:example.com','https://@example.com','https:\\example.com'];
console.log(JSON.stringify({urls:urls.map(u=>safeURL(u,true)),threads:[validThread(input),validThread('arbitrary-agent'),validThread(input.toUpperCase())],contexts:[validContext({description:'<script>alert(1)</script>'}),validContext({agent_url:'https://user:pass@example.com'}),validContext({codex_thread_id:'not-a-thread'}),validContext({last_progress:'tomorrow'}),validContext({last_progress:'2026-11-03T12:00:00Z'}),validContext({model:3}),validContext({unknown:'value'}),validContext({last_progress:'2026-02-30T12:00:00Z'})]}));
''', THREAD)
        self.assertIsNotNone(result['urls'][0])
        self.assertTrue(all(value is None for value in result['urls'][1:]))
        self.assertEqual(result['threads'], [True, False, False])
        self.assertEqual(result['contexts'], [True, False, False, False, True, False, False, False])


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--fixture':
        write_fixture(sys.argv[2])
        print(sys.argv[2])
    else:
        unittest.main(verbosity=2)
