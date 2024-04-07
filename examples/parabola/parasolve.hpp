/*
 * Solves a parabola with friction.
 *
 * Author: Malte J. Ziebarth (mjz.science@fmvkb.de)
 *
 * Copyright (C) 2024 Malte J. Ziebarth
 *
 * Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
 * the European Commission - subsequent versions of the EUPL (the "Licence");
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence at:
 *
 * https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licence is distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licence for the specific language governing permissions and
 * limitations under the Licence.
 */

#ifndef CYANTITIES_EXAMPLES_PARABOLA_PARASOLVE_HPP
#define CYANTITIES_EXAMPLES_PARABOLA_PARASOLVE_HPP

#include <cyantities/unit.hpp>
#include <cyantities/quantitywrap.hpp>


void solve_ball_throw_with_friction(
        const cyantities::QuantityWrapper& t0_qw,
        const cyantities::QuantityWrapper& dt0_qw,
        const cyantities::QuantityWrapper& x0_qw,
        const cyantities::QuantityWrapper& y0_qw,
        const cyantities::QuantityWrapper& vx0_qw,
        const cyantities::QuantityWrapper& vy0_qw,
        const cyantities::QuantityWrapper& cw_qw,
        const cyantities::QuantityWrapper& r_qw,
        const cyantities::QuantityWrapper& rho_qw,
        const cyantities::QuantityWrapper& rho_air_qw,
        const cyantities::QuantityWrapper& t_qw,
        cyantities::QuantityWrapper& x_qw,
        cyantities::QuantityWrapper& y_qw,
        double err_rel,
        double err_abs
);


#endif