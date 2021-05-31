#include "../build/Vqarma_64.h"
#include "verilated.h"

int main(int argc, char **argv, char **env)
{
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vqarma_64 *top = new Vqarma_64{contextp};
    while (!contextp->gotFinish())
    {
        top->clk_in = !top->clk_in;
        top->eval();
    }
    delete top;
    delete contextp;
    return 0;
}