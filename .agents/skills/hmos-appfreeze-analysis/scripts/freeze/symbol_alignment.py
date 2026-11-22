# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Associate a cpuinfo sample with one freeze event, then align exact native PCs.

No ELF lookup or symbol-range inference. Ambiguous events and conflicting donor
symbols remain unresolved, with the evidence available in the result.
"""

import re
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

from freeze.collector import collect_logs
from freeze.common import parse_time, read_lines
from freeze.faultlog import parse_freeze_log

_NAME = re.compile(r"^(?:freeze-cpuinfo-ext|appfreeze|sysfreeze)-(.+)-(\d+)-(\d+)(?:\.log|\.txt)?$")


def _field(lines, name):
    pattern = re.compile(rf'^{re.escape(name)}\s*[:=]\s*(.*?)\s*$')
    return next((m.group(1) for line in lines if (m := pattern.match(line.strip()))), '')


def _sample_headers(lines):
    header = []
    for line in lines:
        if line.startswith('#ThreadInfos'):
            break
        header.append(line)
    # A merged faultlog contains ordinary 'Tid:42, Name:...' thread headers
    # before FREEZE_EXT_INFO. They are not the sampling metadata's numeric Tid.
    # Scope sampling fields to the appended section; only process identity may
    # fall back to the outer fault header (never to event/stack body fields).
    outer_header = []
    boundaries = [i + 1 for i, line in enumerate(header)
                  if re.match(r'^=+FREEZE_EXT_INFO=+\s*$', line)]
    if not boundaries:
        statistics = [i for i, line in enumerate(header) if line.startswith('#Basic Statistical')]
        if statistics:
            times = [i for i, line in enumerate(header[:statistics[-1]])
                     if line.startswith('TimeStamp:')]
            boundaries = [times[-1] if times else statistics[-1]]
    if boundaries:
        prefix = header[:boundaries[-1]]
        for line in prefix:
            if re.match(r'^\*{3,}', line) or re.match(r'^Tid:', line):
                break
            outer_header.append(line)
        header = header[boundaries[-1]:]
    return header, outer_header


def _process_identity(header):
    return dict(module=_field(header, 'Module name'),
                uid=_field(header, 'Uid') or _field(header, 'UID'),
                pid=_field(header, 'Pid') or _field(header, 'PID'))


def _sample_identity(path, lines):
    header, outer_header = _sample_headers(lines)
    tids = set(re.findall(r'^#ThreadInfos Tid:\s*(\d+)', ''.join(lines), re.M))
    tid = next(iter(tids)) if len(tids) == 1 else _field(header, 'Tid') if not tids else ''
    identity = _process_identity(header)
    outer_identity = _process_identity(outer_header)
    error = ''
    if _field(header, 'Tid') and tid != _field(header, 'Tid'):
        error = 'sample header and stack TID conflict'
    for key, value in identity.items():
        outer = outer_identity[key]
        if value and outer and value != outer:
            error = 'sample and outer header identity conflict: ' + key
        identity[key] = value or outer
    name = _NAME.match(Path(path).name)
    if name:
        if ((identity['module'] and identity['module'] != name[1])
                or (identity['uid'] and identity['uid'] != name[2])):
            error = 'sample filename and header identity conflict'
        identity['module'] = identity['module'] or name[1]
        identity['uid'] = identity['uid'] or name[2]
    return dict(identity,
                tid=tid, start=parse_time(_field(header, 'StartTime')),
                end=parse_time(_field(header, 'EndTime')),
                timestamp=parse_time(_field(header, 'TimeStamp')),
                error=error)


def _time_end(value):
    """Exclusive end of a timestamp's precision bucket (seconds or fraction)."""
    start = parse_time(value)
    if not start:
        return None
    match = re.search(r'\d{2}:\d{2}:\d{2}[.:](\d{1,6})$', value)
    if not match:
        match = re.search(r'\d{2}-\d{2}-\d{2}\.(\d{1,6})$', value)
    return start + timedelta(microseconds=10 ** (6 - len(match[1])) if match else 1000000)


def _fault_identity(freeze, lines):
    header = []
    for line in lines:
        if re.match(r'^\*{3,}', line):
            break
        header.append(line)
    parts = [freeze.warning] + ([freeze.block] if freeze.block else [])
    # Fault time may be second precision; do not substitute catch/export times.
    faults = [parse_time(part.msg.fault_time) for part in parts]
    faults = [time for time in faults if time]
    fault_ends = [_time_end(part.msg.fault_time) for part in parts]
    fault_ends = [time for time in fault_ends if time]
    error = ''
    for key in ('pid', 'uid'):
        values = {getattr(part.msg, key) for part in parts if getattr(part.msg, key)}
        if getattr(freeze.header, key):
            values.add(getattr(freeze.header, key))
        if len(values) > 1:
            error = 'fault header and event identity conflict: ' + key
    return dict(module=freeze.process_name, uid=freeze.header.uid or freeze.warning.msg.uid,
                pid=freeze.pid, tid=freeze.fault_tid(),
                timestamp=parse_time(_field(header, 'TIMESTAMP')), faults=faults,
                fault_ends=fault_ends, reason=freeze.reason, error=error,
                fingerprint=_field(header, 'Fingerprint'), build=freeze.header.build_version)


def _association(sample, fault):
    if sample['error']:
        return sample['error']
    if fault['error']:
        return fault['error']
    if not fault['pid']:
        return 'missing event identity: pid'
    for key in ('module', 'uid', 'tid'):
        if not sample[key] or not fault[key]:
            return 'missing event identity: ' + key
        if sample[key] != fault[key]:
            return 'event identity mismatch: ' + key
    if sample['pid'] and sample['pid'] != fault['pid']:
        return 'event identity mismatch: pid'
    start, end = sample['start'], sample['end']
    if not start or not end or start > end:
        return 'missing or invalid sample interval'
    if not fault['faults']:
        return 'missing fault time'
    # A second-precision Fault time denotes that whole second. Overlap the
    # warning-to-block interval with the sample window, never filename time.
    if end < min(fault['faults']) or start >= max(fault['fault_ends']):
        return 'fault interval does not overlap sample interval'
    if sample['timestamp']:
        if not fault['timestamp']:
            return 'missing fault report timestamp'
        # cpuinfo and faultlog headers are emitted separately (usually ms apart).
        if abs((sample['timestamp'] - fault['timestamp']).total_seconds()) > 1:
            return 'report timestamps differ by more than 1 second'
    return ''


def _event_key(fault):
    # Duplicate appfreeze/sysfreeze exports can share this identity. Different
    # onsets, PIDs or reasons are not silently merged even if both overlap.
    return (fault['module'], fault['uid'], fault['pid'], fault['tid'],
            fault['reason'], min(fault['faults']), fault['fingerprint'], fault['build'])


def _json_identity(identity):
    def convert(value):
        if isinstance(value, datetime):
            return value.isoformat()
        if isinstance(value, list):
            return [convert(item) for item in value]
        return value
    return {key: convert(value) for key, value in identity.items()}


def _discover_faultlogs(sample_path):
    """Search the supplied log layout, without recursively scanning ancestors."""
    directory = sample_path.parent
    candidates = {path.resolve() for path in collect_logs(directory).faultlogs}
    parent = directory.parent
    # Exports commonly separate freeze_ext from faultlogger. Also accept
    # faultlogs directly in the containing log bundle.
    for path in parent.iterdir():
        if path.is_file() and path.name.startswith(('appfreeze-', 'sysfreeze-')):
            candidates.add(path.resolve())
        elif path.is_dir() and path.name in ('faultlogger', 'faultlog', 'faultlogs'):
            if path.resolve() != directory:
                candidates.update(item.resolve() for item in collect_logs(path).faultlogs)
    return candidates


def _match_faultlogs(sample, candidates, audit):
    """Reject incompatible or ambiguous events before indexing any symbols."""
    matches = []
    for path in sorted(candidates):
        try:
            freeze = parse_freeze_log(path)
            source_lines = read_lines(path)
            identity = _fault_identity(freeze, source_lines)
            reason = _association(sample, identity)
            if reason:
                audit['rejected_faultlogs'].append(dict(path=str(path), reason=reason))
            else:
                matches.append((path, freeze, identity))
        except (ValueError, OSError) as err:
            audit['rejected_faultlogs'].append(dict(path=str(path), reason=str(err)))
    groups = {_event_key(item[2]) for item in matches}
    if len(groups) > 1:
        audit['status'] = 'ambiguous_event'
        audit['rejected_faultlogs'].extend(
            dict(path=str(item[0]), reason='multiple distinct events match sample') for item in matches)
        matches = []
    if matches:
        audit['status'] = 'matched'
    return matches


def _symbol_index(matches, audit):
    """Collect exact frame keys and retain every matching source location."""
    index = defaultdict(lambda: defaultdict(list))
    for path, freeze, identity in matches:
        audit['matched_faultlogs'].append(str(path))
        audit['matched_events'].append(dict(path=str(path), identity=_json_identity(identity)))
        # Index only the event process stacks, excluding Binder peer dumps.
        parts = [freeze.warning] + ([freeze.block] if freeze.block else [])
        event_frames = [frame for part in parts for stack in part.stacks.values()
                        for frame in stack.frames]
        for frame in event_frames:
            if frame.symbol_key and frame.effective_symbol:
                index[frame.symbol_key][frame.original_symbol].append(
                    dict(path=str(path), line=frame.source_line, raw=frame.raw.rstrip('\r\n'),
                         symbol=frame.original_symbol))
    return index


def align_sample(sample_path, lines, frames, faultlog_paths=None):
    """Mutate only alignment fields; raw/original_symbol/brief remain intact.

    Normal analysis discovers accompanying logs automatically. The optional
    Python argument is for callers with an already collected candidate list;
    these candidates cannot bypass event checks.
    """
    sample_path = Path(sample_path).resolve()
    sample = _sample_identity(sample_path, lines)
    if faultlog_paths is None:
        candidates = _discover_faultlogs(sample_path)
    else:
        candidates = set()
        for root in faultlog_paths:
            candidates.update(path.resolve() for path in collect_logs(root).faultlogs)
    audit = dict(sample=str(sample_path), status='no_matching_event',
                 event_basis='process + UID + TID + sample/fault interval + report timestamp when available',
                 sample_event=_json_identity(sample), matched_events=[],
                 matched_faultlogs=[], rejected_faultlogs=[], frames=[])
    matches = _match_faultlogs(sample, candidates, audit)
    index = _symbol_index(matches, audit)
    for frame in frames:
        symbols = index.get(frame.symbol_key, {})
        if len(symbols) > 1:
            frame.alignment_status = 'conflict'
            frame.symbol_sources = [source for sources in symbols.values() for source in sources]
        elif symbols:
            symbol, sources = next(iter(symbols.items()))
            frame.aligned_symbol = symbol
            frame.symbol_sources = sources
            frame.alignment_status = ('confirmed' if frame.original_symbol == symbol else
                                      'replaced' if frame.original_symbol else 'filled')
        audit['frames'].append(dict(raw=frame.raw.rstrip('\r\n'), line=frame.source_line,
                                  module=frame.module,
                                  build_id=frame.build_id,
                                  pc=f'0x{frame.pc:x}' if frame.pc is not None else None,
                                  original_symbol=frame.original_symbol,
                                  aligned_symbol=frame.aligned_symbol,
                                  effective_frame=frame.effective_brief,
                                  status=frame.alignment_status, sources=frame.symbol_sources))
    audit['counts'] = {status: sum(frame.alignment_status == status for frame in frames)
                       for status in ('filled', 'replaced', 'confirmed', 'conflict', 'unmatched')}
    return audit
