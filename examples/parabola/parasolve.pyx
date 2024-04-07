# Solves a parabola with friction.
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


cdef extern from "parasolve.hpp":
    void solve_ball_throw_with_friction(
        const QuantityWrapper& t0_qw,
        const QuantityWrapper& dt0_qw,
        const QuantityWrapper& x0_qw,
        const QuantityWrapper& y0_qw,
        const QuantityWrapper& vx0_qw,
        const QuantityWrapper& vy0_qw,
        const QuantityWrapper& cw_qw,
        const QuantityWrapper& r_qw,
        const QuantityWrapper& rho_qw,
        const QuantityWrapper& rho_air_qw,
        const QuantityWrapper& t_qw,
        QuantityWrapper& x_qw,
        QuantityWrapper& y_qw,
        double err_rel,
        double err_abs
    ) except+




def ball_throw_with_friction(
        Quantity t, Quantity x0, Quantity y0, Quantity vx0, Quantity vy0,
        Quantity r, Quantity cw, Quantity rho, Quantity rho_air,
        double err_rel = 1e-6, double err_abs = 1e-6
    ):
    """

    """
    # Make sure that all parameters are scalar:
    assert (x0._is_scalar and y0._is_scalar and vx0._is_scalar
            and vy0._is_scalar and r._is_scalar and cw._is_scalar
            and rho._is_scalar and rho_air._is_scalar)

    # Number of time steps:
    cdef size_t Nt
    if t._is_scalar:
        Nt = 1
    else:
        Nt = t._val_ndarray.size

    cdef CppUnit meter = parse_unit("m")
    cdef CppUnit seconds = parse_unit("s")
    cdef Quantity x = Quantity.__new__(Quantity)
    cdef cnp.ndarray xarr = np.empty(Nt)
    x._cyinit(False, np.NaN, xarr, meter)
    cdef Quantity y = Quantity.__new__(Quantity)
    cdef cnp.ndarray yarr = np.empty(Nt)
    y._cyinit(False, np.NaN, yarr, meter)

    cdef Quantity t0 = Quantity.__new__(Quantity)
    t0._cyinit(True, 0.0, None, seconds)
    cdef Quantity dt0 = Quantity.__new__(Quantity)
    dt0._cyinit(True, 1e-3, None, seconds)

    solve_ball_throw_with_friction(
        t0.wrapper(), dt0.wrapper(), x0.wrapper(), y0.wrapper(),
        vx0.wrapper(), vy0.wrapper(), cw.wrapper(), r.wrapper(),
        rho.wrapper(), rho_air.wrapper(), t.wrapper(),
        x.wrapper(), y.wrapper(), err_rel, err_abs
    )

    return x, y