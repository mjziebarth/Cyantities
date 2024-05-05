# Example 2: Gravitational force for bodies of different mass on Earth
This example focuses how to iterate buffers from the Cython world in C++,
all while keeping accurate track of the quantities' units.

## Build
This example is a simple, self-contained script ([run.py](run.py)). For this
reason, the C++ code is built and copied to this current directory, allowing
the execution of [run.py](run.py) as a one-shot simulation.

To build the code, simply run
```bash
python build.py
```
in this directory (with prerequisites numpy, cyantities & meson installed).


## Execute
To run the simulation after building,
```
python run.py
```
This simple codes computes the gravitational force acting on bodies of different
mass with a gravitational acceleration of 9.81 m s⁻².


## Layout
The purpose of this example is to demonstrate how to interface array-Quantites
from C++ numerics code using various methods: index-based access, iterators,
and range adaptor closures.

There are three source files for the binary extension: `gravity.pyx`,
`gravity.hpp`, and `gravity.cpp`. These reflect the typical minimum of source
files (more C++ sources would probably exist). The `meson.build` file
illustrates how these sources can be compiled into a Python extension.

The `build.py` script is a simple build script that uses Meson to compile
the `gravity` extension, and subsequently copies the built extension to
this root folder. Since this example aims to mimic a specialized scientific
simulation, that is typically executed for one purpose only, the whole
layout is kept simple and based on everything being available in this
root directory and controlled by the `run.py` control script.

### Cyantities includes
The
[subprojects/cyantities/meson.build](subprojects/cyantities/meson.build)
blueprint Meson build file takes care of the discovery of the Cyantities
headers and provides a Meson requirement. It can simply be copied to
Meson-based projects to include and link to Cyantities.


## Benchmark
The gravity example lends itself to a benchmark of the computational overhead
that Cyantities causes when wrapping the pure number crunching. Its numerics
consist of a single multiplication---as plain as it gets---so that runtime goes
as close to iteration overhead as possible.

The `benchmark.py` script uses the `gravity` extension to benchmark different
methods to perform the multiplication of a large array (5e8 elements) with a
single number. The methods tested are

1. Pure NumPy array multiplication (baseline)
2. Multiplication of an array-valued Quantity with a scalar Quantity
3. C++: piping of range adaptor closures (RAC; the `|` operator syntax)
4. C++: explicit use of iterators
5. C++: index-based iteration

The relevant C++ code for the RAC (3.) from `gravity.cpp` is
```cpp
std::ranges::copy(
        m.const_iter<Mass>()
        | std::ranges::views::transform(
            [g](const Mass& mi) -> Force
            {
                return mi * g;
            }
        ),
    F.iter<Force>().begin()
);
```
The explicit use of iterators is written
```cpp
auto out = F.iter<Force>().begin();
auto generator = m.const_iter<Mass>();
for (auto in = generator.begin(); in != generator.end(); ++in){
    Mass mi = *in;
    *out = mi * g;
    ++out;
}
```
Finally, the index-based version is written
```cpp
for (size_t i=0; i<m.size(); ++i){
    F.set_element(i, m.get<Mass>(i) * g);
}
```

On a system with AMD Ryzen 5 3600 6-Core Processor with 64GB RAM the following
results were obtained on 2024-05-05:
```
Pure numpy:      0:00:00.550028
Quantities:      0:00:00.548521
C++ RAC (pipes): 0:00:01.594884
C++ iterators:   0:00:01.168716
C++ indexing:    0:00:24.155272
```
The difference between pure NumPy array multiplication and the multiplication
with additional Cyantities overhead is negligible. The explicit use of iterators
incurs about a factor of 2 overhead, and the use of pipes is roughly a factor 3.

The overhead of the explicit indexing is significant, a factor of 44. The
underlying reason is that this approach requires two dynamic translations of
the unit information from the `cyantities::Quantity` instance to a
`boost::units::quantity` variable per iteration. The iterator and piping
approach can reduce this to a single call and store the result in the iterator
objects for the remaining iterations.

The results are probably not representative for use cases where unit parsing or
object generation are dominating the runtime cost (e.g. tight loops that
need to parse or generate units or quantities, possibly in Python). In many
actual use cases with high execution cost due to large data arrays, this
benchmark should give a good guideline.
What is more, typical use cases that mandate a switch to C++ rather than using
`Quantity` multiplications include costly numerics. Then, the overhead of any
of the iteration methods may be negligible.