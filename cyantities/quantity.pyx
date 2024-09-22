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
from cython.cimports.cpython.ref cimport PyObject, PyTypeObject
from cpython.object cimport PyObject_TypeCheck
from numpy cimport ndarray, float64_t, PyArrayObject, npy_intp,\
    NPY_DOUBLE
from .errors import UnitError
from .unit cimport CppUnit, Unit, parse_unit, generate_from_cpp, format_unit
from .quantity cimport Quantity
from libc.math cimport log10
from libc.stdint cimport int16_t
from libcpp cimport bool

cdef extern from *:
    """
    #include <cstdlib>
    #include <numpy/ndarraytypes.h>

    bool is_single_stride(
        npy_intp* stride,
        npy_intp* shape,
        int ndim,
        npy_intp itemsize
    )
    {
        npy_intp expected_stride = itemsize;
        for (int i=0; i<ndim; ++i){
            int j = ndim - i - 1;
            auto x = std::div(stride[j], expected_stride);
            if ((x.quot != 1) || (x.rem != 0)){
                return false;
            }

            /* New expected stride: */
            expected_stride *= shape[j];
        }

        return true;
    }

    size_t ptr2int(const char* ptr){
        return (size_t)ptr;
    }
    """
    npy_intp* PyArray_SHAPE(PyArrayObject*)
    npy_intp* PyArray_STRIDES(PyArrayObject*)
    void* PyArray_DATA(PyArrayObject*)
    int PyArray_NDIM(PyArrayObject*)
    npy_intp PyArray_ITEMSIZE(PyArrayObject*)
    npy_intp PyArray_SIZE(PyArrayObject*)
    PyTypeObject PyArray_Type
    cppclass PyArray_Descr
    int PyArray_CastScalarToCtype(PyObject*, void*, PyArray_Descr*)
    PyArray_Descr* PyArray_DescrFromType(int typenum)


    size_t ptr2int(const char* ptr)
    bool is_single_stride(
        npy_intp* stride,
        npy_intp* shape,
        int ndim,
        npy_intp itemsize
    )


#
# Dummy buffer:
#
cdef double[1] dummy_double
dummy_double[0] = 1.938928939273982423e-78


#
# Double:
#
cdef PyArray_Descr* _DOUBLE_ARRAY_TYPE = PyArray_DescrFromType(NPY_DOUBLE)


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
        if q1._val == 1.0:
            # Shortcut: Do not copy.
            res._cyinit(
                False, dummy_double[0], q0._val_object, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], float(q1._val) * q0._val_object, unit
            )

    else:
        res._cyinit(
            False, dummy_double[0], q0._val_object * q1._val_object, unit
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
            False, dummy_double[0], float(q0._val) / q1._val_object, unit
        )

    elif q1._is_scalar:
        if q1._val == 1.0:
            # Shortcut: Do not copy.
            res._cyinit(
                False, dummy_double[0], q0._val_object, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], q0._val_object / float(q1._val), unit
            )

    else:
        res._cyinit(
            False, dummy_double[0], q0._val_object / q1._val_object, unit
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
                float(s0 * q0._val) + q1._val_object, unit
            )
        elif s1 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                float(s0 * q0._val) - q1._val_object, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0],
                float(s0 * q0._val) + s1 * q1._val_object, unit
            )

    elif q1._is_scalar:
        if s0 == 1.0:
            res._cyinit(
                False, dummy_double[0],
                float(s1 * q1._val) + q0._val_object, unit
            )
        elif s0 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                float(s1 * q1._val) - q0._val_object, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0],
                float(s1 * q1._val) + s0 * q0._val_object, unit
            )

    else:
        if s0 == 1.0 and s1 == 1.0:
            res._cyinit(
                False, dummy_double[0], q0._val_object + q1._val_object, unit
            )
        elif s0 == 1.0 and s1 == -1.0:
            res._cyinit(
                False, dummy_double[0], q0._val_object - q1._val_object, unit
            )
        elif s0 == 1.0:
            res._cyinit(
                False, dummy_double[0],
                q0._val_object + s1 * q1._val_object, unit
            )
        elif s0 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                s1 * q1._val_object - q0._val_object, unit
            )
        elif s1 == 1.0:
            res._cyinit(
                False, dummy_double[0],
                s0 * q0._val_object + q1._val_object, unit
            )
        elif s1 == -1.0:
            res._cyinit(
                False, dummy_double[0],
                s0 * q0._val_object - q1._val_object, unit
            )
        else:
            res._cyinit(
                False, dummy_double[0],
                s0 * q0._val_object + s1 * q1._val_object, unit
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


cdef Quantity _power_quantity(Quantity q0, int b):
    """
    Compute the power of a quantity.
    """
    cdef CppUnit unit = q0._unit.power(b)
    cdef Quantity res = Quantity.__new__(Quantity)
    if q0._is_scalar:
        res._cyinit(True, q0._val ** b, None, unit)

    else:
        res._cyinit(False, dummy_double[0], q0._val_object ** b, unit)

    return res


cdef class Quantity:
    """
    A physical quantity: a single or array of real numbers with an associated
    physical unit.
    """
    __dict__: dict

    __array_ufunc__ = None

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
        cdef double[::1] buffer
        cdef PyArrayObject* pao
        cdef npy_intp* shape
        cdef npy_intp* strides
        cdef npy_intp itemsize
        cdef int ndim
        cdef PyObject* val_array_ptr
        if isinstance(val_object, np.ndarray):
            # Ensure that the array is of double type and ensure that the
            # underlying buffer is non-strided.
            # This single Python call also ensures that non-ndarray types
            # can be handled.
            val_array = np.asarray(
                val_object, dtype=np.double, order='C'
            )
            val_array_ptr = <PyObject*>val_array

            # Obtain a PyArrayObject pointer and get all the relevant info:
            pao = <PyArrayObject*>val_array_ptr
            ndim = PyArray_NDIM(pao)
            shape = PyArray_SHAPE(pao)
            strides = PyArray_STRIDES(pao)
            itemsize = PyArray_ITEMSIZE(pao)

            # Sanity: Assert that all is single stride:
            if not is_single_stride(strides, shape, ndim, itemsize):
                raise RuntimeError(
                    "Could not get a non-strided version of the input "
                    "array."
                )

            # Now set the attributes.
            # We keep an explicit reference to the NDArray 'val_array' so as
            # to have automatic reference counting.
            self._val_object = val_array
            self._val_array_ptr = <double*>PyArray_DATA(pao)
            self._val_array_N = PyArray_SIZE(pao)
        else:
            self._val_object = None
            self._val_array_ptr = NULL
            self._val_array_N = 0
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


    def _array(self, dtype=None, copy=None) -> np.ndarray:
        """
        Returns, if dimensionally possible, a scalar array.
        """
        # TODO: More arguments of the __array__ routine protocol of numpy!
        if not self._unit.dimensionless():
            raise RuntimeError("Attempting to get array of a dimensional quantity.")
        cdef object array
        cdef double scale = self._unit.total_scale()
        if self._is_scalar:
            return np.full(1, self._val * scale, dtype=dtype)

        if scale != 1.0:
            if dtype is not None:
                return (self._val_object * float(scale)).astype(dtype)
            return self._val_object * float(scale)

        if copy:
            return self._val_object.copy()
        if dtype is not None and dtype != self._val_object.dtype:
            return self._val_object.astype(dtype)
        return self._val_object.view()


    def __repr__(self) -> str:
        """
        String representation.
        """
        cdef str rep = "Quantity("
        if self._is_scalar:
            rep += str(float(self._val))
        else:
            rep += self._val_object.__repr__()
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


    def __pow__(self, exponent):
        if not isinstance(exponent, int):
            raise TypeError("Quantities can be exponentiated only to integer "
                "powers."
            )
        return _power_quantity(self, exponent)


    def __neg__(self):
        """
        Unary negative.
        """
        # Mostly a copy, we just have to see which part of the value
        # (scalar or ndarray?) we have to negate:
        cdef Quantity res = Quantity.__new__(Quantity)
        if self._is_scalar:
            res._cyinit(
                True, -self._val, None, self._unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], -self._val_object, self._unit
            )

        return res


    def __abs__(self):
        """
        Unary absolute value.
        """
        # Mostly a copy, we just have to see which part of the value
        # (scalar or ndarray?) we have to negate:
        cdef Quantity res = Quantity.__new__(Quantity)
        if self._is_scalar:
            res._cyinit(
                True, abs(self._val), None, self._unit
            )
        else:
            res._cyinit(
                False, dummy_double[0], np.abs(self._val_object), self._unit
            )

        return res


    def __eq__(self, other):
        # First the case that the other is not a Quantity.
        # This results in nonzero only if this quantity is
        # dimensionless:
        if not isinstance(other, Quantity):
            if not self._unit.dimensionless():
                return False
            if self._is_scalar:
                return float(self._val) == other
            return self._val_object == other

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
                return self._val_object == oq._val_object
            return False

        # Have scale difference. Make the two possible
        # comparisons:
        if self._is_scalar and oq._is_scalar:
            return self._val == scale*oq._val
        elif not self._is_scalar and not oq._is_scalar:
            return self._val_object == scale * oq._val_object
        return False


    def __getitem__(self, index) -> Quantity:
        """
        Indexing of this quantity.
        """
        if self._is_scalar:
            raise IndexError("Cannot index a scalar Quantity.")

        # Here we use NumPy indexing to process all the indexing
        # pecularities and throw appropriate errors (which we then
        # only augment by some decoration indicating that it's a
        # Quantity error):
        cdef object val_object
        try:
            val_object = self._val_object[index]
        except IndexError as ie:
            raise IndexError("Quantity index error: " + ie.args[0])


        # Initialize the new Quantity:
        cdef Quantity q = Quantity.__new__(Quantity)
        cdef PyObject* val_object_ptr
        cdef double* data
        val_object_ptr = <PyObject*>val_object
        cdef bool is_array = PyObject_TypeCheck(
            val_object, &PyArray_Type
        )
        cdef double val
        cdef int success
        if not is_array:
            val = 0.0
            success = PyArray_CastScalarToCtype(
                val_object_ptr, &val, _DOUBLE_ARRAY_TYPE
            )
            if success != 0:
                raise RuntimeError(
                    "Could not cast index result scalar to double. This error "
                    "should not occur."
                )
            q._cyinit(True, val, None, self._unit)

        else:
            q._cyinit(False, dummy_double[0], val_object, self._unit)

        return q


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
            return QuantityWrapper(&self._val, 1, self._unit)
        else:
            return QuantityWrapper(
                self._val_array_ptr,
                self._val_array_N,
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