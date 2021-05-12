use CrossbeamBenchmarks.{runMicroBenchmark, seq, spsc, mpsc, mpmc, selectRx};

// The main entry point.
def main(_args: Array[String]): Int32 & Impure =
  /// let numThreads = 4;
  let numMessages = 8; // 5_000_000;

  let capacity0 = 0; 
  /// runMicroBenchmark("bounded0_mpmc", mpmc(capacity0, numThreads), numMessages);
  /// runMicroBenchmark("bounded0_mpsc", mpsc(capacity0, numThreads), numMessages);
  runMicroBenchmark("bounded0_select_rx", selectRx(capacity0), numMessages);
  /// runMicroBenchmark("bounded0_spsc", spsc(capacity0), numMessages);

  /// let capacity1 = 1;
  /// runMicroBenchmark("bounded1_mpmc", mpmc(capacity1, numThreads), numMessages);
  /// runMicroBenchmark("bounded1_mpsc", mpsc(capacity1, numThreads), numMessages);
  /// runMicroBenchmark("bounded0_select_rx", selectRx(capacity1), numMessages);
  /// runMicroBenchmark("bounded1_spsc", spsc(capacity1), numMessages);

  /// let capacityAll = numMessages; 
  /// runMicroBenchmark("bounded_mpmc", mpmc(capacityAll, numThreads), numMessages);
  /// runMicroBenchmark("bounded_mpsc", mpsc(capacityAll, numThreads), numMessages);
  /// runMicroBenchmark("bounded0_select_rx", selectRx(capacityAll), numMessages);
  /// runMicroBenchmark("bounded_seq", seq(capacityAll), numMessages);
  /// runMicroBenchmark("bounded_spsc", spsc(capacityAll), numMessages);

  0 // exit code
