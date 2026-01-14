Fixes for new submission:
~~1) Add a cs pin to replace the iclk reset scheme~~
~~2) Reorder the addressing scheme so all R registers are at the end~~
~~3) Add a non-destructive read mode by using the MSB of the address (1 = is_write)~~
~~4) Remove any reliance on iclk~~
~~5) Fix the mux output scheme such that it doesn't drop bits on transition~~
~~6) Fix writing so that it doesn't double write~~
~~7) Rewrite the instruction driver~~
~~8) Add an SR (inst_start/inst_stop) latch for clk_enable~~

Debug Log:
- Writing works
- Start instruction works
- Readout from W/R regs works
- (Sequential) Non-destructive read works

To-do:
- Verify the full system (carefully)
- synthesize all relevant blocks and check timing
- Implement tp_mux decoder
- Implement the vtune switch from the SPI
- Test PLL pss and tran_noise