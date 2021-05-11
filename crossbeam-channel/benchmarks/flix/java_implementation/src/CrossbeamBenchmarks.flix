def send(num_messages: Int, c: Channel[Int]): Unit & Impure =
    // Console.printLine("in send: " + printInt(num_messages));
    if (num_messages == 0) 
        ()
    else {
        ///Console.printLine("sending...");
        c <- num_messages; ///send arbitrary value
        send(num_messages-1, c) //repeat
    }  

def recv(num_messages: Int, c: Channel[Int]): Unit & Impure =
    // Console.printLine("in rec: " + printInt(num_messages));
    if (num_messages == 0) {
        //Console.printLine("Done");
        ()
    }
    else {
        ///Console.printLine("receiving...");
        <- c;
        recv(num_messages-1, c)
    }

def mult_send(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Unit & Impure =
    //Console.printLine("in mult_send: " + printInt(num_messages) + " " + printInt(num_threads));
    if (num_threads == 0 ) 
        ()
    else {
        //Console.printLine("Shooting " + printInt(num_messages/final_num_threads) + " messages to be sent");
        spawn send(num_messages/final_num_threads, c);
        mult_send(num_messages,num_threads-1,c,final_num_threads)
    }

def mult_recv(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Unit & Impure =
    //Console.printLine("in mult_recv: " + printInt(num_messages) + " " + printInt(num_threads));
    if (num_threads == 0) 
        ()
    else {
        spawn recv(num_messages/final_num_threads, c);
        mult_recv(num_messages,num_threads-1,c,final_num_threads)
    }

def select_recv(num_iter: Int, c1: Channel[Int], c2: Channel[Int], c3: Channel[Int], c4: Channel[Int]): Unit & Impure =
    Console.printLine("receving!");
    if (num_iter == 0) 
        ()
    else {
        select {
        case v <- c1 => v
        case v <- c2 => v
        case v <- c3 => v
        case v <- c4 => v
        };
        select_recv(num_iter-1,c1,c2,c3,c4)
    }
    
    //} 
def select_recv_help(num_messages: Int, c1: Channel[Int], c2: Channel[Int], c3: Channel[Int], c4: Channel[Int], fin_messages: Int): Unit & Impure =
    //Console.printLine(printInt(fin_messages) + " " + printInt(num_messages));
    if (num_messages == 0) 
        ()
    else {
        spawn select_recv(fin_messages/4,c1,c2,c3,c4);
        select_recv_help(num_messages-1,c1,c2,c3,c4,fin_messages)
    }

def spsc(num_messages: Int, c: Channel[Int]): Int & Impure =
    spawn send(num_messages,c);
    recv(num_messages,c);
    1

def seq(num_messages: Int, c: Channel[Int]): Int & Impure =
    send(num_messages,c);
    recv(num_messages,c);
    1

def mpsc(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Unit & Impure =
    mult_send(num_messages,num_threads,c, final_num_threads);
    recv(num_messages,c)

def mpmc(num_messages: Int, num_threads: Int, c: Channel[Int], final_num_threads: Int): Unit & Impure =
    mult_send(num_messages,num_threads,c, final_num_threads);
    mult_recv(num_messages,num_threads,c, final_num_threads)

def select_rx(num_messages: Int): Unit & Impure =
    let c1 = Channel.newWithCapacity(num_messages);
    let c2 = Channel.newWithCapacity(num_messages);
    let c3 = Channel.newWithCapacity(num_messages);
    let c4 = Channel.newWithCapacity(num_messages);

    spawn send(num_messages/4,c1);
    spawn send(num_messages/4,c2);
    spawn send(num_messages/4,c3);
    spawn send(num_messages/4,c4);

    select_recv_help(num_messages,c1,c2,c3,c4,num_messages)     