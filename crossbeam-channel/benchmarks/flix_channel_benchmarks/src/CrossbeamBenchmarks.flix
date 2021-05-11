namespace CrossbeamBenchmarks {

    use ChannelImpl.{ChannelImpl, get, put, selectImpl, newWithCapacity};

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

    def putNumMessagesParallel(channel: ChannelImpl[Int], done: ChannelImpl[Unit], numThreads: Int, numMessages: Int): Unit & Impure = 
        if (numThreads <= 0)
            ()
        else {
            spawn {
                putNumMessages(channel, numMessages / numThreads);
                put(done, ())
            };
            putNumMessagesParallel(channel, done, numThreads - 1, numMessages)
        }

    def getNumMessagesParallel(channel: ChannelImpl[a], done: ChannelImpl[Unit], numThreads: Int, numMessages: Int): Unit & Impure = 
        if (numThreads <= 0)
            ()
        else { 
            spawn {
                getNumMessages(channel, numMessages / numThreads);
                get(done)
            };
            getNumMessagesParallel(channel, done, numThreads - 1, numMessages)
        }

    pub def seq(capacity: Int, numMessages: Int): Unit & Impure = 
        let c = newWithCapacity(capacity, 0i64);

        putNumMessages(c, numMessages);
        getNumMessages(c, numMessages)

    pub def spsc(capacity: Int, numMessages: Int): Unit & Impure =
        let c = newWithCapacity(capacity, 0i64);

        spawn putNumMessages(c, numMessages);
        getNumMessages(c, numMessages)
        
    pub def mpsc(capacity: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
        let c = newWithCapacity(capacity, 0i64);
        let done = newWithCapacity(0, 0i64);
        
        putNumMessagesParallel(c, done, numThreads, numMessages);
        getNumMessages(c, numMessages);

        getNumMessages(done, numThreads)

    pub def mpmc(capacity: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
        let c = newWithCapacity(capacity, 0i64);
        let done = newWithCapacity(0, 0i64);
        
        putNumMessagesParallel(c, done, numThreads, numMessages);
        getNumMessagesParallel(c, done, numThreads, numThreads);

        getNumMessages(done, numThreads * 2)

    def selectHelper(c0: ChannelImpl[a], c1: ChannelImpl[a], c2: ChannelImpl[a], c3: ChannelImpl[a], done: ChannelImpl[()], numMessages: Int): Unit & Impure =
        if (numMessages == 0) {
            put(done, ());
            ()
        } else {
            selectImpl([c0, c1, c2, c3], false);
            selectHelper(c0, c1, c2, c3, done, numMessages - 1)
        }

    pub def selectRx(capacity: Int, numMessages: Int): Unit & Impure = 
        let numThreads = 4;

        let c0 = newWithCapacity(capacity, 0i64);
        let c1 = newWithCapacity(capacity, 1i64);
        let c2 = newWithCapacity(capacity, 2i64);
        let c3 = newWithCapacity(capacity, 3i64);
        let done = newWithCapacity(0, 0i64);

        spawn putNumMessages(c0, numMessages / numThreads);
        spawn putNumMessages(c1, numMessages / numThreads);
        spawn putNumMessages(c2, numMessages / numThreads);
        spawn putNumMessages(c3, numMessages / numThreads);

        selectHelper(c0, c1, c2, c3, done, numMessages)

    pub def selectBoth(capacity: Int, numMessages: Int): Unit & Impure =
        let numThreads = 4;

        let c0 = newWithCapacity(capacity, 0i64);
        let c1 = newWithCapacity(capacity, 1i64);
        let c2 = newWithCapacity(capacity, 2i64);
        let c3 = newWithCapacity(capacity, 3i64);
        let done = newWithCapacity(0, 0i64);

        spawn putNumMessages(c0, numMessages / numThreads);
        spawn putNumMessages(c1, numMessages / numThreads);
        spawn putNumMessages(c2, numMessages / numThreads);
        spawn putNumMessages(c3, numMessages / numThreads);

        spawn selectHelper(c0, c1, c2, c3, done, numMessages / numThreads);
        spawn selectHelper(c0, c1, c2, c3, done, numMessages / numThreads);
        spawn selectHelper(c0, c1, c2, c3, done, numMessages / numThreads);
        spawn selectHelper(c0, c1, c2, c3, done, numMessages / numThreads);

        getNumMessages(done, 4)


    pub def runMicroBenchmark(name: String, microBenchmark: Int ~> Unit, numMessages: Int): Unit & Impure = 
        import java.lang.System:nanoTime();
        let startTime = nanoTime();
        microBenchmark(numMessages);
        let endTime = nanoTime() - startTime;
        
        let runTime = Int64.toFloat64(endTime) / Int64.toFloat64(1_000_000_000i64);

        Console.printLine(name + " Flix flix " + Float64.toString(runTime) + " sec")

}