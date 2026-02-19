#!/usr/bin/env python3
"""Generate ET4351 Lab 1 Report PDF"""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, cm
from reportlab.lib.colors import HexColor
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER

OUTPUT = "/home/danieltyukov/workspace/tud/tud-digital-vlsi-systems-on-chip/ET4351_Lab1_Report_Tyukov.pdf"

doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    topMargin=2*cm, bottomMargin=2*cm,
    leftMargin=2*cm, rightMargin=2*cm,
)

styles = getSampleStyleSheet()

title_style = ParagraphStyle(
    'CustomTitle', parent=styles['Title'],
    fontSize=18, spaceAfter=6,
)
subtitle_style = ParagraphStyle(
    'Subtitle', parent=styles['Normal'],
    fontSize=12, spaceAfter=12, alignment=TA_CENTER,
)
heading_style = ParagraphStyle(
    'QHeading', parent=styles['Heading2'],
    fontSize=13, spaceBefore=14, spaceAfter=6,
    textColor=HexColor('#1a1a1a'),
)
body_style = ParagraphStyle(
    'Body', parent=styles['Normal'],
    fontSize=10, leading=13, spaceAfter=6,
    fontName='Helvetica',
)
code_style = ParagraphStyle(
    'Code', parent=styles['Normal'],
    fontSize=8.5, leading=11, spaceAfter=4,
    fontName='Courier',
    leftIndent=12,
)
bold_style = ParagraphStyle(
    'Bold', parent=body_style,
    fontName='Helvetica-Bold',
)

story = []

# Title
story.append(Paragraph("ET4351 Labs Report - Lab 1", title_style))
story.append(Spacer(1, 4*mm))

# Student info table
info_data = [
    ["Student Name", "NetID", "Course Code"],
    ["Tyukov, Daniel", "datyukov", "ET4351"],
]
info_table = Table(info_data, colWidths=[7*cm, 5*cm, 4*cm])
info_table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HexColor('#d0d0d0')),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 10),
    ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#999999')),
    ('PADDING', (0, 0), (-1, -1), 6),
]))
story.append(info_table)
story.append(Spacer(1, 8*mm))

story.append(Paragraph("Lab 1: Project Baseline with PicoSoC", styles['Heading1']))
story.append(Spacer(1, 4*mm))

# ──────────────────────────── Q1.1 ────────────────────────────
story.append(Paragraph("Question 1.1", heading_style))
story.append(Paragraph(
    "<b>(a) How does PicoSoC load the firmware?</b>", body_style))
story.append(Paragraph(
    "The testbench (et4351_tb.sv) instantiates the et4351 top-level module (the DUT) and a "
    "spiflash module. During initialization, spiflash.v loads the firmware hex file into its "
    "internal memory array using <font face='Courier'>$readmemh(firmware_file, memory)</font>, "
    "where the firmware path is passed via the <font face='Courier'>+firmware=</font> plusarg. "
    "At reset, the PicoRV32 CPU inside PicoSoC begins fetching instructions starting from "
    "<font face='Courier'>PROGADDR_RESET = 0x0010_0000</font> (1 MB into the flash address space). "
    "The spimemio module in picosoc.v handles SPI flash reads: when the CPU issues a memory access "
    "in the flash range (address >= 4*MEM_WORDS and < 0x0200_0000), spimemio drives the SPI protocol "
    "signals (csb, clk, io0-io3) to the external spiflash model, which responds with the requested "
    "data bytes. The flash model supports multiple SPI modes (standard, dual, quad, DDR) for "
    "increasing throughput.",
    body_style))

story.append(Spacer(1, 2*mm))
story.append(Paragraph(
    "<b>(b) How does PicoSoC display \"Hello, World!\" on the terminal?</b>", body_style))
story.append(Paragraph(
    "The C firmware (hello.c) calls <font face='Courier'>init_uart()</font> which sets the UART "
    "clock divider register at address 0x02000004 to 104, configuring the baud rate. Then "
    "<font face='Courier'>print_str(\"Hello, World!\\n\")</font> iterates over each character and "
    "calls <font face='Courier'>print_char(c)</font>, which writes the character to the UART data "
    "register at address 0x02000008 (<font face='Courier'>reg_uart_data</font>). "
    "In picosoc.v, writes to 0x02000008 are routed to simpleuart's <font face='Courier'>reg_dat_we</font> "
    "input. The simpleuart module serializes each byte into a UART frame (start bit, 8 data bits, "
    "stop bit) and shifts it out on <font face='Courier'>ser_tx</font> at the configured baud rate. "
    "The testbench (et4351_tb.sv) monitors <font face='Courier'>ser_tx</font> with an always block that "
    "detects the start bit (negedge), samples 8 data bits, and uses <font face='Courier'>$write</font> "
    "to display each character on the QuestaSim console. When <font face='Courier'>print_char(-1)</font> "
    "sends a value > 127, the testbench terminates the simulation via <font face='Courier'>$finish</font> "
    "after printing the cycle count (26,554 cycles).",
    body_style))

# ──────────────────────────── Q1.2 ────────────────────────────
story.append(Paragraph("Question 1.2", heading_style))
story.append(Paragraph(
    "The dummy accelerator (accelerator.v) is a counter-based module mapped to address range "
    "0x0300_0000. It has 4 memory-mapped registers: GPIO (0x03000000), CSR (0x03000004), Input "
    "(0x03000008), and Output (0x0300000C). "
    "The accelerator is <b>launched</b> by the CPU writing to the CSR register: bit 0 controls "
    "reset (active-high), bit 1 enables the accelerator, and bit 2 is a read-only done flag. "
    "The memory interface responds when <font face='Courier'>iomem_valid</font> is asserted and "
    "<font face='Courier'>iomem_addr[31:24] == 0x03</font>. Reads and writes to the 4 registers "
    "are handled byte-by-byte using <font face='Courier'>iomem_wstrb</font>.",
    body_style))
story.append(Paragraph(
    "The <b>handshake</b> mechanism works as follows: the CPU writes the target count to the Input "
    "register, then sets the enable bit in CSR. The accelerator increments an internal counter each "
    "clock cycle until it reaches the target value. Upon completion, it copies the counter value to "
    "the result register and sets the <font face='Courier'>valid_out</font> flag, which is reflected "
    "in CSR bit 2. The CPU polls CSR bit 2 and reads the Output register when done. This is a simple "
    "polling-based handshake: the CPU starts the accelerator via CSR and waits for the done flag.",
    body_style))

# ──────────────────────────── Q1.3 ────────────────────────────
story.append(Paragraph("Question 1.3", heading_style))
story.append(Paragraph(
    "In dummy_accel.c, the PicoRV32 core interacts with the accelerator through memory-mapped I/O "
    "registers defined as volatile pointers. The interaction follows these steps:",
    body_style))
story.append(Paragraph(
    "1. <b>Initialize</b>: All four registers (GPIO, CSR, Input, Output) are written to 0x00000000. "
    "This is a write to addresses 0x03000000-0x0300000C via the bus. In accelerator.v, these writes "
    "update <font face='Courier'>iomem_accel[0..3]</font>.",
    body_style))
story.append(Paragraph(
    "2. <b>Reset</b>: The CPU sets CSR bit 0 (<font face='Courier'>reg_csr |= MASK_CSR_RESET</font>) "
    "then clears it. In hardware, <font face='Courier'>reset_accel = iomem_accel[1][0]</font> "
    "resets the counter, result, and valid_out to 0.",
    body_style))
story.append(Paragraph(
    "3. <b>Set Input</b>: <font face='Courier'>reg_input = 0x00012345</font> writes the target "
    "count (74,565 decimal) to <font face='Courier'>iomem_accel[2]</font>, which is assigned to "
    "<font face='Courier'>count_dest</font>.",
    body_style))
story.append(Paragraph(
    "4. <b>Start</b>: <font face='Courier'>reg_csr |= MASK_CSR_START</font> sets bit 1, enabling "
    "the accelerator (<font face='Courier'>enable_accel</font>). The counter increments each cycle.",
    body_style))
story.append(Paragraph(
    "5. <b>Poll</b>: <font face='Courier'>while(!(reg_csr &amp; MASK_CSR_DONE))</font> repeatedly "
    "reads CSR. Each read triggers a bus transaction; accelerator.v returns "
    "<font face='Courier'>iomem_accel[1]</font> with bit 2 reflecting valid_out.",
    body_style))
story.append(Paragraph(
    "6. <b>Read Output</b>: <font face='Courier'>reg_output</font> reads "
    "<font face='Courier'>iomem_accel[3]</font> (= result = 0x00012345). The value is printed "
    "via UART, producing \"Accelerator Output: 0x00012345\".",
    body_style))

# ──────────────────────────── Q1.4 ────────────────────────────
story.append(Paragraph("Question 1.4", heading_style))
story.append(Paragraph(
    "In Task 3, the spiflash.v model for the flash memory is modified compared to Tasks 1/2. "
    "The key difference is the memory declaration and an additional "
    "<font face='Courier'>$readmemh</font> call:",
    body_style))
story.append(Paragraph(
    "<font face='Courier'>reg [7:0] memory [1*1024*1024 : 5*1024*1024-1];</font> declares a 4 MB "
    "flash starting at byte address 0x00100000 and ending at 0x004FFFFF.",
    code_style))
story.append(Paragraph(
    "The firmware (.text section) is loaded first via "
    "<font face='Courier'>$readmemh(firmware_file, memory)</font>, occupying the lower portion "
    "of flash starting at 0x00100000. Then the twiddle factors and signal samples are loaded via "
    "<font face='Courier'>$readmemh(\"../firmware/fft_data.hex\", memory)</font>. "
    "According to the lab documentation (Figure 9), the signal samples are stored at the end of "
    "flash starting from address 0x004F0000. Each sample occupies 4 bytes (32-bit integers) stored "
    "in little-endian byte order. The twiddle factors (precomputed complex exponentials) and the "
    "input signal samples are both placed in fft_data.hex by the prepare_fft.py script, which runs "
    "during compilation. The C code reads these values from flash using memory-mapped read accesses "
    "through the SPI interface, the same mechanism used for instruction fetches.",
    body_style))

# ──────────────────────────── Q1.5 ────────────────────────────
story.append(Paragraph("Question 1.5", heading_style))
story.append(Paragraph(
    "The FFT latency results for different GCC optimization levels (32-point FFT, all verified correct):",
    body_style))

opt_data = [
    ["Optimization Level", "FFT Runtime (cycles)", "Total Latency (cycles)", "Speedup vs -O0"],
    ["-O0", "1,412,441", "3,517,190", "1.00x"],
    ["-O1", "264,711", "1,331,445", "5.33x"],
    ["-O2", "259,390", "1,294,154", "5.45x"],
]
opt_table = Table(opt_data, colWidths=[3.5*cm, 4.5*cm, 4.5*cm, 3.5*cm])
opt_table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HexColor('#d0d0d0')),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 9.5),
    ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#999999')),
    ('PADDING', (0, 0), (-1, -1), 5),
    ('ALIGN', (1, 1), (-1, -1), 'CENTER'),
]))
story.append(opt_table)
story.append(Spacer(1, 3*mm))

story.append(Paragraph(
    "The jump from -O0 to -O1 yields a dramatic ~5.3x speedup in FFT runtime. This is because "
    "-O0 performs no optimization (every variable is stored to and loaded from the stack), while "
    "-O1 enables register allocation, constant folding, dead code elimination, and basic loop "
    "optimizations. Moving from -O1 to -O2 provides a marginal further improvement (~2%), as -O2 "
    "adds instruction scheduling, loop unrolling, and more aggressive inlining. The relatively "
    "small -O1 to -O2 gap suggests the FFT computation is already well-optimized at -O1 and is "
    "limited by memory access latency (SPI flash reads) rather than instruction count alone.",
    body_style))

# ──────────────────────────── Disclaimer ────────────────────────────
story.append(Spacer(1, 12*mm))
story.append(Paragraph("<b>DISCLAIMER</b>", ParagraphStyle(
    'Disc', parent=body_style, alignment=TA_CENTER, fontName='Helvetica-Bold', fontSize=11)))
story.append(Spacer(1, 2*mm))
story.append(Paragraph(
    "This report is individual and formative. I certify that I have done this report individually.",
    body_style))

# Build PDF
doc.build(story)
print(f"PDF generated: {OUTPUT}")
