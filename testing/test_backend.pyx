# Test quantity arithmetics.
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

from cyantities.unit cimport parse_unit, CppUnit
from cyantities.quantity cimport Quantity, QuantityWrapper, dummy_double

def test_cython_functionality():
    # Zero mass vector:
    cdef Quantity m = Quantity.zeros(100, 'kg')
    # Empty force vector:
    cdef Quantity F = Quantity.zeros_like(m, 'N')

    # Some internal state checks:
    assert m._is_scalar == F._is_scalar == False
    assert m._initialized == F._initialized == True
    assert m._val == F._val == dummy_double[0]
    assert m._val_array_N == F._val_array_N == 100
    assert np.all(m._val_object == 0.0)
    assert np.all(F._val_object == 0.0)