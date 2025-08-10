# dotnet-todo

A .NET 8 Todo API with complete CI/CD pipeline, Kubernetes deployment via Helm, and AWS Lambda infrastructure as code.

## Quick Start

### Prerequisites
- Docker
- .NET 8 SDK (for local development)
- Kubernetes cluster (minikube for local testing)
- Helm 3.x
- AWS CLI and Terraform (for AWS deployment)

## Docker

### Building the Docker Image
```bash
docker build -t dotnet-todo .
```

### Running the Docker Container
```bash
docker run -p 5001:5001 dotnet-todo
```

The application will be available at `http://localhost:5001`

### Docker Hub
Pre-built images are available: `miho1808/dotnet-todo:latest`

## API Testing

### Test Endpoints

**GET all todos:**
```bash
curl http://localhost:5001/todoitems
```

**Add a todo:**
```bash
curl -X POST http://localhost:5001/todoitems \
  -H "Content-Type: application/json" \
  -d '{"name":"walk dog","isComplete":false}'
```

**Get specific todo:**
```bash
curl http://localhost:5001/todoitems/1
```

### Expected Response
```json
[
  {
    "id": 1,
    "name": "walk dog",
    "isComplete": false
  }
]
```

**Note:** The application uses an in-memory database. Data is reset on restart.

## Helm Chart Deployment

### Local Kubernetes (minikube)
```bash
# Start minikube
minikube start

# Deploy using Helm
helm install dotnet-todo ./helm

# Check deployment status
kubectl get pods,svc

# Port forward to access locally
kubectl port-forward service/dotnet-todo 8080:80
```

### Customizing Deployment
Edit `helm/values.yaml` or use `--set` parameters:

```bash
helm install dotnet-todo ./helm \
  --set replicas=3 \
  --set image.tag=v1.2.3
```

### Uninstall
```bash
helm uninstall dotnet-todo
```

## CI/CD Pipeline

### GitHub Actions Workflow

The CI pipeline automatically:

**Build Job:**
1. Generates semantic version (YYYY.MM.DD-SHA format)
2. Validates code through Docker build process
3. Builds and pushes Docker images to Docker Hub with versioning

**Deploy Job:**
1. Sets up minikube Kubernetes cluster
2. Installs and configures Helm
3. Deploys application using Helm chart
4. Runs integration tests against deployed endpoints

### Workflow Triggers
- Push to `main` branch

### Required Secrets
Configure these in your GitHub repository settings (Settings → Secrets and variables → Actions):
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub access token

### Integration Tests
The pipeline tests all API endpoints:
- `GET /todoitems` (returns empty array initially)
- `POST /todoitems` (creates new todo item)
- `GET /todoitems` (verifies item was created)

## AWS Lambda Infrastructure

### Infrastructure as Code with Terraform

The infrastructure creates:
- **VPC** with public/private subnets
- **NAT Gateway** for Lambda internet access
- **Lambda function** running in VPC
- **API Gateway** for public HTTP access
- **ECR repository** for container images
- **IAM roles** with proper permissions

### Infrastructure Testing
```bash
cd infrastructure

# Initialize Terraform
terraform init
✅ Terraform has been successfully initialized!

# Validate configuration
terraform validate  
✅ Success! The configuration is valid.

# Plan deployment (requires AWS credentials)
terraform plan
❌ Error: InvalidClientTokenId (Expected - requires AWS credentials)
```

**Result:** Infrastructure is validated and ready for deployment with proper AWS credentials.

### Deploy to AWS (Optional)
```bash
cd infrastructure

# Configure AWS credentials
aws configure

# Deploy infrastructure
terraform init
terraform plan
terraform apply

# Push Docker image to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

docker tag miho1808/dotnet-todo:latest <ecr-url>:latest
docker push <ecr-url>:latest

# Update Lambda function
aws lambda update-function-code \
  --function-name dotnet-todo \
  --image-uri <ecr-url>:latest
```

## Project Structure

```
.
├── .github/workflows/
│   └── ci.yml                   # GitHub Actions CI/CD pipeline
├── src/                         # .NET application source code
├── helm/                        # Helm chart for Kubernetes deployment
│   ├── Chart.yaml              # Chart metadata
│   ├── values.yaml             # Default configuration values
│   └── templates/              # Kubernetes resource templates
│       ├── deployment.yaml     # Application deployment
│       └── service.yaml        # Service configuration
├── infrastructure/              # Terraform AWS infrastructure
│   └── main.tf                 # AWS Lambda infrastructure definition
├── Dockerfile                  # Container image definition
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## Architecture Decisions

**Container-First Approach:**
- Docker for consistent development and deployment environments
- Multi-stage builds for optimized production images

**Kubernetes-Ready:**
- Helm chart following best practices
- Health checks and proper resource management
- Configurable via values.yaml

**Cloud-Native:**
- Infrastructure as Code with Terraform
- Serverless deployment option with AWS Lambda
- API Gateway for public access

**Automated CI/CD:**
- GitHub Actions for automated testing and deployment
- Semantic versioning for release management
- Integration testing in ephemeral environments

## Development

### Local Development
```bash
# Run application locally
dotnet restore src/
dotnet run --project src/

# Access at http://localhost:5001
```

### Code Quality
The CI pipeline validates code quality through the Docker build process, ensuring the application compiles and runs correctly.

## Security

- No hardcoded credentials in source code
- AWS credentials managed through environment variables
- Container runs as non-root user
- Network policies implemented via VPC configuration