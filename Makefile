hellomake: hello.asm
	rgbasm -o hello.o hello.asm
	rgblink -o hello.gb hello.o
	rgbfix -v -p0 hello.gb
	rm hello.o
	bgb64 hello.gb