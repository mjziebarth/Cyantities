# Computes the gravitational force on objects of different mass at Earth's
# surface for a given gravitational acceleration. This is a dummy problem
# to illustrate the use of iterators over the Cython/NumPy numeric buffers.
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
cimport numpy as cnp
from cyantities.unit cimport parse_unit, CppUnit
from cyantities.quantity cimport Quantity, QuantityWrapper


cdef extern from "gravity.hpp":
    void compute_gravitational_force_rac(
            const QuantityWrapper& m,
            const QuantityWrapper& g,
            QuantityWrapper& F
    ) except+

    void compute_gravitational_force_iter(
            const QuantityWrapper& m,
            const QuantityWrapper& g,
            QuantityWrapper& F
    ) except+

    void compute_gravitational_force_index(
            const QuantityWrapper& m,
            const QuantityWrapper& g,
            QuantityWrapper& F
    ) except+




def gravitational_force(
        Quantity m, Quantity g = Quantity(9.81, 'm s^-2'),
        str method = 'rac'
    ):
    """

    Parameters
    ----------

    method : str, optional
       Which iteration method to use. One of 'rac', 'iter',
       or 'index'. Defaults to 'rac'.
    """
    # Make sure that the gravitational acceleration is scalar:
    assert g._is_scalar

    # Empty force vector:
    cdef Quantity F = Quantity.zeros_like(m, 'N')

    if method == 'rac':
        compute_gravitational_force_rac(
            m.wrapper(), g.wrapper(), F.wrapper()
        )
    elif method == 'iter':
        compute_gravitational_force_rac(
            m.wrapper(), g.wrapper(), F.wrapper()
        )
    elif method == 'index':
        compute_gravitational_force_index(
            m.wrapper(), g.wrapper(), F.wrapper()
        )
    else:
        raise ValueError("Method must be one of 'rac', 'iter', or 'index'.")

    return F