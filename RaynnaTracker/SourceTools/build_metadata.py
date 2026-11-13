"""Export the required metadata snapshot; no third-party addon runs in game.

Build dependencies: cbor2, lupa. Input: installed QuestieDB 1.0.13 Forever TOC.
See the bundled upstream licensing notice. Static corrections are baked into
this TOC; relevant Horde/Alliance overlays are exported separately.
"""
import base64
import hashlib
import json
import re
from pathlib import Path

import cbor2
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r'C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\QuestieDB')
toc = (SOURCE / 'QuestieDB_Forever.toc').read_bytes()
metadata = dict(re.findall(r'^## ([^:]+): (.*)$', toc.decode('utf8'), re.M))
metadata = {key: value.rstrip('\r') for key, value in metadata.items()}
FIELDS = {
    'Npc': {'name': 1, 'minLevel': 4, 'maxLevel': 5, 'spawns': 7, 'zoneID': 9},
    'Item': {'name': 1, 'npcDrops': 2, 'startQuest': 5, 'questRewards': 6, 'vendors': 14, 'relatedQuests': 15},
    'Quest': {'name': 1},
}


def decode(key):
    value = metadata.get(key)
    if value is None:
        return None
    if value.startswith('~'):
        value = ''.join(metadata[f'{key}-{i}'] for i in range(1, int(value.strip('~')) + 1))
    return cbor2.loads(base64.b64decode(value))


def clean(value):
    if isinstance(value, bytes):
        return value.decode('utf8')
    if hasattr(value, 'items'):
        return {clean(k): clean(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [clean(v) for v in value]
    return value


def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'
    if isinstance(value, list):
        return '{' + ','.join(map(lua, value)) + '}'
    return str(value)


output = [
    '-- Generated metadata snapshot from QuestieDB 1.0.13 (Forever).',
    '-- Attribution and upstream terms: LICENSE-QuestieDB.txt; GPL-3.0.txt.',
    '-- Source TOC SHA-256: ' + hashlib.sha256(toc).hexdigest(),
    'local _, Addon = ...',
    'Addon.BundledMetadata = {Npc={}, Item={}, Quest={}, factions={}}',
    'local data = Addon.BundledMetadata',
    'data.sourceVersion=' + lua(metadata['Version']),
]
counts = {}
exported_items = {}
for entity, fields in FIELDS.items():
    ids = sorted(int(m[1]) for key in metadata if (m := re.fullmatch('X-' + entity + r'-(\d+)-S', key)))
    counts[entity] = len(ids)
    for entity_id in ids:
        row = clean(decode(f'X-{entity}-{entity_id}-S'))
        if isinstance(row, list):
            row = dict(enumerate(row, 1))
        record = {}
        for field, index in fields.items():
            value = row.get(index)
            if value is None:
                value = clean(decode(f'X-{entity}-{entity_id}-{index}'))
            if field == 'spawns' and isinstance(value, dict):
                value = {zone: True for zone in value}  # Zone membership, no unused coordinates.
            if value is not None:
                record[field] = value
        if record:
            output.append(f'data.{entity}[{entity_id}]=' + lua(record))
            if entity == 'Item':
                exported_items[entity_id] = record

# Quest objectives contain useful relationships missing from some item rows.
def position(value, index):
    if isinstance(value, dict):
        return value.get(index)
    if isinstance(value, list) and len(value) >= index:
        return value[index - 1]

relations = {}
for key in metadata:
    match = re.fullmatch(r'X-Quest-(\d+)-S', key)
    if not match:
        continue
    quest_id = int(match[1])
    objectives = clean(decode(f'X-Quest-{quest_id}-10'))
    item_objectives = position(objectives, 3) or []
    if isinstance(item_objectives, dict):
        item_objectives = item_objectives.values()
    for objective in item_objectives:
        item_id = position(objective, 1)
        if isinstance(item_id, int) and item_id in exported_items:
            relations.setdefault(item_id, set()).add(quest_id)
for item_id, quest_ids in sorted(relations.items()):
    existing = exported_items[item_id].get('relatedQuests', [])
    if isinstance(existing, dict):
        existing = existing.values()
    quest_ids.update(existing)
    output.append(f'data.Item[{item_id}].relatedQuests=' + lua(sorted(quest_ids)))

# Evaluate only the small upstream faction-correction tables at build time.
runtime = LuaRuntime(unpack_returned_tuples=True)
runtime.execute('Modules={}; QuestieLoader={}; function QuestieLoader:CreateModule(n) Modules[n]={}; return Modules[n] end; function QuestieLoader:ImportModule(n) return Modules[n] end; function UnitFactionGroup() return FACTION end')
namespace = runtime.table(Enum=runtime.table())
runtime.execute((SOURCE / 'src/corrections/enum/zones.lua').read_text(), 'Export', namespace)
runtime.globals().Modules['ZoneDB'] = namespace.Enum
runtime.globals().Modules['Phasing'] = runtime.table(phases=runtime.table())
runtime.globals().Modules['QuestieDB'] = runtime.table(
    itemKeys=runtime.table_from({**FIELDS['Item'], 'objectDrops': 3}),
    npcKeys=runtime.table_from(FIELDS['Npc']),
)
for entity, filename, module in [('Npc', 'classicNPCFixes.lua', 'QuestieNPCFixes'), ('Item', 'classicItemFixes.lua', 'QuestieItemFixes')]:
    runtime.execute((SOURCE / 'src/corrections/Forever/legacy' / filename).read_text())
    for faction in ['Horde', 'Alliance']:
        runtime.globals().FACTION = faction
        obj = runtime.globals().Modules[module]
        fixes = clean(obj.LoadFactionFixes(obj))
        converted = {}
        for entity_id, row in fixes.items():
            record = {}
            for field, index in FIELDS[entity].items():
                if index in row:
                    value = row[index]
                    if field == 'spawns':
                        value = {zone: True for zone in value}
                    record[field] = value
            if record:
                converted[entity_id] = record
        output.append(f'data.factions.{faction}=data.factions.{faction} or {{}}')
        output.append(f'data.factions.{faction}.{entity}=' + lua(converted))
(ROOT / 'RaynnaTracker/Metadata.lua').write_text('\n'.join(output) + '\n', encoding='utf8')
print('Bundled metadata:', counts)
