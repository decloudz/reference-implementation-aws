# Bitbucket Templates for Backstage

## Overview

This document provides an overview of the Bitbucket-specific templates created for the CNOE Reference Implementation. These templates enable developers to create new services and applications that use Bitbucket as the source code repository and Bitbucket Pipelines for CI/CD.

## Available Templates

### 1. Basic Bitbucket Template
**Template**: `basic-bitbucket`
**File**: `templates/backstage/basic-bitbucket/template.yaml`

- **Purpose**: Creates a basic Kubernetes deployment with Bitbucket repository
- **Technology**: Generic Kubernetes manifests
- **CI/CD**: Bitbucket Pipelines
- **Features**:
  - Simple Kubernetes deployment and service
  - Basic Bitbucket Pipelines configuration
  - ArgoCD application creation
  - Catalog registration

**Use Case**: Getting started with Bitbucket integration, simple containerized applications

### 2. Node.js Backend (Bitbucket)
**Template**: `nodejs-backend-bitbucket-template`
**File**: `templates/backstage/nodejs-backend-bitbucket/template.yaml`

- **Purpose**: Creates a Node.js/Express backend application with Bitbucket
- **Technology**: Node.js 18, Express, TypeScript
- **Port**: 3000 (default)
- **CI/CD**: Bitbucket Pipelines with Node.js build pipeline
- **Features**:
  - Modern Node.js application structure
  - Automated testing in pipeline
  - Docker containerization
  - Kubernetes deployment manifests
  - Health check endpoints

**Use Case**: REST APIs, microservices, backend services using Node.js

### 3. Spring Boot Backend (Bitbucket)
**Template**: `spring-boot-backend-bitbucket-template`
**File**: `templates/backstage/spring-boot-backend-bitbucket/template.yaml`

- **Purpose**: Creates a Java Spring Boot backend application with Bitbucket
- **Technology**: Java 11+, Spring Boot, Maven
- **Port**: 8080 (default)
- **CI/CD**: Bitbucket Pipelines with Maven build pipeline
- **Features**:
  - Spring Boot application structure
  - Maven dependency management
  - Automated testing with JUnit
  - Multi-stage Docker builds
  - Production-ready configuration

**Use Case**: Enterprise Java applications, REST APIs, Spring-based microservices

### 4. Go Backend (Bitbucket)
**Template**: `go-backend-bitbucket-template`
**File**: `templates/backstage/go-backend-bitbucket/template.yaml`

- **Purpose**: Creates a Go backend application with Bitbucket
- **Technology**: Go 1.21+, Gorilla Mux (or similar)
- **Port**: 8080 (default)
- **CI/CD**: Bitbucket Pipelines with Go build pipeline
- **Features**:
  - Modern Go application structure
  - Go modules for dependency management
  - Automated testing
  - Minimal Alpine-based containers
  - High-performance deployments

**Use Case**: High-performance APIs, cloud-native services, system tools

## Common Features

All Bitbucket templates include:

### 🚀 **Bitbucket Pipelines Integration**
- Automated CI/CD pipeline configuration
- Branch-specific pipeline behavior
- Pull request validation
- Docker image building and publishing
- Artifact management

### 📦 **Containerization**
- Multi-stage Dockerfile for optimal image size
- Health check endpoints
- Environment-specific configurations
- Registry push automation

### 🏗️ **Kubernetes Ready**
- Deployment manifests
- Service configuration
- Ingress setup (optional)
- Namespace isolation

### 🔄 **ArgoCD Integration**
- Automatic ArgoCD application creation
- GitOps-ready configuration
- Sync policy configuration
- Health monitoring

### 📖 **Backstage Catalog**
- Automatic service registration
- Metadata configuration
- Ownership and system assignment
- Documentation integration

## Pipeline Configuration

### Bitbucket Pipelines Features

All templates use `templates/skeletons/bitbucket-pipelines/bitbucket-pipelines.yml` which provides:

1. **Default Pipeline** (All branches):
   - Install dependencies
   - Run tests
   - Build application
   - Generate artifacts

2. **Production Pipeline** (Main branch):
   - Full build and test
   - Docker image creation
   - Image tagging with commit hash
   - Production deployment

3. **Pull Request Pipeline**:
   - Code validation
   - Test execution
   - Build verification

### Supported Build Tools

- **Node.js**: npm/yarn package management, Jest testing
- **Java**: Maven lifecycle, JUnit testing
- **Go**: Go modules, built-in testing

## Template Parameters

### Common Parameters

All templates share these parameters:

- **workspace**: Bitbucket workspace name
- **repoName**: Repository name (must be lowercase, alphanumeric with hyphens)
- **description**: Project description
- **owner**: Team or user responsible for the service
- **system**: System this service belongs to
- **port**: Application port number

### Language-Specific Parameters

#### Java/Spring Boot
- **groupId**: Maven group ID (e.g., `io.cnoe`)
- **artifactId**: Maven artifact ID
- **javaPackageName**: Java package structure

#### CI/CD Options
- **ci**: Pipeline type selection
- **imageRepository**: Container registry (Docker Hub, Quay.io, etc.)
- **imageUrl**: Container image URL pattern
- **namespace**: Kubernetes namespace for deployment

## Usage Instructions

### 1. Prerequisites

Before using these templates:

- ✅ Bitbucket workspace with appropriate permissions
- ✅ Bitbucket App Password configured in Backstage
- ✅ Container registry access (optional)
- ✅ Kubernetes cluster for deployment

### 2. Creating a New Service

1. **Access Backstage Software Catalog**
2. **Click "Create Component"**
3. **Select a Bitbucket template** (e.g., "Node.js Backend (Bitbucket)")
4. **Fill in required parameters**:
   - Workspace: Your Bitbucket workspace
   - Repository name: Service name
   - Owner and system assignment
5. **Review and create**
6. **Backstage will**:
   - Create Bitbucket repository
   - Generate application code
   - Set up Bitbucket Pipelines
   - Create ArgoCD application
   - Register in service catalog

### 3. Development Workflow

1. **Clone the generated repository**
2. **Make changes locally**
3. **Create feature branch**
4. **Push and create pull request**
5. **Pipeline validates changes**
6. **Merge to main triggers deployment**

## File Structure

Generated projects follow this structure:

```
your-service/
├── README.md                    # Auto-generated documentation
├── Dockerfile                   # Multi-stage container build
├── bitbucket-pipelines.yml      # CI/CD pipeline configuration
├── catalog-info.yaml            # Backstage service metadata
├── manifests/                   # Kubernetes deployment files
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── src/                         # Source code (language-specific)
└── tests/                       # Test files
```

## Security Considerations

### Repository Security
- ✅ **Private repositories** by default
- ✅ **Branch protection** on main branch
- ✅ **Required PR reviews** before merge
- ✅ **Pipeline validation** for all changes

### Container Security
- ✅ **Multi-stage builds** for minimal attack surface
- ✅ **Non-root user** execution
- ✅ **Minimal base images** (Alpine Linux)
- ✅ **Health check endpoints** for monitoring

### Secret Management
- ✅ **Bitbucket repository variables** for secrets
- ✅ **Kubernetes secrets** for runtime configuration
- ✅ **External secret management** integration

## Customization

### Adding New Languages

To add support for additional languages:

1. **Create new template** in `templates/backstage/[language]-backend-bitbucket/`
2. **Copy skeleton** from existing language template
3. **Update build pipeline** in Bitbucket Pipelines skeleton
4. **Add Dockerfile** configuration for the language
5. **Register template** in `catalog-info.yaml`

### Modifying Pipelines

The pipeline configuration is in `templates/skeletons/bitbucket-pipelines/`:

- **bitbucket-pipelines.yml**: Main pipeline configuration
- **Dockerfile**: Container build instructions
- **README.md**: Project documentation template

## Troubleshooting

### Common Issues

1. **Repository Creation Fails**
   - Check Bitbucket workspace permissions
   - Verify app password is valid
   - Ensure repository name is unique

2. **Pipeline Fails**
   - Check Bitbucket Pipelines configuration
   - Verify build dependencies
   - Review pipeline logs in Bitbucket

3. **ArgoCD Sync Issues**
   - Verify repository access in ArgoCD
   - Check Kubernetes manifests syntax
   - Ensure cluster has necessary permissions

### Debug Steps

1. **Check Backstage logs** for template execution errors
2. **Review Bitbucket repository** was created correctly
3. **Verify pipeline configuration** in `bitbucket-pipelines.yml`
4. **Test local build** to isolate issues
5. **Check ArgoCD application** sync status

## Future Enhancements

### Planned Features

- **Multi-environment support** (dev, staging, prod)
- **Advanced security scanning** in pipelines
- **Performance testing** integration
- **Monitoring and alerting** setup
- **Database integration** templates
- **Frontend application** templates

### Contributing

To contribute new templates or improvements:

1. Fork the repository
2. Create feature branch
3. Add or modify templates
4. Test with Backstage instance
5. Submit pull request

---

## Template Quick Reference

| Template | Language | Default Port | Best For |
|----------|----------|--------------|----------|
| `basic-bitbucket` | Generic | 8080 | Simple deployments, learning |
| `nodejs-backend-bitbucket` | Node.js/TypeScript | 3000 | REST APIs, web services |
| `spring-boot-backend-bitbucket` | Java/Spring Boot | 8080 | Enterprise applications |
| `go-backend-bitbucket` | Go | 8080 | High-performance services |

---

*Generated for CNOE Reference Implementation with Bitbucket Integration*