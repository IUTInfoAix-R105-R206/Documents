#!/bin/bash
set -e

# Installer les hooks Git (pre-commit SQLFluff)
make install-hooks

# Pré-installer oracledb pour l'extension SQLTools Oracle
mkdir -p ~/.local/share/vscode-sqltools
cd ~/.local/share/vscode-sqltools && npm install oracledb@6.0.1
