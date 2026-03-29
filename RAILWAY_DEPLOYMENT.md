# Railway Deployment Checklist

## ✅ Steps to Deploy Successfully

### 1. Add PostgreSQL Database
```bash
railway add postgresql
```
This automatically sets `DATABASE_URL` environment variable.

### 2. Run Database Migrations
After PostgreSQL is added, you need to run migrations. You can either:

**Option A: Connect locally and migrate**
```bash
# Get the DATABASE_URL from Railway
railway variables

# Run migrations locally
migrate -path backend/migrations -database "YOUR_DATABASE_URL" up
```

**Option B: Add migration step to Dockerfile** (Recommended)
The current Dockerfile doesn't run migrations. You'll need to run them manually once.

### 3. Set Firebase Credentials
```bash
# Copy your Firebase service account JSON content
railway variables set GOOGLE_APPLICATION_CREDENTIALS='{"type":"service_account","project_id":"your-project",...}'
```

Or upload via Railway dashboard:
1. Go to your project → Variables
2. Add `GOOGLE_APPLICATION_CREDENTIALS`
3. Paste the entire JSON content

### 4. Verify Environment Variables
Check that these are set:
- ✅ `DATABASE_URL` (auto-set by Railway)
- ✅ `GOOGLE_APPLICATION_CREDENTIALS` (you set this)
- ✅ `PORT` (optional, defaults to 8080)

### 5. Deploy
```bash
git push origin main
```

Railway will automatically:
1. Detect the Dockerfile
2. Build the Docker image
3. Deploy the container
4. Assign a public URL

### 6. Get Your Deployment URL
```bash
railway domain
```

Or check the Railway dashboard for your app's public URL.

### 7. Test the Deployment
```bash
# Health check (if you have one)
curl https://your-app.railway.app/health

# Test public endpoint
curl -X POST https://your-app.railway.app/loft.v1.PublicService/GetFeed \
  -H "Content-Type: application/json" \
  -d '{}'
```

## 🔧 Troubleshooting

### Build Fails
- Check Railway logs: `railway logs`
- Verify Dockerfile syntax
- Ensure all Go dependencies are in go.mod

### App Crashes on Start
- Check `GOOGLE_APPLICATION_CREDENTIALS` is valid JSON
- Verify `DATABASE_URL` is accessible
- Check logs: `railway logs`

### Database Connection Issues
- Ensure migrations have run
- Check DATABASE_URL format
- Verify PostgreSQL service is running

### Firebase Auth Issues
- Verify Firebase service account JSON is complete
- Check Firebase project settings
- Ensure service account has correct permissions

## 📱 Update Flutter App

Once deployed, update your Flutter app's `.env`:

```bash
API_BASE_URL=https://your-app.railway.app
```

Then rebuild the Flutter app:
```bash
cd frontend
flutter pub get
flutter run
```

## 🎉 Success Indicators

Your deployment is successful when:
- ✅ Railway build completes without errors
- ✅ App starts and stays running (check logs)
- ✅ Public endpoints respond (test with curl)
- ✅ Database queries work
- ✅ Firebase auth validates tokens

## 📊 Monitor Your App

```bash
# View logs
railway logs

# Check status
railway status

# View variables
railway variables
```

---

**Current Status**: Docker build is in progress. Wait for it to complete, then follow steps 2-7 above.
