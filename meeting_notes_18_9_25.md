Meeting Notes:
- Need low-jitter clock above all else for precise timing
- Reference frequency of 40 MHz chosen

VCO: 
- 10.24 GHz LC VCO
- 6 bit digital and analog varactor tuning
- positive tuning
- <= 100fs jitter in PLL, 36fs free-running
- 20MHz - 50MHz frequency jitter (std dev) in PLL
- 9.799 GHz with BAND = 6'h3f in SS
- 10.923 GHz with BAND = 6'h00 in FF
- Kvco (MHz/V): ff = 225, fs = sf = tt = 242, ss = 258 

Clock Divider Block:
- Need a total division ratio of 256 for 10.24 GHz -> 40 MHz
- First divider in CML, second-fourth divider in TSPC, all else using dual-edge FF
- 3.3-3.9 ps (!) jitter in sampling clock in PLL
- 125fs - 138fs jitter in sampling clock free running
- 49%-51.5% duty cycle in sampling clock in PLL
- 49%-51% duty cycle in sampling clock free running
- 2mW - 2.4mW power consumption

PFD:
- Standard 2 TSPC FF with NOR reset path
- ~100ps reset path in worst case -> 0.025 radian deadzone
- Suffers from latchup when PLL doesn't lock fast enough (one clock ``laps" the other)

CP:
- Standard single-ended topology with source-connected switch 
- Seperate current biases for up and down currents
- PMOS switch for up, NMOS switch for down
- 23:1 current mirror ratio (230uA current for 10uA bias)

Loop LPF:
- 20.179K rppoly non salicide resistor (W = 1um, L = 28.4um) series with 20.2pF mimcap
- Parallel with 4.27pF mimcap

Questions:
- What are the figures of merit for a PFD in this case? Should we change the topology to use a different FF or no-feedback approach?
- - PFD is good topology, but use the standard cell FF. Don't worry about reset path.

- Does the charge pump topology pose any issues? Would we gain anything from switching to the only-NMOS switch topology?
- - Yes, the challenge is input/output coupling from VCO. An output buffer + new textbook topology to minimize coupling

- Are there any CP- or PFD-specific layout guidelines?
- - watch the IR drop, symmetry, preserve Q for the VCO, block by block

- How significant are the shark fins and oscillator coupling noise to the jitter? Can we reduce them?
- - Most of this is VCO coupling, so reducing that will be enough

- How do we widen the frequency locking window?
- - Recalculate loop filter topology

- Why are the switching currents so high from the CP?
- - Nothing to worry about, as it gets filtered out

todo:
- Make LPF tunable
- Use a CP topology that minimizes coupling between input and output
- Find Kvco using parameter sweep steady state
- Post layout verification of VCO and PLL