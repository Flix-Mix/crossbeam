/*
 * Copyright 2019 Magnus Madsen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

namespace Channel {

    type alias ReentrantLock = ##java.util.concurrent.locks.ReentrantLock

    def newReentrantLock(): ReentrantLock & Impure =
        import new java.util.concurrent.locks.ReentrantLock() as javaNewReentrantLock;
        javaNewReentrantLock()

    def newCondition(reentrantLock: ReentrantLock): Condition & Impure =
        import java.util.concurrent.locks.ReentrantLock.newCondition() as javaNewCondition;
        javaNewCondition(reentrantLock)

    def java_lock(reentrantLock: ReentrantLock): Unit & Impure =
        import java.util.concurrent.locks.ReentrantLock.lock() as javaLock;
        javaLock(reentrantLock)

    def java_unlock(reentrantLock: ReentrantLock): Unit & Impure =
        import java.util.concurrent.locks.ReentrantLock.unlock() as javaUnlock;
        javaUnlock(reentrantLock)

    type alias Condition = ##java.util.concurrent.locks.Condition

    def signalAll(cond: Condition): Unit & Impure =
        import java.util.concurrent.locks.Condition.signalAll() as javaSignalAll;
        javaSignalAll(cond)

    def await(condition: Condition): Unit & Impure =
        import java.util.concurrent.locks.Condition.await() as javaAwait;
        javaAwait(condition)

    /**
    * The tuple corresponds to (id, channelLock, bufferSize, capacity0, elementQueue, waitingGetters, waitingSetters)
    *   - id
    *   - channelLock is the channelLock of this channel.
    *   - bufferSize is the size of a channel. If you try to put an element in a channel that's full, you wait until there's space.
    *   - a flag for whether the channel is capacity0 or not
    *   - elementQueue is the elementQueue of elements in the list.
    *   - waitingGetters is a set of conditions that is waiting for get. This set is cleared after each new element.
    *   - waitingSetters is a condition that can notify threads of available space in the elementQueue.
    */
    pub enum ChannelImpl[a] {
        case Mpmc(
                Int64,
                ReentrantLock,
                Int,
                Bool,
                MutList[a],
                MutList[(ReentrantLock, Condition)],
                Condition
            )
    }

    /// @Override
    /// pub def equals(o: a): Bool & Impure =
    ///     if (this == o) return true;
    ///     if (o == null || getClass() != o.getClass()) return false;
    ///     ChannelIndexPair that = (ChannelIndexPair) o;
    ///     return index == that.index && Objects.equals(channel, that.channel);
    /// }

    /// @Override
    /// pub def hashCode(cip: ChannelIndexPair): Int =
    ///     import java.util.Objects.hash as hash;
    ///     hash(getChannel(cip), getIndex(cip))

    /// instance Order[ChannelImpl[a]] {
    ///     pub def compare(x: Channel[a], y: Channel[a]): Comparison =
    ///         compare(x.id, y.id)
    /// }

    /// instance Eq[ChannelImpl[a]] {
    ///     pub def eq(x: Channel[a], y: Channel[b]): Bool =
    ///         channelId(x) == channelId(y)
    /// }

    def newId(): Int64 =
        /// import library.Channel.GlobalCounter:newId() as javaNewId;
        /// javaNewId()
        1i64

    def bug!(message: String): Unit & Impure = 
        Console.printLine(message)

    ///
    /// Returns a fresh capacity5M channel with internal capacity `c`.
    ///
    pub def newWithCapacity_dup(bufferSize: Int): ChannelImpl[a] & Impure =
        let (bufSize, capacity0) =
            if (bufferSize < 0) {
                bug!("Channel's buffer size must be non-negative.");
                (1, false)
            } else if (bufferSize == 0)
                (1, true)
            else
                (bufferSize, false);

        let reentrantLock = newReentrantLock();

        Mpmc(
            newId(),
            reentrantLock,
            bufSize,
            capacity0,
            MutList.new(),
            MutList.new(), // MutSet.empty()
            newCondition(reentrantLock)
        )

    def putHelperWaitOnFullChannel(c: ChannelImpl[a]): () & Impure =
        if (MutList.length(getElementQueue(c)) >= getBufferSize(c)) {
            await(getWaitingSetters(c));
            putHelperWaitOnFullChannel(c)
        } else {
            ()
        }


    ///
    /// Sends the element `x` on the channel `c`.
    ///
    /// Equivalent to the expression `c <- x`.
    ///
    pub def put_dup(c: ChannelImpl[a], x: a): ChannelImpl[a] & Impure =
        lock(c);

        // Check if the channel is full
        putHelperWaitOnFullChannel(c);

        // There was space to put another element in the channel
        MutList.push!(x, getElementQueue(c));

        // Signal waitingGetters that there is an element available
        MutList.foreach(
            (lockConditionPair) -> {
                let (conditionLock, condition) = lockConditionPair;
                java_lock(conditionLock);
                signalAll(condition);
                java_unlock(conditionLock)
            },
            getWaitingGetters(c));

        // Clear waitingGetters.
        // If a waitingGetter does not receive an element, it can add itself again
        MutList.clear!(getWaitingGetters(c));

        // If the channel is capacity0, wait for the element to be handed off before continuing
        if (getcapacity0(c)) 
            await(getWaitingSetters(c))
        else 
            ();

        unlock(c);

        c

    /*
    * Recursive helper function for get, loops and awaits on empty channel
    */
    def getHelperWaitOnEmptyChannel(chan: ChannelImpl[a], element: Option[a]): a & Impure =
        match element {
            case None => {
                // No element was found

                // Create a new Lock and Condition
                let conditionLock = newReentrantLock();
                java_lock(conditionLock);

                let condition = newCondition(conditionLock);
                // Add LockConditionPair to the channel
                MutList.push!((conditionLock, condition), getWaitingGetters(chan));

                // Temporarily unlock the channel while waiting. This is necessary as the Condition comes from a different Lock.
                unlock(chan);
                await(condition);
                lock(chan);

                // Someone signalled that an element was put in the channel.
                // Try to get the element (which could already be taken by someone else)
                let optionalElement = MutList.pop!(getElementQueue(chan));

                java_unlock(conditionLock);

                getHelperWaitOnEmptyChannel(chan, optionalElement)
            }
            case Some(e) => e
        }

    ///
    /// Receives an element from the channel `c`.
    ///
    /// Equivalent to the expression `<- c`.
    ///
    pub def get_dup(chan: ChannelImpl[a]): a & Impure =
        lock(chan);

        let optionalElement = MutList.pop!(getElementQueue(chan));
        let element = getHelperWaitOnEmptyChannel(chan, optionalElement);

        // Signal waiting setters that the channel has space
        signalAll(getWaitingSetters(chan));

        unlock(chan);

        // Return the element from the channel
        element
        // TODO : test putting on full channel

    def tryGet(chan: ChannelImpl[a]): Option[a] & Impure =
        lock(chan);

        // Try to get an element from the channel
        let queue = getElementQueue(chan);
        let element = MutList.pop!(queue);

        // If there was an element, signal waiting setters
        match element {
            case None => ()
            case _ => {
                let ws = getWaitingSetters(chan);
                signalAll(ws)
            }
        };

        unlock(chan);
        // Return the element from the channel, or None if channel was empty
        element

    def threadInterrupted(): Bool & Impure =
        import java.lang.Thread:interrupted();
        let isInterrupted = interrupted();
        if (isInterrupted)
            true
        else
            false

    def cmp(a: ChannelImpl[a], b: ChannelImpl[a]): Int =
        let a_id = getId(a);
        let b_id = getId(b);
        if (a_id == b_id)
            (0)
        else if (a_id > b_id)
            (1)
        else
            (-1)

    def sortChannels(channels: Array[ChannelImpl[a]]): Array[ChannelImpl[a]] & Impure =
        Array.sortWith(cmp, channels)

    def selectHelper(channels: Array[ChannelImpl[a]], sortedChannels: Array[ChannelImpl[a]], selectLock: ReentrantLock, condition: Condition, hasDefault: Bool): Option[(Int, a)] & Impure =
        if (not threadInterrupted()) {
            // Lock all channels in sorted order
            lockAllChannels(sortedChannels);

            // Lock the select lock after the channels
            java_lock(selectLock);

            // Find channels with waiting elements
            let selectChoicesWithWaitingElements = MutList.new();
            Array.foreachWithIndex(
                (c, i) -> {
                    match tryGet(c) {
                        case None => ()
                        case Some(element) => {
                            // There is a waiting element in this channel.
                            // Return the element and the branchNumber of this channel

                            // If an element found, add a new selectChoice to the MutList in order to later return
                            MutList.push!((i, element), selectChoicesWithWaitingElements)
                        }
                    }
                },
                channels
                );

            if (not MutList.isEmpty(selectChoicesWithWaitingElements)) {
                // Element found
                Some(MutList.get(0, selectChoicesWithWaitingElements))
            } else if (hasDefault) {
                // No element was found and default case exists
                None
            } else {
                // No element was found.
                // Add our condition to all channels to get notified when a new element is added
                Array.foreach(
                    (c) -> {
                        addGetter(c, selectLock, condition)
                    },
                    channels);

                // Unlock all channels in sorted order, so other threads may input elements
                unlockAllChannels(sortedChannels);

                // Wait for an element to be added to any of the channels
                await(condition);

                // Unlock the selectLock, which is relevant when a different thread wants to put
                // an element into a channel that was not selected from the select.
                // This other channel will then signal the condition from selectLock (in the put method),
                // so it needs the lock.
                java_unlock(selectLock);

                selectHelper(channels, sortedChannels, selectLock, condition, hasDefault)
            }
        } else {
            bug!("Thread is interrupted");
            None
        }

  /**
   * Given a array of channels, returns the first channel that has an element
   * and return the index of that channel and the retrieved element in a
   * SelectChoice object.
   *
   * @param channels the channels to select on
   * @return the channel index of the channel with an element and the element
   */
   // TODO : resolve the function name issue
    pub def selectImpl(channels: Array[ChannelImpl[a]], hasDefault: Bool): Option[(Int, a)] & Impure =
        // Create new Condition and channelLock the current thread
        let selectLock = newReentrantLock();
        let condition = newCondition(selectLock);

        // Sort channels to avoid deadlock when locking
        let sortedChannels = sortChannels(channels);
        selectHelper(channels, sortedChannels, selectLock, condition, hasDefault)

    def getId(c: ChannelImpl[a]): Int64 = match c {
            case Mpmc(id, _, _, _, _, _, _)   => id
        }

    def getChannelLock(c: ChannelImpl[a]): ReentrantLock = match c {
            case Mpmc(_, channelLock, _, _, _, _, _)   => channelLock
        }

    def getBufferSize(c: ChannelImpl[a]): Int = match c {
            case Mpmc(_, _, bufferSize, _, _, _, _)   => bufferSize
        }

    def getcapacity0(c: ChannelImpl[a]): Bool = match c {
            case Mpmc(_, _, _, capacity0, _, _, _)   => capacity0
        }

    def getElementQueue(c: ChannelImpl[a]): MutList[a] = match c {
            case Mpmc(_, _, _, _, elementQueue, _, _)   => elementQueue
        }

    // TODO : make it a MutList or MutSet??
    def getWaitingGetters(c: ChannelImpl[a]): MutList[(ReentrantLock, Condition)] = match c {
            case Mpmc(_, _, _, _, _, waitingGetters, _)   => waitingGetters
        }

    def getWaitingSetters(c: ChannelImpl[a]): Condition = match c {
            case Mpmc(_, _, _, _, _, _, waitingSetters)   => waitingSetters
        }

    def lock(chan: ChannelImpl[a]): Unit & Impure =
        let lock = getChannelLock(chan);
        java_lock(lock)

    def unlock(chan: ChannelImpl[a]): Unit & Impure =
        let lock = getChannelLock(chan);
        java_unlock(lock)

    def lockAllChannels(channels: Array[ChannelImpl[a]]): Unit & Impure =
        Array.foreach(lock, channels)

    def unlockAllChannels(channels: Array[ChannelImpl[a]]): Unit & Impure =
        Array.foreach(unlock, channels)

    /**
    * Adds the given condition to the list of conditions waiting to
    * retrieve elements from the elementQueue.
    *
    * @param condition the condition to add
    */
    def addGetter(channel: ChannelImpl[a], conditionLock: ReentrantLock, condition: Condition): Unit & Impure =
        lock(channel);
        let pair = (conditionLock, condition);

        // Add LockConditionPair to the channel
        MutList.push!(pair, getWaitingGetters(channel));
        unlock(channel)

}

def putNumMessages(channel: Channel.ChannelImpl[Int], numMessages: Int): Unit & Impure = 
    if (numMessages <= 0)
        ()
    else {
        Channel.put_dup(channel, numMessages);
        putNumMessages(channel, numMessages - 1)
    }

def getNumMessages(channel: Channel.ChannelImpl[a], numMessages: Int): Unit & Impure = 
    if (numMessages <= 0)
        ()
    else {
        Channel.get_dup(channel);
        getNumMessages(channel, numMessages - 1) 
    }

def putNumMessagesParallel(channel: Channel.ChannelImpl[Int], done: Channel.ChannelImpl[Unit], numThreads: Int, numMessages: Int): Unit & Impure = 
    if (numThreads <= 0)
        ()
    else {
        spawn {
            putNumMessages(channel, numMessages / numThreads);
            Channel.put_dup(done, ())
        };
        putNumMessagesParallel(channel, done, numThreads - 1, numMessages)
    }

def getNumMessagesParallel(channel: Channel.ChannelImpl[a], done: Channel.ChannelImpl[Unit], numThreads: Int, numMessages: Int): Unit & Impure = 
    if (numThreads <= 0)
        ()
    else { 
        spawn {
            getNumMessages(channel, numMessages / numThreads);
            Channel.get_dup(done)
        };
        getNumMessagesParallel(channel, done, numThreads - 1, numMessages)
    }

def seq(capacity: Int, numMessages: Int): Unit & Impure = 
    let c = Channel.newWithCapacity_dup(capacity);

    putNumMessages(c, numMessages);
    getNumMessages(c, numMessages)

def spsc(capacity: Int, numMessages: Int): Unit & Impure =
    let c = Channel.newWithCapacity_dup(capacity);

    spawn putNumMessages(c, numMessages);
    getNumMessages(c, numMessages)
    
def mpsc(capacity: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
    let c = Channel.newWithCapacity_dup(capacity);
    let done = Channel.newWithCapacity_dup(0);
    
    putNumMessagesParallel(c, done, numThreads, numMessages);
    getNumMessages(c, numMessages);

    getNumMessages(done, numThreads)

def mpmc(capacity: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
    let c = Channel.newWithCapacity_dup(capacity);
    let done = Channel.newWithCapacity_dup(0);
    
    putNumMessagesParallel(c, done, numThreads, numMessages);
    getNumMessagesParallel(c, done, numThreads, numThreads);

    getNumMessages(done, numThreads * 2)

/// def selectRx(capacity: Int, numThreads: Int, numMessages: Int): Unit & Impure = 
///     let channels = [Channel.newWithCapacity_dup(capacity); numThreads];
///     let done = Channel.newWithCapacity_dup(numThreads);

///     Array.foreach((channel) -> putNumMessagesParallel(channel, done, numThreads, numMessages), channels);


///     getNumMessages(done, numThreads)


def runMicroBenchmark(name: String, microBenchmark: Int ~> Unit, numMessages: Int): Unit & Impure = 
    import java.lang.System:nanoTime();
    let startTime = nanoTime();
    microBenchmark(numMessages);
    let endTime = nanoTime() - startTime;
    
    let runTime = Int64.toFloat64(endTime) / Int64.toFloat64(1_000_000_000i64);

    Console.printLine(name + " Flix flix " + Float64.toString(runTime) + " sec")

def main(): Unit & Impure =
    let numThreads = 4;
    let numMessages = 50; // 5_000_000;

    let capacity0 = 0; 
    runMicroBenchmark("bounded0_mpmc", mpmc(capacity0, numThreads), numMessages);
    runMicroBenchmark("bounded0_mpsc", mpsc(capacity0, numThreads), numMessages);
    /// bounded0_select_both
    /// bounded0_select_rx
    runMicroBenchmark("bounded0_spsc", spsc(capacity0), numMessages);

    let capacity1 = 1;
    runMicroBenchmark("bounded1_mpmc", mpmc(capacity1, numThreads), numMessages);
    runMicroBenchmark("bounded1_mpsc", mpsc(capacity1, numThreads), numMessages);
    /// bounded1_select_both
    /// bounded1_select_rx
    runMicroBenchmark("bounded1_spsc", spsc(capacity1), numMessages);

    let capacity5M = 50; // 5_000_000;
    runMicroBenchmark("bounded_mpmc", mpmc(capacity5M, numThreads), numMessages);
    runMicroBenchmark("bounded_mpsc", mpsc(capacity5M, numThreads), numMessages);
    /// bounded_select_both
    /// bounded_select_rx
    runMicroBenchmark("bounded_seq", seq(capacity5M), numMessages);
    runMicroBenchmark("bounded_spsc", spsc(capacity5M), numMessages);

    ()