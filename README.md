# ESBL_RFSoc

Pure sinusoidal phase modulator for electronic sideband locking (ESB locking/ESBL) based on the [RFSoC 4x2](https://www.realdigital.org/hardware/rfsoc-4x2) platform.

<a name="top"></a>

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [System Architecture](#system-architecture)
- [Operation Theory](#operation-theory)
- [Interface](#interface)
- [TODOs](#todos)
- [Paper and Contact](#paper-and-contact)

## Overview

This repository contains the hardware and software for an RFSoC-based direct SDR that generates the phase-modulated radio-frequency (rf) drive used in electronic sideband Pound–Drever–Hall (PDH) laser locking. The design runs on the AMD Zynq UltraScale+ RFSoC ZU48DR on the [RFSoC 4x2](https://www.realdigital.org/hardware/rfsoc-4x2) platform. It synthesizes the required in-phase and quadrature-phase (I/Q) baseband waveforms in the programmable logic (PL), then uses the on-chip RF Data Converter (RFDC) and RF digital-to-analog converter (RF-DAC) to produce the analog output for an electro-optic modulator (EOM).

The repository includes the FPGA gateware and its Migen source, the PYNQ-side control server and startup scripts, and host-side integration with labscript/BLACS. It also contains the KiCad design for an RFSoC adapter board, simulation testbenches, and Jupyter notebooks for hardware tests. The interface software controls the modulation frequency and depth, I/Q amplitudes and relative phase, PDH reference phase, DAC carrier frequency and output level, and programmed carrier-frequency ramps.

## Project Structure

The main directories and their roles are:

```text
.
├── PYNQ_interface/
│   ├── parser.py
│   ├── ESBL_autostart.sh
│   ├── ESBL_service_enable.sh
│   └── ESBL_startup.service
├── gateware/
│   ├── hdl/
│   ├── python/
│   ├── scripts/
│   ├── sim/
│   └── makefile
├── kicad/
│   └── esb_rfsoc_adapter/
├── labscript_devices/
│   └── ESBL_RFSoC/
└── notebooks/
```

- **`PYNQ_interface/`** — Runtime software for the RFSoC processing system (PS). `parser.py` loads the FPGA overlay, configures the RFDC and memory-mapped control registers, and runs the TCP/IP command server. The shell scripts and systemd unit install and launch the server automatically at boot. The accompanying directory README describes deployment on the board.

- **`gateware/hdl/`** — Verilog RTL used by the Vivado design. The main modules implement the phase-modulated I/Q waveform generator, AXI-Lite control registers, the DMA-driven RFDC NCO frequency-update controller, trigger logic, and the serialized reference output. The `.init` files provide lookup-table initialization data used by the waveform generator. The directory also includes the board-level top-level and wrapper HDL files.

- **`gateware/python/`** — Migen source used to generate the phase-generator Verilog. `esbl_parallel_with_PDH.py` generates the parallel phase-modulator implementation used by the design; `esbl_with_PDH_out_hi_res.py` and `small_test.py` provide alternate or reduced test implementations. The `compile` helper runs the generator and places the generated RTL and lookup-table files in the HDL tree.

- **`gateware/scripts/`** — Vivado Tcl project and block-design setup, plus a helper script for downloading the RFSoC 4x2 board-support files and PMOD constraints required by the build.

- **`gateware/sim/`** — Verilog/SystemVerilog testbenches for the phase generator and the DMA-based frequency-update controller, together with simulation waveform configuration.

- **`gateware/makefile`** — Convenience targets for downloading board files, building the Vivado design, deploying the generated bitstream and hardware-handoff file to the RFSoC, and cleaning Vivado logs.

- **`kicad/`** — KiCad schematic, PCB layout, project settings, and custom footprint for the `esb_rfsoc_adapter` board.

- **`labscript_devices/ESBL_RFSoC/`** — labscript device definition and registration, BLACS worker and tab implementation, and the Qt UI used to control the RFSoC from a labscript/BLACS experiment setup.

- **`notebooks/`** — Jupyter notebooks for manually loading and exercising the overlay and for testing the TCP/IP command interface.

## System Architecture

The instrument is organized into a host-control path and a real-time signal-generation path. The host PC communicates with a PYNQ application running on the RFSoC PS. The PYNQ server loads the FPGA overlay, accesses the hardware through the RFSoC Python APIs and memory-mapped registers, and translates the requested waveform settings into register writes or RFDC configuration updates. The server listens for TCP/IP commands; the BLACS worker uses the same connection to send settings and frequency-ramp instructions.

The PL contains the baseband waveform generator and the control logic. The AXI-Lite register block supplies the generator with the baseband modulation-frequency word, modulation-depth scaling, relative I/Q phase, I- and Q-channel amplitude settings, and PDH reference phase. The software trigger flag is also exposed through this register interface. The phase generator uses a phase accumulator and sine/cosine lookup-and-interpolation logic to calculate the I/Q samples. These samples are packed into an AXI-Stream word and sent to the RFDC. In parallel, the generator produces an eight-bit, phase-adjustable reference waveform; a serializer transfers this signal to a PMOD output.

The RFDC performs digital up-conversion: its NCO supplies the tunable carrier, and its interpolation and signal-conditioning stages prepare the waveform for conversion by the RF-DAC. The resulting analog rf signal is amplified as required and applied to the EOM. The DAC sampling-clock network uses the RFSoC clocking hardware, including the LMK04828 jitter-cleaner circuitry, to provide the clocks required by the data converter and to limit clock-jitter contributions.

Carrier-frequency ramps use a separate DMA path. The PYNQ server converts a requested sequence of carrier frequencies into RFDC frequency-tuning words (FTWs), stores the words in a DMA buffer, and transfers them through AXI DMA to the custom `frequency_change_DMA` controller. That controller issues NCO update requests and advances through the programmed sequence when its trigger condition is met. The trigger logic combines the external PMOD trigger input with the software trigger flag, allowing a ramp to be advanced from software or synchronized to an external experiment trigger. This separates fast carrier updates from the slower host command path.

## Operation Theory

### ESB locking

In ESB locking, the EOM is driven by a phase-modulated rf waveform of the form

$$
V_{\mathrm{EOM}}(t)=\xi\sin\!\left[\Omega_c t+\beta_m\sin(\Omega_m t)\right],
$$

where $\Omega_c$ is the tunable rf carrier frequency, $\Omega_m$ is the baseband phase-modulation frequency used for PDH demodulation, and $\beta_m$ is the phase-modulation index. The optical field after phase modulation can be written as

$$
E(t)=E_0\exp\!\left\{j\Omega_0t+
j\beta_c\sin\!\left[\Omega_ct+\beta_m\sin(\Omega_mt)\right]\right\},
$$

where $\Omega_0$ is the unmodulated laser frequency and $\beta_c$ is the optical phase-modulation depth set by the rf drive amplitude. Expanding the field with the Jacobi–Anger identity gives optical components at frequencies $\Omega_0+n\Omega_c+k\Omega_m$, with amplitudes proportional to $J_n(\beta_c)J_k(n\beta_m)$.

The cavity is locked to one of the first-order carrier sidebands, so the lock condition is

$$
\Omega_0\pm\Omega_c=2\pi N\,\mathrm{FSR},
$$

where $N$ is the cavity longitudinal-mode index and FSR is its free spectral range. Once the selected cavity mode is fixed, changing $\Omega_c$ shifts the locked laser carrier frequency by the opposite amount. This is the basis of continuous laser-frequency tuning while retaining the cavity reference. The PDH error signal is obtained by demodulating the detected signal at $\Omega_m$; the relevant signal components form a triplet around the cavity-resonant sideband.

### QAM synthesis of the ESB waveform

The required waveform can be generated by quadrature amplitude modulation (QAM). Applying the angle-sum identity gives

$$
\begin{aligned}
V_{\mathrm{EOM}}(t)
&=\xi\sin\!\left[\Omega_ct+\beta_m\sin(\Omega_mt)\right]\\
&=I(t)\cos(\Omega_ct)+Q(t)\sin(\Omega_ct),
\end{aligned}
$$

with the ideal baseband components

$$
\begin{aligned}
I(t)&=\xi\sin\!\left[\beta_m\sin(\Omega_mt)\right],\\
Q(t)&=\xi\cos\!\left[\beta_m\sin(\Omega_mt)\right].
\end{aligned}
$$

Thus, two carrier components separated by $\pi/2$ are independently amplitude-modulated by $I(t)$ and $Q(t)$ and then summed. For an ideal waveform, $I(t)^2+Q(t)^2=\xi^2$ is constant, while the I/Q phasor angle follows the desired sinusoidal phase modulation. This produces a constant-envelope phase-modulated rf signal rather than relying on a small-index approximation.

In this implementation, the PL generates the baseband I/Q samples digitally. A phase accumulator establishes the $\Omega_m$ timebase, and sine/cosine lookup and interpolation logic generates the modulation functions. The modulation-depth setting scales the phase excursion; the I/Q amplitude and relative-phase settings provide adjustment of the generated phasor. The RFDC NCO then supplies $\Omega_c$ and up-converts the I/Q stream to the output carrier frequency. The PYNQ/PL is also capable of directly adjusting the I/Q impairment calibrations.

## Paper and Contact

Please refer to the [preprint](https://arxiv.org/abs/2409.08764) for details about the theoretical analysis, waveform characterization, and experimental application of this device.

Please contact Alessandro Restelli (arestell"at"umd"dot"edu) or Juntian Tu (juntian"at"umd"dot"edu) for issues related to this repository.
