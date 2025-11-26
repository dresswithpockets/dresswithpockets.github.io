---
layout: post
title:  "The Poison of Unity Builds"
date:   2025-11-26 16:00:00 -0700
tags:   c gcc
---

# The Poison of the Unity Build

This article is on the technique of combining source files in C into a single translation unit, not about the Unity Game Engine - although that Unity is arguably far more poisonous lol.

## what does the C compiler do?

Given this program:

```c
// value.c
int value = 0;

int get_value() {
    return value;
}

void set_value(int new_value) {
    value = new_value;
}

// value.h
int get_value();
void set_value(int new_value);

// main.c
#include <stdio.h>
#include "value.h"

int main() {
    set_value(10);
    printf("%d\n", get_value());
    return 0;
}
```

We can compile it with a simple call to `gcc`:

```sh
gcc main.c value.c -o program
```

This simple call to gcc is hiding a lot of the compilation process. In reality, the compiler is doing quite a few steps involving IO:

- for each input file:
    - load it into memory and preprocess it
    - compile the preprocessed file into an object file
- loads and links all output object files with eachother, and their dependencies
- assembles the linker output into an executable binary, saving it to `program`

So in that single gcc call there are at least 3 reads and 3 writes to disk, and all processing is synchronous by default. That is, each step happens one at a time, despite there being multiple steps that could happen simultaneously to one another.

## the year is 2007

and I'm on a 32 bit computer running Windows XP, with a 5200RPM 128GB Hard Drive, a single 4 GB stick of DDR2, and a dual-core 2.3 Ghz CPU! Cutting edge, I know.

Imagine making my hard drive seek to each of those files, loading as much of it into RAM as I can to compile, only to write each output object file out to disk. For projects with many source files, that HDD is going to do work, and I'll be able to hear it the entire time. Maybe theres a way I could reduce the number of read/writes happening going into the linker step?

### the magic

What if we just compiled everything in a single combined translation unit? Thats called a "unity build", sometimes called a "jumbo build". The classic approach to a unity build is to have a dedicated source file specifically for UB builds, and just `#include` each of our source files we'd normally pass to `gcc` as input files.

```c
// unitybuild.c
#include "main.c"
#include "value.c"
```

Then build like:

```sh
gcc unitybuild.c -o program
```

The preprocessor still has to read every source file into memory, but it only has to write out a single object file. Then only one object file has to be read into for the linker to link.

So thats a lot less IO. That sounds pretty good - and, in the current year 2007 on my cutting edge hardware, it certainly was! In [OJ's OG rant on unity builds](https://web.archive.org/web/20120116121631/https://buffered.io/posts/the-magic-of-unity-builds/), he went from a 55 minute full build time to 6 minutes.

> **N.B.** gcc had some flags which, as far as I can tell, could perform a unity build for you. See footnote([1](#1--pipe-and--combine)).

## the year is 2025

and I'm on a 64 bit computer running Arch Linux, with a 2 TB Solid State Drive, two 32 GB sticks of DDR4, and a 12 core 4.8 Ghz CPU with 24 total threads. And these specs are from two CPU generations ago.

My SSD can perform random reads/writes at astronomical speeds compared to what my old 2007 hard drive was capable of. My RAM can perform 5+ times as many megatransfers as what DDR2 RAM was generally capable of. My CPU has a ton of fast threads I can make use of. If I've got all of this computing potential, what am I doing wasting it on a threadless compilation process?

### the poison

I want to build this [terminal snake game](https://github.com/dresswithpockets/terminal-snake) originally authored by [tbpaolini](https://github.com/). The catch is that `main_unity.c` is a unity build file, used to circumvent the need for a build tool:

```c
#include "helper_functions.c"
#include "game_loop.c"
#include "game_logic.c"
#include "key_mapper.c"
// ... a ton of other source files ...

int main(int argc, char **argv)
{
    // ...
}
```

We're compiling this on modern hardware though, what are we gaining using a unity build? Well, we can compile it in one simple command:

```sh
gcc main_unity.c -O3 -static -o snake.out
```

We have so much unused potential in our hardware though; I suspect we're paying a tax somewhere. Lets investigate:

```sh
➜  time gcc main_unity.c -O3 -o snake.out
gcc main_unity.c -O3 -o snake.out  0.28s user 0.02s system 99% cpu 0.302 total
```

Our build takes about 0.3 seconds. Thats already pretty fast; but, that time will scale with the size and complexity of the project. There are a few taxes I pay when I adopt a unity build as my primary build method:

- `gcc` isn't taking advantage of the 24 threads on my CPU.
- I have to rebuild the entire program whenever I make a change.
- If the sources exceed my available RAM, I will be paging to/from disk constantly.
- I have to consider the location that macros are declared. Macro definitions will leak into other source files, which could potentially change the code that is compiled based on the order the source files are included.

## the cure

If I've got gcc installed, chances are I've also got `make`. It just so happens that, with a pretty simple Makefile, `make` will handle parallelization _and_ incremental builds for us. Given this Makefile:

```makefile
# Makefile
CC = gcc
CFLAGS = -O3
LDFLAGS = -static
objects := $(patsubst %.c,obj/%.o,$(wildcard *.c))

snake: $(objects)
	+$(CC) $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS) -o $@

obj/%.o: %.c $(wildcard *.h)
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY:

clean:
	rm -f snake $(objects)
```

This tiny Makefile builds each intermediary object file for each source file in the project's source directory, then links them together. All you have to do is run `make` and it will build. We do have to change the `#include` directives in `main.c` so its no longer a unity build, though:

```diff
- #include "helper_functions.c"
- #include "game_loop.c"
- #include "game_logic.c"
- #include "key_mapper.c"
+ #include "helper_functions.h"
+ #include "game_loop.h"
```

Now lets time it:

```sh
➜  time make
gcc -O3 -c game_logic.c -o obj/game_logic.o
gcc -O3 -c game_loop.c -o obj/game_loop.o
gcc -O3 -c helper_functions.c -o obj/helper_functions.o
gcc -O3 -c key_mapper.c -o obj/key_mapper.o
gcc -O3 -c main.c -o obj/main.o
# ...
# ... many more source-to-object compilation jobs
# ...
gcc  obj/empty10.o obj/empty11.o obj/empty12.o obj/empty13.o obj/empty14.o obj/empty15.o obj/empty16.o obj/empty17.o obj/empty18.o obj/empty19.o obj/empty1.o obj/empty20.o obj/empty2.o obj/empty3.o obj/empty4.o obj/empty5.o obj/empty6.o obj/empty7.o obj/empty8.o obj/empty9.o obj/game_logic.o obj/game_loop.o obj/helper_functions.o obj/key_mapper.o obj/main.o   -o snake.out
make  0.43s user 0.15s system 98% cpu 0.581 total
```

Oh- thats almost double the amount of time... because `make` is running each job sequentially. We can ask it nicely to do as much as possible in parallel, though:

```sh
➜  time make -j24
...
make -j24  0.52s user 0.20s system 445% cpu 0.162 total
```

Way faster. As a little bonus, `make` will run commands in a rule's recipe as in a jobserver; `gcc`'s linker automatically detects when its ran in the jobserver and will perform Link Time Optimizations in parallel!

`make` also only builds targets whose dependencies have changed. If I edit only `key_mapper.c`, then it will only build `key_mapper.o` and link it with the other object files that have already been built:

```sh
➜  make
gcc -O3 -c key_mapper.c -o obj/key_mapper.o
gcc  obj/empty10.o obj/empty11.o obj/empty12.o obj/empty13.o obj/empty14.o obj/empty15.o obj/empty16.o obj/empty17.o obj/empty18.o obj/empty19.o obj/empty1.o obj/empty20.o obj/empty2.o obj/empty3.o obj/empty4.o obj/empty5.o obj/empty6.o obj/empty7.o obj/empty8.o obj/empty9.o obj/game_logic.o obj/game_loop.o obj/helper_functions.o obj/key_mapper.o obj/main.o   -o snake.out
```

What about **BIG** projects? Like Godot or Inkscape? These projects can take upwards of an hour to compile the first time around even with parallel processing. Some build tools - like [CMake](https://cmake.org/cmake/help/latest/prop_tgt/UNITY_BUILD.html) - actually support algorithmicly combining groups of translation units together for a hybrid unity build approach. The downside is you lose out on incremental builds. See footnote([2](#2-modern-unity-builds)).

Unity builds are probably faster when you don't need incremental builds and don't have many cores with which to compile in parallel. Devs on modern machines working on modern software likely won't benefit from unity builds for local development. CI/CD pipelines, however, tend to be resource-constrained. There are some good reasons to avoid incremental builds in your automated build pipeline; so, unity builds are probably easy to justify - especially if your pipeline is slow.

## footnotes

### 1. `-pipe` and `-combine`

In 2007, `gcc` (and potentially other compilers) had some flags which drastically reduced disk IO at the expense of greater RAM usage:

- `-pipe`: uses unix pipes instead of files when passing outputs to subsequent stages in the compiler
- `-combine`: combines all C sources into a single translation unit before compiling

That sounds an awful lot like a unity build though... Interestingly, I haven't been able to find any contemporary usages of `-pipe` or `-combine` in the context of a unity build. Even OJ fails to mention it in his article. `-combine` has been removed from modern versions of gcc, and `-pipe` isn't really that useful unless youre heavily IO constrained, so I don't have great insight into these flags, unfourtunately.

### 2. modern unity builds

Here are a few articles on using unity build to speed up non-incremental builds, particularly those that don't benefit from total parallelization:

- [Comparing C/C++ unity build with regular build on a large codebase](https://web.archive.org/web/20250312114353/https://hereket.com/posts/cpp-unity-compile-inkscape/)
- [Experimenting with CMake’s unity builds](https://web.archive.org/web/20250419125845/https://schneide.blog/2025/04/11/experimenting-with-cmakes-unity-builds/)

### 3. learn the tools

I've heard some developers recommending unity builds to new developers, because it allows them to skirt around some quirks of the language - such as symbol linkage, one-definition rule, headers, and build tools.

I'm editorializing a bit here: Not only are these concepts important to learn in C, they're also often trivial problems to solve. We're replacing trivial solutions to trivial problems with unity builds - which ultimately hinder the development experience in modern contexts.
