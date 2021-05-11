#!/bin/bash

cd "$(dirname "$0")"
set -ex

cargo run --release --bin chan | tee chan.txt
cargo run --release --bin crossbeam-channel | tee crossbeam-channel.txt
cargo run --release --bin futures-channel | tee futures-channel.txt
cargo run --release --bin mpsc | tee mpsc.txt
go run go.go | tee go.txt
java -jar flix.jar flix_flix.flix | tee flix_flix.txt

./plot.py *.txt
