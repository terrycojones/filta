CFLAGS = -O

filta: filta.o filta.h
	cc $(CFLAGS) -o filta filta.o
