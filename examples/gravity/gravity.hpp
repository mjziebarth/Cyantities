/*
 * Computes the gravitational force on objects of different mass at Earth's
 * surface for a given gravitational acceleration. This is a dummy problem
 * to illustrate the use of iterators over the Cython/NumPy numeric buffers.
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

#ifndef CYANTITIES_EXAMPLES_GRAVITY_GRAVITY_HPP
#define CYANTITIES_EXAMPLES_GRAVITY_GRAVITY_HPP

#include <cyantities/unit.hpp>
#include <cyantities/quantitywrap.hpp>


/*
 * This version uses the range adapter closure (pipe syntax):
 */
void compute_gravitational_force_rac(
        const cyantities::QuantityWrapper& m,
        const cyantities::QuantityWrapper& g,
        cyantities::QuantityWrapper& F
);

/*
 * This version users iterators explicitly:
 */
void compute_gravitational_force_iter(
        const cyantities::QuantityWrapper& m,
        const cyantities::QuantityWrapper& g,
        cyantities::QuantityWrapper& F
);

/*
 * This version uses integer indices:
 */
void compute_gravitational_force_index(
        const cyantities::QuantityWrapper& m,
        const cyantities::QuantityWrapper& g,
        cyantities::QuantityWrapper& F
);


#endif