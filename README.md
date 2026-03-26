# Cloud Resume Challenge — AWS

**Live Site:** https://d19mfjmr0dtnqm.cloudfront.net/
*(HTTPS + CloudFront URL will replace this in Week 2)*


---

## What This Is

A hands-on cloud engineering project built to demonstrate real AWS
infrastructure skills — not just theory. Based on the
[Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/)
by Forrest Brazeal.

This project deploys a personal resume as a live, serverless web
application on AWS — built, automated, and managed entirely through
code.

---

## What I'm Learning & Practicing

| Skill | Service | Status |
|---|---|---|
| Static website hosting | S3 | ✅ Week 1 |
| CDN + HTTPS | CloudFront + ACM | 🟡 Week 2 |
| DNS configuration | Route 53 | 🟡 Week 3 |
| Serverless compute | Lambda (Python) | ⬜ Week 4 |
| NoSQL database | DynamoDB | ⬜ Week 4 |
| REST API | API Gateway | ⬜ Week 5 |
| Infrastructure as Code | Terraform | ⬜ Week 6 |
| CI/CD automation | GitHub Actions | ⬜ Week 7 |
| Unit testing | Python + pytest | ⬜ Week 8 |

---

## Architecture
```
User → CloudFront (CDN + HTTPS)
          └→ S3 (Static Website — HTML/CSS)
          └→ API Gateway → Lambda → DynamoDB
                          (Visitor Counter)
```

*Diagram will be added in Week 6 once Terraform is complete.*

---

## Tech Stack

- **Cloud:** AWS (S3, CloudFront, ACM, Route 53, Lambda,
  DynamoDB, API Gateway, IAM)
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Language:** Python, HTML, CSS
- **Testing:** pytest

---

## Project Structure
```
cloud-resume-challenge-aws/
├── website/
│   └── index.html          # Resume — deployed to S3
├── terraform/
│   ├── main.tf             # All AWS infrastructure as code
│   └── variables.tf        # Configurable values
├── lambda/
│   ├── counter.py          # Visitor counter function
│   └── test_counter.py     # Unit tests
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD pipeline
└── README.md
```

---

## SOP — How to Deploy This Yourself

> **Prerequisites:** AWS account, AWS CLI configured,
> Terraform installed, GitHub account, Python 3.x installed

### Step 1 — Clone the repo
```bash
git clone https://github.com/RavjotD/cloud-resume-challenge-aws.git
cd cloud-resume-challenge-aws
```

### Step 2 — Configure AWS credentials
```bash
aws configure
```

Enter your:
- AWS Access Key ID: `[YOUR_ACCESS_KEY]`
- AWS Secret Access Key: `[YOUR_SECRET_KEY]`
- Default region: `[YOUR_REGION]` *(e.g. ca-central-1)*
- Default output format: `json`

### Step 3 — Create S3 bucket
```bash
aws s3 mb s3://[YOUR-BUCKET-NAME] --region [YOUR-REGION]
aws s3 website s3://[YOUR-BUCKET-NAME] --index-document index.html
```

### Step 4 — Allow public access
```bash
aws s3api put-public-access-block \
  --bucket [YOUR-BUCKET-NAME] \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,\
BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

### Step 5 — Apply bucket policy

Create a file called `bucket-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::[YOUR-BUCKET-NAME]/*"
    }
  ]
}
```

Apply it:
```bash
aws s3api put-bucket-policy \
  --bucket [YOUR-BUCKET-NAME] \
  --policy file://bucket-policy.json
```

### Step 6 — Deploy resume to S3
```bash
aws s3 cp website/index.html s3://[YOUR-BUCKET-NAME]/index.html
```

### Step 7 — Deploy infrastructure with Terraform
*(Available Week 6)*
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 8 — Set up GitHub Actions CI/CD
*(Available Week 7)*

Add these secrets to your GitHub repo under
**Settings → Secrets and variables → Actions:**

| Secret Name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM user secret key |
| `AWS_REGION` | Your AWS region |
| `S3_BUCKET` | Your bucket name |

---

## Progress Log

- **Week 1 — Mar 2026:** S3 static website live.
  HTML resume deployed. GitHub repo initialized.
- **Week 2 — Mar 2026:** CloudFront distribution deployed.
  HTTPS live at https://[your-cloudfront-domain].cloudfront.net.
  Cache invalidation tested manually.- **Week 3 — *(upcoming)*:** DNS via Route 53
- **Week 4 — *(upcoming)*:** Lambda + DynamoDB visitor counter
- **Week 5 — *(upcoming)*:** API Gateway
- **Week 6 — *(upcoming)*:** Full Terraform IaC
- **Week 7 — *(upcoming)*:** GitHub Actions CI/CD
- **Week 8 — *(upcoming)*:** Tests + final documentation

---

## Author

**Ravjot Duhra**
[LinkedIn](https://www.linkedin.com/in/ravjot-duhra/) ·
[GitHub](https://github.com/RavjotD)

*Part of a multi-cloud portfolio — Azure version coming after
AWS is complete.*
