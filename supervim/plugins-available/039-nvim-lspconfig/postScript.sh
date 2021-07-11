#!/bin/bash

if ! command -v rust-analyzer >/dev/null 2>&1;then
    case $(uname) in
        Darwin)
            echo "brew install rust-analyzer.."
            brew install rust-analyzer && { echo "Ok"; } || { echo "install rust-analyzer failed!"; exit 1; }
            ;;
        Linux)
            echo "download rust-analyzer..."
            curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
            chmod +x ~/.local/bin/rust-analyzer
            ;;
    esac
fi
