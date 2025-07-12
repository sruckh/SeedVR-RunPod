# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of SeedVR-RunPod container
- Support for SeedVR2-3B and SeedVR2-7B models
- Gradio web interface with model selection
- Robust setup script with retry logic and error handling
- Smart caching for wheels and models
- Comprehensive GPU and CUDA verification
- Environment variable configuration for Gradio
- GitHub Actions for automated Docker Hub deployment
- Complete documentation and deployment guides

### Features
- **Dual Model Support**: Choose between 3B (faster) or 7B (higher quality)
- **Lightweight Container**: Downloads dependencies on remote host
- **Enhanced Robustness**: Comprehensive error checking and retry logic
- **Smart Caching**: Caches wheels and models for faster restarts
- **GPU Verification**: Real tensor operations testing
- **Configurable Interface**: Environment variables for Gradio settings

### Infrastructure
- Docker multi-stage build optimization
- GitHub Actions CI/CD pipeline
- Automated versioning and tagging
- Issue and PR templates
- Contributing guidelines
- Comprehensive documentation

## [1.0.0] - 2025-01-XX (Target Release)

### Added
- First stable release
- Production-ready container for RunPod deployment
- Complete feature set as described above

---

## Release Notes Template

When creating a new release, use this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

### Security
- Security improvements

### Deprecated
- Features that will be removed

### Removed
- Features that were removed
```