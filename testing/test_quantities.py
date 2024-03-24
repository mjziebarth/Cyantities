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


import numpy as np
from cyantities import Unit, Quantity

def test_quantity():
    """
    Test whether we can setup a quantity.
    """
    q0 = Quantity(1.0, "m")
    q1 = Quantity(np.array([1.0, 2.0, 3.0]), 'm')
    q3 = Quantity(2.0, "kg")

    # Multiplication:
    q2 = q0 * q1
    assert q2.unit() == Unit("m^2")
    assert (q2 * Unit("m^-2")).unit() == Unit("1")
    assert np.all(q2 == Quantity(np.array([1.0, 2.0, 3.0]), "m^2"))

    # Division:
    q4 = q0 / q1
    assert q4.unit() == Unit("1")
    assert (q4 * Unit("m")).unit() == Unit("m")
    print(q4 == Quantity(1.0 / np.array([1.0, 2.0, 3.0]), "1"))
    print(q4)
    print(Quantity(1.0 / np.array([1.0, 2.0, 3.0]), "1"))
    assert np.all(q4 == Quantity(1.0 / np.array([1.0, 2.0, 3.0]), "1"))

    # Associativity of multiplication:
    assert np.all(q2 * 1 == 1 * q2)