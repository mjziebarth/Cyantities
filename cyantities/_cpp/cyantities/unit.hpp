/*
 * Units.
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

#ifndef CYANTITIES_UNIT_HPP
#define CYANTITIES_UNIT_HPP

#include <vector>
#include <array>
#include <cstdint>

namespace cyantities {


/*
 * This defines the base units:
 */
typedef uint8_t base_unit_index_t;

enum base_unit_t : base_unit_index_t
{
    SI_METER = 0,
    SI_KILOGRAM = 1,
    SI_SECOND = 2,
    SI_AMPERE = 3,
    SI_KELVIN = 4,
    SI_MOLE = 5,
    SI_CANDELA = 6,
    OTHER_RADIANS = 7,
    OTHER_STERADIAN = 8
};
constexpr base_unit_index_t BASE_UNIT_COUNT = 9;


typedef std::array<int8_t,BASE_UNIT_COUNT> base_unit_array_t;


class Unit;

/*
 * UnitBuilder
 * ===========
 *
 * This class can be used to iteratively add base unit exponents to
 * a unit.
 */

struct UnitBuilder
{
    friend Unit;
public:
    UnitBuilder();

    int add_base_unit_occurrence(base_unit_t unit, int8_t exponent);
    void add_decadal_exponent(int16_t exp);
    void multiply_conversion_factor(double f);

private:
    int16_t dec_exp;
    double conv;
    base_unit_array_t unit;
};


/*
 * Unit
 * ====
 *
 * The main workhorse. A representation of a unit in the SI
 * system.
 *
 */

class Unit
{
public:
    Unit();
    Unit(int16_t dec_exp, double conv = 1.0);
    Unit(const UnitBuilder& builder);

    bool same_dimension(const Unit& other) const;

    bool dimensionless() const;

    bool operator==(const Unit& other) const;

    Unit  operator*(const Unit& other) const;
    Unit& operator*=(const Unit& other);

    Unit  operator/(const Unit& other) const;
    Unit& operator/=(const Unit& other);

    Unit invert() const;

    int16_t decadal_exponent() const;
    double conversion_factor() const;
    double total_scale() const;

    const base_unit_array_t& base_units() const;

private:
    int16_t dec_exp;
    base_unit_array_t _base_units;
    double conv;
};

}

#endif