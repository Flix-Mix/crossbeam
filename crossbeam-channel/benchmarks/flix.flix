def addToChannel(channel: Channel[Int], count: Int): Unit & Impure =
    channel <- count;
    addToChannel(channel, count - 1)

def removeFromChannel(channel: Channel[Int], count: Int): Unit & Impure =
    <- channel;
    removeFromChannel(channel, count - 1)

def seq(messageCount: Int, chanCapacity: Int): Unit & Impure =
    let c = chan Int chanCapacity;
    addToChannel(c, messageCount);
    removeFromChannel(c, messageCount);

