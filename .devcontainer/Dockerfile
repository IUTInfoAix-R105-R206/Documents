FROM mcr.microsoft.com/devcontainers/base:debian

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git curl ca-certificates \
    python3 python3-pip python3-venv \
    pandoc \
    texlive-latex-base texlive-latex-extra texlive-latex-recommended \
    texlive-fonts-recommended texlive-lang-french \
    texlive-pictures texlive-science texlive-plain-generic \
    lmodern inkscape \
    sqlite3 \
    postgresql-client \
    docker.io \
    && rm -rf /var/lib/apt/lists/*