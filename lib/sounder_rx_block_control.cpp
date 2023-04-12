// Author: Michiel Sandra, Lund University

// Include our own header:
#include <sounder_rx_block_control.hpp>

// These two includes are the minimum required to implement a block:
#include <uhd/rfnoc/defaults.hpp>
#include <uhd/rfnoc/registry.hpp>

//using namespace rfnoc::example;
using namespace uhd::rfnoc;

const uint32_t sounder_rx_block_control::REG_ML_ADDR = 0x00;
const uint32_t sounder_rx_block_control::REG_K_ADDR = 0x01;
const uint32_t sounder_rx_block_control::REG_L_ADDR = 0x02;
const uint32_t sounder_rx_block_control::REG_R_ADDR = 0x03;
const uint32_t sounder_rx_block_control::REG_P_ADDR = 0x04;
const uint32_t sounder_rx_block_control::REG_A_ADDR = 0x05;
const uint32_t sounder_rx_block_control::REG_M_ADDR = 0x06;
const uint32_t sounder_rx_block_control::REG_PA_ADDR = 0x07;

class sounder_rx_block_control_impl : public sounder_rx_block_control {
public:
    RFNOC_BLOCK_CONSTRUCTOR(sounder_rx_block_control) {}

    void set_ml(const uint32_t x)
    {
        regs().poke32(REG_ML_ADDR, x);
    }

    uint32_t get_ml()
    {
        return regs().peek32(REG_ML_ADDR);
    }
    
    void set_k(const uint32_t x)
    {
        regs().poke32(REG_K_ADDR, x);
    }

    uint32_t get_k()
    {
        return regs().peek32(REG_K_ADDR);
    }
    
    void set_r(const uint32_t x)
    {
        regs().poke32(REG_R_ADDR, x);
    }

    uint32_t get_r()
    {
        return regs().peek32(REG_R_ADDR);
    }

    void set_p(const uint32_t x)
    {
        regs().poke32(REG_P_ADDR, x);
    }

    uint32_t get_p()
    {
        return regs().peek32(REG_P_ADDR);
    }

    void set_a(const uint32_t x)
    {
        regs().poke32(REG_A_ADDR, x);
    }

    uint32_t get_a()
    {
        return regs().peek32(REG_A_ADDR);
    }

    void set_l(const uint32_t x)
    {
        regs().poke32(REG_L_ADDR, x);
    }

    uint32_t get_l()
    {
        return regs().peek32(REG_L_ADDR);
    }
    
    void set_m(const uint32_t x)
    {
        regs().poke32(REG_M_ADDR, x);
    }

    uint32_t get_m()
    {
        return regs().peek32(REG_M_ADDR);
    }
    
    void set_pa(const uint32_t x)
    {
        regs().poke32(REG_PA_ADDR, x);
    }

    uint32_t get_pa()
    {
        return regs().peek32(REG_PA_ADDR);
    }




private:
};

UHD_RFNOC_BLOCK_REGISTER_DIRECT(
    sounder_rx_block_control, 0x0e870000, "SounderRx", CLOCK_KEY_GRAPH, "bus_clk")
