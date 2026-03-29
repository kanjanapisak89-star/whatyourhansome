# Railway Deployment Setup for Frontend

## ไฟล์ที่ต้องสร้าง

สร้างไฟล์ `railway.json` ใน frontend directory:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "restartPolicyType": "ON_FAILURE"
  }
}
```

## Environment Variables ที่ต้องตั้งค่าใน Railway

ใน Railway Dashboard → Variables:

```
API_BASE_URL=https://your-backend.railway.app
```

(เปลี่ยน `your-backend.railway.app` เป็น URL จริงของ backend)

## Firebase Authentication Setup

1. ไปที่: https://console.firebase.google.com/project/loft-71a46/authentication/providers
2. คลิก "Get started" (ถ้ายังไม่เคยเปิด)
3. เปิดใช้งาน "Google" provider
4. ใส่ support email
5. คลิก "Save"

## Deploy Steps

### ทางเลือก 1: Deploy ผ่าน Railway Dashboard

1. ไปที่ https://railway.app/
2. คลิก "New Project"
3. เลือก "Deploy from GitHub repo"
4. เลือก repo: `whatyourhansome`
5. เลือก root directory: `frontend`
6. Railway จะ detect Dockerfile และ build อัตโนมัติ

### ทางเลือก 2: Deploy ผ่าน Railway CLI

```bash
# ติดตั้ง Railway CLI
npm i -g @railway/cli

# Login
railway login

# ใน frontend directory
cd frontend

# Deploy
railway up
```

## หลัง Deploy สำเร็จ

1. คัดลอก URL ของ frontend จาก Railway
2. อัพเดท Firebase Authorized domains:
   - ไปที่ Firebase Console → Authentication → Settings
   - เพิ่ม domain ของ Railway ใน "Authorized domains"

3. ทดสอบ:
   - เปิด URL ของ frontend
   - ลองกด "Login with Google"
   - ตรวจสอบว่าล็อกอินได้

## Troubleshooting

### ถ้า Build ล้มเหลว
- ตรวจสอบ logs ใน Railway Dashboard
- ตรวจสอบว่า Dockerfile อยู่ใน frontend directory

### ถ้า Login ไม่ได้
- ตรวจสอบว่าเปิดใช้งาน Google Sign-in ใน Firebase
- ตรวจสอบว่าเพิ่ม domain ใน Authorized domains แล้ว
- ตรวจสอบว่า API_BASE_URL ถูกต้อง

### ถ้า API ไม่ทำงาน
- ตรวจสอบว่า backend ทำงานอยู่
- ตรวจสอบ CORS settings ใน backend
- ตรวจสอบว่า API_BASE_URL ถูกต้อง
