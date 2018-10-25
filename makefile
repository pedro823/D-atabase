.PHONY: clean
UNITTEST:=""

all: server.o parser.o database.o
	dmd $^
	./server

unittest: server.o parser.o database.o
	dmd $^ -unittest
	./server

%.o: %.d
	dmd $^ -c -unittest

clean:
	rm -f *.o server
