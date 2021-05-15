namespace CrossbeamBenchmarks {

    use ChannelImpl.{ChannelImpl, get, put, selectImpl, new, newWithId};

    def putNumMessages(channel: ChannelImpl[Int], numMessages: Int): Unit & Impure = 
        if (numMessages <= 0)
            ()
        else {
            put(channel, numMessages);
            putNumMessages(channel, numMessages - 1)
        }

    def getNumMessages(channel: ChannelImpl[a], numMessages: Int): Unit & Impure = 
        if (numMessages <= 0)
            ()
        else {
            get(channel);
            getNumMessages(channel, numMessages - 1) 
        }

    def putNumMessagesParallelHelper(channel: ChannelImpl[Int], done: ChannelImpl[Unit], numThreadsLeft: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
        if (numThreadsLeft <= 0)
            ()
        else {
            spawn {
                putNumMessages(channel, numMessages / numThreads);
                put(done, ())
            };
            putNumMessagesParallelHelper(channel, done, numThreadsLeft - 1, numThreads, numMessages)
        }

    def putNumMessagesParallel(channel: ChannelImpl[Int], done: ChannelImpl[Unit], numThreads: Int, numMessages: Int): Unit & Impure = 
        putNumMessagesParallelHelper(channel, done, numThreads, numThreads, numMessages)

    def getNumMessagesParallelHelper(channel: ChannelImpl[a], done: ChannelImpl[Unit], numThreadsLeft: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
        if (numThreadsLeft <= 0)
            ()
        else { 
            spawn {
                getNumMessages(channel, numMessages / numThreads);
                put(done, ())
            };
            getNumMessagesParallelHelper(channel, done, numThreadsLeft - 1, numThreads, numMessages)
        }

    def getNumMessagesParallel(channel: ChannelImpl[a], done: ChannelImpl[Unit], numThreads: Int, numMessages: Int): Unit & Impure = 
        getNumMessagesParallelHelper(channel, done, numThreads, numThreads, numMessages)

    pub def seq(capacity: Int, numMessages: Int): Unit & Impure = 
        let c = new(capacity);

        putNumMessages(c, numMessages);
        getNumMessages(c, numMessages)

    pub def spsc(capacity: Int, numMessages: Int): Unit & Impure =
        let c = new(capacity);

        spawn putNumMessages(c, numMessages);
        getNumMessages(c, numMessages)
        
    pub def mpsc(capacity: Int, numThreads: Int, numMessages: Int): Unit & Impure =         
        let c = new(capacity);
        let done = new(numThreads);
        
        putNumMessagesParallel(c, done, numThreads, numMessages);
        getNumMessages(c, (numMessages / numThreads) * numThreads)

    pub def mpmc(capacity: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
        let c = new(capacity);
        let done = new(numThreads);
        
        putNumMessagesParallel(c, done, numThreads, numMessages);
        getNumMessagesParallel(c, done, numThreads, numMessages);

        getNumMessages(done, numThreads * 2)

    def selectHelper(c0: ChannelImpl[a], c1: ChannelImpl[a], c2: ChannelImpl[a], c3: ChannelImpl[a], numMessages: Int): Unit & Impure =
        if (numMessages <= 0)
            ()
        else {
            selectImpl([c0, c1, c2, c3], false);
            selectHelper(c0, c1, c2, c3, numMessages - 1)
        }

    pub def selectRx(capacity: Int, numMessages: Int): Unit & Impure = 
        let numThreads = 4;

        let c0 = newWithId(capacity, 0i64);
        let c1 = newWithId(capacity, 1i64);
        let c2 = newWithId(capacity, 2i64);
        let c3 = newWithId(capacity, 3i64);

        spawn putNumMessages(c0, numMessages / numThreads);
        spawn putNumMessages(c1, numMessages / numThreads);
        spawn putNumMessages(c2, numMessages / numThreads);
        spawn putNumMessages(c3, numMessages / numThreads);

        selectHelper(c0, c1, c2, c3, (numMessages / numThreads) * numThreads)

    pub def runMicroBenchmark(name: String, microBenchmark: Int ~> Unit, numMessages: Int): Unit & Impure = 
        import java.lang.System:nanoTime();
        let startTime = nanoTime();
        microBenchmark(numMessages);
        let endTime = nanoTime() - startTime;
        
        let runTime = Int64.toFloat64(endTime) / Int64.toFloat64(1_000_000_000i64);

        Console.printLine(name + " Flix flix " + Float64.toString(runTime) + " secs")

}
