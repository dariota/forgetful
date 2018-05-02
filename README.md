# Forgetful Project

This project can also be viewed on https://github.com/dariota/Forgetful

## Forgetful Plugin

The code for the Forgetful plug-in is in the plug-in/ directory. Once Frama-C has been installed (it is recommended that it be installed from opam), the plug-in may be added to your Frama-C installation by running the `make && make install` command in that directory.

Note that the `make install` step may require elevated privileges (i.e. `sudo make install` if Frama-C was installed globally).

To use the plug-in on the file `example.c`, run the command `frama-c -val example.c -then -Forgetful`. This will first run the value analysis plug-in, EVA, to produce information required by the Forgetful plug-in, and then run the Forgetful plug-in.

## Case Studies

The code for the case studies is in the src/ directory. The results used in the report are included for the specialised benchmarks, which are in the sub-folders naive and parallel.

To compile the specialised benchmarks, use the command `gcc -std=gnu11 -O<level> *.c` in the relevant benchmark's folder, where level is a number between 0 and 3 as relevant. They can then be run once with `./a.out`. This will run the benchmark once and output the comma-separated results to standard output.

To run the real world, cURL benchmarks, run `./replicate.sh` in the curl sub-folder. This will retrieve the source code from the cURL GitHub repository, and so requires an internet connection. It will then build the relevant executables, set up the testing server and run the benchmarks, writing results into the timings sub-folder.

## Demo

The demo files are in the demo folder. To view the demo, run `python -m http.server` in that folder, then go to http://localhost:8000/ in your browser.

## Poster and Class Presentations

The pdf files used for the presentations are in the presentations folder.

## Report

The LaTeX files for the report along with the few image assets used are all in the Report folder. The report is presented, built, as main.pdf in that folder, and can be built with the `pdflatex main.tex` command. However, successfully building the report may require the installation of packages.
