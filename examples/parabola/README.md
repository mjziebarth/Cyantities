# Example 1: Throwing parabola with friction.
This example demonstrates how to use Cyantities to connect Python quantities
with a C++ numerics backend that uses Boost Units.

## Build
This example is a simple, self-contained script ([run.py](run.py)). For this
reason, the C++ code is built and copied to this current directory, allowing
the execution of [run.py](run.py) as a one-shot simulation.

To build the code, simply run
```bash
python build.py
```
in this directory (with prerequisites numpy, cyantities, meson, ? installed).


## Execute
To run the simulation after building,
```
python run.py
```
This simulates a ball comparable to a baseball being thrown at professional
speeds in a 45° angle with air friction, and writes the resulting trajectory
to a `result.pdf` file (requires matplotlib).


## Layout
The purpose of this example is to demonstrate how to build a C++ numerics code
interfaced by Cyantities.

**TODO** (important: the
[subprojects/cyantities/meson.build](subprojects/cyantities/meson.build)
blueprint Meson build file that can simply be copied to Meson-based projects
to include and link to Cyantities)