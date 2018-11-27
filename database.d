class Database(T) {
    struct Result {
        bool found;
        T value = null;
    }


    T[string] db;

    @safe
    public Result get(string key) {
        Result result;
        T* found = (key in db);
        result.found = found !is null;
        if (!result.found) {
            return result;
        }
        result.value = *found;
        return result;
    }

    @safe
    public void set(string key, T value) 
    in (value != null) {
        db[key] = value;
    }

    @safe
    public bool remove(string key) {
        return db.remove(key);
    }
}

class IndexedDatabase(T) : Database!T {
    import std.stdio;

    ulong[string] indexes;
    File dbfile;

    public this(string fileName) {
        import std.file;
        if (fileName.exists) {
            buildDatabaseFromFile(fileName);
            return;
        }
        dbfile = File(fileName, "w+");
    }

    @trusted
    public override void set(string key, T value) 
    in (value != null)
    {
        dbfile.seek(0, SEEK_END);
        dbfile.writeln(key);
        indexes[key] = dbfile.tell;
        dbfile.writeln(value);
    }

    @trusted
    public override Result get(string key) {
        import std.string;
        Result result;
        ulong* location = (key in indexes);
        result.found = location !is null;
        if (!result.found) {
            return result;
        }
        dbfile.seek(*location, SEEK_SET);
        T value = cast(T) dbfile.readln.chop;
        result.value = value;
        return result;
    }

    @trusted
    public override bool remove(string key) {
        ulong* location = (key in indexes);
        if (location is null) {
            return false;
        }
        dbfile.seek(*location, SEEK_SET);
        dbfile.write('\0');
        return indexes.remove(key);
    }

    @trusted
    private void buildDatabaseFromFile(string fileName) {
        import std.stdio;
        import std.string;
        
        dbfile = File(fileName, "r+");
        bool keyPhase = true;
        string line, key;
        ulong offset = 0;
        while ((line = dbfile.readln()) !is null) {
            line = line.chop;
            if (keyPhase) {
                key = line;
            }
            else {
                if (T value = cast(T) line) {
                    "%s => %s".writefln(key, value);
                    indexes[key] = offset;
                }
                else {
                    // Warn, delete and continue
                    writefln("Key %s was deleted", key);
                    indexes.remove(key);
                    key = null;
                }
            }
            offset += line.length + 1;
            keyPhase = !keyPhase;
        }
    }
}

unittest {
    import std.stdio;
    import std.file;
    auto fileName = "test/testdb.db";
    scope(exit) fileName.remove;
    
    {
        auto idb = new IndexedDatabase!string(fileName);
        auto result = idb.get("test");
        assert(!result.found);

        idb.set("test", "testresult");
        result = idb.get("test");
        assert(result.found && result.value == "testresult");

        idb.set("test", "test2");
        result = idb.get("test");
        assert(result.found && result.value == "test2");
    }

    {
        auto idb = new IndexedDatabase!string(fileName);
        auto result = idb.get("test");
        assert(result.found && result.value == "test2");
        assert(idb.remove("test"));
    }

    {
        // auto idb = new IndexedDatabase!string(fileName);
        // idb.indexes.writeln;
        // auto result = idb.get("test");
        // result.value.writeln;
        // assert(!result.found);
    }

    "[DEBUG] IndexedDatabase passed".writeln;
}