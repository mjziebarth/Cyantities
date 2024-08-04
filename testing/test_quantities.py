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
import pytest
from cyantities import Unit, Quantity

def test_quantity():
    """
    Test whether we can setup a quantity and perform some operations.
    """
    q0 = Quantity(1.0, "m")
    q1 = Quantity(np.array([1.0, 2.0, 3.0]), 'm')
    q3 = Quantity(2.0, "kg")
    q0_1 = Quantity(1, "m")

    # Shapes:
    assert q0.shape() == q3.shape() == 1
    assert q1.shape() == (3,)

    # Equality of float <-> int as scalar:
    assert q0 == q0_1

    # Multiplication:
    q2 = q0 * q1
    assert q2.unit() == Unit("m^2")
    assert (q2 * Unit("m^-2")).unit() == Unit("1")
    assert np.all(q2 == Quantity(np.array([1.0, 2.0, 3.0]), "m^2"))

    # Division:
    q4 = q0 / q1
    assert q4.shape() == (3,)
    assert q4.unit() == Unit("1")
    assert (q4 * Unit("m")).unit() == Unit("m")
    assert np.all(q4 == Quantity(1.0 / np.array([1.0, 2.0, 3.0]), "1"))

    # Associativity of multiplication:
    assert np.all(q2 * 1 == 1 * q2)

    # Addition:
    with pytest.raises(RuntimeError):
        q0 + q3

    q5 = q0 + q1
    assert np.all(q5 == Quantity(np.array([1.0, 2.0, 3.0]) + 1.0, "m"))

    # Test an addition in which one of the units has a prefix that is too
    # small to cause any change to double precision:
    assert np.all(q1 * q1 + Quantity(1.0, "nm") * Quantity(1.0, "nm")
                  == Quantity(np.array([1.0, 4.0, 9.0]), "m^2"))

    # Subtraction:
    q6 = q1 - q0
    assert np.all(q6 == Quantity(np.array([1.0, 2.0, 3.0]) - 1.0, "m"))
    q7 = q0 - q1
    assert np.all(q7 == Quantity(1.0 - np.array([1.0, 2.0, 3.0]), "m"))
    with pytest.raises(RuntimeError):
        q0 - q3

    # Test conversion of dimensionless Quantities to NumPy arrays:
    q8 = q1 / Unit('m')
    assert np.all(np.array(q8) == np.array([1.0, 2.0, 3.0]))
    q9 = q1 / Unit('cm')
    assert np.all(np.array(q9) == np.array([100.0, 200.0, 300.0]))

    # Test conversion of dimensionless Quantities to floats:
    q10 = q0 / Unit('m')
    assert float(q10) == 1.0
    with pytest.raises(RuntimeError):
        float(q0)
    with pytest.raises(RuntimeError):
        float(q1 / Unit('m'))
    assert float(q0 / Unit('cm')) == 100.0