// Firestore 보안 규칙 테스트. 실제 Firebase 가 아니라 로컬 에뮬레이터에서 돈다.
//   cd tools/rules_test && npm install && npm test
import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, test } from "node:test";
import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { Bytes, doc, getDoc, getDocs, collection, deleteDoc, serverTimestamp, setDoc, updateDoc, writeBatch, Timestamp } from "firebase/firestore";

let env;
const sig = Bytes.fromUint8Array(new Uint8Array([1, 2, 3]));

const parentDoc = (o = {}) => ({ role: "parent", loginId: "mom01", name: "평촌 초3맘", area: "호계", plus: false, createdAt: serverTimestamp(), kids: [{ order: "첫째", grade: "초3", birthYear: 2017, sex: "여" }], interests: ["수학"], ...o });
const staffDoc = (o = {}) => ({ role: "staff", loginId: "teacher01", name: "김도현", area: "", plus: false, createdAt: serverTimestamp(), academyId: "A001", position: "원장", verified: false, ...o });
const studentDoc = (o = {}) => ({ role: "student", loginId: "kid01", name: "김지우", area: "", plus: false, createdAt: serverTimestamp(), grade: "초3", parentUid: "p1", academyIds: [], ...o });
const privateDoc = (o = {}) => ({ phone: "010-1234-5678", email: "", agreed: ["terms", "privacy", "child"], signaturePng: sig, signedAt: serverTimestamp(), ...o });

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "alumalum-rules-test",
    firestore: { rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8"), host: "127.0.0.1", port: 8080 },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// 아이디 계정 토큰(가입 전환 후). loginId 를 주면 이메일이 <loginId>@alumalum.app
const as = (uid, loginId) => env.authenticatedContext(uid, { email: loginId ? `${loginId}@alumalum.app` : undefined, firebase: { sign_in_provider: "password" } }).firestore();
const guest = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: "anonymous" } }).firestore();
const anon = () => env.unauthenticatedContext().firestore();

async function signUpParent(uid = "p1", code = "482915") {
  const db = as(uid, "mom01");
  const b = writeBatch(db);
  b.set(doc(db, "users", uid), parentDoc());
  b.set(doc(db, `users/${uid}/private/info`), privateDoc({ linkCode: code }));
  b.set(doc(db, "linkCodes", code), { parentUid: uid, parentName: "평촌 초3맘" });
  await assertSucceeds(b.commit());
}

describe("users", () => {
  test("학부모 가입 배치(프로필 · 개인 정보 · 연결 코드)가 통과한다", () => signUpParent());

  test("남의 프로필은 읽을 수 없다 (자녀 정보 보호)", async () => {
    await signUpParent();
    await assertSucceeds(getDoc(doc(as("p1"), "users/p1")));
    await assertFails(getDoc(doc(as("x"), "users/p1")));
    await assertFails(getDocs(collection(as("x"), "users")));
    await assertFails(getDoc(doc(anon(), "users/p1")));
  });

  test("남의 uid 로 프로필을 만들 수 없다", () => assertFails(setDoc(doc(as("x"), "users/p1"), parentDoc())));

  test("관계자가 서류 확인(verified)을 스스로 켤 수 없다", async () => {
    await assertFails(setDoc(doc(as("s1"), "users/s1"), staffDoc({ verified: true })));
    await assertSucceeds(setDoc(doc(as("s1", "teacher01"), "users/s1"), staffDoc()));
    await assertFails(updateDoc(doc(as("s1"), "users/s1"), { verified: true }));
    await assertFails(updateDoc(doc(as("s1"), "users/s1"), { academyId: "A002" }));
  });

  test("역할 · 아이디 · 가입 시각은 바꿀 수 없다", async () => {
    await signUpParent();
    await assertFails(updateDoc(doc(as("p1"), "users/p1"), { role: "staff" }));
    await assertFails(updateDoc(doc(as("p1"), "users/p1"), { loginId: "other" }));
    await assertFails(updateDoc(doc(as("p1"), "users/p1"), { createdAt: Timestamp.fromMillis(0) }));
  });

  test("가입 때 플러스를 켤 수 없고, 가입 뒤에는 본인이 켤 수 있다(테스트 결제)", async () => {
    await assertFails(setDoc(doc(as("p1"), "users/p1"), parentDoc({ plus: true })));
    await signUpParent();
    await assertSucceeds(updateDoc(doc(as("p1"), "users/p1"), { plus: true }));
  });

  test("정해지지 않은 필드 · 역할에 맞지 않는 필드 · 너무 긴 값은 거부", async () => {
    await assertFails(setDoc(doc(as("p1"), "users/p1"), parentDoc({ isAdmin: true })));
    await assertFails(setDoc(doc(as("p1"), "users/p1"), parentDoc({ academyId: "A001" })));
    await assertFails(setDoc(doc(as("p1"), "users/p1"), parentDoc({ name: "가".repeat(31) })));
    await assertFails(setDoc(doc(as("p1"), "users/p1"), parentDoc({ area: "강남" })));
    await assertFails(setDoc(doc(as("p1"), "users/p1"), parentDoc({ role: "admin" })));
    await signUpParent();
    await assertFails(updateDoc(doc(as("p1"), "users/p1"), { name: "가".repeat(5000) }));
    await assertFails(updateDoc(doc(as("p1"), "users/p1"), { interests: Array(11).fill("수학") }));
  });

  test("학생 가입(보호자 연결 · 다니는 학원)이 통과하고, 보호자 연결은 나중에 바꿀 수 없다", async () => {
    await signUpParent();
    const db = as("t1", "kid01");
    const b = writeBatch(db);
    b.set(doc(db, "users/t1"), studentDoc());
    b.set(doc(db, "users/t1/private/info"), privateDoc({ linkCode: "482915" }));
    await assertSucceeds(b.commit());
    await assertFails(updateDoc(doc(db, "users/t1"), { parentUid: "p2" }));
  });

  test("가입 시각을 과거로 적을 수 없다", () => assertFails(setDoc(doc(as("p1"), "users/p1"), parentDoc({ createdAt: Timestamp.fromMillis(0) }))));
});

describe("users/private", () => {
  test("본인만 읽고, 수정은 아무도 못 한다", async () => {
    await signUpParent();
    await assertSucceeds(getDoc(doc(as("p1"), "users/p1/private/info")));
    await assertFails(getDoc(doc(as("x"), "users/p1/private/info")));
    await assertFails(updateDoc(doc(as("p1"), "users/p1/private/info"), { phone: "010" }));
  });

  test("info 외 문서 · 큰 서명 · 잘못된 코드는 거부", async () => {
    await assertFails(setDoc(doc(as("p1"), "users/p1/private/other"), privateDoc()));
    await assertFails(setDoc(doc(as("p1"), "users/p1/private/info"), privateDoc({ signaturePng: Bytes.fromUint8Array(new Uint8Array(200001)) })));
    await assertFails(setDoc(doc(as("p1"), "users/p1/private/info"), privateDoc({ linkCode: "12ab56" })));
  });
});

describe("linkCodes", () => {
  test("코드를 아는 사람은 1건 조회, 목록은 불가, 로그인 안 하면 불가", async () => {
    await signUpParent();
    await assertSucceeds(getDoc(doc(guest("g1"), "linkCodes/482915")));
    await assertFails(getDocs(collection(guest("g1"), "linkCodes")));
    await assertFails(getDoc(doc(anon(), "linkCodes/482915")));
  });

  test("학부모가 아닌 사람 · 남의 uid · 덮어쓰기는 거부", async () => {
    await assertFails(setDoc(doc(as("g"), "linkCodes/111111"), { parentUid: "g", parentName: "가짜" }));
    await assertFails(setDoc(doc(as("g"), "linkCodes/111111"), { parentUid: "p1", parentName: "가짜" }));
    await signUpParent();
    await assertFails(setDoc(doc(as("p1"), "linkCodes/482915"), { parentUid: "p1", parentName: "바꿈" }));
  });
});

describe("academies", () => {
  test("로그인한 사람(임시 계정 포함)만 읽고, 아무도 쓸 수 없다", async () => {
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), "academies/A001"), { name: "가온수학" }));
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), "academies_meta/A001"), { ext: { rating: 4.1 } }));
    await assertSucceeds(getDoc(doc(guest("g1"), "academies/A001")));
    await assertFails(getDoc(doc(anon(), "academies/A001")));
    await assertFails(setDoc(doc(guest("g1"), "academies/A001"), { name: "바꿈" }));
    await assertFails(getDoc(doc(guest("g1"), "academies_meta/A001")));
  });
});

describe("적대 리뷰 반영 (261009)", () => {
  test("#7 임시(익명) 계정은 프로필 · 개인 정보 · 연결 코드를 만들 수 없다", async () => {
    const g = guest("g1");
    await assertFails(setDoc(doc(g, "users/g1"), parentDoc({ loginId: "mom01" })));
    await assertFails(setDoc(doc(g, "users/g1/private/info"), privateDoc()));
    const b = writeBatch(g);
    b.set(doc(g, "users/g1"), parentDoc());
    b.set(doc(g, "users/g1/private/info"), privateDoc({ linkCode: "222222" }));
    b.set(doc(g, "linkCodes/222222"), { parentUid: "g1", parentName: "평촌 초3맘" });
    await assertFails(b.commit());
  });

  test("#7 로그인한 아이디와 다른 loginId 로 프로필을 만들 수 없다 (아이디 사칭)", () =>
    assertFails(setDoc(doc(as("p1", "mom01"), "users/p1"), parentDoc({ loginId: "someone" }))));

  test("#5 이미 가입한 학부모가 나중에 연결 코드를 더 만들 수 없다 (코드 선점)", async () => {
    await signUpParent();
    await assertFails(setDoc(doc(as("p1", "mom01"), "linkCodes/333333"), { parentUid: "p1", parentName: "평촌 초3맘" }));
  });

  test("#5 가입 배치에서도 개인 정보의 코드와 다른 코드, 다른 닉네임으로는 만들 수 없다", async () => {
    const db = as("p2", "mom02");
    const b1 = writeBatch(db);
    b1.set(doc(db, "users/p2"), parentDoc({ loginId: "mom02" }));
    b1.set(doc(db, "users/p2/private/info"), privateDoc({ linkCode: "444444" }));
    b1.set(doc(db, "linkCodes/555555"), { parentUid: "p2", parentName: "평촌 초3맘" });
    await assertFails(b1.commit());
    const b2 = writeBatch(db);
    b2.set(doc(db, "users/p2"), parentDoc({ loginId: "mom02" }));
    b2.set(doc(db, "users/p2/private/info"), privateDoc({ linkCode: "444444" }));
    b2.set(doc(db, "linkCodes/444444"), { parentUid: "p2", parentName: "다른 이름" });
    await assertFails(b2.commit());
  });

  test("#6 학생은 코드 없이 · 틀린 코드로 아무 보호자에게 연결할 수 없다", async () => {
    await signUpParent();
    const db = as("t1", "kid01");
    const noCode = writeBatch(db);
    noCode.set(doc(db, "users/t1"), studentDoc());
    noCode.set(doc(db, "users/t1/private/info"), privateDoc());
    await assertFails(noCode.commit());
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), "linkCodes/777777"), { parentUid: "other", parentName: "남" }));
    const wrong = writeBatch(db);
    wrong.set(doc(db, "users/t1"), studentDoc());
    wrong.set(doc(db, "users/t1/private/info"), privateDoc({ linkCode: "777777" }));
    await assertFails(wrong.commit());
    const free = writeBatch(db);
    free.set(doc(db, "users/t1"), studentDoc({ parentUid: null }));
    free.set(doc(db, "users/t1/private/info"), privateDoc());
    await assertSucceeds(free.commit());
  });
});

describe("academies/classes (반별 수강료, 261022)", () => {
  const cls = (o = {}) => ({ grade: "초3", name: "사고력반", subject: "수학", perWeek: 2, minutes: 90, fee: 240000, cap: 8, updatedAt: serverTimestamp(), ...o });
  // staffDoc 의 소속 학원은 A001
  const seedStaff = (uid = "s1", o = {}) => env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), `users/${uid}`), { ...staffDoc(o), createdAt: Timestamp.now() }));

  test("소속 관계자는 만들고 고치고 지운다, 로그인한 사람은 읽는다", async () => {
    await seedStaff();
    const db = as("s1", "teacher01");
    await assertSucceeds(setDoc(doc(db, "academies/A001/classes/c1"), cls()));
    await assertSucceeds(setDoc(doc(db, "academies/A001/classes/c1"), cls({ fee: 260000 })));
    await assertSucceeds(getDocs(collection(guest("g1"), "academies/A001/classes")));
    await assertFails(getDocs(collection(anon(), "academies/A001/classes")));
    await assertSucceeds(deleteDoc(doc(db, "academies/A001/classes/c1")));
  });

  test("다른 학원 관계자 · 학부모 · 임시 계정은 쓸 수 없다", async () => {
    await seedStaff("s2", { academyId: "A002" });
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), "users/p1"), { ...parentDoc(), createdAt: Timestamp.now() }));
    await assertFails(setDoc(doc(as("s2", "teacher01"), "academies/A001/classes/c1"), cls()));
    await assertFails(setDoc(doc(as("p1", "mom01"), "academies/A001/classes/c1"), cls()));
    await assertFails(setDoc(doc(guest("s1"), "academies/A001/classes/c1"), cls()));
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), "academies/A001/classes/c9"), cls({ updatedAt: Timestamp.now() })));
    await assertFails(deleteDoc(doc(as("s2", "teacher01"), "academies/A001/classes/c9")));
    await assertFails(setDoc(doc(as("s2", "teacher01"), "academies/A001/classes/c9"), cls({ fee: 1 })));
  });

  test("범위 밖 값 · 정해지지 않은 필드 · 과거 시각은 거부", async () => {
    await seedStaff();
    const db = as("s1", "teacher01");
    for (const bad of [{ fee: -1 }, { fee: 10000001 }, { perWeek: 0 }, { perWeek: 8 }, { minutes: 5 }, { cap: 0 }, { name: "" }, { name: "가".repeat(21) }, { fee: 1.5 }, { extra: 1 }, { updatedAt: Timestamp.fromMillis(0) }]) {
      await assertFails(setDoc(doc(db, "academies/A001/classes/c1"), cls(bad)));
    }
  });
});

describe("한글 아이디 (261022)", () => {
  // 앱 AuthService.keyOf('평촌맘') 과 같은 값: 'k.' + UTF-8 16진수
  const key = "k." + Buffer.from("평촌맘", "utf8").toString("hex");

  test("한글 아이디 키로 만든 계정은 같은 키를 loginId 로 프로필을 만든다", async () => {
    const db = as("p9", key);
    const b = writeBatch(db);
    b.set(doc(db, "users/p9"), parentDoc({ loginId: key }));
    b.set(doc(db, "users/p9/private/info"), privateDoc({ linkCode: "112233" }));
    b.set(doc(db, "linkCodes/112233"), { parentUid: "p9", parentName: "평촌 초3맘" });
    await assertSucceeds(b.commit());
  });

  test("한글을 그대로 쓰거나 형식이 틀린 키는 거부", async () => {
    await assertFails(setDoc(doc(as("p8", "평촌맘"), "users/p8"), parentDoc({ loginId: "평촌맘" })));
    await assertFails(setDoc(doc(as("p7", "k.zz"), "users/p7"), parentDoc({ loginId: "k.zz" })));
    await assertFails(setDoc(doc(as("p6", key), "users/p6"), parentDoc({ loginId: "k.abcd" })));
  });
});
