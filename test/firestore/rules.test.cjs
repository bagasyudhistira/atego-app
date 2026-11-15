const { before, after, beforeEach, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, deleteField, runTransaction } = require('firebase/firestore');

let env;
const employee = { employee_id: 'TEST-001', name: 'Test Employee', email: 'test@example.invalid', role: 'employee', job: 'QA', created_at: '2026-11-16T08:00:00' };
const event = { date: '2026-11-16T08:00:00', latitude: -7.766026, longitude: 110.371772, address: 'Test office', in_area: true, distance: 100, on_time: true };
const entry = { date: event.date, masuk: event };
const checkout = { ...event, date: '2026-11-16T16:00:00', in_area: false, distance: 250 };
const db = (uid = 'alice', verified = true) => env.authenticatedContext(uid, { email_verified: verified }).firestore();
const presence = (store, uid = 'alice', day = '11-16-2026') => doc(store, `employee/${uid}/presence/${day}`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-atego-rules',
    firestore: { rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8') },
  });
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'employee/alice'), employee);
    await setDoc(doc(context.firestore(), 'employee/bob'), employee);
    await setDoc(doc(context.firestore(), 'employee/admin'), { ...employee, role: 'admin' });
  });
});

test('only verified employees can access their own data; listing employees is denied', async () => {
  await assertSucceeds(getDoc(doc(db(), 'employee/alice')));
  await assertSucceeds(getDocs(collection(db(), 'employee/alice/presence')));
  await assertFails(getDoc(doc(db(), 'employee/bob')));
  await assertFails(getDocs(collection(db(), 'employee')));
  await assertFails(getDoc(doc(db('alice', false), 'employee/alice')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'employee/alice')));
  await assertFails(getDoc(doc(db('admin'), 'employee/alice')));
  await assertFails(setDoc(presence(db('missing'), 'missing'), entry));
});

test('profile updates allow location and name but protect identity and role', async () => {
  const ref = doc(db(), 'employee/alice');
  await assertSucceeds(updateDoc(ref, { name: 'Updated Test', position: { latitude: 0, longitude: 0 }, address: 'Office', avatar: 'https://example.invalid/avatar.png' }));
  await assertSucceeds(updateDoc(ref, { avatar: deleteField() }));
  for (const patch of [{ role: 'admin' }, { email: 'other@example.invalid' }, { employee_id: 'OTHER' }, { created_at: 'changed' }, { name: '' }, { position: { latitude: 91, longitude: 0 } }, { position: { latitude: 0 } }, { address: 42 }, { arbitrary: true }]) {
    await assertFails(updateDoc(ref, patch));
  }
  await assertFails(deleteDoc(ref));
  await assertFails(setDoc(doc(db(), 'employee/new'), employee));
});

test('attendance transactions allow one check-in followed by one check-out', async () => {
  const store = db();
  const ref = presence(store);
  await assertSucceeds(runTransaction(store, async (tx) => {
    await tx.get(ref);
    tx.set(ref, entry, { merge: true });
  }));
  await assertSucceeds(runTransaction(store, async (tx) => {
    await tx.get(ref);
    tx.update(ref, { keluar: checkout });
  }));
  await assertFails(updateDoc(ref, { keluar: { ...checkout, distance: 300 } }));
  await assertFails(updateDoc(ref, { masuk: { ...event, distance: 0 } }));
  await assertFails(deleteDoc(ref));
  await assertFails(getDoc(presence(db('bob'))));
});

test('invalid attendance and cross-user writes are denied', async () => {
  const store = db();
  const ref = presence(store);
  await assertFails(setDoc(presence(store, 'bob'), entry));
  await assertFails(setDoc(ref, { date: event.date, keluar: checkout }));
  await assertFails(setDoc(ref, { ...entry, keluar: checkout }));
  await assertFails(setDoc(ref, { ...entry, masuk: { ...event, latitude: 91 } }));
  await assertFails(setDoc(ref, { ...entry, masuk: { ...event, distance: 201 } }));
  await assertFails(setDoc(ref, { ...entry, masuk: { ...event, in_area: false } }));
  await assertFails(setDoc(ref, { ...entry, extra: true }));
  await assertSucceeds(setDoc(ref, entry));
  await assertFails(updateDoc(ref, { keluar: { ...checkout, date: '2026-11-16T07:00:00' } }));
  await assertFails(updateDoc(ref, { date: 'changed', keluar: checkout }));
  await assertFails(updateDoc(ref, { keluar: { ...checkout, on_time: 'yes' } }));
});
