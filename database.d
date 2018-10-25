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
        result.value = db[key];
        return result;
    }

    @safe
    public void set(string key, T value) {
        db[key] = value;
    }

    @safe
    public bool remove(string key) {
        return db.remove(key);
    }
}