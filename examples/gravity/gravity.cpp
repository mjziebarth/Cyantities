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

#include <gravity.hpp>
#include <cyantities/boost.hpp>

#include <ranges>

#include <boost/units/quantity.hpp>
#include <boost/units/systems/si/mass.hpp>
#include <boost/units/systems/si/acceleration.hpp>
#include <boost/units/systems/si/force.hpp>

namespace bu = boost::units;


typedef bu::quantity<bu::si::mass, double> Mass;
typedef bu::quantity<bu::si::acceleration, double> Acceleration;
typedef bu::quantity<bu::si::force, double> Force;


void compute_gravitational_force_rac(
        const cyantities::QuantityWrapper& m,
        const cyantities::QuantityWrapper& g_qw,
        cyantities::QuantityWrapper& F
)
{
    /*
     * Sanity:
     */
    if (g_qw.size() != 1)
        throw std::runtime_error("'g' needs to be size-one.");
    if (m.size() != F.size())
        throw std::runtime_error("Incompatible size between 'm' and 'F'.");
    if (m.size() == 0)
        return;

    /*
     * A single acceleration value:
     */
    Acceleration g = g_qw.get<Acceleration>();

    /*
     * Now use the range adaptor closure:
     */
    std::ranges::copy(
         m.const_iter<Mass>()
         | std::ranges::views::transform(
                [g](const Mass& mi) -> Force
                {
                    return mi * g;
                }
            ),
        F.iter<Force>().begin()
    );

}


void compute_gravitational_force_iter(
        const cyantities::QuantityWrapper& m,
        const cyantities::QuantityWrapper& g_qw,
        cyantities::QuantityWrapper& F
)
{
    /*
     * Sanity:
     */
    if (g_qw.size() != 1)
        throw std::runtime_error("'g' needs to be size-one.");
    if (m.size() != F.size())
        throw std::runtime_error("Incompatible size between 'm' and 'F'.");
    if (m.size() == 0)
        return;

    /*
     * A single acceleration value:
     */
    Acceleration g = g_qw.get<Acceleration>();

    /*
     * Now use the range iterators:
     */
    auto out = F.iter<Force>().begin();
    auto generator = m.const_iter<Mass>();
    for (auto in = generator.begin(); in != generator.end(); ++in){
        Mass mi = *in;
        *out = mi * g;
        ++out;
    }
}


void compute_gravitational_force_index(
        const cyantities::QuantityWrapper& m,
        const cyantities::QuantityWrapper& g_qw,
        cyantities::QuantityWrapper& F
)
{
    /*
     * Sanity:
     */
    if (g_qw.size() != 1)
        throw std::runtime_error("'g' needs to be size-one.");
    if (m.size() != F.size())
        throw std::runtime_error("Incompatible size between 'm' and 'F'.");
    if (m.size() == 0)
        return;

    /*
     * A single acceleration value:
     */
    Acceleration g = g_qw.get<Acceleration>();

    /*
     * Now use the indices:
     */
    for (size_t i=0; i<m.size(); ++i){
        F.set_element(i, m.get<Mass>(i) * g);
    }
}