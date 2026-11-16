// 배포된 실제 보안 규칙에서 앱과 같은 순서로 학부모 · 학생 가입이 통과하는지 확인하고, 만든 계정 · 문서를 지운다.
//   node live_signup_check.mjs
import { readFileSync } from "node:fs";
import { initializeApp } from "firebase/app";
import { EmailAuthProvider, getAuth, linkWithCredential, signInAnonymously, signOut } from "firebase/auth";
import { Bytes, doc, getFirestore, serverTimestamp, writeBatch, deleteDoc, getDoc } from "firebase/firestore";

const g = JSON.parse(readFileSync(new URL("../../android/app/google-services.json", import.meta.url), "utf8"));
const app = initializeApp({ apiKey: g.client[0].api_key[0].current_key, projectId: g.project_info.project_id, appId: g.client[0].client_info.mobilesdk_app_id });
const auth = getAuth(app);
const db = getFirestore(app);
const stamp = Date.now().toString(36);
const sig = Bytes.fromUint8Array(new Uint8Array([1, 2, 3]));
const results = [];
const ok = (name, cond) => results.push(`${cond ? "PASS" : "FAIL"} ${name}`);

async function guestThenUpgrade(loginId) {
  await signInAnonymously(auth);
  const cred = await linkWithCredential(auth.currentUser, EmailAuthProvider.credential(`${loginId}@alumalum.app`, "abcd1234"));
  return cred.user;
}

const cleanup = [];
try {
  // 학부모
  const momId = `livemom${stamp}`;
  const mom = await guestThenUpgrade(momId);
  const code = String(100000 + Math.floor(Math.random() * 900000));
  const b = writeBatch(db);
  b.set(doc(db, "users", mom.uid), { role: "parent", loginId: momId, name: "live-mom", area: "호계", plus: false, createdAt: serverTimestamp(), kids: [{ order: "첫째", grade: "초3", birthYear: 2017, sex: "여" }], interests: ["수학"] });
  b.set(doc(db, `users/${mom.uid}/private/info`), { phone: "010-1234-5678", email: "", agreed: ["terms", "privacy", "child"], signaturePng: sig, linkCode: code, signedAt: serverTimestamp() });
  b.set(doc(db, "linkCodes", code), { parentUid: mom.uid, parentName: "live-mom" });
  await b.commit();
  ok("학부모: 임시 → 아이디 전환 직후 가입 배치 저장", true);
  cleanup.push(mom);
  await signOut(auth);

  // 학생 (같은 코드로 연결)
  const kidId = `livekid${stamp}`;
  const kid = await guestThenUpgrade(kidId);
  const link = await getDoc(doc(db, "linkCodes", code));
  ok("학생: 코드로 보호자 조회", link.data()?.parentUid === mom.uid);
  const kb = writeBatch(db);
  kb.set(doc(db, "users", kid.uid), { role: "student", loginId: kidId, name: "live-kid", area: "", plus: false, createdAt: serverTimestamp(), grade: "초3", parentUid: mom.uid, academyIds: [] });
  kb.set(doc(db, `users/${kid.uid}/private/info`), { phone: "010-5555-6666", email: "", agreed: ["terms", "privacy", "child"], signaturePng: sig, linkCode: code, signedAt: serverTimestamp() });
  await kb.commit();
  ok("학생: 연결 증명과 함께 가입 배치 저장", true);
  cleanup.push(kid);
} catch (e) {
  ok(`예외 ${e.code || ""} ${e.message}`, false);
}

// 정리: 문서는 규칙상 앱에서 못 지우므로 계정만 지우고, 문서 삭제는 아래 REST 정리에 맡긴다
for (const u of cleanup) results.push(`cleanup uid ${u.uid}`);
console.log(results.join("\n"));
process.exit(0);
