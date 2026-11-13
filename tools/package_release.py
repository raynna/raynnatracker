"""Create player-only ZIPs; run in a source repository or the multi-addon workspace."""
from pathlib import Path
import re
import zipfile
ROOT = Path(__file__).resolve().parents[1]
for folder in ('RaynnaTracker', 'RaynnaBestiary', 'TalentGuide'):
    addon = ROOT / folder
    toc = addon / (folder + '.toc')
    if not toc.exists():
        continue
    version = re.search(r'^## Version: (.+)$', toc.read_text(), re.M).group(1).strip()
    files = [toc]
    for line in toc.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            files.append(addon / line.replace('\\', '/'))
    media = ['RaynnaParchment']
    if folder != 'TalentGuide':
        media += ['Horizontal', 'Vertical', 'DiagonalDown', 'DiagonalUp']
    files += [addon / 'Media' / (name + '.tga') for name in media]
    files += [addon / name for name in ('GPL-3.0.txt','LICENSE-ClassicDB.txt',
                'LICENSE-QuestieDB.txt','REFERENCE-SOURCES.txt','SOURCES.md') if (addon / name).exists()]
    if folder == 'RaynnaTracker':
        files.append(ROOT / 'ForeverHunt/ForeverHunt.toc')
    assert all(p.is_file() for p in files), 'Missing required runtime file'
    out = ROOT / 'dist' / f'{folder}-{version}-CurseForge.zip'
    out.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(set(files)):
            archive.write(path, path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(out) as archive:
        assert archive.testzip() is None
        assert not any('/SourceTools/' in n or '/tests/' in n for n in archive.namelist())
        for path in files:
            assert archive.read(path.relative_to(ROOT).as_posix()) == path.read_bytes()
    print(f'{out.name}: {len(set(files))} verified files; {out.stat().st_size:,} bytes')
