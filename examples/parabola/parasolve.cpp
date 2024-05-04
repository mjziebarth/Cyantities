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


#include <parasolve.hpp>
#include <cyantities/boost.hpp>

#include <numbers>

#include <boost/units/quantity.hpp>
#include <boost/units/systems/si/mass.hpp>
#include <boost/units/systems/si/length.hpp>
#include <boost/units/systems/si/area.hpp>
#include <boost/units/systems/si/mass_density.hpp>
#include <boost/units/systems/si/velocity.hpp>
#include <boost/units/systems/si/acceleration.hpp>
#include <boost/units/systems/si/dimensionless.hpp>
#include <boost/units/cmath.hpp>

#include <boost/fusion/container.hpp>
#include <boost/range/iterator_range.hpp>

/* Boost odeint: */
#include <boost/numeric/odeint/config.hpp>
#include <boost/numeric/odeint/stepper/controlled_runge_kutta.hpp>
#include <boost/numeric/odeint/stepper/dense_output_runge_kutta.hpp>
#include <boost/numeric/odeint/stepper/runge_kutta_dopri5.hpp>
#include <boost/numeric/odeint/integrate/integrate_times.hpp>
#include <boost/numeric/odeint/integrate/integrate_n_steps.hpp>
#include <boost/numeric/odeint/stepper/generation/make_dense_output.hpp>
#include <boost/numeric/odeint.hpp>
#include <boost/numeric/odeint/iterator/times_iterator.hpp>
#include <boost/numeric/odeint/algebra/fusion_algebra.hpp>
#include <boost/numeric/odeint/algebra/fusion_algebra_dispatcher.hpp>


namespace bu = boost::units;
namespace odeint = boost::numeric::odeint;


/* Define the boost quantities that we will later use: */
typedef bu::quantity<bu::si::mass, double> Mass;
typedef bu::quantity<bu::si::mass_density, double> Density;
typedef bu::quantity<bu::si::length, double> Length;
typedef bu::quantity<bu::si::area, double> Area;
typedef bu::quantity<bu::si::time, double> Time;
typedef bu::quantity<bu::si::velocity, double> Velocity;
typedef bu::quantity<bu::si::acceleration, double> Acceleration;
typedef bu::quantity<bu::si::dimensionless, double> Dimensionless;


namespace boost::units {
    Time operator*(const Time& t, const size_t& i)
    {
        return t * static_cast<double>(i);
    }
}


/* The ODE's state as a boost fusion type: */
typedef boost::fusion::vector<Length, Length, Velocity, Velocity> base_state_t;
typedef boost::fusion::vector<Velocity, Velocity,
                              Acceleration, Acceleration> derivative_t;

/*
 * Make the states easier to digest through named attribute access functions:
 */
struct state_t : public base_state_t
{
public:
    state_t() : base_state_t(0*bu::si::meter, 0*bu::si::meter,
                             0*bu::si::meter_per_second,
                             0*bu::si::meter_per_second)
    {}

    state_t(const Length& x, const Length& y, const Velocity& vx,
            const Velocity& vy) : base_state_t(x,y,vx,vy)
    {}

    Length x() const
    {
        return boost::fusion::at_c<0>(*this);
    }

    Length y() const
    {
        return boost::fusion::at_c<1>(*this);
    }

    Velocity vx() const
    {
        return boost::fusion::at_c<2>(*this);
    }

    Velocity vy() const
    {
        return boost::fusion::at_c<3>(*this);
    }
};


/*
 * The observer that collects the state trajectory during integration:
 */
struct vector_observer {
    std::vector<state_t> states;
    std::vector<Time> times;

    vector_observer(state_t initial, Time t0)
    {
        states.push_back(initial);
        times.push_back(t0);
    }

    void operator()(const state_t& state, const Time& t)
    {
        if (t > times.back()){
            states.push_back(state);
            times.push_back(t);
        }
    }
};


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
)
{
    /* Assert that correct sizes are given: */
    if (t0_qw.size() != 1 || x0_qw.size() != 1 || y0_qw.size() != 1 ||
        vx0_qw.size() != 1 || vy0_qw.size() != 1 || cw_qw.size() != 1 ||
        r_qw.size() != 1 || rho_qw.size() != 1)
        throw std::runtime_error("Incorrect size of scalar parameters.");
    const size_t N = t_qw.size();
    if (N == 0)
        throw std::runtime_error("No time steps given.");
    if (x_qw.size() != N || y_qw.size() != N)
        throw std::runtime_error("No time steps given.");

    /* Mass of the ball: */
    Length r = r_qw.get<Length>();
    Density rho = rho_qw.get<Density>();
    Density rho_air = rho_air_qw.get<Density>();
    Mass m = 4.0 / 3.0 * std::numbers::pi_v<double> * r * r * r * rho;
    Area A = std::numbers::pi_v<double> * r * r;

    /* cw: */
    if (!cw_qw.unit().dimensionless())
        throw std::runtime_error("Not dimensionless!");
    double cw = cw_qw.get<Dimensionless>();

    /* Initial state: */
    state_t initial_state(x0_qw.get<Length>(), y0_qw.get<Length>(),
                          vx0_qw.get<Velocity>(), vy0_qw.get<Velocity>());


    auto friction_parabola
    = [cw,A,rho_air,m](const state_t& state, derivative_t& deriv, Time _t)
    {
        /* Drag: */
        auto v2 = state.vx() * state.vx() + state.vy() * state.vy();
        auto v = bu::sqrt(v2);
        auto F = cw * A * 0.5 * rho_air * v2;
        auto a_drag = F / m;

        /* Drag components: */
        auto a_drag_x = -a_drag * state.vx() / v;
        auto a_drag_y = -a_drag * state.vy() / v;

        /* Gravitational acceleration: */
        auto g = 9.81 * bu::si::meter / (bu::si::second * bu::si::second);

        std::cout << "drag to gravitation: " << (double)(a_drag_y / g) << "\n";

        /* Set the velocity time derivative: */
        boost::fusion::at_c<2>(deriv) = a_drag_x;
        boost::fusion::at_c<3>(deriv) = a_drag_y - g;

        /* Set the position time derivative: */
        boost::fusion::at_c<0>(deriv) = state.vx();
        boost::fusion::at_c<1>(deriv) = state.vy();
    };

    typedef odeint::runge_kutta_dopri5<
                state_t, double , derivative_t, Time
            > stepper_t;

    Time t0 = t0_qw.get<Time>();

    vector_observer solution(initial_state, t0);

    stepper_t stepper;

//    odeint::integrate_times(
//        odeint::make_dense_output(err_abs, err_rel, stepper),
//        friction_parabola,
//        initial_state, t_range, dt0_qw.get<Time>(), solution
//    );

    typedef cyantities::QuantityIterator<Time,const double> quantity_iter_t;

    std::cout << "t_qw size: " << t_qw.size() << "\n" << std::flush;

    /*
     * Create an ODE solution iterator which performs all the
     * heavy integration behind the scenes:
     */
    auto dense = odeint::make_dense_output(err_abs, err_rel, stepper);
    auto solution_iter = odeint::make_times_iterator_begin(
        dense, friction_parabola, initial_state,
        t_qw.cbegin<Time>(), t_qw.end<Time>(), dt0_qw.get<Time>()
    );
    auto solution_end \
        = odeint::make_times_iterator_end<quantity_iter_t>(
            dense, friction_parabola, initial_state
    );


    /*
     * Based on this iterator, we can now assign the solution vector
     * corresponding to the requested time points:
     */
    size_t i=0;
    for (; solution_iter != solution_end; ++solution_iter)
    {
        x_qw.set_element(i, solution_iter->x());
        y_qw.set_element(i, solution_iter->y());
        ++i;
    }
}