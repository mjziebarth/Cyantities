/*
 * A wrapper around the Cython Quantity class.
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

#ifndef CYANTITIES_QUANTITYWRAP_HPP
#define CYANTITIES_QUANTITYWRAP_HPP

#include <cyantities/unit.hpp>
#include <cyantities/boost.hpp>

#include <concepts>
#include <iterator>
#include <memory>

namespace cyantities {

class QuantityWrapper;


/*
 * Ensure that const and non-const QuantityIterator has the
 * ConstQuantityIteratorGenerator and QuantityIteratorGenerator (respectively)
 * as friend class.
 */
template<typename boost_quantity, typename T>
class QuantityIteratorGenerator;

template<typename boost_quantity, typename T>
class ConstQuantityIteratorGenerator;

template<typename boost_quantity, typename T, bool is_const=std::is_const_v<T>>
struct iterator_generator;

template<typename boost_quantity, typename T>
struct iterator_generator<boost_quantity, T, true>
{
    typedef ConstQuantityIteratorGenerator<
                boost_quantity,
                std::remove_const_t<T>
            > type;
};

template<typename boost_quantity, typename T>
struct iterator_generator<boost_quantity, T, false>
{
    typedef QuantityIteratorGenerator<
                boost_quantity,
                T
            > type;
};


/*
 * This class allows unit-aware setting of Quantity elements.
 */
template<typename boost_quantity, typename T>
class QuantityIterator;

template<typename boost_quantity, typename T>
struct quantity_setter
{
    friend QuantityIterator<boost_quantity, T>;

    /* Constructors: */
    quantity_setter(T* data, const boost_quantity& unit)
       : data(data), unit(unit)
    {}
    quantity_setter() : data(nullptr)
    {}
    ~quantity_setter() noexcept = default;
    quantity_setter(quantity_setter<boost_quantity,T>&&) = default;
    quantity_setter(const quantity_setter<boost_quantity,T>&) = default;

    /* Copy-assign: */
    quantity_setter<boost_quantity,T>&
    operator=(quantity_setter<boost_quantity,T>&&) = default;
    quantity_setter<boost_quantity,T>&
    operator=(const quantity_setter<boost_quantity,T>&) = default;

    constexpr operator boost_quantity() const
    {
        return *data * unit;
    }

    quantity_setter<boost_quantity,T>&
    operator=(const boost_quantity& q)
    {
        T val = q / unit;
        *data = val;
        return *this;
    }

//    // these might be implemented (and tested!)
//    // in future versions.
//    quantity_setter& operator+=(const boost_quantity& q)
//    {
//        T val = *data + q/unit;
//        *data = val;
//        return *this;
//    }
//
//    quantity_setter& operator-=(const boost_quantity& q)
//    {
//        T val = *data - q/unit;
//        *data = val;
//        return *this;
//    }

private:
    T* data;
    boost_quantity unit;
};

/*
 * Iterators over multidimensional quantities.
 * This class iterates all values (one or more) of the QuantityWrapper class
 * below. Dereferencing the iterator yields a Boost.Units quantity.
 */
template<typename boost_quantity, typename T>
class QuantityIterator
{
    typedef iterator_generator<boost_quantity, T>::type Generator;
    friend QuantityWrapper;
    friend Generator;
public:
    typedef quantity_setter<boost_quantity, T> setter_t;

    /* Iterator traits: */
    typedef std::ptrdiff_t difference_type;
    typedef setter_t value_type;
    typedef std::forward_iterator_tag iterator_category;
    typedef setter_t& reference;

    /* Con- and destructors: */
    QuantityIterator() : data(nullptr), begin(nullptr), end(nullptr),
       setter(std::make_unique<setter_t>())
    {}

    QuantityIterator(QuantityIterator<boost_quantity,T>&&) = default;

    QuantityIterator(const QuantityIterator<boost_quantity,T>& other)
       : data(other.data), begin(other.begin), end(other.end),
         setter((other.setter) ? std::make_unique<setter_t>(*other.setter)
                               : std::make_unique<setter_t>())
    {
    }

    ~QuantityIterator() noexcept(true)
    {
    }

    /* Assignment: */
    QuantityIterator<boost_quantity,T>&
    operator=(QuantityIterator<boost_quantity,T>&& other) = default;

    QuantityIterator<boost_quantity,T>&
    operator=(const QuantityIterator<boost_quantity,T>& other)
    {
        data = other.data;
        begin = other.begin;
        end = other.end;
        setter = std::make_unique<setter_t>(*other.setter);
    }


    QuantityIterator<boost_quantity,T>& operator++()
    {
        ++data;
        setter->data = data;
        return *this;
    }

    QuantityIterator<boost_quantity,T> operator++(int)
    {
        QuantityIterator res(*this);
        this->operator++();
        return res;
    }

    QuantityIterator<boost_quantity,T>& operator--()
    {
        --data;
        setter->data = data;
        return *this;
    }

    std::ptrdiff_t operator-(const QuantityIterator<boost_quantity,T>& other) const
    {
        return data - other.data;
    }

    template<typename integer>
    QuantityIterator<boost_quantity,T>& operator-(integer off)
    {
        data -= off;
        setter->data = data;
        return *this;
    }

    template<typename integer>
    QuantityIterator<boost_quantity,T>& operator+=(integer off)
    {
        data += off;
        setter->data = data;
        return *this;
    }

    quantity_setter<boost_quantity, T>& operator*()
    {
        if (data == nullptr)
            throw std::runtime_error("Trying to dereference nullptr");
        if (data < begin){
            throw std::runtime_error(
                "Trying to dereference QuantityIterator before begin."
            );
        }
        if (data >= end)
            throw std::runtime_error(
                "Trying to dereference QuantityIterator past end."
            );
        return *setter;
    }

    quantity_setter<boost_quantity, T>& operator*() const
    {
        if (data == nullptr)
            throw std::runtime_error("Trying to dereference nullptr");
        if (data < begin){
            throw std::runtime_error(
                "Trying to dereference QuantityIterator before begin."
            );
        }
        if (data >= end)
            throw std::runtime_error(
                "Trying to dereference QuantityIterator past end."
            );
        return *setter;
    }

    bool operator==(const QuantityIterator& other) const
    {
        return data == other.data && unit == other.unit;
    }

private:
    /* The 'data' member stores the pointer to the actual numeric data in a
     * container (e.g. with T=double, this may be a double buffer).
     * T may be const or non const (in the former case, this iterator
     * is not assignable). */
    T* data;
    const T* begin;
    const T* end;
    /*
     * This is the unit in which the numeric 'data' is given.
     */
    boost_quantity unit;
    /*
     * The following member is a hacky way to wrap the non-unit-aware
     * 'data' buffer by an std::input_iterator-compatible unit-aware
     * iterator.
     * The quantity_setter struct is the value type of this iterator.
     * It can be explicitly cast to a boost_quantity (which simply multiplies
     * the 'data'-value with the 'unit' member.), and it can be assigned
     * a boost_quantity instance (in which case the assignment operator takes
     * care of extracting the numerical value in the correct unit, and assigning
     * to 'data').
     * The reason why we use the unique_ptr here is the combination of the
     * following requirements:
     *    1) The iterator shall return a reference to a quantity_setter, so
     *       an instance of quantity_setter must exist somewhere and we cannot
     *       simply return a new instance.
     *    2) The returned reference must be independent of the const/non-const
     *       qualifyer of this iterator. Hence, we cannot simply provide a
     *       quantity_setter member in this iterator. The simples (possibly
     *       only?) way to solve this issue is to use a pointer.
     *    3) The setter, being just a temporary middle man between the raw
     *       numbers and the unit-aware design, should be unique to each
     *       iterator since it contains a pointer to the destination 'data'
     *       which is assigned whenever the iterator changes.
     *       If it were done by a shared_ptr, incrementing one iterator would
     *       also increment all derived iterators (and vice versa).
     *
     * A downside of this approach is that references to [*QuantityIterator]
     * are invalidated once the QuantityIterator and all copied instances go
     * out of scope.
     */
    std::unique_ptr<setter_t> setter;

    QuantityIterator(T* data, size_t N, boost_quantity unit
    )
       : data(data), begin(data), end(data+N), unit(unit),
         setter(
            std::make_unique<quantity_setter<boost_quantity, T>>(data, unit)
         )
    {
        if (this->data < this->begin)
            throw std::runtime_error("Invalid initialization!");
    }
};


/*
 * These two structs are used to solve the following issue: when
 * we use QuantityWrapper directly, it is not possible to use it
 * directly in a range-based for loop since begin() and end() are
 * templated function.
 * As a solution, these two structs produce thin wrappers around
 * the underlying pointers. All their template parameters are defined
 * at creation, so that their begin() and end() functions can be
 * used for automatic type deduction.
 * Setting the template parameters at creation works by setting
 * the correct template parameter in QuantityWrapper::iter<>().
 * This allows writing loops like
 *
 *    for (auto& l : qw.iter<length_t>()){
 *        ...
 *    }
 */
template<typename boost_quantity, typename T>
class QuantityIteratorGenerator
   : public std::ranges::view_interface<QuantityIterator<boost_quantity, T>>
{
public:
    typedef QuantityIterator<boost_quantity, T> iterator;

    QuantityIteratorGenerator()
       : data(nullptr), _N(0)
    {}

    QuantityIteratorGenerator(T* data, size_t N, const Unit& unit)
       : data(data), _N(N), _unit(unit)
    {}

    iterator begin()
    {
        return QuantityIterator<boost_quantity, T>(
            data, _N, get_converter<boost_quantity>(_unit)
        );
    }

    iterator end()
    {
        auto _end(begin());
        _end += _N;
        return _end;
    }


private:
    T* data;
    size_t _N;
    Unit _unit;

    /*
     * These static asserts are here to ensure consistency of the iterator
     * class.
     * Most of these checks are redundant; checks higher up are contained
     * in those lower down. The two final checks encompass the whole set
     * of checks.
     * The purpose of writing this lengthy list of checks is to construct
     * meaningful compiler error messages should any of them trigger.
     * Using only the top level concepts is like searching for the needle
     * in a hay stack in those cases.
     */
    static_assert(std::destructible<iterator>);
    static_assert(std::is_object_v<iterator>);
    static_assert(std::move_constructible<iterator>);
    static_assert(std::assignable_from<iterator&, iterator>);
    static_assert(std::swappable<iterator>);
    static_assert(std::movable<iterator>);
    static_assert(std::copy_constructible<iterator>);
    /* input_iterator: */
    static_assert(
        std::common_reference_with<
            std::iter_reference_t<iterator>&&,
            std::iter_value_t<iterator>&
        >
    );
    static_assert(
        std::common_reference_with<
            std::iter_reference_t<iterator>&&,
            std::iter_rvalue_reference_t<iterator>&&
        >
    );
    static_assert(
        std::common_reference_with<
            std::iter_rvalue_reference_t<iterator>&&,
            const std::iter_value_t<iterator>&
        >
    );
    static_assert(std::indirectly_readable<iterator>);
    /* sentinel_for: */
    static_assert(std::assignable_from<iterator&,iterator&>);
    static_assert(std::assignable_from<iterator&, const iterator&>);
    static_assert(std::assignable_from<iterator&, const iterator>);
    static_assert(std::copyable<iterator>);
    static_assert(std::default_initializable<iterator>);
    static_assert(std::semiregular<iterator>);
    /*
     * These two are the actual top-level requirements:
     */
    static_assert(
        std::input_or_output_iterator<iterator>
        || std::is_const_v<T>
    );
    static_assert(std::input_iterator<iterator>);
    static_assert(std::sentinel_for<iterator, iterator>);
};

template<typename boost_quantity, typename T>
struct ConstQuantityIteratorGenerator
   : public std::ranges::view_interface<
                QuantityIterator<boost_quantity, const T>
            >
{
    typedef QuantityIterator<boost_quantity, const T> iterator;

    ConstQuantityIteratorGenerator()
       : data(nullptr), _N(0)
    {}

    ConstQuantityIteratorGenerator(const T* data, size_t N, const Unit& unit)
       : data(data), _N(N), _unit(unit)
    {}

    iterator begin() const
    {
        return QuantityIterator<boost_quantity, const T>(
            data, _N, get_converter<boost_quantity>(_unit)
        );
    }

    iterator end() const
    {
        auto _end(begin());
        _end += _N;
        return _end;
    }

private:
    const T* data;
    size_t _N;
    Unit _unit;


    /*
     * These static asserts are here to ensure consistency of the iterator
     * class.
     * Most of these checks are redundant; checks higher up are contained
     * in those lower down. The two final checks encompass the whole set
     * of checks.
     * The purpose of writing this lengthy list of checks is to construct
     * meaningful compiler error messages should any of them trigger.
     * Using only the top level concepts is like searching for the needle
     * in a hay stack in those cases.
     */
    static_assert(std::destructible<iterator>);
    static_assert(std::is_object_v<iterator>);
    static_assert(std::move_constructible<iterator>);
    static_assert(std::assignable_from<iterator&, iterator>);
    static_assert(std::swappable<iterator>);
    static_assert(std::movable<iterator>);
    static_assert(std::copy_constructible<iterator>);
    static_assert(std::assignable_from<iterator&, iterator&>);
    static_assert(std::assignable_from<iterator&, const iterator&>);
    static_assert(std::assignable_from<iterator&, const iterator>);
    static_assert(std::copyable<iterator>);
    static_assert(std::default_initializable<iterator>);
    static_assert(std::semiregular<iterator>);
    /*
     * These two are the actual top-level requirements:
     */
    static_assert(std::input_or_output_iterator<iterator>);
    static_assert(std::sentinel_for<iterator, iterator>);
};


/*
 * Quantity Wrapper
 * ================
 *
 * This class wraps the info from the Cython/Python 'Quantity' class
 * (i.e. a scalar double or an array of doubles + a unit) into something
 * of the C++ world, and provides templates to obtain the quantity in
 * Boost.Unit units (based on the conversion in boost.hpp).
 **/
class QuantityWrapper {
public:
    QuantityWrapper();

    QuantityWrapper(double data, const Unit& unit);

    QuantityWrapper(double* data, size_t N, const Unit& unit);

    QuantityWrapper(const QuantityWrapper& other);

    QuantityWrapper& operator=(const QuantityWrapper& other);

    template<typename boost_quantity>
    boost_quantity get(size_t i = 0) const
    {
        if (i >= _N)
            throw std::out_of_range("Index out of range.");

        return data[i] * get_converter<boost_quantity>(_unit);
    }

    template<typename boost_quantity>
    void set_element(size_t i, boost_quantity bq)
    {
        if (i >= _N)
            throw std::out_of_range("Index out of range.");

        boost_quantity scale = get_converter<boost_quantity>(_unit);
        data[i] = bq / scale;
    }

    template<typename boost_quantity>
    QuantityIterator<boost_quantity,double> begin()
    {
        return QuantityIterator<boost_quantity, double>(
            data, _N, get_converter<boost_quantity>(_unit)
        );
    }

    template<typename boost_quantity>
    QuantityIterator<boost_quantity,const double> cbegin() const
    {
        return QuantityIterator<boost_quantity, const double>(
            data, _N, get_converter<boost_quantity>(_unit)
        );
    }

    template<typename boost_quantity>
    QuantityIterator<boost_quantity, const double> end() const
    {
        auto _end(cbegin<boost_quantity>());
        _end += _N;
        return _end;
    }

    template<typename boost_quantity>
    QuantityIteratorGenerator<boost_quantity, double> iter()
    {
        return QuantityIteratorGenerator<boost_quantity, double>(
            data, _N, _unit
        );
    }

    template<typename boost_quantity>
    ConstQuantityIteratorGenerator<boost_quantity, double> const_iter() const
    {
        return ConstQuantityIteratorGenerator<boost_quantity, double>(
            data, _N, _unit
        );
    }


private:
    double scalar_data;

    /* Attributes: */
    double* data;
    size_t _N;
    Unit _unit;

public:
    size_t size() const;
    const Unit& unit() const;
};



} // end namespace


/*
 * Enable borrowed range for the generators:
 */
template< typename boost_quantity, typename T >
inline constexpr bool
std::ranges::enable_borrowed_range<
    cyantities::QuantityIteratorGenerator<boost_quantity, T>
> = true;


#endif