# Contributing to SIYI A8 Mini Camera Control System

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork:
```bash
git clone <your-fork-url>
cd siyi_sdk
```

3. Create a new branch:
```bash
git checkout -b feature/your-feature-name
```

## Development Environment

### 1. System Requirements
- Python 3.10+
- FFmpeg
- GStreamer
- Tailscale

### 2. Virtual Environment Setup
```bash
# Create virtual environment
python -m venv serve
source serve/bin/activate

# Install dependencies
pip install fastapi uvicorn
```

### 3. Camera Setup
- Connect A8 mini camera via ethernet
- Configure network:
  - IP: 192.168.144.12
  - Gateway: 192.168.144.25
  - Netmask: 255.255.255.0

## Project Structure
```
siyi_sdk/
├── api_server.py    # REST API implementation
├── cameras.py       # Camera specifications
├── stream.py        # RTSP stream handler
├── starter.sh       # Main startup script
├── siyi_sdk.py     # Core SDK implementation
├── tests/          # Test examples
└── logs/           # Application logs
```

## Development Guidelines

### Code Style
- Follow PEP 8 guidelines
- Use meaningful variable and function names
- Add docstrings to functions and classes
- Comment complex logic
- Use type hints where possible

### API Development
When modifying the API:
1. Update API documentation
2. Follow existing response formats
3. Add proper error handling
4. Update Swagger documentation
5. Test all endpoints

### Stream Handling
When working with video streams:
1. Maintain low latency
2. Handle connection errors
3. Implement proper cleanup
4. Log relevant information

### Testing
Before submitting:
1. Test all API endpoints
2. Verify stream functionality
3. Check error handling
4. Validate log output
5. Test on both development and production setups

## Commit Guidelines

### Commit Messages
Format: `<type>: <description>`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

Example:
```bash
git commit -m "feat: add zoom control endpoint"
git commit -m "fix: handle stream disconnection"
```

### Pull Request Process
1. Update documentation
2. Add/update tests
3. Ensure all tests pass
4. Update README if needed
5. Create detailed PR description

## Documentation

### API Documentation
When adding/modifying endpoints:
1. Update API_doc.md
2. Include request/response examples
3. Document error cases
4. Update Swagger annotations

### Code Documentation
- Add docstrings to new functions/classes
- Include type hints
- Document exceptions
- Add usage examples

## Getting Help
- Open an issue for bugs
- Use discussions for questions
- Tag maintainers when needed

## License
By contributing, you agree that your contributions will be licensed under the project's license.