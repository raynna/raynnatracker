"""Build the CurseForge player ZIP from explicit runtime inputs."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
addon = ROOT / 'RaynnaTracker'
toc = addon / 'RaynnaTracker.toc'
version = re.search(r'^## Version: (.+)$', toc.read_text(), re.M).group(1).strip()
paths = [toc, ROOT / 'ForeverHunt/ForeverHunt.toc']
for line in toc.read_text().splitlines():
    line = line.strip()
    if line and not line.startswith('#'):
        paths.append(addon / line.replace('\\', '/'))
paths += [addon / 'Media' / (name + '.tga') for name in
          ('RaynnaParchment', 'Horizontal', 'Vertical', 'DiagonalDown', 'DiagonalUp')]
paths += [addon / name for name in ('GPL-3.0.txt', 'LICENSE-ClassicDB.txt',
                                    'LICENSE-QuestieDB.txt', 'REFERENCE-SOURCES.txt')]
for path in paths:
    assert path.is_file(), f'Missing runtime input: {path}'
output = ROOT / 'dist' / f'RaynnasTracker-{version}-CurseForge.zip'
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for path in sorted(set(paths)):
        archive.write(path, path.relative_to(ROOT).as_posix())
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert set(name.split('/')[0] for name in archive.namelist()) == {'RaynnaTracker', 'ForeverHunt'}
    assert not any('SourceTools' in name or 'tests/' in name for name in archive.namelist())
print(f'{output}: {len(set(paths))} files, {output.stat().st_size:,} bytes; ZIP verified')
