//
// Copyright 2019 Ettus Research, a National Instruments Brand
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

//#ifndef INCLUDED_RFNOC_EXAMPLE_GAIN_BLOCK_CONTROL_HPP
//#define INCLUDED_RFNOC_EXAMPLE_GAIN_BLOCK_CONTROL_HPP

#pragma once

#include <uhd/config.hpp>
#include <uhd/rfnoc/noc_block_base.hpp>
#include <uhd/types/stream_cmd.hpp>

namespace uhd { namespace rfnoc {

/*! Block controller for the gain block: Multiply amplitude of signal
 *
 * This block multiplies the signal input with a fixed gain value.
 */
class UHD_API sounder_rx_block_control : public uhd::rfnoc::noc_block_base
{
public:
    RFNOC_DECLARE_BLOCK(sounder_rx_block_control)

    static const uint32_t REG_ML_ADDR;
    static const uint32_t REG_K_ADDR;
    static const uint32_t REG_L_ADDR;
    static const uint32_t REG_R_ADDR;
    static const uint32_t REG_P_ADDR;
    static const uint32_t REG_A_ADDR;
    static const uint32_t REG_M_ADDR;
    static const uint32_t REG_PA_ADDR;

    virtual void set_k(const uint32_t k) = 0;
    virtual uint32_t get_k() = 0;
    
    virtual void set_ml(const uint32_t ml) = 0;
    virtual uint32_t get_ml() = 0;
    
    virtual void set_l(const uint32_t l) = 0;
    virtual uint32_t get_l() = 0;
    
    virtual void set_r(const uint32_t r) = 0;
    virtual uint32_t get_r() = 0;
    
    virtual void set_p(const uint32_t p) = 0;
    virtual uint32_t get_p() = 0;
    
    virtual void set_a(const uint32_t a) = 0;
    virtual uint32_t get_a() = 0;
    
    virtual void set_m(const uint32_t m) = 0;
    virtual uint32_t get_m() = 0;
    
    virtual void set_pa(const uint32_t pa) = 0;
    virtual uint32_t get_pa() = 0;
};

}} // namespace rfnoc::example

//#endif [> INCLUDED_RFNOC_EXAMPLE_GAIN_BLOCK_CONTROL_HPP <]
