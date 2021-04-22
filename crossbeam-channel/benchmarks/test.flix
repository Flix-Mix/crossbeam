def send(num_messages: Int, c: Channel[Int]): Int & Impure =
    if (num_messages == 0) (0)
    else {
        c <- num_messages; ///send arbitrary value
        send(num_messages-1, c) //repeat
    }  

def recv(num_messages: Int, c: Channel[Int]): Int & Impure =
    if (num_messages == 500) (0) //must change if num messages change
    else {
        <- c;
        recv(num_messages+1, c)
    }

def mult_send(num_messages: Int, num_threads: Int, c: Channel[Int]): Int & Impure =
    if (num_threads == 0 ) (0)
    else {
        spawn send(num_messages/num_threads, c);
        mult_send(num_messages,num_threads-1,c)
    }

def mult_recv(num_messages: Int, num_threads: Int, c: Channel[Int]): Int & Impure =
    if (num_threads == 0) (0)
    else {
        spawn recv(num_messages/num_threads, c);
        mult_recv(num_messages,num_threads-1,c)
    }

def select_recv(num_messages: Int, c1: Channel[Int], c2: Channel[Int], c3: Channel[Int], c4: Channel[Int]): Int & Impure =
    if (num_messages == 0) (0)
    else {
        select {
        case v <- c1 => v
        case v <- c2 => v
        case v <- c3 => v
        case v <- c4 => v
        };
        select_recv(num_messages-1,c1,c2,c3,c4)
    }
    

def spsc(num_messages: Int, c: Channel[Int]): Int & Impure =
    send(num_messages,c);
    recv(num_messages,c)


def mpsc(num_messages: Int, num_threads: Int, c: Channel[Int]): Int & Impure =
    mult_send(num_messages,num_threads,c);
    recv(num_messages,c)

def mpmc(num_messages: Int, num_threads: Int, c: Channel[Int]): Int & Impure =
    mult_send(num_messages,num_threads,c);
    mult_recv(num_messages,num_threads,c)

def select_rx_u(num_messages: Int): Int & Impure =
    let c1 = chan Int 0;
    let c2 = chan Int 0;
    let c3 = chan Int 0;
    let c4 = chan Int 0;

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
    Console.printLine("Starting...");
    let messages = 500; //from crossbeam  (5000000)
    let threads = 4; //from crossbeam
    let c_unbounded = chan Int 0;
    let c_bounded = Channel.newWithCapacity(messages); 
    spawn spsc(messages, c_unbounded);
    spawn spsc(messages, c_bounded);

    spawn mpsc(messages,threads,c_unbounded);
    spawn mpsc(messages,threads, c_bounded);

    spawn mpmc(messages,threads,c_unbounded);
    spawn mpmc(messages,threads, c_bounded);

    spawn select_rx_u(messages); //runtime crash
    spawn select_rx_b(messages); //runtime crash

    "Done"

