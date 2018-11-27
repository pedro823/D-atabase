import std.socket;
import std.datetime.stopwatch;
import std.random;
import std.stdio;
import std.traits;

const int BUFFER_SIZE = 4096;
const long AMOUNT_OF_KEYS = 100;

@safe
string randomString(L)(L length) 
if (isIntegral!L) {
    import std.ascii : lowercase;
    import std.array : join;
    import std.range : iota, take;
    import std.algorithm : map;
    import std.array : array;
    import std.conv : to;
    static immutable auto randomLetter = () => randomSample(lowercase, 1, lowercase.length).front;
    return length.iota.map!(_ => randomLetter()).array.to!string;
}

string generateSetCommand(string key, string value) {
    return "set " ~ key ~ " " ~ value;
}

@safe
void clearBuffer(L)(char[] buffer, L size)
if (isIntegral!L) {
    for (int i = 0; i < size; i++) buffer[i] = 0;
}

void sendRandomKey(TcpSocket client) {
    char[BUFFER_SIZE] buffer;
    auto received = client.receive(buffer);
    clearBuffer(buffer, received);
    auto randKey = randomString(30);
    auto randValue = randomString(30);
    auto setCommand = generateSetCommand(randKey, randValue);
    client.send(setCommand);
    received = client.receive(buffer);
    assert(buffer[0 .. received] == "OK\n");
    writeln(randKey);
}

void main() {
    import core.thread;
    import std.datetime.stopwatch;
    import std.conv : to;
    import std.parallelism;

    char[BUFFER_SIZE] buffer;

    auto socket = new TcpSocket;
    socket.connect(new InternetAddress("localhost", 10000));

    auto sw = StopWatch(AutoStart.yes);
    foreach(long i; 0..AMOUNT_OF_KEYS) {
        // taskPool.put(task!sendRandomKey(socket));
        sendRandomKey(socket);
    }
    // taskPool.finish(true);
    sw.stop();
    "%d keys were inserted in %s".writefln(AMOUNT_OF_KEYS, sw.peek);

    auto timePerKey = sw.peek() / AMOUNT_OF_KEYS;
    "time per key = %s".writefln(timePerKey);
    double keysPerSec = cast(double) 1.seconds.total!"nsecs" / timePerKey.total!"nsecs";
    "keys per sec = %g".writefln(keysPerSec);
}