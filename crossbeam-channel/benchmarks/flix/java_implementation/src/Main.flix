// The main entry point.
def main(_args: Array[String]): Int32 & Impure =
  /// Console.printLine("Starting...");
  import java.lang.System:nanoTime();

  let messages = 4; // from crossbeam  (5_000_000)
  let threads = 4; // from crossbeam

  let c_bounded = Channel.newWithCapacity(messages); 
  let c_bounded_0 = Channel.newWithCapacity(0);
  let c_bounded_1 = Channel.newWithCapacity(1);
  let sb = StringBuilder.new();

  StringBuilder.appendString!(sb, "bounded0_mpmc      flix flix      ");
  let s40 = nanoTime();
  mpmc(messages,threads, c_bounded_0, threads);
  let diff40 = nanoTime()-s40;
  let sec40 = Int64.toFloat64(diff40)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec40);
  StringBuilder.appendLine!(sb, " sec");

  StringBuilder.appendString!(sb, "bounded0_mpsc      flix flix      ");
  let s20 = nanoTime();
  mpsc(messages, threads, c_bounded_0, threads);
  let diff20 = nanoTime()-s20;
  let sec20 = Int64.toFloat64(diff20)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec20);
  StringBuilder.appendLine!(sb, " sec");

  // TODO: add `bounded0_select_rx`

  StringBuilder.appendString!(sb, "bounded0_spsc      flix flix      ");
  let s0 = nanoTime();
  spsc(messages, c_bounded_0);
  let diff0 = nanoTime()-s0;
  let sec0 = Int64.toFloat64(diff0)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec0);
  StringBuilder.appendLine!(sb, " sec");


  StringBuilder.appendString!(sb, "bounded1_mpmc      flix flix      ");
  let s400 = nanoTime();
  mpmc(messages,threads, c_bounded_1, threads);
  let diff400 = nanoTime()-s400;
  let sec400 = Int64.toFloat64(diff400)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec400);
  StringBuilder.appendLine!(sb, " sec");

  StringBuilder.appendString!(sb, "bounded1_mpsc      flix flix      ");
  let s200 = nanoTime();
  mpsc(messages, threads, c_bounded_1, threads);
  let diff200 = nanoTime()-s200;
  let sec200 = Int64.toFloat64(diff200)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec200);
  StringBuilder.appendLine!(sb, " sec");

  // TODO: add `bounded1_select_rx`

  StringBuilder.appendString!(sb, "bounded1_spsc      flix flix      ");
  let s00 = nanoTime();
  spsc(messages, c_bounded_1);
  let diff00 = nanoTime()-s00;
  let sec00 = Int64.toFloat64(diff00)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec00);
  StringBuilder.appendLine!(sb, " sec");


  StringBuilder.appendString!(sb, "bounded_mpmc      flix flix      ");
  let s4 = nanoTime();
  mpmc(messages,threads, c_bounded, threads);
  let diff4 = nanoTime()-s4;
  let sec4 = Int64.toFloat64(diff4)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec4);
  StringBuilder.appendLine!(sb, " sec");

  StringBuilder.appendString!(sb, "bounded_mpsc      flix flix      ");
  let s2 = nanoTime();
  mpsc(messages, threads, c_bounded, threads);
  let diff2 = nanoTime()-s2;
  let sec2 = Int64.toFloat64(diff2)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec2);
  StringBuilder.appendLine!(sb, " sec");

  StringBuilder.appendString!(sb, "bounded_select_rx      flix flix      ");
  let s6 = nanoTime();
  select_rx(messages);
  let diff6 = nanoTime()-s6;
  let sec6 = Int64.toFloat64(diff6)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec6);
  StringBuilder.appendLine!(sb, " sec");

  StringBuilder.appendString!(sb, "bounded_seq      flix flix      ");
  let s5 = nanoTime();
  seq(messages, c_bounded);
  let diff5 = nanoTime()-s5;
  let sec5 = Int64.toFloat64(diff5)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec5);
  StringBuilder.appendLine!(sb, " sec");

  StringBuilder.appendString!(sb, "bounded_spsc      flix flix      ");
  let s = nanoTime();
  spsc(messages, c_bounded);
  let diff = nanoTime()-s;
  let sec = Int64.toFloat64(diff)/1000000000.0;
  StringBuilder.appendFloat64!(sb,sec);
  StringBuilder.appendLine!(sb, " sec");

  Console.printLine(StringBuilder.toString(sb));

  0 // Exit code