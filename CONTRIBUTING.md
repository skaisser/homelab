# Contributing to @skaisser Homelab

Thank you for your interest in contributing! This guide will help you get started.

## Code of Conduct

By participating in this project, you agree to maintain a welcoming, inclusive, and harassment-free environment. Be respectful, constructive, and helpful.

## How Can I Contribute?

### Documentation Improvements
- Fix typos or clarify existing guides
- Add missing information or examples
- Improve formatting and readability
- Update outdated information

### New Guides
We welcome new guides in these categories:
- **Infrastructure** — virtualization, containers, storage
- **Services** — networking, security, monitoring, automation
- **Applications** — media servers, home automation, self-hosted services
- **Management** — backup, maintenance, troubleshooting

### Script Improvements
- Improve existing automation scripts
- Add error handling and validation
- Create new utilities

### Bug Reports
- Use the issue tracker
- Include clear steps to reproduce
- Provide system information
- Suggest possible solutions

## Guide Structure

All guides should follow our [template](templates/guide-template.md) and include:
- Clear title and tags
- Table of contents
- Prerequisites
- Step-by-step instructions
- Examples and code snippets
- Troubleshooting section

## Style Guide

### Markdown
- Use headers appropriately (H1 for title, H2 for sections)
- Include code blocks with proper language tags
- Use lists for steps and bullet points

### Content
- Write in clear, concise English
- Include practical examples
- Add screenshots when helpful
- Provide command explanations
- Include error handling
- Reference official documentation

### Script Standards
- Always include `set -euo pipefail`
- Add input validation for all arguments
- Use lock files to prevent concurrent execution
- Include structured logging
- Never hardcode credentials — use environment variables or config files

> **Security**: Never commit real credentials, API keys, or passwords. All example configurations must use obvious placeholder values.

### Tags
Use appropriate tags from these categories:
- Infrastructure: #virtualization #containers #storage
- Services: #networking #security #monitoring
- Applications: #media #home-assistant #self-hosted
- Skills: #basics #advanced #troubleshooting
- Tools: #ansible #docker #prometheus

## Pull Request Process

1. **Fork & Clone**
   ```bash
   git clone https://github.com/skaisser/homelab.git
   cd homelab
   ```

2. **Create Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes** — follow the style guide

4. **Commit**
   ```bash
   git commit -m "feat: add new guide for X"
   ```

5. **Push & Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## Questions?

- Open an issue for questions
- Join our [Discussions](https://github.com/skaisser/homelab/discussions)
- Check existing documentation
