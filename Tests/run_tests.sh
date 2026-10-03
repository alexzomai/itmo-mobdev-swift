#!/bin/bash
set -e
cd "$(dirname "$0")"
SRC=../itmo-mobdev-swift
OUT=$(mktemp -d)
swiftc "$SRC/Tokenizer.swift" "$SRC/Validator.swift" "$SRC/Parser.swift" "$SRC/CalculatorViewModel.swift" main.swift -o "$OUT/tests"
"$OUT/tests"
