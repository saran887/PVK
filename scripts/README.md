# Firebase Admin Scripts

## Setup

1. Download your Firebase service account key from Firebase Console:
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save as `service-account-key.json` in the `scripts` folder

2. Install dependencies:
   ```
   cd scripts
   npm install
   ```

## Cleanup Database

To remove all products, locations, and shops from the database:

```
cd scripts
npm run cleanup
```

**Warning:** This will permanently delete all products, locations, and shops. Make sure you have backups if needed.
