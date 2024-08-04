# Cyantities
Cython-powered quantities.


## Usage
### Python
Cyantities ships two Python classes: `Unit` and `Quantity`. The `Unit` class
represents a physical unit, that is, a reference vector in a basis of physical
dimensions. In Cyantities, everything is based upon the SI (internally all
units are represented as an array of integers, each of which represents the
powers of an SI basic unit).

The `Unit` class can be initialized by passing a string representation of the
unit:
```python
from cyantities import Unit

unit0 = Unit('km')
unit1 = Unit('m/(s^2)')
unit2 = Unit('kg m s^-2')
```
The `Quantity` class represents numbers that are associated with a unit: physical
quantities.
```python
from cyantities import Quantity
```
For convenience and efficiency, the numbers can be either a single
`float` (essentially leading to a `(float,Unit)` tuple) or a NumPy array. See,
for instance, the following code excerpt from the example of a ball throw with
air friction ([examples/parabola/run.py](examples/parabola/run.py#L34))
```python
t = Quantity(np.linspace(0.0, 6.0), 's')
x0 = Quantity(0.0, 'm')
y0 = Quantity(2.1, 'm')
v = Quantity(145.0, 'km h^-1')
```
Here, the first line creates an equidistantly spaced set of time points between
0 and 6 seconds. The second and third line set the initial position of the ball,
two scalars with unit metre, to above head height of an average human. The last
line sets the initial velocity to 145 kilometers per hour.

To convert quantities back to pure numbers, unit dimensions need to be canceled
out through multiplication or division. See, for instance, the following lines
of [examples/parabola/run.py](examples/parabola/run.py#L58) that plot the trajectory
of the ball thrown with firction:
```python
import matplotlib as plt

# ... more code here, resulting in the trajetories 'x' and 'y' ...

fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(np.array(x / Unit('m')), np.array(y / Unit('m')), marker='.')
```
The last line highlights an important feature of the `Quantity` class: if, and only
if, a `Quantity` instance is dimensionless, it can be converted to a NumPy array.
This conversion can be automatic via the NumPy `__array__` interface. This special
method is added dynamically to dimensionless `Quantity` instances, allowing automatic
conversions from the NumPy side like
```python
import numpy as np
z = np.exp(Quantity(np.arange(3), 'm') / Unit('cm'))
```
but preventing numeric operations on quantities with a physical dimension:
```python
z = np.exp(Quantity(np.arange(3), 'm')) # raises an exception
```
Besides multiplication and division with other quantities and units, `Quantity`
instances can be added to and subtracted from quantities of the same unit
dimension, taking into account potential scale differences in the physical units.

#### Unit String Representation
Two methods (_rules_) are available to specify units. Both methods accept a string
representation of the unit and parse that string assuming a certain formatting.
A description of the two rules follows.

##### Coherent SI Rule
The _coherent SI_-style string representation has to be of the form
`'u0 u1 u3^2 u4^-1 u5^-3'`. Here, units are demarked by spaces (multiplication
signs `*` can also be used). Integer unit powers, including negative, follow
the unit representation and are indicated by the caret `^`.

Note: Any order of the input units is acceptable.

##### Nominator-Denominator Rule
The _nominator-denominator rule_ string representation has to be of the form
`'u0*u1*u3^2/(u4*u5^3)'`, where `u0` is the first unit including prefix (e.g.
`km`), and so forth. Units are demarked by multiplication signs `*`, integer
unit powers follow the unit  representation and are indicated by the caret `^`.
All negative powers of units have to follow a single slash `/`, be enclosed in
parantheses, and be positive therein.

### C++ and Boost.Units
The main reason for developing Cyantities was to have a translation utility of
unit-associated quantities from the Python world to the Boost.Units library.
The canonical means to do so with Cyantities is through an intermediary Cython
step (Python → Cython → C++).

Users will create units and quantities using the `Unit` and `Quantities` units of
the Cyantities package. Importing the Cyantities Cython API, the `cyantities::Unit`
C++ class, which is backing both Python classes, is exposed. This C++ class can
then be transformed into a Boost.Units quantity, performing runtime checks of the
dimensional correctness of the data passed from the Python level. Once this is done,
the numerical data can similarly be transformed from the Python objects to the
Boost.Units-powered C++ library.

The interaction of Cyantities with Boost.Units is best explained through an
example. See the example of a ball throw with gravity and friction in
[examples/parabola](examples/parabola/) for a blueprint of how to use
Cyantities with Boost.Units, and the example of gravitational force on different
masses in [examples/gravity](examples/gravity/) for different methods to iterate
vector-valued quantities in C++.


## Python Known Units
The following basic units are currently implemented in Cyantities and can be used
to compose units based on the [coherent SI](#coherent-si-rule) or the [nominator-denominator](#nominator-denominator-rule) rule:

| Python string | Unit          | Comment            |
| ------------- | ------------- | ------------------ |
| `"1"`         | dimensionless | no prefix allowed  |
| `"m"`         | metre         |                    |
| `"kg"`        | kilogram      |                    |
| `"s"`         | second        |                    |
| `"A"`         | Ampère        |                    |
| `"K"`         | Kelvin        |                    |
| `"mol"`       | mole          |                    |
| `"cd"`        | candela       |                    |
| `"rad"`       | radian        | Follow Boost.Units |
| `"sr"`        | steradian     | Follow Boost.Units |

The following SI-derived units are similarly available:

| Python string | Unit          | Comment            |
| ------------- | ------------- | ------------------ |
| `"Pa"`        | Pascal        |                    |
| `"J"`         | Joule         |                    |
| `"Hz"`        | Hertz         |                    |
| `"N"`         | Newton        |                    |
| `"W"`         | Watt          |                    |
| `"C"`         | Coulomb       |                    |
| `"V"`         | Volt          |                    |
| `"F"`         | Farad         |                    |
| `"Ω"`         | Ohm           |                    |
| `"S"`         | Siemens       |                    |
| `"Wb"`        | Weber         |                    |
| `"T"`         | Tesla         |                    |
| `"H"`         | Henry         |                    |
| `"lm"`        | lumen         |                    |
| `"lx"`        | lux           |                    |
| `"Bq"`        | Becquerel     |                    |
| `"Gy"`        | Gray          |                    |
| `"Sv"`        | Sievert       |                    |
| `"kat"`       | katal         |                    |

Other units include:

| Python string | Unit          | Comment            |
| ------------- | ------------- | ------------------ |
| `"erg"`       | erg           | (CGS units)        |
| `"g"`         | gram          |                    |
| `"h"`         | hour          |                    |

The temperature scales °C and °F are not supported as Python strings since they
are not proportional to Kelvin and require an offset. Please define all your
temperatures in K.

## License
This software is licensed under the European Public License (EUPL) version 1.2 or later.

## Changelog
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### [0.2.1] - 2024-08-04
#### Changed
- Fix check in `Quantity` not considering integers as valid scalars.

### [0.2.0] - 2024-08-04
#### Added
- Add `shape` method for `Quantity`, which allows to query the (array-) shape
  of the underlying data.

### [0.1.0] - 2024-05-05
#### Added
- Add `zeros_like` generator function for `Quantity` (Cython only)
- Add the `iter()` and `const_iter()` templated methods to C++
  `QuantityWrapper` class, allowing for the use of range-based for loops and
  range adaptor closures (`|`-operator syntax) in compile-time provided units.
- Add the `gravity` example that showcases different methods to iterate
  vector-valued quantities in C++.
- Add benchmark for different iteration methods.

### [0.0.3] - 2024-04-24
#### Changed
- Fixed the installation requirements and source distribution manifest.
- Add version coherence test script.

### [0.0.2] - 2024-04-23
#### Changed
- First release