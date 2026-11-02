"""Independent RV32I subset reference model.

The model intentionally does not import or inspect the RTL. It implements the
architectural state transition for the supported ADD, SUB, AND, OR, XOR, and
ADDI instructions.
"""

MASK32 = 0xFFFFFFFF

OP_RTYPE = 0x33
OP_ITYPE = 0x13


def u32(value: int) -> int:
    """Return value constrained to a 32-bit architectural word."""
    return value & MASK32


def sign_extend(value: int, width: int) -> int:
    """Sign-extend a width-bit value and return its 32-bit representation."""
    value &= (1 << width) - 1
    if value & (1 << (width - 1)):
        value -= 1 << width
    return u32(value)


class CPUModel:
    """Small, stateful reference model for the Phase 1 CPU instruction set."""

    def __init__(self) -> None:
        self.pc = 0
        self.regs = [0] * 32

    def read_reg(self, index: int) -> int:
        return 0 if index == 0 else self.regs[index]

    def write_reg(self, index: int, value: int) -> None:
        if index != 0:
            self.regs[index] = u32(value)
        self.regs[0] = 0

    def step(self, instruction: int) -> dict[str, int | bool]:
        """Execute one instruction and return an execution transaction."""
        instruction = u32(instruction)
        old_pc = self.pc
        opcode = instruction & 0x7F
        rd = (instruction >> 7) & 0x1F
        funct3 = (instruction >> 12) & 0x7
        rs1 = (instruction >> 15) & 0x1F
        rs2 = (instruction >> 20) & 0x1F
        funct7 = (instruction >> 25) & 0x7F

        result = 0
        reg_write = False
        operation = "UNSUPPORTED"

        if opcode == OP_RTYPE and funct7 in (0x00, 0x20):
            left = self.read_reg(rs1)
            right = self.read_reg(rs2)
            if funct3 == 0x0 and funct7 == 0x00:
                result, operation = u32(left + right), "ADD"
            elif funct3 == 0x0 and funct7 == 0x20:
                result, operation = u32(left - right), "SUB"
            elif funct3 == 0x7 and funct7 == 0x00:
                result, operation = left & right, "AND"
            elif funct3 == 0x6 and funct7 == 0x00:
                result, operation = left | right, "OR"
            elif funct3 == 0x4 and funct7 == 0x00:
                result, operation = left ^ right, "XOR"

            reg_write = operation != "UNSUPPORTED"

        elif opcode == OP_ITYPE and funct3 == 0x0:
            immediate = sign_extend(instruction >> 20, 12)
            result = u32(self.read_reg(rs1) + immediate)
            operation = "ADDI"
            reg_write = True

        if reg_write:
            self.write_reg(rd, result)

        self.regs[0] = 0
        self.pc = u32(self.pc + 4)

        return {
            "pc": old_pc,
            "instruction": instruction,
            "rd": rd,
            "result": result,
            "reg_write": reg_write,
            "operation": operation,
        }

    def run(self, program: list[int]) -> list[dict[str, int | bool]]:
        return [self.step(instruction) for instruction in program]


def encode_rtype(funct7: int, rs2: int, rs1: int, funct3: int, rd: int) -> int:
    return u32((funct7 << 25) | (rs2 << 20) | (rs1 << 15) |
               (funct3 << 12) | (rd << 7) | OP_RTYPE)


def encode_addi(rd: int, rs1: int, immediate: int) -> int:
    return u32(((immediate & 0xFFF) << 20) | (rs1 << 15) | (rd << 7) | OP_ITYPE)


def directed_program() -> list[int]:
    """Return the same directed sequence used by the RTL CPU testbench."""
    return [
        0x00A00093,  # ADDI x1, x0, 10
        0x01400113,  # ADDI x2, x0, 20
        0x002081B3,  # ADD  x3, x1, x2
        0x40118233,  # SUB  x4, x3, x1
        0x0020F2B3,  # AND  x5, x1, x2
        0x0020E333,  # OR   x6, x1, x2
        0x0020C3B3,  # XOR  x7, x1, x2
        0x07B00413,  # ADDI x8, x0, 123
        0x00209433,  # unsupported R-type
        0x00141413,  # unsupported I-type
    ]
