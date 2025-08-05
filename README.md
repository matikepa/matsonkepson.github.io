# Personal Blog

Welcome to my personal blog repository! This is the source code for my website where I share technical articles, tutorials, and insights.

🌐 **Live Website**: [https://kepa.eu.org](https://kepa.eu.org/)

## Tech Stack

- **Static Site Generator**: [Hugo](https://gohugo.io/) - Lightning fast, flexible, and user-friendly
- **Theme**: [Qubt](https://github.com/chrede88/qubt) - Clean and modern theme optimized for technical content
- **Hosting**: [GitHub Pages](https://pages.github.com/) - Fast and secure static site hosting
- **CI/CD**: [GitHub Actions](https://github.com/features/actions) - Automated workflows for build and deployment

## Project Status

| Component         | Status                                                                                                                                                                                                                                    |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GitHub Pages**  | ![GitHub Pages](https://github.com/matikepa/matsonkepson.github.io/actions/workflows/hugo-deploy.yaml/badge.svg?branch=main)                                                                                                              |
| **Pull Requests** | ![PR status](https://github.com/matikepa/matsonkepson.github.io/actions/workflows/create-pr.yaml/badge.svg?branch=develop)                                                                                                                |
| **Dependencies**  | [![Dependabot Updates](https://github.com/matikepa/matsonkepson.github.io/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/matikepa/matsonkepson.github.io/actions/workflows/dependabot/dependabot-updates) |
| **Analytics**     | [![Page Analytics](https://github.com/matikepa/matsonkepson.github.io/actions/workflows/analytics.yml/badge.svg)](https://github.com/matikepa/matsonkepson.github.io/actions/workflows/analytics.yml)                                     |
| **Code Style**    | [![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square)](https://github.com/prettier/prettier)                                                                                            |

## Local Development

To run this blog locally:

1. Install Hugo (extended version)
2. Clone this repository
3. Run `./build-local.sh` to start the development server
4. Visit `http://localhost:1313`

## Content Management

- New posts can be created using `./new-post.sh`
- Clean build artifacts with `./clean.sh`
- All content is written in Markdown and stored in the `content/` directory

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.
