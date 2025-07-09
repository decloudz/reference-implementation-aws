# ${{ values.repoName }}

${{ values.description }}

## Overview

This project was generated using the Backstage software template with Bitbucket integration. It includes:

- 🚀 **Bitbucket Pipelines CI/CD** - Automated build, test, and deploy pipeline
- 📦 **Containerized Application** - Ready-to-deploy Docker container
- 🏗️ **Infrastructure as Code** - Kubernetes manifests for deployment
- 📖 **Documentation** - Auto-generated documentation and catalog integration

## Quick Start

### Prerequisites

- Docker
- {% if values.imageBuilder == "s2i-nodejs" %}Node.js 18+{% elif values.imageBuilder == "s2i-java" %}Java 11+ and Maven{% elif values.imageBuilder == "s2i-go" %}Go 1.21+{% endif %}
- Access to Bitbucket repository: https://bitbucket.org/${{ values.workspace }}/${{ values.repoName }}

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://bitbucket.org/${{ values.workspace }}/${{ values.repoName }}.git
   cd ${{ values.repoName }}
   ```

2. **Install dependencies:**
   {% if values.imageBuilder == "s2i-nodejs" %}
   ```bash
   npm install
   ```
   {% elif values.imageBuilder == "s2i-java" %}
   ```bash
   mvn install
   ```
   {% elif values.imageBuilder == "s2i-go" %}
   ```bash
   go mod download
   ```
   {% endif %}

3. **Run the application:**
   {% if values.imageBuilder == "s2i-nodejs" %}
   ```bash
   npm start
   ```
   {% elif values.imageBuilder == "s2i-java" %}
   ```bash
   mvn spring-boot:run
   ```
   {% elif values.imageBuilder == "s2i-go" %}
   ```bash
   go run main.go
   ```
   {% endif %}

4. **Access the application:**
   - URL: http://localhost:${{ values.port | default(8080) }}

### Testing

{% if values.imageBuilder == "s2i-nodejs" %}
```bash
npm test
```
{% elif values.imageBuilder == "s2i-java" %}
```bash
mvn test
```
{% elif values.imageBuilder == "s2i-go" %}
```bash
go test ./...
```
{% endif %}

### Docker Build

```bash
docker build -t ${{ values.repoName }} .
docker run -p ${{ values.port | default(8080) }}:${{ values.port | default(8080) }} ${{ values.repoName }}
```

## CI/CD Pipeline

This project uses **Bitbucket Pipelines** for continuous integration and deployment:

### Pipeline Stages

1. **Build & Test** (All branches)
   - Install dependencies
   - Run tests
   - Build application
   - Generate artifacts

2. **Deploy** (Main branch)
   - Build Docker image
   - Tag with commit hash
   - Deploy to staging/production

3. **Pull Request Validation**
   - Run tests on PRs
   - Validate code quality
   - Ensure builds succeed

### Pipeline Configuration

The pipeline is defined in `bitbucket-pipelines.yml`. Key features:

- **Caching**: Dependencies and build artifacts
- **Docker Support**: Container builds and pushes
- **Branch Policies**: Different actions for main vs feature branches
- **Artifacts**: Preserves build outputs

### Environment Variables

Configure these in Bitbucket repository settings:

{% if values.imageRepository and values.imageUrl %}
- `DOCKER_USERNAME`: Docker registry username
- `DOCKER_PASSWORD`: Docker registry password
- `REGISTRY_URL`: Container registry URL
{% endif %}

## Deployment

### Kubernetes Deployment

The application includes Kubernetes manifests in the `manifests/` directory:

- `deployment.yaml`: Application deployment configuration
- `service.yaml`: Service exposure
- `ingress.yaml`: External access configuration

Apply to your cluster:
```bash
kubectl apply -f manifests/
```

### ArgoCD Integration

This project is configured for GitOps deployment with ArgoCD:

- **Repository**: https://bitbucket.org/${{ values.workspace }}/${{ values.repoName }}
- **Path**: `manifests/`
- **Target Namespace**: `${{ values.repoName }}`

## Development

### Project Structure

```
${{ values.repoName }}/
├── README.md              # This file
├── Dockerfile             # Container definition
├── bitbucket-pipelines.yml # CI/CD pipeline
├── catalog-info.yaml      # Backstage catalog metadata
├── manifests/             # Kubernetes resources
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
{% if values.imageBuilder == "s2i-nodejs" %}
├── package.json           # Node.js dependencies
├── src/                   # Source code
└── tests/                 # Test files
{% elif values.imageBuilder == "s2i-java" %}
├── pom.xml                # Maven configuration
├── src/                   # Source code
│   ├── main/
│   └── test/
{% elif values.imageBuilder == "s2i-go" %}
├── go.mod                 # Go modules
├── go.sum                 # Go dependencies
├── main.go                # Main application
└── pkg/                   # Package code
{% endif %}
```

### Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit:
   ```bash
   git add .
   git commit -m "Add your feature"
   ```

3. Push and create a pull request:
   ```bash
   git push origin feature/your-feature-name
   ```

4. The pipeline will automatically:
   - Run tests on your PR
   - Build and validate the application
   - Deploy to staging when merged to main

## Monitoring and Observability

The application includes:

- **Health Check Endpoint**: `/health`
- **Metrics Endpoint**: `/metrics` (if configured)
- **Logging**: Structured logging to stdout

## Security

- **Container Security**: Multi-stage builds for minimal attack surface
- **Dependency Scanning**: Automated vulnerability scanning in pipeline
- **Secret Management**: Use Bitbucket repository variables for secrets

## Support

- **Repository**: https://bitbucket.org/${{ values.workspace }}/${{ values.repoName }}
- **Owner**: ${{ values.owner }}
- **System**: ${{ values.system }}

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

[Add your license information here]

---

*Generated by Backstage with Bitbucket integration*