# Contributing to SeedVR-RunPod

Thank you for your interest in contributing to SeedVR-RunPod! This guide will help you get started.

## 🤝 How to Contribute

### Reporting Issues
- Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) for bugs
- Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) for new features
- Search existing issues before creating a new one
- Include as much detail as possible (logs, environment, steps to reproduce)

### Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (see Testing section below)
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request using our [template](.github/pull_request_template.md)

## 🧪 Testing

### Local Testing
```bash
# Build the container
docker build -t seedvr-runpod:test .

# Test with environment variables
docker run --gpus all -p 7860:7860 \
  -e GRADIO_SHARE=true \
  -e HF_TOKEN=your_token \
  seedvr-runpod:test
```

### RunPod Testing
- Test deployment on RunPod with different GPU configurations
- Verify model downloads work correctly
- Check Gradio interface functionality
- Test both SeedVR2-3B and SeedVR2-7B models

### Required Test Cases
- [ ] Container builds successfully
- [ ] Setup script completes without errors
- [ ] Models download correctly
- [ ] GPU detection and CUDA verification works
- [ ] Gradio interface launches and is accessible
- [ ] Video processing completes successfully
- [ ] Environment variables are respected

## 📝 Code Style

### Shell Scripts
- Use `set -e` for error handling
- Include comprehensive error checking
- Add retry logic for network operations
- Use meaningful function names
- Include progress indicators and logging

### Python Code
- Follow PEP 8 style guidelines
- Include type hints where appropriate
- Add comprehensive error handling
- Use logging instead of print statements
- Include docstrings for functions

### Docker
- Use multi-stage builds when beneficial
- Minimize layer count
- Clean up package managers after installation
- Use specific versions for reproducibility
- Add meaningful labels and comments

## 🎯 Areas for Contribution

### High Priority
- Performance optimizations
- Additional model support
- Better error messages and diagnostics
- Memory usage optimization
- Multi-GPU improvements

### Medium Priority
- Additional output formats
- Batch processing capabilities
- API endpoints beyond Gradio
- Integration with other platforms
- Documentation improvements

### Good First Issues
- README improvements
- Example scripts
- Error message clarifications
- Configuration validation
- Log formatting enhancements

## 🚀 Development Setup

### Prerequisites
- Docker with GPU support
- Python 3.10+
- Access to GPU for testing
- Hugging Face account (for model downloads)

### Development Environment
```bash
# Clone your fork
git clone https://github.com/sruckh/SeedVR-RunPod.git
cd SeedVR-RunPod

# Create development branch
git checkout -b feature/your-feature

# Build and test locally
docker build -t seedvr-runpod:dev .
```

### Environment Variables for Testing
```bash
export HF_TOKEN=your_huggingface_token
export GRADIO_SHARE=false
export GRADIO_PORT=7860
export CUDA_VISIBLE_DEVICES=0
```

## 📋 Release Process

1. Update version numbers in relevant files
2. Update CHANGELOG.md with new features/fixes
3. Test thoroughly on multiple GPU configurations
4. Create release PR
5. Tag release after merge
6. GitHub Actions will build and push to Docker Hub

## ❓ Questions?

- Open a [Discussion](https://github.com/sruckh/SeedVR-RunPod/discussions) for general questions
- Check existing [Issues](https://github.com/sruckh/SeedVR-RunPod/issues) for known problems
- Review the [README](README.md) and [RunPod deployment guide](RUNPOD_DEPLOYMENT.md)

## 🙏 Acknowledgments

- **ByteDance**: For the original SeedVR research and models
- **RunPod**: For the cloud GPU platform
- **Contributors**: Everyone who helps improve this project

---

By contributing, you agree that your contributions will be licensed under the MIT License.