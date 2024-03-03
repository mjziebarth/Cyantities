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
from .unit cimport CppUnit, Unit, parse_unit


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



    def __mul__(self, other):
        return NotImplemented
    
    def __div__(self, other):
        return NotImplemented
    
    def __add__(self, Quantity other):
        return NotImplemented
    
    def __sub__(self, Quantity other):
        return NotImplemented