// 학원 엑셀 → Firestore academies 컬렉션
//   미리보기: node import.mjs <엑셀 경로>                       → preview.json 만 만든다(업로드 안 함)
//   업로드:   node import.mjs <엑셀 경로> --upload              → 학원ID를 문서 키로, 엑셀에 있는 칸만 갱신한다
//                                                                 (학원장이 앱에서 입력한 반별 수강료 classes 는 그대로 남는다)
//   교체:     node import.mjs <엑셀 경로> --upload --replace    → 위에 더해, 엑셀에 없는 학원 문서를 지운다
// 업로드 권한: gcloud auth application-default login 으로 로그인한 계정(또는 GOOGLE_APPLICATION_CREDENTIALS = 서비스 계정 키 파일)
import { readFileSync, writeFileSync } from "node:fs";
import ExcelJS from "exceljs";
import { COL, toAcademy, toCourse } from "./convert.mjs";

const [xlsxPath, ...flags] = process.argv.slice(2);
if (!xlsxPath) { console.log("사용법: node import.mjs <엑셀 경로> [--upload] [--replace]"); process.exit(1); }

const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile(xlsxPath);

// 수식 · 링크 · 서식 있는 글자도 화면에 보이는 값으로 읽는다.
// 결과가 저장되지 않은 수식(결과가 "" 이거나, 엑셀에서 저장하지 않은 파일)은 빈 값으로 읽고 개수를 알린다.
let emptyFormulas = 0;
const plain = (v) =>
  v === null || v === undefined ? null
  : v instanceof Date ? v
  : typeof v !== "object" ? v
  : "formula" in v || "sharedFormula" in v ? (v.result === undefined ? (emptyFormulas++, null) : plain(v.result))
  : "richText" in v ? v.richText.map((t) => t.text).join("")
  : "text" in v ? plain(v.text)
  : null;

// 첫 열 이름이 들어 있는 줄을 머리글로 보고, 그 아래 줄을 { 열 이름: 값 } 으로 읽는다
function sheetRows(name, firstHeader) {
  const ws = wb.getWorksheet(name);
  if (!ws) throw new Error(`'${name}' 시트가 없어요`);
  let header = null;
  const out = [];
  ws.eachRow((row) => {
    const vals = row.values.slice(1).map(plain);
    if (!header) { if (vals.includes(firstHeader)) header = vals; return; }
    out.push(Object.fromEntries(header.map((h, i) => [h, vals[i] ?? null])));
  });
  if (!header) throw new Error(`'${name}' 시트에서 '${firstHeader}' 머리글을 찾지 못했어요`);
  return out;
}

const listSheet = wb.worksheets.find((w) => w.name.startsWith("학원목록"))?.name;
if (!listSheet) throw new Error("'학원목록'으로 시작하는 시트가 없어요");
const rows = sheetRows(listSheet, COL.id).filter((r) => /^[A-Z]\d{3}$/.test(String(r[COL.id] ?? "").trim()));
const courses = {};
for (const r of sheetRows("학원비(교육청 등록)", "학원ID")) {
  const c = toCourse(r);
  if (c) (courses[String(r["학원ID"]).trim()] ??= []).push(c);
}
const list = rows.map((r) => {
  const id = String(r[COL.id]).trim();
  return { id, ...toAcademy(r), courses: courses[id] ?? [] };
});

if (emptyFormulas) console.warn(`결과가 비어 있는 수식 칸 ${emptyFormulas}개를 빈 값으로 읽었어요. 값이 빠져 보이면 엑셀에서 열어 저장한 뒤 다시 돌려 주세요.`);
const count = (f) => list.filter(f).length;
console.log(`학원 ${list.length}곳 · 주소 ${count((a) => a.addr)} · 전화 ${count((a) => a.phone)} · 과목 ${count((a) => a.subjects.length)} · 나이 ${count((a) => a.levels.length || a.adult)} · 교습비 ${count((a) => a.fee)} · 교습과정 ${list.reduce((n, a) => n + a.courses.length, 0)}건`);
const by = (k) => list.reduce((m, a) => ((m[a[k] || "(미정)"] = (m[a[k] || "(미정)"] || 0) + 1), m), {});
console.log("권역", by("area"), "규모", by("size"));
writeFileSync(new URL("./preview.json", import.meta.url), JSON.stringify(list, null, 2));
console.log("preview.json 을 만들었어요.");

if (!flags.includes("--upload")) process.exit(0);

const projectId = JSON.parse(readFileSync(new URL("../../.firebaserc", import.meta.url), "utf8")).projects.default;
const { initializeApp, applicationDefault } = await import("firebase-admin/app");
const { getFirestore } = await import("firebase-admin/firestore");
initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

// 외부 후기 · 조사 메모는 앱이 읽지 못하는 academies_meta 에 따로 둔다(보안 규칙 참고)
const writes = list.flatMap(({ id, ext, meta, ...doc }) => [[db.collection("academies").doc(id), doc], [db.collection("academies_meta").doc(id), { ext, meta }]]);
if (flags.includes("--replace")) {
  // 엑셀을 잘못 읽어 목록이 비거나 크게 줄었는데 전부 지워 버리는 일을 막는다
  const existing = (await db.collection("academies").listDocuments()).length;
  if (list.length < 50 || list.length < existing * 0.3) {
    console.error(`읽은 학원이 ${list.length}곳뿐이에요(지금 ${existing}곳). 엑셀을 확인해 주세요. 지우지 않고 멈춰요.`);
    process.exit(1);
  }
  const keep = new Set(list.map((a) => a.id));
  for (const col of ["academies", "academies_meta"]) {
    const stale = (await db.collection(col).listDocuments()).filter((d) => !keep.has(d.id));
    writes.push(...stale.map((d) => [d, null]));
    console.log(`${col}: 엑셀에 없는 문서 ${stale.length}개를 지워요`);
  }
}
for (let i = 0; i < writes.length; i += 400) {
  const batch = db.batch();
  for (const [ref, data] of writes.slice(i, i + 400)) data === null ? batch.delete(ref) : batch.set(ref, data, { mergeFields: Object.keys(data) });
  await batch.commit();
}
console.log(`${projectId} 에 ${list.length}곳을 올렸어요.`);
