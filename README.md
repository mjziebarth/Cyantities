# Cyantities
Cython-powered quantities.


## Usage
### Python
Cyantities ships two Python classes: `Unit` and `Quantity`. The `Unit` class
represents a physical unit, that is, a reference vector in a basis of physical dimensions. In Cyantities, everything is based upon the SI (internally all
units are represented as an array of integers, each of which represents the
powers of an SI basic unit).

The `Unit` class can be initialized by passing a string representation of the
unit:
```python
from cyantities import Unit

unit0 = Unit('km')
unit1 = Unit('m/(s^2)')
```
The `Quantity` class represents numbers that are associated with a unit: physical
quantities. For convenience and efficiency, the numbers can be either a single
`float` (essentially leading to a `(float,Unit)` tuple) or a NumPy array.

**TODO**

#### Unit String Representation
The string representation has to be of the form `'u0*u1*u3^2/(u4*u5^3)'`, where
`u0` is the first unit including prefix (e.g. `km`), and so forth. Units are 
demarked by multiplication signs `*`, integer unit powers follow the unit 
representation and are indicated by the caret `^`. All negative powers of units
have to follow a single slash `/` and be enclosed in parantheses.

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

**TODO**


## Python Known Units
**TODO**




## License
This software is licensed under the European Public License (EUPL) version 1.2 or later.