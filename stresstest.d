const int BUFFER_SIZE = 4096;

void main() {
    import std.socket;
    import std.datetime.stopwatch;
    char[BUFFER_SIZE] buffer;

    auto socket = new TCPSocket;
    socket.connect(new InternetAddress("localhost", 10000));
}