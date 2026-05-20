Yes — you need a proper `README.md` that includes the architecture, implementation, CI/CD explanation, testing evidence, troubleshooting, and submission details.

Below is a complete README you can paste into your infrastructure repository.

---

# Step 1: Open Your Infrastructure README

Run:

```powershell
cd C:\Users\User\Documents\starttech-infra
code README.md
```

Delete the current content and paste this:

````markdown
# StartTech Full-Stack Cloud Deployment with Terraform, Docker, GitHub Actions, ALB, MongoDB Atlas, and ElastiCache Redis

## 1. Project Overview

This project implements a complete DevOps deployment workflow for StartTech’s full-stack task management application. The assessment required the deployment of a React frontend, a Golang backend API, Redis caching, MongoDB database persistence, infrastructure automation, CI/CD pipelines, monitoring, and security controls.

The application architecture includes:

- React frontend deployed to Amazon S3
- CloudFront CDN for global frontend delivery
- Golang backend containerized with Docker
- Backend deployed on EC2 instances managed by an Auto Scaling Group
- Application Load Balancer for backend traffic distribution
- Amazon ECR for backend Docker image storage
- Amazon ElastiCache Redis for caching and sessions
- MongoDB Atlas for managed database persistence
- CloudWatch Log Groups for application monitoring
- Terraform for Infrastructure as Code
- GitHub Actions for CI/CD automation

The goal was to create a production-style deployment where infrastructure and application delivery are automated from code commit to deployment.

---

## 2. Assessment Requirements Covered

The assessment required the following core components:

- Infrastructure managed with Terraform
- Auto Scaling Group for backend EC2 instances
- Application Load Balancer with target group
- S3 bucket for frontend hosting
- CloudFront distribution
- ElastiCache Redis cluster
- MongoDB Atlas database
- CloudWatch Log Groups
- IAM roles and policies
- Security Groups
- Frontend CI/CD pipeline
- Backend CI/CD pipeline
- Infrastructure CI/CD pipeline
- Monitoring and documentation

The assessment also required two repositories:

1. Application repository with frontend and backend CI/CD workflows
2. Infrastructure repository with Terraform and infrastructure CI/CD workflow

---

## 3. Repository Links

### Infrastructure Repository

```text
https://github.com/taiwohassanajadi/starttech-infra
````

### Application Repository

```text
PASTE_YOUR_FORKED_APPLICATION_REPOSITORY_URL_HERE
```

---

## 4. System Architecture

### 4.1 High-Level Architecture Diagram

```text
                         Internet Users
                              |
                              v
                      +----------------+
                      |   CloudFront   |
                      |  CDN Frontend  |
                      +----------------+
                              |
                              v
                      +----------------+
                      |   S3 Bucket    |
                      | React Frontend |
                      +----------------+


                         API Requests
                              |
                              v
                    +----------------------+
                    | Application Load     |
                    | Balancer - Public    |
                    +----------------------+
                              |
             -------------------------------------
             |                                   |
             v                                   v
   +--------------------+              +--------------------+
   | EC2 Backend App    |              | EC2 Backend App    |
   | Private Subnet 1   |              | Private Subnet 2   |
   | Docker Container   |              | Docker Container   |
   +--------------------+              +--------------------+
             |                                   |
             -------------------------------------
                              |
              ---------------------------------
              |                               |
              v                               v
   +---------------------+         +----------------------+
   | ElastiCache Redis   |         | MongoDB Atlas        |
   | Private Cache Layer |         | Managed Database     |
   +---------------------+         +----------------------+

                              |
                              v
                    +----------------------+
                    | CloudWatch Logs      |
                    | Monitoring & Logs    |
                    +----------------------+
```

---

## 5. Architecture Explanation

### 5.1 Frontend Layer

The frontend is a React application. It is built into static production files and deployed to an Amazon S3 bucket. CloudFront is placed in front of S3 to provide faster global content delivery and caching.

### 5.2 Backend Layer

The backend is a Golang API. It is packaged into a Docker image and pushed to Amazon ECR. EC2 instances in private subnets pull the Docker image from ECR and run the backend container.

The backend is not directly exposed to the internet. All external backend traffic must pass through the Application Load Balancer.

### 5.3 Load Balancing Layer

The Application Load Balancer receives HTTP traffic and forwards requests to healthy backend EC2 instances registered in the target group.

The ALB performs health checks against the backend service to determine whether instances are healthy.

### 5.4 Auto Scaling Layer

An Auto Scaling Group manages backend EC2 instances. The desired capacity was configured to run multiple backend instances for availability.

If an instance becomes unhealthy or is terminated, the Auto Scaling Group replaces it automatically.

### 5.5 Database Layer

MongoDB Atlas was selected as the managed database solution instead of running MongoDB as a container. This reduced operational complexity and avoided managing database storage, replication, backups, and failover manually.

### 5.6 Cache Layer

Amazon ElastiCache Redis was used for caching and session storage instead of running Redis as a container. This follows cloud-native best practice by using a managed cache service.

### 5.7 Monitoring Layer

CloudWatch Log Groups were created for backend application logs. The EC2 role was configured with the necessary permissions for CloudWatch and Systems Manager.

---

## 6. Why MongoDB Atlas Was Used

MongoDB Atlas was used because it removes the operational burden of managing MongoDB on EC2 or inside a Docker container.

Benefits include:

* Managed database hosting
* Automatic backups
* Improved reliability
* Built-in security controls
* Easier connection through MongoDB URI
* Better production readiness

This means the backend container only needs the MongoDB URI injected as an environment variable.

---

## 7. Why ElastiCache Redis Was Used

Redis was deployed using Amazon ElastiCache because it is a managed AWS service.

Benefits include:

* No Redis container maintenance
* AWS-managed patching and availability
* Private subnet deployment
* Better integration with AWS networking
* Improved reliability for caching and sessions

---

## 8. Infrastructure Components Implemented

### 8.1 VPC and Networking

The Terraform configuration created:

* Custom VPC
* Two public subnets
* Two private subnets
* Internet Gateway
* NAT Gateway
* Route tables
* Route table associations

Public subnets were used for the ALB, NAT Gateway, and CloudFront/S3 access path.

Private subnets were used for backend EC2 instances and Redis.

### 8.2 Security Groups

The following security groups were created:

* ALB Security Group
* Backend EC2 Security Group
* Redis Security Group

Security design:

* Internet traffic is allowed only to the ALB
* Backend EC2 instances accept traffic only from the ALB
* Redis accepts traffic only from backend instances
* Backend instances are not directly exposed publicly

### 8.3 IAM Roles

The EC2 backend role was configured with permissions for:

* Pulling Docker images from ECR
* Sending logs to CloudWatch
* Using Systems Manager Session Manager for debugging

### 8.4 ECR Repository

An Amazon ECR repository was created to store backend Docker images.

Repository:

```text
starttech-dev-backend
```

### 8.5 Launch Template

A Launch Template was created for backend EC2 instances. It installs Docker, logs in to ECR, pulls the latest backend image, and runs the backend container.

### 8.6 Auto Scaling Group

An Auto Scaling Group was created to manage backend EC2 instances.

The ASG ensures:

* Multiple backend instances are running
* Failed instances are replaced
* Rolling updates can be triggered using instance refresh

### 8.7 Application Load Balancer

The ALB was configured with:

* Listener on HTTP port 80
* Target Group on backend port 8080
* Health check path
* Public DNS output

Backend ALB DNS:

```text
starttech-dev-backend-alb-1263910639.eu-north-1.elb.amazonaws.com
```

### 8.8 S3 and CloudFront

The frontend hosting layer included:

* S3 bucket for React static files
* CloudFront distribution for CDN delivery

CloudFront domain:

```text
d31ltfyuxkn26n.cloudfront.net
```

### 8.9 ElastiCache Redis

Redis was deployed in private subnets using AWS ElastiCache.

Redis endpoint:

```text
starttech-dev-redis.2cgszr.0001.eun1.cache.amazonaws.com
```

### 8.10 CloudWatch Log Group

A backend CloudWatch log group was created:

```text
/starttech/dev/backend
```

---

## 9. CI/CD Pipeline Design

## 9.1 Infrastructure CI/CD Pipeline

The infrastructure repository contains:

```text
.github/workflows/infrastructure-deploy.yml
```

The infrastructure pipeline is responsible for:

* Checking out the repository
* Configuring AWS credentials
* Running Terraform format check
* Running Terraform init
* Running Terraform validate
* Running Terraform plan
* Running Terraform apply when approved

Typical pipeline flow:

```text
GitHub Push → GitHub Actions → Terraform Init → Validate → Plan → Apply → AWS Infrastructure Updated
```

---

## 9.2 Backend CI/CD Pipeline

The backend pipeline is responsible for:

* Running Go tests
* Building Docker image
* Authenticating to Amazon ECR
* Tagging Docker image
* Pushing Docker image to ECR
* Triggering Auto Scaling Group instance refresh
* Running backend smoke tests

Backend deployment flow:

```text
Code Push → GitHub Actions → Test → Docker Build → ECR Push → ASG Refresh → ALB Health Check
```

---

## 9.3 Frontend CI/CD Pipeline

The frontend pipeline is responsible for:

* Installing Node.js dependencies
* Running frontend tests
* Building React production files
* Running npm audit
* Syncing build files to S3
* Invalidating CloudFront cache

Frontend deployment flow:

```text
Code Push → GitHub Actions → npm install → npm build → S3 Sync → CloudFront Invalidation
```

---

## 10. Environment Variables and Secrets

Sensitive values are not hardcoded into the repository.

Required secrets include:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
MONGO_URI
JWT_SECRET_KEY
ECR_REPOSITORY
FRONTEND_BUCKET_NAME
CLOUDFRONT_DISTRIBUTION_ID
```

MongoDB Atlas connection string is injected into the backend container as:

```text
MONGO_URI
```

Redis is injected using the ElastiCache endpoint.

---

## 11. Deployment Commands Used

### 11.1 Terraform Initialization

```powershell
cd C:\Users\User\Documents\starttech-infra\terraform
terraform init
```

### 11.2 Terraform Validation

```powershell
terraform fmt
terraform validate
```

### 11.3 Terraform Plan

```powershell
terraform plan
```

### 11.4 Terraform Apply

```powershell
terraform apply
```

### 11.5 Docker Build

```powershell
cd C:\Users\User\Documents\much-to-do\Server\MuchToDo
docker build -t starttech-backend .
```

### 11.6 ECR Login

```powershell
$PASSWORD = aws ecr get-login-password --region eu-north-1
docker login --username AWS --password $PASSWORD 135167709863.dkr.ecr.eu-north-1.amazonaws.com
```

### 11.7 Docker Tag

```powershell
docker tag starttech-backend:latest 135167709863.dkr.ecr.eu-north-1.amazonaws.com/starttech-dev-backend:latest
```

### 11.8 Docker Push

```powershell
docker push 135167709863.dkr.ecr.eu-north-1.amazonaws.com/starttech-dev-backend:latest
```

### 11.9 Auto Scaling Instance Refresh

```powershell
$env:Path += ";C:\Windows\System32"
$env:AWS_PAGER=""
aws autoscaling start-instance-refresh --auto-scaling-group-name starttech-dev-backend-asg --region eu-north-1
```

---

## 12. Testing and Validation

The following tests were performed:

### 12.1 Terraform Validation

Terraform configuration was validated successfully.

```text
Success! The configuration is valid.
```

### 12.2 Docker Image Build

The backend Docker image was built successfully.

### 12.3 ECR Push

The backend image was pushed successfully to Amazon ECR.

### 12.4 EC2 Instance Validation

Backend EC2 instances were launched by the Auto Scaling Group.

### 12.5 SSM Validation

Systems Manager Session Manager was used to connect to private backend instances securely without public IP access.

### 12.6 Target Group Validation

The backend instances were registered with the ALB target group.

### 12.7 Backend Debugging

Docker logs were inspected using:

```bash
sudo docker logs backend
```

### 12.8 Health Check Testing

The backend health endpoint was tested using:

```bash
curl localhost:8080/health
```

---

## 13. Challenges and Troubleshooting

### 13.1 GitHub Large File Push Error

Problem:

Terraform provider files and state files were accidentally staged for Git commit.

Solution:

A `.gitignore` file was created to exclude:

```text
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
*.tfvars
```

Then cached files were removed from Git tracking.

---

### 13.2 SSM Session Manager Not Connecting

Problem:

EC2 instances were private and EC2 Instance Connect was not available.

Solution:

SSM IAM permissions were added to the EC2 instance role:

```text
AmazonSSMManagedInstanceCore
```

This enabled secure access to private instances without public IP addresses.

---

### 13.3 Backend Container Exiting

Problem:

The backend container exited after startup due to MongoDB URI parsing.

Observed error:

```text
error parsing uri: scheme must be "mongodb" or "mongodb+srv"
```

Likely cause:

MongoDB URI was being passed incorrectly or contained formatting issues.

Solution approach:

* Verified MongoDB Atlas password
* Verified `MONGO_URI`
* Inspected Docker environment variables
* Adjusted Terraform user-data environment variable injection
* Triggered Auto Scaling instance refresh

---

### 13.4 Target Group Unhealthy

Problem:

The ALB target group showed unhealthy targets.

Cause:

The backend container was not running successfully, so port 8080 was not available.

Solution:

Backend logs were inspected through SSM and Docker to identify the MongoDB URI issue.

---

## 14. Security Practices Implemented

### Network Security

* Backend EC2 instances are in private subnets
* No public IP addresses on backend servers
* Public access only through ALB
* Redis deployed privately
* Security groups restrict traffic flow

### IAM Security

* EC2 uses IAM role instead of static AWS credentials
* Least privilege principle applied
* SSM access controlled through IAM

### Secret Handling

* Sensitive values excluded from Git
* `.tfvars` ignored
* MongoDB URI managed outside committed source code
* GitHub Secrets designed for CI/CD secret injection

### Container Security

* Backend image built using multi-stage Dockerfile
* Smaller runtime image used
* Docker image stored in private ECR repository

---

## 15. Monitoring and Observability

Monitoring setup includes:

* CloudWatch Log Group for backend logs
* ALB target group health checks
* EC2 instance status checks
* Auto Scaling Group activity history
* SSM Session Manager debugging

CloudWatch Log Group:

```text
/starttech/dev/backend
```

---

## 16. Evidence Collected

Screenshots were collected for:

* Terraform apply outputs
* EC2 running instances
* ALB target group
* Auto Scaling Group
* ECR repository image push
* S3 frontend bucket
* CloudFront distribution
* ElastiCache Redis
* MongoDB Atlas setup
* SSM debugging session
* Docker container logs

---

## 17. Known Limitation at Submission Time

The full infrastructure was successfully provisioned, and the backend Docker image was successfully built and pushed to ECR.

At the time of documentation, backend runtime debugging was still ongoing due to MongoDB URI parsing inside the container. The issue was isolated to application environment variable injection rather than infrastructure provisioning.

The following components were confirmed working:

* Terraform infrastructure deployment
* ECR repository
* Docker image build and push
* EC2 Auto Scaling Group
* Application Load Balancer
* SSM access to private instances
* ElastiCache Redis
* S3 and CloudFront frontend hosting
* MongoDB Atlas cluster creation

---

## 18. Cleanup Instructions

To avoid AWS charges after assessment review:

```powershell
cd C:\Users\User\Documents\starttech-infra\terraform
terraform destroy
```

Type:

```text
yes
```

Also manually confirm deletion of:

* NAT Gateway
* Elastic IP
* EC2 instances
* Load Balancer
* Target Group
* ElastiCache Redis cluster
* S3 bucket
* CloudFront distribution
* ECR repository
* CloudWatch Log Groups

---

## 19. Final Submission Checklist

* [x] Infrastructure repository created
* [x] Application repository forked
* [x] Terraform infrastructure implemented
* [x] VPC and subnet networking created
* [x] NAT Gateway created
* [x] Security groups configured
* [x] ECR repository created
* [x] Backend Docker image built
* [x] Backend Docker image pushed to ECR
* [x] Launch Template created
* [x] Auto Scaling Group created
* [x] ALB and Target Group created
* [x] S3 frontend bucket created
* [x] CloudFront distribution created
* [x] ElastiCache Redis created
* [x] MongoDB Atlas configured
* [x] CloudWatch Log Group created
* [x] SSM debugging enabled
* [x] README documentation completed

---

## 20. Conclusion

This project demonstrates a full-stack cloud deployment workflow using modern DevOps practices. The architecture separates frontend delivery, backend compute, database persistence, caching, monitoring, and CI/CD automation into well-defined layers.

The implementation shows practical knowledge of AWS infrastructure, Terraform, Docker, GitHub Actions, managed database services, load balancing, auto scaling, and cloud security.

The design follows a production-style pattern where only the backend application is containerized, while database and cache layers are handled by managed cloud services.

```text
https://github.com/taiwohassanajadi/starttech-infra