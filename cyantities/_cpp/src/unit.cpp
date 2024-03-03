/*
 * SI Units.
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

#include <cyantities/unit.hpp>

#include <stdexcept>
#include <cmath>

namespace cyantities {


/*
 * UnitBuilder
 */
UnitBuilder::UnitBuilder() : dec_exp(0), conv(1.0)
{
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i)
        unit[i] = 0;
}

int UnitBuilder::add_base_unit_occurrence(base_unit_t base_unit, int8_t exponent)
{
    uint_fast8_t i = base_unit;
    if (i >= BASE_UNIT_COUNT)
        return 1;
    unit[i] += exponent;
    return 0;
}

void UnitBuilder::add_decadal_exponent(int16_t exp)
{
    dec_exp += exp;
}

void UnitBuilder::multiply_conversion_factor(double f)
{
    conv *= f;
}



/*
 * Unit:
 */
Unit::Unit() : dec_exp(0), conv(1.0)
{
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i)
        _base_units[i] = 0;
}


Unit::Unit(int16_t dec_exp, double conv) : dec_exp(dec_exp), conv(1.0)
{
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i)
        _base_units[i] = 0;
}

Unit::Unit(const UnitBuilder& builder)
    : dec_exp(builder.dec_exp), conv(builder.conv)
{
    /* Init the array: */
    _base_units = builder.unit;
}

Unit Unit::invert() const
{
    Unit res(-dec_exp, 1.0 / conv);
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i)
        res._base_units[i] = -_base_units[i];
    return res;
}


bool Unit::operator==(const Unit& other) const
{
    return (dec_exp == other.dec_exp) && (_base_units == other._base_units)
        && (conv == other.conv);
}


bool Unit::same_dimension(const Unit& other) const
{
    return _base_units == other._base_units;
}

bool Unit::dimensionless() const
{
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i)
        if (_base_units[i] != 0)
            return false;

    return true;
}

/*
 * Multiplication:
 */

Unit Unit::operator*(const Unit& other) const
{
    /* Setup the new unit: */
    Unit result;

    /* Insert this unit's base units: */
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i){
        result._base_units[i] += _base_units[i];
    }

    /* The other unit's base units: */
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i){
        result._base_units[i] += other._base_units[i];
    }

    /* Scale and convergence factor: */
    result.dec_exp = dec_exp + other.dec_exp;
    result.conv = conv * other.conv;

    return result;
}


Unit& Unit::operator*=(const Unit& other)
{
    /* The other unit's base units: */
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i){
        _base_units[i] += other._base_units[i];
    }

    /* Scale and convergence factor: */
    dec_exp += other.dec_exp;
    conv *= other.conv;

    return *this;
}



/*
 * Division:
 */

Unit Unit::operator/(const Unit& other) const
{
    /* Setup the new unit: */
    Unit result;

    /* Insert this unit's base units: */
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i){
        result._base_units[i] += _base_units[i];
    }

    /* The other unit's base units: */
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i){
        result._base_units[i] -= other._base_units[i];
    }

    /* Scale and convergence factor: */
    result.dec_exp = dec_exp - other.dec_exp;
    result.conv = conv / other.conv;


    return result;
}


Unit& Unit::operator/=(const Unit& other)
{
    /* The other unit's base units: */
    for (uint_fast8_t i=0; i<BASE_UNIT_COUNT; ++i){
        _base_units[i] -= other._base_units[i];
    }

    /* Scale and convergence factor: */
    dec_exp -= other.dec_exp;
    conv /= other.conv;

    return *this;
}

/*
 * Access the unit properties:
 */

int16_t Unit::decadal_exponent() const
{
    return dec_exp;
}


double Unit::conversion_factor() const
{
    return conv;
}


double Unit::total_scale() const
{
    return conv * std::pow(10.0, dec_exp);
}

const base_unit_array_t& Unit::base_units() const
{
    return _base_units;
}

}