const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkUsers() {
  const snapshot = await db.collection('users').get();
  if (snapshot.empty) {
    console.log('No users found.');
    return;
  }

  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`ID: ${doc.id}, Name: ${data.name}, Role: ${data.role}`);
  });
}

checkUsers();
