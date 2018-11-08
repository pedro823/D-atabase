.PHONY: clean
UNITTEST:=""

all: server run

server: server.o parser.o database.o
	dmd $^

run:
	./server

unittest: server.o parser.o database.o
	dmd $^ -unittest
	./server

%.o: %.d
	dmd $^ -c -unittest

clean:
	rm -f *.o server

stresstest: stresstest.o
	dmd $^