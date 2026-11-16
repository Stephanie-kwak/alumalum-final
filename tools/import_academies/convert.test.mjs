import { test } from "node:test";
import assert from "node:assert/strict";
import { toAcademy, toCourse, COL, ADULT } from "./convert.mjs";

const row = {
  [COL.id]: "H001", [COL.name]: "테스트학원", [COL.dong]: "평촌동", [COL.addr]: "확인필요", [COL.phone]: null, [COL.size]: "공부방교습소", [COL.shuttle]: "확인필요",
  "초3-4": "O", "초5-6": "O", 중등: "O", [ADULT]: null, 수학: "O", 과학: "O", 영어: null,
  [COL.feeMin]: 160000, [COL.feeMax]: 240000, [COL.feeAvg]: 200000, [COL.feeDate]: new Date("2024-03-02T00:00:00Z"),
  [COL.rating]: 4.5, [COL.reviews]: 12,
};

test("O 표시된 나이 · 과목만 넣는다", () => {
  const a = toAcademy(row);
  assert.deepEqual(a.levels, ["초3-4", "초5-6", "중등"]);
  assert.deepEqual(a.subjects, ["수학", "과학"]);
  assert.equal(a.adult, false);
  assert.equal(toAcademy({ ...row, [ADULT]: "O" }).adult, true);
});

test("확인필요는 빈 값(앱에서 '미정'), 동은 권역 값으로 저장", () => {
  const a = toAcademy(row);
  assert.equal(a.addr, "");
  assert.equal(a.phone, "");
  assert.equal(a.shuttle, null);
  assert.equal(a.size, "공부방·교습소");
  assert.equal(a.dong, "평촌동");
  assert.equal(a.area, "평촌 학원가");
  assert.equal(toAcademy({ ...row, [COL.shuttle]: "있음" }).shuttle, true);
});

test("교습비 요약 · 외부 후기는 보관만", () => {
  const a = toAcademy(row);
  assert.deepEqual(a.fee, { min: 160000, max: 240000, avg: 200000, date: "2024-03-02", extra: "" });
  assert.equal(toAcademy({ ...row, [COL.feeMin]: null }).fee, null);
  assert.equal(toAcademy({ ...row, [COL.feeMin]: "240,000" }).fee.min, 240000, "글자로 적힌 금액의 쉼표");
  assert.equal(a.ext.rating, 4.5);
  assert.equal(a.ext.shown, false);
});

test("교습과정: 요약에 반영된 정규 과정만", () => {
  const c = { "요약 반영": "O", "교습과정명(교육청 등록)": "초등주3회", "대상 학교급": "초등", "과목 분류": "수학", "정원(명)": 8, "총교습시간(분)": 1080, "월 환산 교습비(원)": 240000 };
  assert.deepEqual(toCourse(c), { name: "초등주3회", level: "초등", subject: "수학", cap: 8, minutes: 1080, monthly: 240000 });
  assert.equal(toCourse({ ...c, "요약 반영": null }), null);
});
