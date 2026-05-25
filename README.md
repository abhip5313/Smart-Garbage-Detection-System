# 🗑️ Smart Garbage Detection System

> **AI-Powered | Serverless | AWS Cloud | Real-Time Complaint Dashboard**

A fully serverless web application that allows citizens to **capture garbage images, auto-detect their GPS location, and submit complaints** — which are then analyzed using **AWS Rekognition** and **Clipdrop AI**, stored in **DynamoDB**, and reviewed by admins via a **secure OTP-protected dashboard**.

---

## 🌐 Live Demo

> Hosted on AWS CloudFront CDN  
> **URL:** `https://dqeokaapk0jcc.cloudfront.net`

---

## 📸 Screenshots

| Complaint UI | Admin Dashboard |
|---|---|
| ![UI](screenshots/ui.png) | ![Admin](screenshots/admin.png) |

---

## ✨ Features

- 📷 **Camera Capture** — Open device camera directly in browser, no app install needed
- 📍 **Auto GPS Location** — Fetches precise coordinates using browser Geolocation API
- 🗺️ **Reverse Geocoding** — Converts GPS coords to human-readable address automatically
- ☁️ **Secure S3 Upload** — Images uploaded via presigned URLs (no credentials exposed)
- 🤖 **AI Image Enhancement** — Clipdrop Super-Resolution improves image quality before analysis
- 👁️ **AWS Rekognition** — Detects faces, emotions and severity from the enhanced image
- 🗃️ **DynamoDB Storage** — All complaint data stored: ImageID, severity, message, location, address, time
- 👮 **Admin Panel** — Real-time dashboard with severity badge, GPS links, image viewer
- 🔐 **OTP Verification** — Custom-built OTP system secures the admin panel access
- 🌍 **Global CDN** — CloudFront serves the frontend with free HTTPS worldwide

---

## 🏗️ Architecture

```
User Browser
    │
    ├── 📷 Capture Image + GPS Location
    │
    ▼
CloudFront CDN  ──►  S3 (UI Bucket)
    │
    ▼
API Gateway (HTTP API)
    │
    ├── GET /upload-url  ──►  UploadImageLambda  ──►  S3 Presigned URL
    │
    ├── GET /result      ──►  GetImageResultLambda  ──►  DynamoDB
    │
    └── GET /all-results ──►  GetAllResultsLambda   ──►  DynamoDB
                                                          (Admin Panel)

S3 Image Upload
    │
    └── S3 Event Trigger
            │
            ▼
    ProcessImageLambda
            │
            ├── Clipdrop Super-Resolution (enhance image)
            ├── AWS Rekognition (detect faces/emotions)
            └── DynamoDB (store results)
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | HTML5, CSS3, Vanilla JavaScript |
| **Hosting** | AWS S3 + CloudFront CDN |
| **API** | AWS API Gateway (HTTP API) |
| **Backend** | AWS Lambda (Python 3.10) |
| **Storage** | Amazon S3 (images), Amazon DynamoDB (results) |
| **AI — Enhancement** | Clipdrop Super-Resolution API |
| **AI — Analysis** | AWS Rekognition |
| **Security** | Custom OTP Verification System |
| **IaC** | Terraform |

---

## 📁 Project Structure

```
Image-Recognition-App/
│
├── frontend/
│   ├── index.html          # Complaint submission UI
│   ├── style.css           # Styling
│   └── script.js           # Camera, GPS, upload logic
│
├── lambda/
│   ├── upload_lambda.py         # Generates S3 presigned URL
│   ├── process_image_lambda.py  # Enhance → Rekognition → DynamoDB
│   ├── get_result_lambda.py     # Fetch single result by ImageID
│   └── get_all_results_lambda.py# Fetch all results (Admin Panel)
│
├── apigateway.tf           # HTTP API + routes + CORS
├── cloudfront.tf           # CDN distribution
├── dynamoDB.tf             # DynamoDB table definition
├── iam.tf                  # Lambda IAM roles & permissions
└── lambda_env/             # Lambda environment variable configs
```

---

## 🗄️ DynamoDB Table Schema

**Table Name:** `ImageRecognitionResults`

| Field | Type | Description |
|---|---|---|
| `ImageID` | String (PK) | Unique UUID filename — Partition key |
| `severity` | String | Garbage severity — e.g. Clean / Dirty / Severe |
| `message` | String | Complaint message entered by the user |
| `location` | String | GPS coordinates (latitude, longitude) |
| `address` | String | Reverse geocoded human-readable address |
| `time` | String | ISO datetime of complaint submission |

---

## ⚡ Lambda Functions

### 1. `UploadImageLambda`
- **Trigger:** `GET /upload-url` via API Gateway
- **Purpose:** Generates a secure S3 presigned URL for direct image upload from browser
- Handles CORS preflight (OPTIONS) requests

### 2. `ProcessImageLambda`
- **Trigger:** S3 `ObjectCreated` event
- **Purpose:** Full AI pipeline —
  1. Fetches uploaded image from S3
  2. Enhances it via Clipdrop Super-Resolution API
  3. Saves enhanced image to `enhanced/` prefix in S3
  4. Runs AWS Rekognition `detect_faces()` on enhanced image
  5. Stores result in DynamoDB
- Has loop protection (skips `enhanced/` and `reports/` keys)

### 3. `GetImageResultLambda`
- **Trigger:** `GET /result?image=<ImageID>` via API Gateway
- **Purpose:** Fetches a single complaint result from DynamoDB by `ImageID`
- Handles `Decimal` serialization for JSON response

### 4. `GetAllResultsLambda`
- **Trigger:** `GET /all-results` via API Gateway
- **Purpose:** Returns all complaint records for the Admin Panel dashboard

---

## 🔐 OTP Verification System

The Admin Panel is protected by a custom-built OTP verification system:

1. Admin navigates to the `/admin` route
2. System generates a one-time code
3. OTP is sent to the admin (email/SMS)
4. Admin enters the code in the UI
5. On success, full dashboard access is granted

> Built with AWS Lambda + API Gateway — no third-party auth library required.

---

## 🚀 Deployment

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform installed (`>= 1.0`)
- Python 3.10+
- Clipdrop API Key → [clipdrop.co](https://clipdrop.co/apis)

### Steps

**1. Clone the repo**
```bash
git clone https://github.com/your-username/smart-garbage-detection.git
cd smart-garbage-detection
```

**2. Set environment variables**

Create a `lambda_env/process_image.env` file:
```
BUCKET_NAME=your-s3-bucket-name
CLIPDROP_API_KEY=your_clipdrop_key
```

**3. Package Lambda functions**
```bash
cd lambda
zip upload_lambda.zip upload_lambda.py
zip process_image_lambda.zip process_image_lambda.py
zip get_result_lambda.zip get_result_lambda.py
zip get_all_results_lambda.zip get_all_results_lambda.py
```

**4. Deploy with Terraform**
```bash
terraform init
terraform plan
terraform apply
```

**5. Upload frontend to S3**
```bash
aws s3 sync frontend/ s3://your-ui-bucket-name/
```

**6. Open CloudFront URL**

Get the URL from Terraform output or AWS Console → CloudFront → Distributions.

---

## 🌍 AWS Resources Created

| Resource | Name | Region |
|---|---|---|
| S3 Bucket (Images) | `image-recognition-image-<account-id>` | ap-south-1 |
| S3 Bucket (UI) | `image-recognition-ui` | ap-south-1 |
| DynamoDB Table | `ImageRecognitionResults` | ap-south-1 |
| Lambda Functions | 4 functions (Python 3.10) | ap-south-1 |
| API Gateway | HTTP API | ap-south-1 |
| CloudFront | Standard Distribution | Global |

---

## 🔮 Future Enhancements

- [ ] Native mobile app (React Native)
- [ ] Analytics dashboard with charts
- [ ] Map view with complaint pins (Google Maps integration)
- [ ] Push notifications for status updates
- [ ] Multi-city / multi-ward support
- [ ] Trend analysis & heat maps

---

## 👨‍💻 Author

**Abhishek Pawar**

---

## 📄 License

This project is licensed under the MIT License.

---

> ⭐ If you found this project helpful, please give it a star!
