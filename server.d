import std.stdio;
import std.string;
import std.socket;
import parser;
import database;

const int BUFFER_SIZE = 4096;

@safe
void print_prompt() {
    "simple_db> ".write;
}

@safe
void send_prompt(Socket client) {
    client.send("simple_db> ");
}

class ExitException : Exception {
    pure this(string msg = null, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

void clearBuffer(char[] buffer, int size) {
    for (int i = 0; i < size; i++) buffer[i] = 0;
}

void handle_metacommand(Statement statement) {
    switch(statement.metacommand) {
        case MetaCommandResult.META_COMMAND_EXIT:
            throw new ExitException;
        default:
            break;
    }
}

void handle_command(Statement statement, database.Database!string db, Socket client) {
    import std.conv;
    if (statement.metacommand != MetaCommandResult.META_COMMAND_NOT_FOUND) {
        handle_metacommand(statement);
        return;
    }
    switch(statement.command) {
        case CommandResult.COMMAND_SET:
            db.set(statement.key, statement.value);
            client.send("OK\n");
            break;
        case CommandResult.COMMAND_GET:
            auto result = db.get(statement.key);
            if (result.found) {
                client.send(result.value ~ "\n");
            }
            else {
                client.send("(empty string)\n");
            }
            break;
        case CommandResult.COMMAND_DELETE:
            client.send(db.remove(statement.key).to!string ~ "\n");
            break;
        case CommandResult.COMMAND_KEYS:
            client.send("not implemented\n");
            break;
        default:
            break;
    }
}

void main() {
    import core.thread;
    import std.conv;

    auto idb = new database.IndexedDatabase!string("/tmp/tmpdb.db");
    auto server = new TcpSocket();
    server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
    server.bind(new InternetAddress(10000));
    server.listen(3);

    "[INFO] Server Listening".writeln;

    while (true) {
        auto client = server.accept();
        new Thread({
            char[BUFFER_SIZE] buffer;

            while (true) {
                send_prompt(client);
                auto read = client.receive(buffer);
                if (read == 0) {
                    break;
                }

                auto input = buffer[0..read].to!string;
                if (input.isEmpty) {
                    client.send("\n");
                    break;
                }
                else {
                    input = input.strip;
                }
                try {
                    auto parseResult = parser.parse(input);
                    parseResult.handle_command(idb, client);
                }
                catch (ParseException ex) {
                    client.send(ex.msg ~ "\n");
                }
                catch (ExitException) {
                    break;
                }
                clearBuffer(buffer, BUFFER_SIZE);
            }
        }).start();
    }
}