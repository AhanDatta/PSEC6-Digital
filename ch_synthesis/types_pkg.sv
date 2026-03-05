package types_pkg;
    typedef enum logic [3:0] {
            STATE_INIT, // All counters are reset to 0 and stopped, and all SCAs are stopped.
            STATE_STOPPED, // All SCAs and counters are stopped, but the counters are left at their current value.
            STATE_SAMPLING_A, // sample the fast buffer A. The length of the buffer is 3.2ns.
            STATE_SAMPLING_B, // sample the fast buffer B.
            STATE_SAMPLING_C, // sample the fast buffer C.
            STATE_SAMPLING_D, // sample the fast buffer D.
            STATE_SAMPLING_E, // sample the slow buffer.
            STATE_SAMPLING_A_AND_B, // sample the fast buffers A and B.
            //Note that the writing strobe at the last capacitor of bank A is fed to that of the first capacitor of bank B,
            //which avails wraparoundless sampling.
            //The two banks effectively act as one buffer of length 6.4ns.
            STATE_SAMPLING_C_AND_D, // sample the fast buffers C and D.
            STATE_SAMPLING_ALL, // sample all fast buffers. The length of the buffer is 12.8ns.
            STATE_READOUT // load the counter data and trigger count into the output shift register
        } state_t;

    //This has to agree with the SPI convention
    typedef enum logic [1:0] {
        MODE_SAMPLE1 = 2'b01,
        MODE_SAMPLE2 = 2'b10,
        MODE_SAMPLE4 = 2'b11
    } smode_t;
endpackage