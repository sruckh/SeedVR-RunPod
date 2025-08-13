# Code Style and Conventions

## EditorConfig Settings
From `.editorconfig`:
- **Charset**: UTF-8
- **Indent Style**: Spaces (4 spaces)
- **Line Endings**: LF (Unix-style)
- **Final Newline**: Required
- **Trim Trailing Whitespace**: Enabled (except in Markdown)

## Python Code Style
Based on existing code analysis:
- **Import Organization**: Standard library, third-party, local imports
- **Function Naming**: snake_case
- **Class Naming**: PascalCase
- **Constants**: UPPER_CASE
- **Docstrings**: Present for main functions
- **Error Handling**: Try-except blocks with descriptive messages
- **Progress Reporting**: Use Gradio Progress for long operations

## File Naming
- **Python Files**: snake_case.py
- **Shell Scripts**: descriptive_name.sh
- **Documentation**: UPPERCASE.md for main docs
- **Configuration**: lowercase or dotfiles

## Directory Structure
- Root level: Main application files and documentation
- `/coordination/`: Project coordination and memory files
- `/PLAYBOOKS/`: Operational procedures
- Temporary processing directories created at runtime

## Code Quality
- Clear variable names and function purposes
- Comprehensive error handling with user-friendly messages
- Modular design with separate concerns
- Robust retry logic for network operations