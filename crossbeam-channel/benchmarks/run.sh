#!/bin/bash

cd "$(dirname "$0")"
set -ex

cargo run --release --bin chan | tee chan.txt
cargo run --release --bin crossbeam-channel | tee crossbeam-channel.txt
cargo run --release --bin futures-channel | tee futures-channel.txt
cargo run --release --bin mpsc | tee mpsc.txt
go run go.go | tee go.txt
java -jar flix/flix-2021-05-11.jar flix/flix_implementation run | tee flix-flix.txt
java -jar flix/flix-2021-05-11.jar flix/java_implementation run | tee flix-java.txt

./plot.py *.txt
