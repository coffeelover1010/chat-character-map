"""Build an allowlisted install archive and verify its contents against source."""
from pathlib import Path
import zipfile,hashlib,re
root=Path(__file__).resolve().parents[1]
folder=root.name
toc=root/(folder+'.toc')
version=re.search(r'^## Version:\s*(\S+)',toc.read_text(),re.M)[1]
files={toc}
for line in toc.read_text().splitlines():
 if line.strip() and not line.startswith('#'):
  files.add(root/line.strip().replace('\\','/'))
for name in ('Bindings.xml','README.md','CHANGELOG.md','LICENSE','Libs/NOTICE.txt','Libs/Ace3-LICENSE.txt'):
 if (root/name).is_file():files.add(root/name)
for directory in ('media','release-media'):
 if (root/directory).exists():
  files.update(p for p in (root/directory).rglob('*') if p.is_file() and p.suffix.lower() in ('.png','.jpg','.tga','.blp'))
out=root/'dist'/f'{folder}-{version}.zip';out.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(files):
  assert p.is_file(),p
  z.write(p,folder+'/'+p.relative_to(root).as_posix())
with zipfile.ZipFile(out) as z:
 assert z.testzip() is None
 for p in files:assert z.read(folder+'/'+p.relative_to(root).as_posix())==p.read_bytes()
print(out, len(files), 'verified files', hashlib.sha256(out.read_bytes()).hexdigest())
