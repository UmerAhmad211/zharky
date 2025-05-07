const std = @import("std");

pub fn tgELF32(header: *std.ArrayList(u8)) !void {
    // e_indent => magic numbers
    try header.append(0x7F);
    try header.append(0x45); // 'E'
    try header.append(0x4C); // 'L'
    try header.append(0x46); // 'F'
    try header.append(1); // 32 bit
    try header.append(1); // little endian
    try header.append(1); // ELF version
    try header.append(0); // OS_ABI SYSV
    try header.append(0); // OS_ABI version
    // PAD
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // e_type => TYPE: EXECUTABLE
    try header.append(2);
    try header.append(0);
    // e_machine => i386
    try header.append(3);
    try header.append(0);
    // e_version
    try header.append(1);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // e_entry
    try header.append(0);
    try header.append(0x90);
    try header.append(4);
    try header.append(8);
    // e_phoff prgram header tables file offset
    try header.append(0x34);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // e_shoff section header tables file offset
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // e_flags
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // e_hsize ELF headers size
    try header.append(0x34);
    try header.append(0);
    // e_phentsize size of one entry in file program header
    try header.append(0x20);
    try header.append(0);
    // e_phnum
    try header.append(2);
    try header.append(0);
    // e_shentsize
    try header.append(0);
    try header.append(0);
    // e_shnum
    try header.append(0);
    try header.append(0);
    // e_shstrndx
    try header.append(0);
    try header.append(0);

    //
    // program headers
    //
    // Code segment
    // p_type
    try header.append(0x01);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_offset
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_vaddr
    try header.append(0);
    try header.append(0x80);
    try header.append(4);
    try header.append(8);
    // p_padder
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_filesz
    // save space, calculate at runtime
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_memsz
    // save space, calculate at runtime
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_flags
    try header.append(0x05);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_align
    try header.append(0);
    try header.append(0x10);
    try header.append(0);
    try header.append(0);

    // data segment
    // p_type
    try header.append(0x01);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_offset
    // ELF_header = 52 bytes + 2 program headers = (52 + (2 x 32)) bytes
    // calculated at runtime
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_vaddr
    // save space, calculate at runtime
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_padder
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_filesz
    // save space, calculate at runtime
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_memsz
    // save space, calculate at runtime
    try header.append(0);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_flags
    try header.append(0x06);
    try header.append(0);
    try header.append(0);
    try header.append(0);
    // p_align
    try header.append(0);
    try header.append(0x10);
    try header.append(0);
    try header.append(0);
}

pub fn updateELF(header: *std.ArrayList(u8), text_len: u32, data_len: u32, data_offset: u32) void {
    // filesz and memsz
    const filesz = text_len + 0x1000;
    header.*.items[68] += @intCast(filesz & 0xFF);
    header.*.items[69] += @intCast((filesz >> 8) & 0xFF);
    header.*.items[70] += @intCast((filesz >> 16) & 0xFF);
    header.*.items[71] += @intCast((filesz >> 24) & 0xFF);

    header.*.items[72] += @intCast(filesz & 0xFF);
    header.*.items[73] += @intCast((filesz >> 8) & 0xFF);
    header.*.items[74] += @intCast((filesz >> 16) & 0xFF);
    header.*.items[75] += @intCast((filesz >> 24) & 0xFF);

    // offset data
    header.*.items[88] += @intCast(data_offset & 0xFF);
    header.*.items[89] += @intCast((data_offset >> 8) & 0xFF);
    header.*.items[90] += @intCast((data_offset >> 16) & 0xFF);
    header.*.items[91] += @intCast((data_offset >> 24) & 0xFF);

    // p_vaddr
    const data_addr = data_offset + 0x08048000;
    header.*.items[92] += @intCast(data_addr & 0xFF);
    header.*.items[93] += @intCast((data_addr >> 8) & 0xFF);
    header.*.items[94] += @intCast((data_addr >> 16) & 0xFF);
    header.*.items[95] += @intCast((data_addr >> 24) & 0xFF);

    // filesz and memsz for data
    header.*.items[100] += @intCast(data_len & 0xFF);
    header.*.items[101] += @intCast((data_len >> 8) & 0xFF);
    header.*.items[102] += @intCast((data_len >> 16) & 0xFF);
    header.*.items[103] += @intCast((data_len >> 24) & 0xFF);

    header.*.items[104] += @intCast(data_len & 0xFF);
    header.*.items[105] += @intCast((data_len >> 8) & 0xFF);
    header.*.items[106] += @intCast((data_len >> 16) & 0xFF);
    header.*.items[107] += @intCast((data_len >> 24) & 0xFF);
}
