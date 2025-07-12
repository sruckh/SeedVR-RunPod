# 📁 Project Structure

```
SeedVR-RunPod/
├── 📄 README.md                    # Main documentation
├── 📄 RUNPOD_DEPLOYMENT.md         # RunPod deployment guide
├── 📄 CONTRIBUTING.md               # Contribution guidelines
├── 📄 CHANGELOG.md                 # Version history
├── 📄 LICENSE                      # MIT license
├── 📄 PROJECT_STRUCTURE.md         # This file
├── 📄 .env.example                 # Environment variables template
├── 📄 .gitignore                   # Git ignore rules
├── 📄 .dockerignore                # Docker ignore rules
├── 📄 docker-compose.yml           # Docker Compose configuration
├── 📄 Dockerfile                   # Container definition
├── 📄 requirements.txt             # Python dependencies
├── 📄 setup_repo.sh               # Repository setup script
│
├── 🐍 Python Files
│   ├── 📄 gradio_app.py            # Main Gradio interface
│   ├── 📄 download_models.py       # Model download script
│   └── 📄 setup_environment.sh     # Environment setup script
│
├── 📁 .github/                     # GitHub configuration
│   ├── 📁 workflows/
│   │   └── 📄 docker-build-push.yml # CI/CD pipeline
│   ├── 📁 ISSUE_TEMPLATE/
│   │   ├── 📄 bug_report.md        # Bug report template
│   │   └── 📄 feature_request.md   # Feature request template
│   ├── 📄 pull_request_template.md # PR template
│   └── 📄 dependabot.yml          # Dependency updates
│
├── 📁 scripts/                     # Utility scripts
│   ├── 📄 build_and_push.sh       # Build and push to Docker Hub
│   └── 📄 test_local.sh           # Local testing script
│
└── 📁 src/                        # Source code placeholder
    └── 📄 __init__.py             # Python package marker
```

## 📋 File Descriptions

### Core Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage container definition with Python 3.10 and CUDA support |
| `requirements.txt` | Core Python dependencies (torch installed separately) |
| `setup_environment.sh` | Robust setup with retry logic and error checking |
| `gradio_app.py` | Web interface with dual model support and GPU verification |
| `download_models.py` | Enhanced model downloader with retry and caching |

### Configuration

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Local development and testing setup |
| `.env.example` | Environment variable template |
| `.github/workflows/docker-build-push.yml` | Automated CI/CD pipeline |

### Documentation

| File | Purpose |
|------|---------|
| `README.md` | Main project documentation and usage guide |
| `RUNPOD_DEPLOYMENT.md` | Detailed RunPod deployment instructions |
| `CONTRIBUTING.md` | Guidelines for contributors |
| `CHANGELOG.md` | Version history and release notes |

### Scripts

| File | Purpose |
|------|---------|
| `setup_repo.sh` | Automated GitHub repository setup |
| `scripts/build_and_push.sh` | Manual Docker build and push |
| `scripts/test_local.sh` | Local development testing |

## 🎯 Key Features by File

### Enhanced Robustness (`setup_environment.sh`)
- ✅ CUDA/GPU verification with real tensor operations
- ✅ Retry logic with exponential backoff
- ✅ Smart caching for wheels and models
- ✅ Comprehensive error handling
- ✅ Progress reporting and logging

### Dual Model Support (`gradio_app.py`)
- ✅ SeedVR2-3B and SeedVR2-7B model selection
- ✅ Dynamic GPU memory management
- ✅ Configurable output resolution
- ✅ Environment variable configuration
- ✅ Real-time processing feedback

### CI/CD Pipeline (`.github/workflows/`)
- ✅ Automated Docker Hub deployment
- ✅ Multi-architecture support
- ✅ Semantic versioning
- ✅ Dependency scanning
- ✅ Security checks

### Model Management (`download_models.py`)
- ✅ Hugging Face integration
- ✅ Resume interrupted downloads
- ✅ Model verification
- ✅ Storage monitoring
- ✅ Detailed progress reporting

## 🚀 Quick Start

1. **Setup Repository**: `./setup_repo.sh`
2. **Test Locally**: `./scripts/test_local.sh`
3. **Deploy to RunPod**: Follow `RUNPOD_DEPLOYMENT.md`
4. **Contribute**: Read `CONTRIBUTING.md`

## 📞 Support

- 🐛 **Issues**: Use GitHub issue templates
- 💡 **Features**: Submit feature requests
- 🤝 **Contribute**: Follow contribution guidelines
- 📖 **Docs**: Check README and deployment guide