# Quantities with units.
#
# Author: Malte J. Ziebarth (mjz.science@fmvkb.de)
#
# Copyright (C) 2024 Malte J. Ziebarth
#
# Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
# the European Commission - subsequent versions of the EUPL (the "Licence");
# You may not use this work except in compliance with the Licence.
# You may obtain a copy of the Licence at:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the Licence is distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Licence for the specific language governing permissions and
# limitations under the Licence.


import numpy as np
from numpy cimport ndarray, float64_t
from .errors import UnitError
from .unit cimport CppUnit, Unit, parse_unit, generate_from_cpp
from .quantity cimport Quantity


#
# Dummy buffer:
#
cdef double[1] dummy_double
dummy_double[0] = 1.938928939273982423e-78


cdef Quantity _multiply_quantities(Quantity q0, Quantity q1):
    """
    Multiply two quantities.
    """
    cdef Quantity res = Quantity.__new__(Quantity)
    cdef CppUnit unit = q0._unit * q1._unit

    if q0._is_scalar and q1._is_scalar:
        res._cyinit(True, q0._val * q1._val, None, unit)

    elif q0._is_scalar:
        if q0._val == 1.0:
            # Shortcut: Do not copy.
            res._cyinit(
                False, dummy_double[0], q1._val_object, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], float(q0._val) * q1._val_object, unit
            )

    elif q1._is_scalar:
        res._cyinit(
            False, dummy_double[0], float(q1._val) * q0._val_object, unit
        )

    else:
        res._cyinit(
            False, dummy_double[0], q0._val_object * q1._val_object, unit
        )

    return res




cdef class Quantity:
    """
    A physical quantity: a single or array of real numbers with an associated
    physical unit.
    """

    def __init__(self, value, unit, bool copy=True):
        #
        # First assign the values:
        #
        if isinstance(value, float):
            self._is_scalar = True
            self._val = value
        elif isinstance(value, np.ndarray):
            self._is_scalar = False
            if copy:
                self._val_object = value.copy()
                self._val_object.flags['WRITEABLE'] = False
            else:
                self._val_object = value
        else:
            raise TypeError("'value' has to be either a float or a NumPy array.")

        #
        # Then the unit:
        #
        cdef Unit unit_Unit
        if isinstance(unit, Unit):
            unit_Unit = unit
            self._unit = unit_Unit._unit
        elif isinstance(unit, str):
            self._unit = parse_unit(unit)

        else:
            raise TypeError("'unit' has to be either a string or a Unit.")

        # Set initialized:
        self._initialized = True


    cdef _cyinit(self, bool is_scalar, double val, object val_object,
                 CppUnit unit):
        if self._initialized:
            raise RuntimeError("Trying to initialize a second time.")
        self._is_scalar = is_scalar
        self._val = val
        cdef ndarray[dtype=float64_t] val_array
        if isinstance(val_object, np.ndarray):
            val_array = val_object.astype(np.float64, copy=False)
            self._val_object = val_array
        self._unit = unit

        self._initialized = True


    def __mul__(self, other):
        """
        Multiply this quantity with another quantity or float.
        """
        # Classifying the other object:
        cdef Quantity other_quantity
        cdef Unit a_unit

        #
        # Initialize the quantity that we would like to multiply with:
        #
        if isinstance(other, np.ndarray):
            other_quantity = Quantity.__new__(Quantity)
            if other.size == 1:
                other_quantity._cyinit(True, other.flat[0], None, CppUnit())
            else:
                other_quantity._cyinit(False, dummy_double[0], other, CppUnit())

        elif isinstance(other, float):
            other_quantity = Quantity.__new__(Quantity)
            other_quantity._cyinit(True, other, None, CppUnit())

        elif isinstance(other, Quantity):
            other_quantity = other

        elif isinstance(other, Unit):
            a_unit = other
            other_quantity = Quantity.__new__(Quantity)
            other_quantity._cyinit(True, 1.0, None, a_unit._unit)
        else:
            return NotImplemented

        return _multiply_quantities(self, other_quantity)


    def __div__(self, other):
        return NotImplemented

    def __add__(self, Quantity other):
        if not self._unit.same_dimension(other._unit):
            raise UnitError("Trying to add two quantities of incompatible units.")
        return NotImplemented

    def __sub__(self, Quantity other):
        return NotImplemented