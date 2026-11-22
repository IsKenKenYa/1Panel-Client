"""Behavioral regressions: event isolation, symbol provenance and stack clustering."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from itertools import product

SCRIPTS = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(SCRIPTS))
from sample_stack_analyzer import SampleStackAnalyzer
from freeze.main import build_report
from freeze.collector import collect_logs

# Deterministic synthetic ELF BuildID; no credentials are used by these tests.
BUILD = bytes(range(16)).hex()
MODULE = '/data/storage/el1/bundle/libs/arm64/libdemo.so'
SYMBOL = 'Demo::Work(std::vector<int> const&)+16'


def frame(pc='0000ABCD', symbol='', build=BUILD, module=MODULE):
    return f'#00 pc {pc} {module}' + (f'({symbol})' if symbol else '') + (f'({build})' if build else '')


def fault_text(frames, uid='2001', pid='42', tid='42', module='com.example.app',
               fault='2026/09/22-10:00:01', report='2026/09/22-10:00:04:501'):
    return f'''Module name:{module}
Pid:{pid}
Uid:{uid}
Reason:THREAD_BLOCK_6S
TIMESTAMP:{report}
*******************************************
start time: 2026/09/22-10:00:04:501
EVENTNAME = THREAD_BLOCK_6S
TIMESTAMP = {report}
PID = {pid}
UID = {uid}
TID = {tid}
PROCESS_NAME = {module}
MSG =
Fault time:{fault}
thread blocked
Tid:{tid}, Name:{module}
{chr(10).join(frames)}
Catche stack trace end time:
'''


def sample_text(stacks, tid='42', module='com.example.app', timestamp='2026-09-22 10:00:04.500'):
    result = f'''TimeStamp: {timestamp}
Module name: {module}
#Basic Statistical Infomation
Tid: {tid}
StartTime: 2026-09-22 10:00:01:500
EndTime: 2026-09-22 10:00:04:500
StaticsDuration: 3000 ms
CpuTime: 300 ms
#CpuFreq Usage
cpu0 Usage 10.00%
#ThreadInfos Tid: {tid}, Name: {module}
'''
    for i, stack in enumerate(stacks):
        result += f'SnapshotTime:2026-09-22-10-00-0{2 + i}.000000\n' + '\n'.join(stack) + '\n'
    return result


class AlignmentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.sample = self.root / 'freeze-cpuinfo-ext-com.example.app-2001-20260922100015'
        self.fault = self.root / 'appfreeze-com.example.app-2001-20260922100004.log'

    def write(self, sample=None, fault=None):
        self.sample.write_text(sample if sample is not None else sample_text([[frame()]]))
        self.fault.write_text(fault if fault is not None else fault_text([frame(symbol=SYMBOL)]))

    def run_analysis(self, paths=None):
        return SampleStackAnalyzer().build(str(self.sample), paths).analyze()

    def test_fill_preserves_original_and_exact_source_location(self):
        self.write()
        before = self.sample.read_bytes(), self.fault.read_bytes()
        result = self.run_analysis()
        aligned = result['symbol_alignment']['frames'][0]
        self.assertEqual(aligned['status'], 'filled')
        self.assertEqual(aligned['pc'], '0xabcd')
        self.assertEqual(aligned['original_symbol'], '')
        self.assertEqual(aligned['aligned_symbol'], SYMBOL)
        self.assertEqual(aligned['raw'], frame())
        source = aligned['sources'][0]
        self.assertEqual(source['path'], str(self.fault))
        self.assertEqual(self.fault.read_text().splitlines()[source['line'] - 1], source['raw'])
        self.assertEqual(self.sample.read_text().splitlines()[aligned['line'] - 1], aligned['raw'])
        self.assertEqual(before, (self.sample.read_bytes(), self.fault.read_bytes()))

    def test_replace_cpuinfo_export_symbol_and_cluster_after_alignment(self):
        self.write(sample_text([[frame(symbol='NearestExport+4096')], [frame()]]))
        result = self.run_analysis()
        self.assertEqual(result['symbol_alignment']['counts']['replaced'], 1)
        self.assertEqual(result['symbol_alignment']['counts']['filled'], 1)
        self.assertEqual(len(result['stack_clusters']), 1)
        self.assertEqual(result['stack_clusters'][0]['count'], 2)
        self.assertEqual(result['parent_node_stats'][0]['count'], 2)
        self.assertIn(SYMBOL, result['stack_clusters'][0]['stack'][0])
        self.assertEqual(result['snapshot_details'][0]['frames'][0]['original_symbol'], 'NearestExport+4096')

    def test_full_stack_not_just_parent_is_clustered(self):
        parent = '#01 at parent (entry/src/main/ets/Index.ets:1:1)'
        self.write(sample_text([[frame(), parent], [frame(pc='abcd'), parent],
                                [frame(pc='abcd'), '#01 at other (entry/src/main/ets/Index.ets:2:1)']]))
        result = self.run_analysis()
        self.assertEqual([item['count'] for item in result['stack_clusters']], [2, 1])

    def test_system_frames_are_aligned_and_used_in_full_stack_clusters(self):
        module = '/system/lib64/libsystem.so'
        self.write(sample_text([[frame(module=module)]]), fault_text([frame(module=module, symbol=SYMBOL)]))
        result = self.run_analysis()
        self.assertEqual(result['parent_node_stats'], [])
        self.assertIn(SYMBOL, result['stack_clusters'][0]['stack'][0])

    def test_normalized_pc_and_buildid(self):
        self.write(sample_text([[frame(pc='0x0000abcd', build=BUILD.upper())]]))
        self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 1)

    def test_exact_identity_required(self):
        for changes in ({'pc': 'abce'}, {'module': '/other/libdemo.so'},
                        {'build': 'f' * 32}, {'build': ''}):
            with self.subTest(changes=changes):
                self.write(sample_text([[frame(**changes)]]))
                self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 0)
        self.write(fault=fault_text([frame(symbol=SYMBOL, build='')]))
        self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 0)

    def test_conflicting_donors_do_not_override_sample(self):
        self.write(sample_text([[frame(symbol='Original+4')]]))
        other = self.root / 'sysfreeze-com.example.app-2001-20260922100004.log'
        other.write_text(fault_text([frame(symbol='Conflict+8')]))
        result = self.run_analysis()
        self.assertEqual(result['symbol_alignment']['counts']['conflict'], 1)
        aligned = result['symbol_alignment']['frames'][0]
        self.assertEqual(aligned['aligned_symbol'], '')
        self.assertEqual(len(aligned['sources']), 2)
        self.assertIn('Original+4', result['stack_clusters'][0]['stack'][0])

    def test_sysfreeze_only_and_consistent_duplicate_sources(self):
        self.write()
        other = self.root / 'sysfreeze-com.example.app-2001-20260922100004.log'
        other.write_bytes(self.fault.read_bytes())
        result = self.run_analysis()
        self.assertEqual(len(result['symbol_alignment']['matched_faultlogs']), 2)
        self.assertEqual(len(result['symbol_alignment']['frames'][0]['sources']), 2)
        self.fault.unlink()
        self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 1)

    def test_different_event_identity_or_time_rejected_even_explicit(self):
        for changes in ({'uid': '2002'}, {'tid': '99'}, {'module': 'other.app'},
                        {'fault': '2026/09/22-09:59:01'}, {'report': '2026/09/22-10:00:10:500'},
                        {'fault': ''}):
            with self.subTest(changes=changes):
                self.write(fault=fault_text([frame(symbol=SYMBOL)], **changes))
                result = self.run_analysis([self.fault])
                self.assertEqual(result['symbol_alignment']['status'], 'no_matching_event')
                self.assertEqual(result['symbol_alignment']['counts']['filled'], 0)
                self.assertTrue(result['symbol_alignment']['rejected_faultlogs'][0]['reason'])

    def test_ambiguous_overlapping_events_rejected(self):
        self.write(sample=sample_text([[frame()]], timestamp=''))
        other = self.root / 'sysfreeze-com.example.app-2001-20260922100005.log'
        other.write_text(fault_text([frame(symbol=SYMBOL)], fault='2026/09/22-10:00:02'))
        result = self.run_analysis()
        self.assertEqual(result['symbol_alignment']['status'], 'ambiguous_event')
        self.assertEqual(result['symbol_alignment']['counts']['filled'], 0)
        self.assertEqual(result['symbol_alignment']['matched_faultlogs'], [])

    def test_missing_metadata_and_sample_filename_conflict(self):
        for sample in (sample_text([[frame()]]).replace('StartTime:', 'Unknown:'),
                       sample_text([[frame()]]).replace('com.example.app', 'other.app'),
                       sample_text([[frame()]]).replace('Module name:', 'Pid: 99\nModule name:')):
            with self.subTest(sample=sample):
                self.write(sample=sample)
                self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 0)

    def test_precise_fault_time_is_not_expanded_to_a_whole_second(self):
        self.write(fault=fault_text([frame(symbol=SYMBOL)], fault='2026/09/22-10:00:01:100'))
        self.assertEqual(self.run_analysis()['symbol_alignment']['status'], 'no_matching_event')

    def test_missing_buildid_or_unknown_donor_is_not_a_symbol(self):
        for symbol in ('??', 'unknown+0', '<unknown>'):
            self.write(fault=fault_text([frame(symbol=symbol)]))
            self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 0)

    def test_header_event_identity_conflict_is_rejected(self):
        self.write(fault=fault_text([frame(symbol=SYMBOL)]).replace('PID = 42', 'PID = 99'))
        self.assertEqual(self.run_analysis()['symbol_alignment']['status'], 'no_matching_event')
        self.write(sample=sample_text([[frame()]]).replace('\nTid: 42', '\nTid: 99'))
        self.assertEqual(self.run_analysis()['symbol_alignment']['status'], 'no_matching_event')

    def test_alignment_audit_contains_event_evidence(self):
        self.write()
        audit = self.run_analysis()['symbol_alignment']
        self.assertEqual(audit['sample_event']['start'], '2026-09-22T10:00:01.500000')
        self.assertEqual(audit['matched_events'][0]['identity']['pid'], '42')
        self.assertEqual(audit['matched_events'][0]['identity']['faults'], ['2026-09-22T10:00:01'])

    def test_missing_symbols_keep_distinct_pcs_and_builds_in_clusters(self):
        self.write(sample_text([[frame(pc='1')], [frame(pc='2')], [frame(pc='1', build='f' * 32)]]))
        result = self.run_analysis([])
        self.assertEqual(len(result['stack_clusters']), 3)
        self.assertTrue(all(item['count'] == 1 for item in result['stack_clusters']))

    def test_unknown_sample_symbols_keep_distinct_addresses(self):
        self.write(sample_text([[frame(pc='1', symbol='??')], [frame(pc='2', symbol='??')]]))
        result = self.run_analysis([])
        self.assertEqual(len(result['stack_clusters']), 2)
        self.assertEqual(result['symbol_alignment']['frames'][0]['original_symbol'], '??')
        self.assertIn('pc 0x1', result['stack_clusters'][0]['stack'][0])

    def test_no_faultlog_keeps_legacy_input_usable(self):
        self.write()
        self.fault.unlink()
        result = self.run_analysis()
        self.assertEqual(result['symbol_alignment']['status'], 'no_matching_event')
        self.assertEqual(result['basic_info']['snapshot_count'], 1)
        self.assertIn('pc 0xabcd', result['stack_clusters'][0]['stack'][0])

    def test_binder_peer_symbols_are_not_donors(self):
        self.write(fault=fault_text([frame()]) + 'Tid:77, Name:peer\n' + frame(symbol=SYMBOL) + '\n')
        self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 0)

    def test_block_source_lines_and_identical_peer_frame_provenance(self):
        warning = fault_text([frame()])
        block = fault_text([frame(symbol=SYMBOL)]).split('*******************************************\n', 1)[1]
        self.write(fault=warning + '*******************************************\n' + block
                   + 'Tid:77, Name:peer\n' + frame(symbol=SYMBOL) + '\n')
        aligned = self.run_analysis()['symbol_alignment']['frames'][0]
        self.assertEqual(aligned['status'], 'filled')
        self.assertEqual(len(aligned['sources']), 1)
        source = aligned['sources'][0]
        self.assertEqual(self.fault.read_text().splitlines()[source['line'] - 1], source['raw'])
        self.assertGreater(source['line'], len(warning.splitlines()))

    def test_attachment_report_routes_to_alignment(self):
        self.write()
        report = build_report(str(self.root), 'attachments')
        self.assertNotIn('--faultlogs', report)
        self.assertIn('自动发现', report)
        self.assertIn(str(self.root), report)

    def test_original_cli_automatically_aligns_without_extra_arguments(self):
        self.write()
        command = [sys.executable, str(SCRIPTS / 'sample_stack_analyzer.py'), str(self.sample)]
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        self.assertIn('Aligned Full Stack Clusters', result.stdout)
        self.assertIn(str(self.fault), result.stdout)
        self.assertIn('Original:', result.stdout)
        self.assertIn("'filled': 1", result.stdout)
        help_result = subprocess.run(command[:2] + ['--help'], capture_output=True, text=True, check=True)
        self.assertNotIn('--faultlogs', help_result.stdout)
        self.assertNotIn('--json', help_result.stdout)

    def test_automatic_discovery_in_sibling_faultlogger_and_parent(self):
        self.write()
        samples = self.root / 'freeze_ext'
        samples.mkdir()
        self.sample = self.sample.rename(samples / self.sample.name)
        # A containing bundle can place the faultlog beside freeze_ext.
        self.assertEqual(self.run_analysis()['symbol_alignment']['counts']['filled'], 1)
        faults = self.root / 'faultlogger'
        faults.mkdir()
        self.fault = self.fault.rename(faults / self.fault.name)
        result = self.run_analysis()
        self.assertEqual(result['symbol_alignment']['matched_faultlogs'], [str(self.fault)])
        self.assertEqual(result['symbol_alignment']['counts']['filled'], 1)
        command = [sys.executable, str(SCRIPTS / 'sample_stack_analyzer.py'), str(self.sample)]
        result = subprocess.run(command, cwd=self.root.parent, capture_output=True, text=True, check=True)
        self.assertIn("'filled': 1", result.stdout)

    def test_automatic_discovery_does_not_scan_unrelated_siblings(self):
        self.write()
        unrelated = self.root.parent / (self.root.name + '-unrelated')
        unrelated.mkdir()
        self.addCleanup(unrelated.rmdir)
        other = unrelated / 'sysfreeze-com.example.app-2001-20260922100004.log'
        other.write_text(fault_text([frame(symbol='Conflict+8')]))
        self.addCleanup(other.unlink)
        result = self.run_analysis()
        self.assertEqual(result['symbol_alignment']['counts']['filled'], 1)
        self.assertEqual(result['symbol_alignment']['counts']['conflict'], 0)

    def test_multi_thread_or_duplicate_snapshot_does_not_silently_mix(self):
        for suffix in ('#ThreadInfos Tid: 99, Name:worker\n',
                       'SnapshotTime:2026-09-22-10-00-02.000000\n' + frame()):
            self.write(sample_text([[frame()]]) + suffix)
            with self.assertRaises(ValueError):
                self.run_analysis()

    def embedded_log(self, sample=None, marker=True):
        # HiAppEvent names differ from faultlogger names and require sniffing.
        self.fault = self.root / 'APP_FREEZE_1790060074589_42.log'
        # Keep the literal platform log field required for content detection.
        text = fault_text([frame(symbol=SYMBOL)]).replace(
            'MSG =', 'eventLog_action = t\nMSG =')
        text += ('==========FREEZE_EXT_INFO==========\n' if marker else '')
        text += sample if sample is not None else sample_text(
            [[frame(symbol='NearestExport+4096')], [frame()]])
        self.fault.write_text(text)
        return text

    def test_embedded_discovery_alignment_and_clustering_preserve_original_lines(self):
        original = self.embedded_log()
        for path in (self.fault, self.root):
            collected = collect_logs(path)
            self.assertEqual(collected.faultlogs, [self.fault])
            self.assertEqual(collected.sample_stacks, [self.fault])
            self.assertIn('采样栈 1 个', build_report(str(path), 'overview'))
            self.assertIn(str(self.fault), build_report(str(path), 'attachments'))
        result = SampleStackAnalyzer().build(str(self.fault)).analyze()
        self.assertEqual(result['basic_info']['snapshot_count'], 2)
        self.assertEqual(result['symbol_alignment']['status'], 'matched')
        self.assertEqual(result['symbol_alignment']['counts']['filled'], 1)
        self.assertEqual(result['symbol_alignment']['counts']['replaced'], 1)
        self.assertEqual(len(result['stack_clusters']), 1)
        self.assertEqual(result['stack_clusters'][0]['count'], 2)
        for aligned in result['symbol_alignment']['frames']:
            self.assertEqual(original.splitlines()[aligned['line'] - 1], aligned['raw'])
            for source in aligned['sources']:
                self.assertEqual(source['path'], str(self.fault))
                self.assertEqual(original.splitlines()[source['line'] - 1], source['raw'])
                self.assertLess(source['line'], aligned['line'])
        self.assertEqual(original, self.fault.read_text())

    def test_embedded_statistics_without_ext_marker(self):
        self.embedded_log(marker=False)
        result = SampleStackAnalyzer().build(str(self.fault)).analyze()
        self.assertEqual(result['symbol_alignment']['status'], 'matched')
        self.assertEqual(result['symbol_alignment']['counts']['filled'], 1)

    def test_embedded_true_identity_conflicts_and_bad_time_remain_rejected(self):
        base = sample_text([[frame()]])
        for text in (base.replace('Tid: 42', 'Tid: 99', 1),
                     base.replace('com.example.app', 'other.app'),
                     base.replace('Module name:', 'Uid: 999\nModule name:'),
                     base.replace('Module name:', 'Pid: 99\nModule name:'),
                     base.replace('StartTime:', 'MissingStartTime:'),
                     base.replace('TimeStamp: 2026-09-22 10:00:04.500',
                                  'TimeStamp: 2026-09-22 10:01:04.500')):
            with self.subTest(text=text):
                self.embedded_log(text)
                audit = SampleStackAnalyzer().build(str(self.fault)).analyze()['symbol_alignment']
                self.assertEqual(audit['status'], 'no_matching_event')
                self.assertEqual(audit['counts']['filled'], 0)

    def test_faultlog_without_snapshots_is_not_a_sample_source(self):
        self.fault.write_text(fault_text([frame(symbol=SYMBOL)])
                              + '==========FREEZE_EXT_INFO==========\n'
                              + '#ThreadInfos Tid: 42, Name: com.example.app\n')
        self.assertEqual(collect_logs(self.fault).sample_stacks, [])

    def test_embedded_existing_cli_uses_complete_faultlog(self):
        self.embedded_log()
        result = subprocess.run([sys.executable, str(SCRIPTS / 'sample_stack_analyzer.py'),
                                 str(self.fault)], capture_output=True, text=True, check=True)
        self.assertIn("'filled': 1", result.stdout)
        self.assertIn("'replaced': 1", result.stdout)
        self.assertIn('Aligned Full Stack Clusters', result.stdout)

    def test_submitter_tail_does_not_change_sample_analysis(self):
        markers = ('SubmitterStacktrace:', '  SubmitterStacktrace:  ',
                   'SubmitterStacktrace', '========SubmitterStacktrace========')
        for embedded, marker in product((False, True), markers):
            with self.subTest(embedded=embedded, marker=marker):
                if embedded:
                    self.embedded_log()
                    path = self.fault
                else:
                    self.write(sample_text([[frame()], [frame()]]))
                    path = self.sample
                baseline = SampleStackAnalyzer().build(str(path)).analyze()
                # Both native and JS submitter frames must be excluded from
                # alignment, full-stack clusters and business-parent stats.
                with path.open('a') as stream:
                    stream.write('\n' + marker + '\n' + frame() + '\n'
                                 '#01 at submitWork (entry/src/main/ets/Submit.ets:1:1)\n')
                original = path.read_bytes()
                actual = SampleStackAnalyzer().build(str(path)).analyze()
                self.assertEqual(len(actual['snapshot_details'][-1]['submitter_frames']), 2)
                for snapshot in actual['snapshot_details']:
                    self.assert_submitter_sources(snapshot['submitter_frames'], original, path)
                    snapshot['submitter_frames'] = []
                self.assertEqual(actual, baseline)
                self.assertEqual(path.read_bytes(), original)

    def assert_submitter_sources(self, frames, original, path):
        for submitted in frames:
            self.assertEqual(original.decode().splitlines(keepends=True)[submitted['source_line'] - 1],
                             submitted['raw'])
            self.assertEqual(submitted['source_path'], str(path))
            self.assertEqual(submitted['aligned_symbol'], '')

    def test_each_snapshot_stops_at_submitter_and_next_snapshot_is_retained(self):
        for embedded in (False, True):
            with self.subTest(embedded=embedded):
                clean = sample_text([[frame()], [frame()]])
                if embedded:
                    self.embedded_log(clean)
                    path = self.fault
                else:
                    self.write(clean)
                    path = self.sample
                baseline = SampleStackAnalyzer().build(str(path)).analyze()
                original = path.read_text().replace(
                    frame() + '\n', frame() + '\n========SubmitterStacktrace========\n'
                    + frame(symbol='SubmitterOnly+4') + '\n'
                    '#01 at submitWork (entry/src/main/ets/Submit.ets:1:1)\n')
                path.write_text(original)
                result = SampleStackAnalyzer().build(str(path)).analyze()
                self.assertEqual(result['basic_info']['snapshot_count'], 2)
                self.assertEqual(result['stack_clusters'], baseline['stack_clusters'])
                self.assertEqual(result['parent_node_stats'], baseline['parent_node_stats'])
                self.assertEqual(result['symbol_alignment']['counts'], baseline['symbol_alignment']['counts'])
                self.assertEqual([len(s['frames']) for s in result['snapshot_details']], [1, 1])
                self.assertEqual([len(s['submitter_frames']) for s in result['snapshot_details']], [2, 2])
                for aligned in result['symbol_alignment']['frames']:
                    self.assertEqual(original.splitlines()[aligned['line'] - 1], aligned['raw'])
                self.assertEqual(path.read_text(), original)

    def test_submitter_in_fault_body_or_symbol_does_not_cut_later_samples(self):
        original = self.embedded_log(sample_text([[frame(symbol='SubmitterStacktrace+4')]]))
        self.fault.write_text(original.replace('Catche stack trace end time:',
                                              'SubmitterStacktrace:\nCatche stack trace end time:'))
        result = SampleStackAnalyzer().build(str(self.fault)).analyze()
        self.assertEqual(collect_logs(self.fault).sample_stacks, [self.fault])
        self.assertEqual(result['basic_info']['snapshot_count'], 1)
        self.assertEqual(result['symbol_alignment']['counts']['replaced'], 1)

    def test_execution_and_submitter_stop_at_thread_or_snapshot_boundary(self):
        for boundary in ('Tid:99, Name:other', '#ThreadInfos Tid: 42, Name:other',
                         'SnapshotEnd', 'EndSnapshot', '========OtherSection========',
                         'Catche stack trace end time:'):
            for has_submitter in (False, True):
                with self.subTest(boundary=boundary, submitter=has_submitter):
                    current = '#00 at running (entry/src/main/ets/Run.ets:1:1)'
                    submitter = '#00 at hasPermission (entry/src/main/ets/Permission.ets:1:1)'
                    tail = (['========SubmitterStacktrace========', submitter]
                            if has_submitter else [])
                    lines = sample_text([[current] + tail + [boundary, frame()], [current]])
                    analyzer = SampleStackAnalyzer()
                    analyzer.build_time_stack(lines.splitlines(keepends=True))
                    self.assertEqual([len(s) for s in analyzer.time_stack_dict.values()], [1, 1])
                    self.assertEqual([len(s) for s in analyzer.submitter_stack_dict.values()],
                                     [int(has_submitter), 0])
                    self.write(lines)
                    result = self.run_analysis()
                    self.assertEqual([len(s['frames']) for s in result['snapshot_details']], [1, 1])
                    self.assertEqual([len(s['submitter_frames']) for s in result['snapshot_details']],
                                     [int(has_submitter), 0])

    def test_review_permission_submitter_is_context_not_execution_hotspot(self):
        # Synthetic reproduction of the review's two distinct execution/origin chains.
        current = ['#00 at doSendToRender (entry/src/main/ets/Render.ets:1:1)',
                   '#01 at notifyAnimationRepeat (entry/src/main/ets/Lottie.ets:2:1)']
        origin = ['========SubmitterStacktrace========', frame(),
                  '#01 at hasPermission (entry/src/main/ets/PermissionUtils.ts:25:1)']
        for embedded in (False, True):
            with self.subTest(embedded=embedded):
                text = sample_text([current + origin, current])
                if embedded:
                    self.embedded_log(text)
                    path = self.fault
                else:
                    self.write(text)
                    path = self.sample
                result = SampleStackAnalyzer().build(str(path)).analyze()
                self.assertEqual(len(result['symbol_alignment']['frames']), 4)
                self.assertEqual(result['symbol_alignment']['counts']['filled'], 0)
                self.assertTrue(all(f['pc'] is None for f in result['symbol_alignment']['frames']))
                self.assertEqual(len(result['stack_clusters']), 1)
                self.assertEqual(result['stack_clusters'][0]['count'], 2)
                self.assertIn('notifyAnimationRepeat', result['parent_node_stats'][0]['parent_node'])
                self.assertEqual(result['parent_node_stats'][0]['count'], 2)
                first, second = result['snapshot_details']
                self.assertEqual(len(first['submitter_frames']), 2)
                self.assertEqual(first['submitter_frames'][0]['aligned_symbol'], '')
                self.assertEqual(second['submitter_frames'], [])
                out = subprocess.run([sys.executable, str(SCRIPTS / 'sample_stack_analyzer.py'),
                                      str(path)], capture_output=True, text=True, check=True).stdout
                execution, context = out.split('[Async Submission Context — not sampled execution]')
                self.assertNotIn('hasPermission', execution)
                self.assertIn('hasPermission', context)
                self.assertIn('不参与', context)


if __name__ == '__main__':
    unittest.main()
