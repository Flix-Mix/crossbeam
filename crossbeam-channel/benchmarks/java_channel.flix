///type alias Date = ##java.util.Date

/// def java_data(): Unit & Impure =
///     import java.lang.System.nanoTime as nanoTime;
///     nanoTime()

def printInt(n: Int): String & Impure =
    let sb = StringBuilder.new();
    StringBuilder.appendInt32!(sb, n);
    StringBuilder.toString(sb)

def send(num_messages: Int, c: Channel[Int]): Int & Impure =
    // Console.printLine("in send: " + printInt(num_messages));
    if (num_messages == 0) (0)
    else {
        ///Console.printLine("sending...");
        c <- num_messages; ///send arbitrary value
        send(num_messages-1, c) //repeat
    }  

def recv(num_messages: Int, c: Channel[Int]): Int & Impure =
    // Console.printLine("in rec: " + printInt(num_messages));
    if (num_messages == 0) {
        //Console.printLine("Done");
        0
    }
    else {
        ///Console.printLine("receiving...");
        <- c;
        recv(num_messages-1, c)
    }

def mult_send(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Int & Impure =
    //Console.printLine("in mult_send: " + printInt(num_messages) + " " + printInt(num_threads));
    if (num_threads == 0 ) (0)
    else {
        //Console.printLine("Shooting " + printInt(num_messages/final_num_threads) + " messages to be sent");
        spawn send(num_messages/final_num_threads, c);
        mult_send(num_messages,num_threads-1,c,final_num_threads)
    }

def mult_recv(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Int & Impure =
    //Console.printLine("in mult_recv: " + printInt(num_messages) + " " + printInt(num_threads));
    if (num_threads == 0) (0)
    else {
        spawn recv(num_messages/final_num_threads, c);
        mult_recv(num_messages,num_threads-1,c,final_num_threads)
    }

/// def select_recv(num_iter: Int, c1: Channel[Int], c2: Channel[Int], c3: Channel[Int], c4: Channel[Int]): Int & Impure =
///     Console.printLine("receving!");
///     if (num_iter == 0) (0)
///     else {
///         select {
///         case v <- c1 => v
///         case v <- c2 => v
///         case v <- c3 => v
///         case v <- c4 => v
///         case _ => 0
///         };
///         select_recv(num_iter-1,c1,c2,c3,c4)
///     }
    
///     //} 
/// def select_recv_help(num_messages: Int, c1: Channel[Int], c2: Channel[Int], c3: Channel[Int], c4: Channel[Int], fin_messages: Int): Int & Impure =
///     //Console.printLine(printInt(fin_messages) + " " + printInt(num_messages));
///     if (num_messages == 0) (0)
///     else {
///         spawn select_recv(fin_messages/4,c1,c2,c3,c4);
///         select_recv_help(num_messages-1,c1,c2,c3,c4,fin_messages)
///     }


/// def select_send(num_messages: Int, c1: Channel[Int], c2: Channel[Int], c3: Channel[Int], c4: Channel[Int]): Int & Impure =
///     if (num_messages == 0) (0)
///     else {
///         select {
///         case c1 <- 0 => 0
///         case c2 <- 0 => 0
///         case c3 <- 0 => 0
///         case c4 <- 0 => 0
///         case _ => 0
///         };
///         select_send(num_messages-1,c1,c2,c3,c4);
///         1
///     }

def spsc(num_messages: Int, c: Channel[Int]): Int & Impure =
    spawn send(num_messages,c);
    recv(num_messages,c);
    1

def seq(num_messages: Int, c: Channel[Int]): Int & Impure =
    send(num_messages,c);
    recv(num_messages,c);
    1


def mpsc(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Int & Impure =
    mult_send(num_messages,num_threads,c, final_num_threads);
    recv(num_messages,c)

def mpmc(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Int & Impure =
    mult_send(num_messages,num_threads,c, final_num_threads);
    mult_recv(num_messages,num_threads,c, final_num_threads)


/// def select_rx(num_messages: Int): Int & Impure =
///     let c1 = Channel.newWithCapacity(num_messages);
///     let c2 = Channel.newWithCapacity(num_messages);
///     let c3 = Channel.newWithCapacity(num_messages);
///     let c4 = Channel.newWithCapacity(num_messages);

///     let n1 = num_messages;
///     let n2 = num_messages;
///     let n3 = num_messages;
///     let n4 = num_messages;
///     let n5 = num_messages;

///     spawn send(n1/4,c1);
///     spawn send(n2/4,c2);
///     spawn send(n3/4,c3);
///     spawn send(n4/4,c4);

///     select_recv_help(n5,c1,c2,c3,c4,n5);
///     1

/// def select_both(num_messages: Int): Int & Impure =
///     let c1 = Channel.newWithCapacity(num_messages);
///     let c2 = Channel.newWithCapacity(num_messages);
///     let c3 = Channel.newWithCapacity(num_messages);
///     let c4 = Channel.newWithCapacity(num_messages);

///     let n1 = num_messages;
///     let n2 = num_messages;
///     let n3 = num_messages;
///     let n4 = num_messages;
///     let n5 = num_messages;
///     let n6 = num_messages;

///     spawn select_send(n5,c1,c2,c3,c4);

///     spawn select_recv(n6,c1,c2,c3,c4);
///     1
    
 
def main(): String & Impure=
    /// Console.printLine("Starting...");
    import java.lang.System:nanoTime();

    let messages = 4; //from crossbeam  (5000000)
    let threads = 4; //from crossbeam
    printInt(messages);
    //let c_unbounded = chan Int 5;
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
    

    /// StringBuilder.appendString!(sb, "bounded0_seq      flix flix      ");
    /// let s50 = nanoTime();
    /// seq(messages, c_bounded_0);
    /// let diff50 = nanoTime()-s50;
    /// let sec50 = Int64.toFloat64(diff50)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec50);
    /// StringBuilder.appendLine!(sb, " sec");


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
    

    /// StringBuilder.appendString!(sb, "bounded1_seq      flix flix      ");
    /// let s500 = nanoTime();
    /// seq(messages, c_bounded_1);
    /// let diff500 = nanoTime()-s500;
    /// let sec500 = Int64.toFloat64(diff500)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec500);
    /// StringBuilder.appendLine!(sb, " sec");


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


    
    



    /// StringBuilder.appendString!(sb, "bounded_select_rx      flix flix      ");
    /// let s6 = nanoTime();
    /// select_rx(messages);
    /// let diff6 = nanoTime()-s6;
    /// let sec6 = Int64.toFloat64(diff6)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec6);
    /// StringBuilder.appendLine!(sb, " sec");

    /// StringBuilder.appendString!(sb, "bounded_select_both      flix flix      ");
    /// let s7 = nanoTime();
    /// select_both(messages);
    /// let diff7 = nanoTime()-s7;
    /// let sec7 = Int64.toFloat64(diff7)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec7);
    /// StringBuilder.appendLine!(sb, " sec");




    Console.printLine(StringBuilder.toString(sb));
    ""

