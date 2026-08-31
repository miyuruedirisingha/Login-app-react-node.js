# Auth Project (React + Node.js + JWT)

Monorepo: `frontend` (React) + `backend` (Node.js/Express + MongoDB, JWT auth), Dockerized, with Terraform (AWS) and a Jenkins pipeline.

## Structure
```
auth-project/
├── backend/          # Express API (register/login/profile, JWT, MongoDB)
├── frontend/         # React app (Login/Register/Dashboard)
├── terraform/         # AWS infra: VPC, EC2, ECR, IAM
├── docker-compose.yml
└── Jenkinsfile
```

## 1. Run locally with Docker Compose (do this first)
```bash
cd auth-project
cp .env.example .env          # edit JWT_SECRET
docker compose up --build
```
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000/api
- MongoDB: localhost:27017 (container)

Test the API directly:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Kasun","email":"kasun@test.com","password":"secret123"}'
```

## 2. Run backend/frontend without Docker (dev mode)
```bash
# backend
cd backend && cp .env.example .env
npm install && npm run dev     # needs local mongod or update MONGO_URI

# frontend (new terminal)
cd frontend
echo "REACT_APP_API_URL=http://localhost:5000/api" > .env
npm install && npm start
```

## 3. Provision AWS infra with Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit key_pair_name, jwt_secret etc.
terraform init
terraform plan
terraform apply
```
Creates: VPC + subnet, security group, 2x ECR repos (frontend/backend), IAM role, EC2 instance that auto-installs Docker and runs the app via `docker compose` on boot.

## 4. Jenkins Pipeline
The `Jenkinsfile` at repo root:
1. Checkout → install/build backend & frontend
2. Build Docker images
3. Push images to ECR
4. `terraform apply` to (re)provision infra
5. SSH into the EC2 box → `docker compose pull && up -d`

### Jenkins credentials needed (Manage Jenkins → Credentials)
| ID | Type | Purpose |
|---|---|---|
| `aws-account-id` | Secret text | Your 12-digit AWS account ID |
| `aws-jenkins-creds` | AWS Credentials | IAM user/role with ECR + EC2 + Terraform permissions |
| `jwt-secret` | Secret text | JWT signing secret passed to Terraform |
| `ec2-ssh-key` | SSH Username with private key | Key pair matching `key_pair_name` in terraform.tfvars |

### Jenkins requirements on the agent
- Node.js (matching frontend/backend needs)
- Docker installed + Jenkins user in `docker` group
- AWS CLI
- Terraform CLI
- `sshagent` (SSH Agent plugin) for the deploy stage

## Security notes before production
- Change `JWT_SECRET` to a long random value.
- Restrict `ssh_allowed_cidr` in `terraform.tfvars` to your IP, not `0.0.0.0/0`.
- Put MongoDB behind auth / use MongoDB Atlas instead of a plain container in production.
- Consider ALB + HTTPS (ACM cert) instead of exposing EC2 directly on port 80.
