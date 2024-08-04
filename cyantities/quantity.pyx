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
from .unit cimport CppUnit, Unit, parse_unit, generate_from_cpp, format_unit
from .quantity cimport Quantity
from libc.math cimport log10
from libc.stdint cimport int16_t


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
                False, dummy_double[0], q1._val_ndarray, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], float(q0._val) * q1._val_ndarray, unit
            )

    elif q1._is_scalar:
        if q1._val == 1.0:
            # Shortcut: Do not copy.
            res._cyinit(
                False, dummy_double[0], q0._val_ndarray, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], float(q1._val) * q0._val_ndarray, unit
            )

    else:
        res._cyinit(
            False, dummy_double[0], q0._val_ndarray * q1._val_ndarray, unit
        )

    return res


cdef Quantity _divide_quantities(Quantity q0, Quantity q1):
    """
    Multiply two quantities.
    """
    cdef Quantity res = Quantity.__new__(Quantity)
    cdef CppUnit unit = q0._unit / q1._unit

    if q0._is_scalar and q1._is_scalar:
        res._cyinit(True, q0._val / q1._val, None, unit)

    elif q0._is_scalar:
        res._cyinit(
            False, dummy_double[0], float(q0._val) / q1._val_ndarray, unit
        )

    elif q1._is_scalar:
        if q1._val == 1.0:
            # Shortcut: Do not copy.
            res._cyinit(
                False, dummy_double[0], q0._val_ndarray, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], q0._val_ndarray / float(q1._val), unit
            )

    else:
        res._cyinit(
            False, dummy_double[0], q0._val_ndarray / q1._val_ndarray, unit
        )

    return res


cdef Quantity _add_quantities_equal_scale(Quantity q0, double s0, Quantity q1,
                                          double s1, CppUnit unit):
    """
    Adds two quantities of equal scale.
    """
    cdef Quantity res = Quantity.__new__(Quantity)
    s0 *= (q0._unit / unit).total_scale()
    s1 *= (q1._unit / unit).total_scale()

    if q0._is_scalar and q1._is_scalar:
        res._cyinit(True, s0 * q0._val + s1 * q1._val, None, unit)

    elif q0._is_scalar:
        if s1 == 1.0:
            res._cyinit(
                False, dummy_double[0],
                float(s0 * q0._val) + q1._val_ndarray, unit
            )
        elif s1 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                float(s0 * q0._val) - q1._val_ndarray, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0],
                float(s0 * q0._val) + s1 * q1._val_ndarray, unit
            )

    elif q1._is_scalar:
        if s0 == 1.0:
            res._cyinit(
                False, dummy_double[0],
                float(s1 * q1._val) + q0._val_ndarray, unit
            )
        elif s0 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                float(s1 * q1._val) - q0._val_ndarray, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0],
                float(s1 * q1._val) + s0 * q0._val_ndarray, unit
            )

    else:
        if s0 == 1.0 and s1 == 1.0:
            res._cyinit(
                False, dummy_double[0], q0._val_ndarray + q1._val_ndarray, unit
            )
        elif s0 == 1.0 and s1 == -1.0:
            res._cyinit(
                False, dummy_double[0], q0._val_ndarray - q1._val_ndarray, unit
            )
        elif s0 == 1.0:
            res._cyinit(
                False, dummy_double[0],
                q0._val_ndarray + s1 * q1._val_ndarray, unit
            )
        elif s0 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                s1 * q1._val_ndarray - q0._val_ndarray, unit
            )
        elif s1 == 1.0:
            res._cyinit(
                False, dummy_double[0],
                s0 * q0._val_ndarray + q1._val_ndarray, unit
            )
        elif s1 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                s0 * q0._val_ndarray - q1._val_ndarray, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0],
                s0 * q0._val_ndarray + s1 * q1._val_ndarray, unit
            )

    return res


cdef Quantity _add_quantities(Quantity q0, Quantity q1):
    """
    Add two quantities.
    """
    if q0._unit == q1._unit:
        return _add_quantities_equal_scale(q0, 1.0, q1, 1.0, q0._unit)

    # Otherwise need to decide which unit to add in:
    cdef CppUnit scale = q0._unit / q1._unit
    if not scale.dimensionless():
        raise RuntimeError("Cannot add quantities of different dimension.")

    # Decide which unit to add in:
    cdef int16_t dec_exp = scale.decadal_exponent()
    cdef double total_exp = dec_exp + log10(scale.conversion_factor())
    if total_exp <= 0:
        # Use scale of q1.
        return _add_quantities_equal_scale(q0, 1.0, q1, 1.0, q1._unit)
    else:
        # Use scale of q0.
        return _add_quantities_equal_scale(q0, 1.0, q1, 1.0, q0._unit)


cdef Quantity _subtract_quantities(Quantity q0, Quantity q1):
    """
    Add two quantities.
    """
    if q0._unit == q1._unit:
        return _add_quantities_equal_scale(q0, 1.0, q1, -1.0, q0._unit)

    # Otherwise need to decide which unit to add in:
    cdef CppUnit scale = q0._unit / q1._unit
    if not scale.dimensionless():
        raise RuntimeError("Cannot add quantities of different dimension.")

    # Decide which unit to add in:
    cdef int16_t dec_exp = scale.decadal_exponent()
    cdef double total_exp = dec_exp + log10(scale.conversion_factor())
    if total_exp <= 0:
        # Use scale of q1.
        return _add_quantities_equal_scale(q0, 1.0, q1, -1.0, q1._unit)
    else:
        # Use scale of q0.
        return _add_quantities_equal_scale(q0, 1.0, q1, -1.0, q0._unit)




cdef class Quantity:
    """
    A physical quantity: a single or array of real numbers with an associated
    physical unit.
    """
    __dict__: dict

    def __init__(self, value, unit, bool copy=True):
        #
        # First determine the values (scalar / ndarray)
        # and setup all corresponding members for a call
        # to _cyinit
        #
        cdef double d_value
        cdef bool is_scalar
        cdef object val_object
        if isinstance(value, float) or isinstance(value, int):
            is_scalar = True
            d_value = value
            val_object = None
        elif isinstance(value, np.ndarray):
            is_scalar = False
            d_value = dummy_double[0]
            if copy:
                val_object = value.copy()
                val_object.flags['WRITEABLE'] = False
            else:
                val_object = value
        else:
            raise TypeError("'value' has to be either a float or a NumPy array.")

        #
        # Then the unit:
        #
        cdef Unit unit_Unit
        cdef CppUnit cpp_unit
        if isinstance(unit, Unit):
            unit_Unit = unit
            cpp_unit = unit_Unit._unit
        elif isinstance(unit, str):
            cpp_unit = parse_unit(unit)

        else:
            raise TypeError("'unit' has to be either a string or a Unit.")

        self._cyinit(is_scalar, d_value, val_object, cpp_unit)


    cdef _cyinit(self, bool is_scalar, double val, object val_object,
                 CppUnit unit):
        if self._initialized:
            raise RuntimeError("Trying to initialize a second time.")
        self._is_scalar = is_scalar
        self._val = val
        cdef ndarray[dtype=float64_t] val_array
        if isinstance(val_object, np.ndarray):
            val_array = val_object.astype(np.float64, copy=False)
            self._val_ndarray = val_array
            self._val_object = val_array
        else:
            self._val_object = None
        self._unit = unit

        # Add, if dimensionless, the __array__ routine:
        if unit.dimensionless():
            self.__array__ = self._array

        self._initialized = True


    def __float__(self):
        """
        Returns, if dimensionally possible, a scalar.
        """
        if not self._unit.dimensionless():
            raise RuntimeError("Attempting to convert a dimensional quantity "
                               "to dimensionless scalar.")
        if not self._is_scalar:
            raise RuntimeError("Attempting to convert a non-scalar quantity to "
                               "a scalar.")

        return float(self._val * self._unit.total_scale())


    def _array(self) -> np.ndarray:
        """
        Returns, if dimensionally possible, a scalar array.
        """
        # TODO: More arguments of the __array__ routine protocol of numpy!
        if not self._unit.dimensionless():
            raise RuntimeError("Attempting to get array of a dimensional quantity.")
        cdef object array
        cdef double scale = self._unit.total_scale()
        if self._is_scalar:
            return np.full(1, self._val * scale)

        if scale != 1.0:
            return self._val_object * float(scale)

        return self._val_object.view()


    def __repr__(self) -> str:
        """
        String representation.
        """
        cdef str rep = "Quantity("
        if self._is_scalar:
            rep += str(float(self._val))
        else:
            rep += self._val_ndarray.__repr__()
        rep += ", '"
        rep += format_unit(self._unit, 'coherent')
        rep += "')"

        return rep


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

        elif isinstance(other, float) or isinstance(other, int):
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


    def __rmul__(self, other):
        """
        Multiply this quantity with another quantity or float (from the
        right).
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

        elif isinstance(other, float) or isinstance(other, int):
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

        return _multiply_quantities(other_quantity, self)


    def __truediv__(self, other):
        """
        Divide this quantity by another quantity or float.
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

        elif isinstance(other, float) or isinstance(other, int):
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

        return _divide_quantities(self, other_quantity)


    def __rtruediv__(self, other):
        """
        Divide this quantity by another quantity or float.
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

        elif isinstance(other, float) or isinstance(other, int):
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

        return _divide_quantities(other_quantity, self)


    def __add__(self, Quantity other):
        if not self._unit.same_dimension(other._unit):
            raise UnitError("Trying to add two quantities of incompatible "
                            "units.")

        return _add_quantities(self, other)


    def __sub__(self, Quantity other):
        if not self._unit.same_dimension(other._unit):
            raise UnitError("Trying to subtract two quantities of incompatible "
                            "units.")

        return _subtract_quantities(self, other)


    def __eq__(self, other):
        # First the case that the other is not a Quantity.
        # This results in nonzero only if this quantity is
        # dimensionless:
        if not isinstance(other, Quantity):
            if not self._unit.dimensionless():
                return False
            if self._is_scalar:
                return float(self._val) == other
            return self._val_ndarray == other

        # Now compare quantities:
        cdef Quantity oq = other
        if not self._unit.same_dimension(oq._unit):
            return False

        # Check whether there's a scale difference:
        cdef CppUnit div_unit = self._unit / oq._unit
        cdef double scale = div_unit.total_scale()
        if scale == 1.0:
            # No scale difference. Make the two possible
            # comparisons:
            if self._is_scalar and oq._is_scalar:
                return self._val == oq._val
            elif not self._is_scalar and not oq._is_scalar:
                return self._val_ndarray == oq._val_ndarray
            return False

        # Have scale difference. Make the two possible
        # comparisons:
        if self._is_scalar and oq._is_scalar:
            return self._val == scale*oq._val
        elif not self._is_scalar and not oq._is_scalar:
            return self._val_ndarray == scale * oq._val_ndarray
        return False


    def shape(self) -> int | tuple[int,...]:
        """
        Return this quantity's shape.
        """
        if self._is_scalar:
            return 1
        return self._val_object.shape


    def unit(self) -> Unit:
        return generate_from_cpp(self._unit)


    cdef QuantityWrapper wrapper(self) nogil:
        """
        Return a QuantityWrapper instance for talking to C++.
        """
        if self._is_scalar:
            return QuantityWrapper(self._val, self._unit)
        else:
            return QuantityWrapper(
                <double*>self._val_ndarray.data,
                self._val_ndarray.size,
                self._unit)


    @staticmethod
    cdef Quantity zeros_like(Quantity other, object unit):
        """
        Returns a zero-value quantity with shape like another,
        potentially with a different unit.
        """
        # First check the unit:
        cdef Unit src_unit
        cdef CppUnit dest_unit
        if unit is None:
            dest_unit = other._unit
        elif isinstance(unit, str):
            dest_unit = parse_unit(unit)
        elif isinstance(unit, Unit):
            src_unit = unit
            dest_unit = src_unit._unit
        else:
            raise TypeError("'unit' must be a Unit instance, unit-specifying "
                "string, or None."
            )

        # Now determine the shape of the target quantity:
        cdef Quantity res = Quantity.__new__(Quantity)
        if other._is_scalar:
            res._cyinit(True, 0.0, None, dest_unit)

        else:
            # Generate a NumPy array with shape equal to the other
            # quantity:
            res._cyinit(False, dummy_double[0],
                np.zeros_like(other._val_object),
                dest_unit
            )

        return res