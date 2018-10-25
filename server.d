import std.stdio;
import std.string;
import parser;
import database;

@safe
void print_prompt() {
    "simple_db> ".write;
}

class ExitException : Exception {
    pure this(string msg = null, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

void handle_metacommand(Statement statement) {
    switch(statement.metacommand) {
        case MetaCommandResult.META_COMMAND_EXIT:
            throw new ExitException;
        default:
            break;
    }
}

void handle_command(Statement statement, database.Database!string db) {
    if (statement.metacommand != MetaCommandResult.META_COMMAND_NOT_FOUND) {
        handle_metacommand(statement);
        return;
    }
    switch(statement.command) {
        case CommandResult.COMMAND_SET:
            db.set(statement.key, statement.value);
            "OK".writeln;
            break;
        case CommandResult.COMMAND_GET:
            auto result = db.get(statement.key);
            if (result.found) {
                result.value.writeln;
            }
            else {
                "(empty string)".writeln;
            }
            break;
        case CommandResult.COMMAND_DELETE:
            db.remove(statement.key).writeln;
            break;
        case CommandResult.COMMAND_KEYS:
            "not implemented".writeln;
            break;
        default:
            break;
    }
}

void main() {
    auto db = new database.Database!string;
    while (true) {
        print_prompt;
        auto input = stdin.readln.strip;
        if (input.isEmpty) {
            continue;
        }
        try {
            auto parseResult = input.parse;
            parseResult.handle_command(db);
        }
        catch (ParseException ex) {
            ex.msg.writeln;
        }
        catch (ExitException) {
            break;
        }
    }
}