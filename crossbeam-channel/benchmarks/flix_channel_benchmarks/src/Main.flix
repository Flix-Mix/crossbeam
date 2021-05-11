use CrossbeamBenchmarks.{runMicroBenchmark, seq, spsc, mpsc, mpmc, selectRx};

// The main entry point.
def main(_args: Array[String]): Int32 & Impure =
  /// let numThreads = 4;
  let numMessages = 4; // 5_000_000;

  /// let capacity0 = 0; 
  /// runMicroBenchmark("bounded0_mpmc", mpmc(capacity0, numThreads), numMessages);
  /// runMicroBenchmark("bounded0_mpsc", mpsc(capacity0, numThreads), numMessages);
  /// runMicroBenchmark("bounded0_select_rx", selectRx(capacity0), numMessages);
  /// runMicroBenchmark("bounded0_spsc", spsc(capacity0), numMessages);

  /// let capacity1 = 1;
  /// runMicroBenchmark("bounded1_mpmc", mpmc(capacity1, numThreads), numMessages);
  /// runMicroBenchmark("bounded1_mpsc", mpsc(capacity1, numThreads), numMessages);
  /// runMicroBenchmark("bounded0_select_rx", selectRx(capacity1), numMessages);
  /// runMicroBenchmark("bounded1_spsc", spsc(capacity1), numMessages);

  let capacity5M = 40; // 5_000_000;
  /// runMicroBenchmark("bounded_mpmc", mpmc(capacity5M, numThreads), numMessages);
  /// runMicroBenchmark("bounded_mpsc", mpsc(capacity5M, numThreads), numMessages);
  runMicroBenchmark("bounded0_select_rx", selectRx(capacity5M), numMessages);
  /// runMicroBenchmark("bounded_seq", seq(capacity5M), numMessages);
  /// runMicroBenchmark("bounded_spsc", spsc(capacity5M), numMessages);

  0 // exit code
