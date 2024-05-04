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
from .unit cimport CppUnit, Unit
from libcpp cimport bool
from numpy cimport ndarray, float64_t


cdef extern from "cyantities/quantitywrap.hpp" namespace "cyantities" nogil:
    cppclass QuantityWrapper:
        QuantityWrapper()
        QuantityWrapper(double data, const CppUnit& unit)
        QuantityWrapper(double* data, size_t N, const CppUnit& unit)


cdef class Quantity:
    """
    A physical quantity: a single or array of real numbers with an associated
    physical unit.
    """
    cdef bool _initialized
    cdef bool _is_scalar
    cdef double _val
    # So as to hold a reference to the buffer, define the following:
    cdef ndarray _val_ndarray
    cdef object _val_object
    cdef CppUnit _unit
    cdef dict __dict__

    cdef _cyinit(self, bool is_scalar, double val, object val_object,
                 CppUnit unit)

    cdef QuantityWrapper wrapper(self) nogil

    @staticmethod
    cdef Quantity zeros_like(Quantity other, object unit)