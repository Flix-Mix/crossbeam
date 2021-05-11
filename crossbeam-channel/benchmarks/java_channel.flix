///type alias Date = ##java.util.Date

/// def java_data(): Unit & Impure =
///     import java.lang.System.nanoTime as nanoTime;
///     nanoTime()

def printInt(n: Int): String & Impure =
    let sb = StringBuilder.new();
    StringBuilder.appendInt32!(sb, n);
    StringBuilder.toString(sb)

def send(num_messages: Int, c: Channel[Int]): Int & Impure =
    //Console.printLine("in send: " + printInt(num_messages));
    if (num_messages == 0) (0)
    else {
        ///Console.printLine("sending...");
        c <- num_messages; ///send arbitrary value
        send(num_messages-1, c) //repeat
    }  

def recv(num_messages: Int, c: Channel[Int]): Int & Impure =
    //Console.printLine("in rec: " + printInt(num_messages));
    if (num_messages == 0) (0)
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

def select_recv(num_messages: Int, c1: Channel[Int], c2: Channel[Int], c3: Channel[Int], c4: Channel[Int]): Int & Impure =
    if (num_messages == 0) (0)
    else {
        select {
        case v <- c1 => v
        case v <- c2 => v
        case v <- c3 => v
        case v <- c4 => v
        case _ => 0
        };
        select_recv(num_messages-1,c1,c2,c3,c4)
    }

def spsc(num_messages: Int, c: Channel[Int]): Int & Impure =
    send(num_messages,c);
    recv(num_messages,c)


def mpsc(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Int & Impure =
    mult_send(num_messages,num_threads,c, final_num_threads);
    recv(num_messages,c)

def mpmc(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Int & Impure =
    mult_send(num_messages,num_threads,c, final_num_threads);
    mult_recv(num_messages,num_threads,c, final_num_threads)

/// def select_rx_u(num_messages: Int): Int & Impure =
///     let c1 = chan Int 0;
///     let c2 = chan Int 0;
///     let c3 = chan Int 0;
///     let c4 = chan Int 0;

///     let n1 = num_messages;
///     let n2 = num_messages;
///     let n3 = num_messages;
///     let n4 = num_messages;
///     let n5 = num_messages;

///     send(n1,c1);
///     send(n2,c2);
///     send(n3,c3);
///     send(n4,c4);

///     select_recv(n5,c1,c2,c3,c4)

def select_rx_b(num_messages: Int): Int & Impure =
    let c1 = Channel.newWithCapacity(num_messages);
    let c2 = Channel.newWithCapacity(num_messages);
    let c3 = Channel.newWithCapacity(num_messages);
    let c4 = Channel.newWithCapacity(num_messages);

    let n1 = num_messages;
    let n2 = num_messages;
    let n3 = num_messages;
    let n4 = num_messages;
    let n5 = num_messages;

    send(n1,c1);
    send(n2,c2);
    send(n3,c3);
    send(n4,c4);

    select_recv(n5,c1,c2,c3,c4)
    
 
def main(): String & Impure=
    /// Console.printLine("Starting...");
    import java.lang.System:nanoTime();

    let messages = 5000000; //from crossbeam  (5000000)
    let threads = 4; //from crossbeam
    printInt(messages);
    //let c_unbounded = chan Int 5;
    let c_bounded = Channel.newWithCapacity(messages); 

    let sb = StringBuilder.new();



    
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
    

    StringBuilder.appendString!(sb, "bounded_scsp      flix flix      ");
    let s = nanoTime();
    spsc(messages, c_bounded);
    let diff = nanoTime()-s;
    let sec = Int64.toFloat64(diff)/1000000000.0;
    StringBuilder.appendFloat64!(sb,sec);
    StringBuilder.appendLine!(sb, " sec");
    
    /// StringBuilder.appendString!(sb, "unbounded_scsp      flix flix      ");
    /// let s1 = nanoTime();
    /// spsc(messages, c_unbounded);
    /// let diff1 = nanoTime()-s1;
    /// let sec1 = Int64.toFloat64(diff1)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec1);
    /// StringBuilder.appendLine!(sb, " sec");







 


    /// StringBuilder.appendString!(sb, "unbounded_mpsp      flix flix      ");
    /// let s3 = nanoTime();
    /// spawn mpsc(messages,threads,c_unbounded);
    /// let diff3 = nanoTime()-s3;
    /// let sec3 = Int64.toFloat64(diff3)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec3);
    /// StringBuilder.appendLine!(sb, " sec");

    
    



    


    /// StringBuilder.appendString!(sb, "unbounded_mpmc      flix flix      ");
    /// let s5 = nanoTime();
    /// spawn mpmc(messages,threads,c_unbounded);
    /// let diff5 = nanoTime()-s5;
    /// let sec5 = Int64.toFloat64(diff5)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec5);
    /// StringBuilder.appendLine!(sb, " sec");





    StringBuilder.appendString!(sb, "bounded_select_rx      flix flix      ");
    let s6 = nanoTime();
    select_rx_b(messages);
    let diff6 = nanoTime()-s6;
    let sec6 = Int64.toFloat64(diff6)/1000000000.0;
    StringBuilder.appendFloat64!(sb,sec6);
    StringBuilder.appendLine!(sb, " sec");


    /// StringBuilder.appendString!(sb, "unbounded_select_rx      flix flix      ");
    /// let s7 = nanoTime();
    /// spawn select_rx_u(messages);
    /// let diff7 = nanoTime()-s7;
    /// let sec7 = Int64.toFloat64(diff7)/1000000000.0;
    /// StringBuilder.appendFloat64!(sb,sec7);
    /// StringBuilder.appendLine!(sb, " sec");
    


    Console.printLine(StringBuilder.toString(sb));
    ""

