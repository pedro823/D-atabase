enum MetaCommandResult {
    META_COMMAND_NOT_FOUND,
    META_COMMAND_EXIT
};

enum CommandResult {
    COMMAND_NOT_FOUND,
    COMMAND_SET,
    COMMAND_GET,
    COMMAND_DELETE,
    COMMAND_KEYS
};

static enum ParseState {
    ERROR_STATE,
    FINISH_STATE,

    COMMAND_STATE,
    GET_KEY_STATE,
    SET_KEY_STATE,
    SET_VALUE_STATE,

    DELETE_KEY_STATE
};

struct Statement {
    MetaCommandResult metacommand = MetaCommandResult.META_COMMAND_NOT_FOUND;
    CommandResult command = CommandResult.COMMAND_NOT_FOUND;
    string key = null;
    string value = null;
};

class ParseException : Exception {
    string line, argument;
    pure this(string msg, string argument, string line) {
        super(argument != null ? msg ~ " : " ~ argument : msg);
        this.line = line;
        this.argument = argument;
    }
}

static immutable string
    TOKEN_EXIT = ".exit",

    TOKEN_SET = "set",
    TOKEN_GET = "get",
    TOKEN_DELETE = "delete",
    TOKEN_KEYS = "keys",
    
    EXCEPTION_INVALID_STATE = "Invalid parse state",
    EXCEPTION_INVALID_ARG_AMOUNT = "Invalid argument amount",
    EXCEPTION_UNKNOWN_COMMAND = "Command not recognized";

@safe
pure MetaCommandResult findMetaCommand(string line) {
    import std.uni : toLower;
    switch (line.toLower) {
        case TOKEN_EXIT:
            return MetaCommandResult.META_COMMAND_EXIT;
        default:
            return MetaCommandResult.META_COMMAND_NOT_FOUND;
    }
}

@safe
pure CommandResult findCommand(string line) {
    import std.algorithm : splitter;
    import std.uni : toLower;
    switch (splitter(line).front.toLower) {
        case TOKEN_GET:
            return CommandResult.COMMAND_GET;
        case TOKEN_SET:
            return CommandResult.COMMAND_SET;
        case TOKEN_KEYS:
            return CommandResult.COMMAND_KEYS;
        default:
            return CommandResult.COMMAND_NOT_FOUND;
    }
}

@safe
pure ParseState parseCommand(string argument, ref Statement parseResult) {
    import std.uni : toLower;
    switch (argument.toLower) {
        case TOKEN_GET:
            parseResult.command = CommandResult.COMMAND_GET;
            return ParseState.GET_KEY_STATE;
        case TOKEN_SET:
            parseResult.command = CommandResult.COMMAND_SET;
            return ParseState.SET_KEY_STATE;
        case TOKEN_KEYS:
            parseResult.command = CommandResult.COMMAND_KEYS;
            return ParseState.FINISH_STATE;
        case TOKEN_DELETE:
            parseResult.command = CommandResult.COMMAND_DELETE;
            return ParseState.DELETE_KEY_STATE;
        default:
            parseResult.command = CommandResult.COMMAND_NOT_FOUND;
            return ParseState.ERROR_STATE;
    }
}

@safe
pure bool isEmpty(string s) nothrow {
    return s == null || s == "" || s.length == 0;
}

pure Statement parse(string line) {
    import std.algorithm : splitter;
    import std.stdio;

    Statement parseResult;
    if (line.isEmpty) {
        return parseResult;
    }
    if ((parseResult.metacommand = findMetaCommand(line))
        != MetaCommandResult.META_COMMAND_NOT_FOUND) {
        return parseResult;
    }
    ParseState state = ParseState.COMMAND_STATE;
    string msg = EXCEPTION_INVALID_ARG_AMOUNT;
    string errorArgument = null;
    foreach (argument; splitter(line)) {
        switch (state) {
            case ParseState.COMMAND_STATE:
                state = parseCommand(argument, parseResult);
                if (state == ParseState.ERROR_STATE) {
                    msg = EXCEPTION_UNKNOWN_COMMAND;
                    errorArgument = argument;
                }
                break;
            case ParseState.GET_KEY_STATE:
                parseResult.key = argument;
                state = ParseState.FINISH_STATE;
                break;
            case ParseState.SET_KEY_STATE:
                parseResult.key = argument;
                state = ParseState.SET_VALUE_STATE;
                break;
            case ParseState.DELETE_KEY_STATE:
                parseResult.key = argument;
                state = ParseState.FINISH_STATE;
                break;
            case ParseState.SET_VALUE_STATE:
                parseResult.value = argument;
                state = ParseState.FINISH_STATE;
                break;
            default:
                throw new ParseException(msg,
                                         errorArgument, line);
        }
    }
    if (state == ParseState.FINISH_STATE) {
        return parseResult;
    }
    throw new ParseException(state == ParseState.ERROR_STATE 
                                ? msg 
                                : EXCEPTION_INVALID_ARG_AMOUNT,
                             errorArgument, line);
}

unittest {
    import std.stdio;

    assert(findMetaCommand(".exit") == MetaCommandResult.META_COMMAND_EXIT);
    assert(findMetaCommand("") == MetaCommandResult.META_COMMAND_NOT_FOUND);
    assert(findCommand(".exit") == CommandResult.COMMAND_NOT_FOUND);
    assert(findCommand("GET a") == CommandResult.COMMAND_GET);
    assert(isEmpty(""));
    assert(!isEmpty(" "));
    assert(isEmpty(null));
    // TODO make parser tests

    "[DEBUG] Parser tests passed".writeln;
}
