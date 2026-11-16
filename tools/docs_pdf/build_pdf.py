# docs 의 설명 문서 → 표지가 있는 A4 PDF (Chrome 인쇄). 문서를 고친 뒤 다시 돌리면 된다.
#   python tools/docs_pdf/build_pdf.py <출력 PDF 경로> <버전 표기> [guide|code]
#   guide: docs/수정가이드.md (기본) · code: docs/코드_DB_설명서.md
import os
import pathlib
import subprocess
import sys

import markdown

ROOT = pathlib.Path(__file__).resolve().parents[2]
out_pdf = pathlib.Path(sys.argv[1]).resolve()
version = sys.argv[2] if len(sys.argv) > 2 else ""
kind = sys.argv[3] if len(sys.argv) > 3 else "guide"

# 문서별 원본 · 표지 문구
DOCS = {
    "guide": ("수정가이드.md", "BETA DEMO · GUIDE", "설치 · 사용 안내와<br>수정 가이드",
              "안양 동안구 학원 소개 안드로이드 앱 '알음알음' 베타 데모의 설치 방법, 이번 버전에서 해 볼 수 있는 기능, 사용 언어와 기술, 그리고 소스를 직접 고치실 때 필요한 내용을 담았습니다. 화면이 늘어날 때마다 함께 갱신해 드립니다."),
    "code": ("코드_DB_설명서.md", "SOURCE CODE · DATABASE", "코드 · DB<br>설명서",
             "알음알음의 소스코드 구조와 데이터베이스(Firebase)를 직접 보고 고치실 수 있도록, 코드를 받아 실행하는 법, 폴더와 파일의 역할, 데이터가 저장되는 길, Firestore 컬렉션별 필드, 보안 규칙, 시연용 화면을 실제 저장으로 바꾸는 방향을 정리했습니다."),
}
src, eyebrow, cover_title, cover_text = DOCS[kind]
md = (ROOT / "docs" / src).read_text(encoding="utf-8")
# 맨 위 제목 · 인용 안내는 표지로 옮긴다
body_md = md.split("---", 1)[1]
body = markdown.markdown(body_md, extensions=["tables", "fenced_code", "sane_lists"])
font = (ROOT / "assets" / "fonts").as_uri()

html = f"""<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>알음알음 설명서</title><style>
@font-face{{font-family:P;font-weight:400;src:url("{font}/Pretendard-Regular.otf")}}
@font-face{{font-family:P;font-weight:500;src:url("{font}/Pretendard-Medium.otf")}}
@font-face{{font-family:P;font-weight:600;src:url("{font}/Pretendard-SemiBold.otf")}}
@font-face{{font-family:P;font-weight:700;src:url("{font}/Pretendard-Bold.otf")}}
@page{{size:A4;margin:20mm 18mm 18mm}}
@page :first{{margin:0}}
*{{box-sizing:border-box}}
body{{font-family:P,sans-serif;color:#151A23;font-size:10pt;line-height:1.65;margin:0;word-break:keep-all}}
.cover{{height:297mm;display:flex;flex-direction:column;page-break-after:always}}
.cover .top{{background:#2B50D9;color:#fff;padding:44mm 22mm 18mm}}
.cover .brand{{display:flex;align-items:center;gap:12px;font-size:22pt;font-weight:700}}
.cover .brand i{{font-style:normal;width:46px;height:46px;border-radius:12px;background:#fff;color:#2B50D9;display:grid;place-items:center;font-size:20pt}}
.cover .eyebrow{{letter-spacing:.25em;font-size:9pt;opacity:.85;margin-top:26mm}}
.cover h1{{font-size:30pt;line-height:1.25;margin:6mm 0 0;font-weight:700}}
.cover .mid{{padding:14mm 22mm;flex:1}}
.cover .mid p{{font-size:11pt;color:#4B5563;max-width:150mm}}
.cover dl{{display:grid;grid-template-columns:32mm 1fr;gap:3mm 6mm;margin:0;padding:12mm 22mm 20mm;background:#F5F6F8;font-size:10pt}}
.cover dt{{color:#6B7280}}
h2{{font-size:15pt;font-weight:700;color:#151A23;border-top:2px solid #2B50D9;padding-top:4mm;margin:10mm 0 4mm;page-break-after:avoid}}
h2:first-child{{margin-top:0}}
h3{{font-size:11.5pt;font-weight:700;margin:6mm 0 2mm;page-break-after:avoid}}
p{{margin:2mm 0}}
table{{width:100%;border-collapse:collapse;margin:3mm 0 4mm;font-size:9pt;page-break-inside:avoid}}
tr{{page-break-inside:avoid}}
th{{background:#EEF2FF;color:#1F3DB0;font-weight:700;text-align:left;padding:2mm 2.5mm;border-bottom:1.5px solid #2B50D9}}
td{{padding:2mm 2.5mm;border-bottom:1px solid #E3E6EB;vertical-align:top}}
code{{font-family:Consolas,monospace;font-size:8.6pt;background:#F1F3F6;padding:.3mm 1.2mm;border-radius:3px}}
pre{{background:#151A23;color:#E5E7EB;padding:4mm;border-radius:6px;font-size:8.4pt;line-height:1.5;white-space:pre-wrap;page-break-inside:avoid}}
pre code{{background:none;color:inherit;padding:0}}
blockquote{{margin:3mm 0;padding:2.5mm 4mm;background:#FFF1D6;border-radius:6px;color:#8A4B00}}
blockquote p{{margin:0}}
ul,ol{{padding-left:6mm;margin:2mm 0}}
li{{margin:1mm 0}}
hr{{border:0;margin:0}}
a{{color:#2B50D9;text-decoration:none}}
</style></head><body>
<section class="cover">
  <div class="top"><div class="brand"><i>알</i>알음알음</div>
    <div class="eyebrow">{eyebrow}</div>
    <h1>{cover_title}</h1></div>
  <div class="mid"><p>{cover_text}</p></div>
  <dl><dt>버전</dt><dd>{version}</dd><dt>사용 언어</dt><dd>Flutter (Dart) · Firebase (Authentication · Cloud Firestore)</dd><dt>대상 기기</dt><dd>안드로이드 7.0 이상</dd><dt>작성</dt><dd>ITF</dd></dl>
</section>
{body}
</body></html>"""

tmp = out_pdf.with_suffix(".html")
out_pdf.parent.mkdir(parents=True, exist_ok=True)
tmp.write_text(html, encoding="utf-8")
chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
subprocess.run([chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", f"--print-to-pdf={out_pdf}", tmp.as_uri()], check=True, capture_output=True)
tmp.unlink()
print(out_pdf, out_pdf.stat().st_size)
