const std = @import("std");
const ut = @import("../util.zig");
const ELF_HDR_SZ = ut.ELF_HDR_SZ;

pub fn tgELF32() [ELF_HDR_SZ]u8 {
    var header: [ELF_HDR_SZ]u8 = undefined;
    // e_indent => magic numbers
    header[0] = (0x7F);
    header[1] = (0x45); // 'E'
    header[2] = (0x4C); // 'L'
    header[3] = (0x46); // 'F'
    header[4] = (1); // 32 bit
    header[5] = (1); // little endian
    header[6] = (1); // ELF version
    header[7] = (0); // OS_ABI SYSV
    header[8] = (0); // OS_ABI version
    // PAD
    header[9] = (0);
    header[10] = (0);
    header[11] = (0);
    header[12] = (0);
    header[13] = (0);
    header[14] = (0);
    header[15] = (0);
    // e_type => TYPE: EXECUTABLE
    header[16] = (2);
    header[17] = (0);
    // e_machine => i386
    header[18] = (3);
    header[19] = (0);
    // e_version
    header[20] = (1);
    header[21] = (0);
    header[22] = (0);
    header[23] = (0);
    // e_entry
    header[24] = (0);
    header[25] = (0x90);
    header[26] = (4);
    header[27] = (8);
    // e_phoff prgram header tables file offset
    header[28] = (0x34);
    header[29] = (0);
    header[30] = (0);
    header[31] = (0);
    // e_shoff section header tables file offset
    header[32] = (0);
    header[33] = (0);
    header[34] = (0);
    header[35] = (0);
    // e_flags
    header[36] = (0);
    header[37] = (0);
    header[38] = (0);
    header[39] = (0);
    // e_hsize ELF headers size
    header[40] = (0x34);
    header[41] = (0);
    // e_phentsize size of one entry in file program header
    header[42] = (0x20);
    header[43] = (0);
    // e_phnum
    header[44] = (2);
    header[45] = (0);
    // e_shentsize
    header[46] = (0);
    header[47] = (0);
    // e_shnum
    header[48] = (0);
    header[49] = (0);
    // e_shstrndx
    header[50] = (0);
    header[51] = (0);

    //
    // program headers
    //
    // Code segment
    // p_type
    header[52] = (0x01);
    header[53] = (0);
    header[54] = (0);
    header[55] = (0);
    // p_offset
    header[56] = (0);
    header[57] = (0);
    header[58] = (0);
    header[59] = (0);
    // p_vaddr
    header[60] = (0);
    header[61] = (0x80);
    header[62] = (4);
    header[63] = (8);
    // p_padder
    header[64] = (0);
    header[65] = (0);
    header[66] = (0);
    header[67] = (0);
    // p_filesz
    // save space, calculate at runtime
    header[68] = (0);
    header[69] = (0);
    header[70] = (0);
    header[71] = (0);
    // p_memsz
    // save space, calculate at runtime
    header[72] = (0);
    header[73] = (0);
    header[74] = (0);
    header[75] = (0);
    // p_flags
    header[76] = (0x05);
    header[77] = (0);
    header[78] = (0);
    header[79] = (0);
    // p_align
    header[80] = (0);
    header[81] = (0x10);
    header[82] = (0);
    header[83] = (0);

    // data segment
    // p_type
    header[84] = (0x01);
    header[85] = (0);
    header[86] = (0);
    header[87] = (0);
    // p_offset
    // ELF_header = 52 bytes + 2 program headers = (52 + (2 x 32)) bytes
    // calculated at runtime
    header[88] = (0);
    header[89] = (0);
    header[90] = (0);
    header[91] = (0);
    // p_vaddr
    // save space, calculate at runtime
    header[92] = (0);
    header[93] = (0);
    header[94] = (0);
    header[95] = (0);
    // p_padder
    header[96] = (0);
    header[97] = (0);
    header[98] = (0);
    header[99] = (0);
    // p_filesz
    // save space, calculate at runtime
    header[100] = (0);
    header[101] = (0);
    header[102] = (0);
    header[103] = (0);
    // p_memsz
    // save space, calculate at runtime
    header[104] = (0);
    header[105] = (0);
    header[106] = (0);
    header[107] = (0);
    // p_flags
    header[108] = (0x06);
    header[109] = (0);
    header[110] = (0);
    header[111] = (0);
    // p_align
    header[112] = (0);
    header[113] = (0x10);
    header[114] = (0);
    header[115] = (0);

    return header;
}

pub fn updateELF(header: *[ELF_HDR_SZ]u8, text_len: u32, data_len: u32, data_offset: u32) void {
    // filesz and memsz
    const filesz = text_len + 0x1000;
    ut.updateFourConsecIndexes(&header.*, filesz, 68);
    ut.updateFourConsecIndexes(&header.*, filesz, 72);

    // offset data
    ut.updateFourConsecIndexes(&header.*, data_offset, 88);

    // p_vaddr
    const data_addr = data_offset + 0x08048000;
    ut.updateFourConsecIndexes(&header.*, data_addr, 92);

    // filesz and memsz for data
    ut.updateFourConsecIndexes(&header.*, data_len, 100);
    ut.updateFourConsecIndexes(&header.*, data_len, 104);
}
