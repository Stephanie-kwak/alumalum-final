// 학원 엑셀(동안구_학원정보_최종.xlsx)의 한 줄을 앱의 academies 문서 하나로 바꾼다.
// 열 이름이 바뀌면 COL · AGES · SUBJECTS 만 고치면 된다.

export const COL = {
  id: "학원ID", name: "학원명", dong: "지역(동)", addr: "도로명주소", phone: "전화번호", size: "학원규모", shuttle: "셔틀버스",
  feeMin: "월 교습비 최저(원)", feeMax: "월 교습비 최고(원)", feeAvg: "월 교습비 평균(원)", feeDate: "최근 교습비 적용일", extraCost: "기타경비(차량비 등)",
  tags: "특징·태그", web: "홈페이지",
  rating: "후기 평점", reviews: "후기 수", recommend: "추천율(%)",
  ageNote: "대상나이 근거", sizeNote: "규모 판단근거", shuttleNote: "셔틀 근거", src: "교육청 등록정보 URL", reviewSrc: "후기 출처 URL", kind: "데이터 구분", note: "비고",
};

// [엑셀 열, 앱 값]. O 표시된 열만 넣는다.
export const AGES = [["초1-2", "초1-2"], ["초3-4", "초3-4"], ["초5-6", "초5-6"], ["중등", "중등"], ["고등", "고등"]];
export const ADULT = "성인(검정고시·입시)";
export const SUBJECTS = ["국어", "영어", "수학", "과학", "미술", "논술", "코딩", "외국어", "입시"];

// 엑셀의 동 → 앱이 저장하는 권역 값(회원 정보 · 보안 규칙이 이 값을 쓴다. 화면에는 동 이름으로 보인다)
const AREAS = { 평촌동: "평촌 학원가", 호계동: "호계", 관양동: "관양·인덕원", 비산동: "비산" };
const SIZES = { 공부방교습소: "공부방·교습소", 소형: "소형", 중형: "중형", 대형: "대형" };

const UNKNOWN = ["", "확인필요", "-"];
const str = (v) => (v === null || v === undefined ? "" : v instanceof Date ? v.toISOString().slice(0, 10) : String(v).trim());
const clean = (v) => (UNKNOWN.includes(str(v)) ? "" : str(v));
const num = (v) => { const n = Number(clean(v).replace(/,/g, "")); return clean(v) && Number.isFinite(n) ? n : null; };
const isO = (v) => str(v).toUpperCase() === "O";

export function toAcademy(row) {
  const g = (k) => clean(row[COL[k]]);
  const min = num(row[COL.feeMin]);
  return {
    name: g("name"),
    size: SIZES[g("size")] || "",
    subjects: SUBJECTS.filter((s) => isO(row[s])),
    levels: AGES.filter(([col]) => isO(row[col])).map(([, v]) => v),
    adult: isO(row[ADULT]),
    addr: g("addr"), dong: g("dong"), area: AREAS[g("dong")] || "",
    phone: g("phone"), web: g("web"),
    shuttle: g("shuttle") === "있음" ? true : null, // 확인되지 않은 셔틀은 '미정'(null)
    tags: g("tags") ? g("tags").split(",").map((t) => t.trim()).filter(Boolean) : [],
    // 교육청 등록 교습비(월 환산). 학원 상세의 '참고 교습비'
    fee: min === null ? null : { min, max: num(row[COL.feeMax]), avg: num(row[COL.feeAvg]), date: g("feeDate"), extra: g("extraCost") },
    // 외부 사이트 후기. 앱 노출 여부는 의뢰인 확인 전(설계안 G4)이라 보관만 한다.
    ext: { rating: num(row[COL.rating]), reviews: num(row[COL.reviews]), recommend: num(row[COL.recommend]), shown: false },
    meta: { ageNote: g("ageNote"), sizeNote: g("sizeNote"), shuttleNote: g("shuttleNote"), src: g("src"), reviewSrc: g("reviewSrc"), kind: g("kind"), note: g("note") },
  };
}

// '학원비(교육청 등록)' 시트 한 줄 → 교습과정. 요약에 반영된 정규 과정만 쓴다.
export function toCourse(row) {
  if (str(row["요약 반영"]) !== "O") return null;
  return {
    name: clean(row["교습과정명(교육청 등록)"]),
    level: clean(row["대상 학교급"]),
    subject: clean(row["과목 분류"]),
    cap: num(row["정원(명)"]),
    minutes: num(row["총교습시간(분)"]),
    monthly: num(row["월 환산 교습비(원)"]),
  };
}
