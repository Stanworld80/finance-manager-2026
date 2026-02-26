const admin = require('firebase-admin');

// 1. Initialize admin SDK with default app (assumes running with proper credentials)
// Since we don't have a service account key easily, we will run this from an authenticated
// Firebase CLI session: `firebase login` and `firebase use finance-manager-2026-stg`
// Alternatively, we use application default credentials.

var serviceAccount = require("../service-account-key.json"); // We need to create this

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixAccounts() {
    console.log("Fixing accounts...");
    const accountsSnapshot = await db.collection('accounts').get();
    
    let updatedCount = 0;
    for (const doc of accountsSnapshot.docs) {
        const data = doc.data();
        let updateData = {};
        
        if (!data.ownerId && data.userId) {
            updateData.ownerId = data.userId;
        } else if (!data.ownerId && !data.userId) {
             console.log(`Account ${doc.id} has no ownerId or userId. Skipping.`);
        }
        
        if (!data.accessibleUserIds) {
            updateData.accessibleUserIds = [data.ownerId || data.userId];
        }

        if (Object.keys(updateData).length > 0) {
             console.log(`Updating account ${doc.id} with`, updateData);
             await doc.ref.update(updateData);
             updatedCount++;
        }
    }
    console.log(`Finished fixing ${updatedCount} accounts.`);
}

async function fixTransactions() {
    console.log("Fixing transactions...");
    const accountsSnapshot = await db.collection('accounts').get();
    
    let updatedCount = 0;
    for (const accountDoc of accountsSnapshot.docs) {
        const ownerId = accountDoc.data().ownerId || accountDoc.data().userId;
        
        if (!ownerId) {
            console.log(`Account ${accountDoc.id} has no owner. Skipping its txs.`);
            continue;
        }

        const txSnapshot = await accountDoc.ref.collection('transactions').get();
        for (const txDoc of txSnapshot.docs) {
             const data = txDoc.data();
             let updateData = {};
             
             if (!data.ownerId) {
                  updateData.ownerId = ownerId;
             }
             
             if (Object.keys(updateData).length > 0) {
                 console.log(`Updating tx ${txDoc.id} in account ${accountDoc.id}`);
                 await txDoc.ref.update(updateData);
                 updatedCount++;
             }
        }
    }
    console.log(`Finished fixing ${updatedCount} transactions.`);
}

async function main() {
    await fixAccounts();
    await fixTransactions();
}

main().catch(console.error);
