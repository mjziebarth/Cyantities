/*
 * Interface with boost::units using template metaprogramming.
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

#ifndef CYANTITIES_BOOST_HPP
#define CYANTITIES_BOOST_HPP

/*
 * Inludes of boost::unit:
 */
#include <boost/units/quantity.hpp>
#include <boost/units/systems/si/base.hpp>
#include <boost/units/systems/si/time.hpp>
#include <boost/units/systems/si/length.hpp>
#include <boost/units/systems/si/mass.hpp>
#include <boost/units/systems/si/current.hpp>
#include <boost/units/systems/si/temperature.hpp>
#include <boost/units/systems/si/amount.hpp>
#include <boost/units/systems/si/luminous_intensity.hpp>
#include <boost/units/systems/si/plane_angle.hpp>
#include <boost/units/systems/si/solid_angle.hpp>

#include <stdexcept>
#include <cyantities/unit.hpp>


namespace cyantities {

/*
 * Make some boost units namespaces available in shorthand form:
 */
namespace bu = boost::units;
namespace si = boost::units::si;


/*
 * Here we create a mapping between the boost::units base dimensions
 * and the SI base units of Cyantities
 *
 *   SI_SECOND = 0,
 *   SI_METER = 1,
 *   SI_KILOGRAM = 2,
 *   SI_AMPERE = 3,
 *   SI_KELVIN = 4,
 *   SI_MOLE = 5,
 *   SI_CANDELA = 6,
 *   OTHER_RADIANS = 7,
 *   OTHER_STERADIAN = 8
 */

template<typename Dim>
struct dimension_map
{
    template<typename T>
    constexpr static bool false_on_instantiation()
    {
        return false;
    }

    void resolve_error(){
        static_assert(false_on_instantiation<Dim>());
    }
};

template<>
struct dimension_map<bu::time_base_dimension>
{
    typedef si::time fundamental_unit;
    constexpr static base_unit_t index = SI_SECOND;
};

template<>
struct dimension_map<bu::length_base_dimension>
{
    typedef si::length fundamental_unit;
    constexpr static base_unit_t index = SI_METER;
};

template<>
struct dimension_map<bu::mass_base_dimension>
{
    typedef si::mass fundamental_unit;
    constexpr static base_unit_t index = SI_KILOGRAM;
};

template<>
struct dimension_map<bu::current_base_dimension>
{
    typedef si::current fundamental_unit;
    constexpr static base_unit_t index = SI_AMPERE;
};

template<>
struct dimension_map<bu::temperature_base_dimension>
{
    typedef si::temperature fundamental_unit;
    constexpr static base_unit_t index = SI_KELVIN;
};

template<>
struct dimension_map<bu::amount_base_dimension>
{
    typedef si::amount fundamental_unit;
    constexpr static base_unit_t index = SI_MOLE;
};

template<>
struct dimension_map<bu::luminous_intensity_base_dimension>
{
    typedef si::luminous_intensity fundamental_unit;
    constexpr static base_unit_t index = SI_CANDELA;
};

template<>
struct dimension_map<bu::plane_angle_base_dimension>
{
    typedef si::plane_angle fundamental_unit;
    constexpr static base_unit_t index = OTHER_RADIANS;
};

template<>
struct dimension_map<bu::solid_angle_base_dimension>
{
    typedef si::solid_angle fundamental_unit;
    constexpr static base_unit_t index = OTHER_STERADIAN;
};

/*
 * Struct to get the base unit of a composite unit:
 */
template<typename DimensionList>
struct dlist_to_base
{
    typedef typename DimensionList::item   Dimension;
    typedef typename Dimension::tag_type   BaseDimension;
    typedef typename Dimension::value_type ExponentType;
    constexpr static int                   Exponent = ExponentType::numerator();

    /* SI unit of the base dimension: */
    typedef typename dimension_map<BaseDimension>::fundamental_unit SIUnit;

    typedef typename bu::power_typeof_helper<
                        SIUnit,
                        bu::static_rational<Exponent>
                     >::type               BaseUnit;

    typedef typename bu::multiply_typeof_helper<
                BaseUnit,
                typename dlist_to_base<typename DimensionList::next>::unit
            >::type unit;
};

template<>
struct dlist_to_base<bu::dimensionless_type>
{
    typedef si::dimensionless unit;
};


template<typename DimensionList>
struct dlist_to_array_t
{
    /*
     * A function to get the cyantities::Unit base unit array
     * from a boost::unit dimension list.
     */
    constexpr static base_unit_array_t
    array()
    {
        /* Information about the unit: */
        typedef typename DimensionList::item   Dimension;
        typedef typename Dimension::tag_type   BaseDimension;
        typedef typename Dimension::value_type ExponentType;
        constexpr int                          Exponent = ExponentType::numerator();
        typedef typename DimensionList::next next_t;

        static_assert(ExponentType::denominator() == 1);

        if constexpr (std::is_same<next_t,
                                   bu::dimensionless_type>::value)
        {
            base_unit_array_t array;
            for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i)
                array[i] = 0;

            /* Update: */
            array[dimension_map<BaseDimension>::index] += Exponent;

            return array;
        } else {
            base_unit_array_t array = dlist_to_array_t<next_t>::array();

            /* Update: */
            array[dimension_map<BaseDimension>::index] += Exponent;

            return array;
        }
    }
};


template<typename Quantity>
constexpr static base_unit_array_t get_base_unit_array()
{
    typedef typename Quantity::unit_type Unit;
    typedef typename Unit::dimension_type Dimension;
    if constexpr (std::is_same<Dimension,bu::dimensionless_type>::value)
    {
        base_unit_array_t array;
        for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i)
            array[i] = 0;
        return array;
    } else {
        return dlist_to_array_t<Dimension>::array();
    }
}

/*
 * The main method to convert from a quantity in a given unit
 * (run time-set) to a compile-time boost::units quantity.
 */
template<typename Quantity>
Quantity get_converter(const Unit& from_unit)
{
    /* Get the dimension vector of the requested unit: */
    constexpr base_unit_array_t array = get_base_unit_array<Quantity>();

    /* Assert that the unit is compatible: */
    for (uint_fast8_t i=0; i<static_cast<uint_fast8_t>(BASE_UNIT_COUNT); ++i){
        if (array[i] != from_unit.base_units()[i]){
            /*
             * Failed. Compose an error message:
             */
            std::string msg("'from_unit' is incompatible with desired "
                            "quantity.\nfrom_unit: [");
            for (uint_fast8_t j=0; j<BASE_UNIT_COUNT; ++j){
                msg += std::to_string((int)array[j]);
                msg += ", ";
            }
            msg += "]\ndesired:   [";
            for (uint_fast8_t j=0; j<BASE_UNIT_COUNT; ++j){
                msg += std::to_string((int)from_unit.base_units()[j]);
                msg += ", ";
            }
            msg += "]\nat index ";
            msg += std::to_string((int)i);
            msg += "/";
            msg += std::to_string((int)BASE_UNIT_COUNT);
            msg += ": ";
            msg += std::to_string((int)array[i]);
            msg += " vs. ";
            msg += std::to_string((int)from_unit.base_units()[i]);

            throw std::runtime_error(msg);
        }
    }

    /* Get the base unit: */
    typedef typename Quantity::unit_type QUnit;
    typedef typename QUnit::dimension_type Dimension;
    typedef typename dlist_to_base<Dimension>::unit BaseUnit;

    const BaseUnit base_unit;
    const QUnit out_unit;
    double scale = bu::conversion_factor(base_unit, out_unit);

    /* Now take into consideration the scale that has been provided
     * by 'from_unit': */
    scale *= from_unit.total_scale();


    return scale * out_unit;
}



}

#endif