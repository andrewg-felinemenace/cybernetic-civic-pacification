cybernetic-civic-pacification
=============================

Docker image of Fedora + KLEE + AFL + Radamsa + other fuzzing tools

Please note the Dockerfile is a prime counter example for secure, reproducable Dockerfile builds. The only thing missing is curl -s http://some
thing | bash

Included Tools
--------------

[KLEE][1] is a tool to perform symbolic execution of inputs for a program.

[AFL][2] is a tool that instruments source code at compile time to improve fuzzer code coverage.

[Radamsa][3] is a tool to fuzz inputs and generate output data for feeding into the program, and is designed for easy scripting (ie, no wizz-ba
ng features like running the program and doing crash analysis.

[zzuf][4] is a transparent application input fuzzer which intercepts file and network operations.

Ideally, the above would be an installable RPM, perhaps done via [copr.fedoraproject.org][5]

What's with the name?
---------------------

[Doctor Who Universe reference][6], chosen due to the "robo-fuzz" reference.

[1]: http://klee.github.io/klee/
[2]: https://code.google.com/p/american-fuzzy-lop/
[3]: https://code.google.com/p/ouspg/wiki/Radamsa
[4]: http://caca.zoy.org/wiki/zzuf
[5]: http://copr.fedoraproject.org
[6]: http://tardis.wikia.com/wiki/CCPC

