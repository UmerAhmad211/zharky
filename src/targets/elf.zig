const std = @import("std");

pub fn tgELF32(encodings: *std.ArrayList(u8)) !void {
    // e_indent => magic numbers
    try encodings.append(0x7F);
    try encodings.append(0x45); // 'E'
    try encodings.append(0x4C); // 'L'
    try encodings.append(0x46); // 'F'
    try encodings.append(1); // 32 bit
    try encodings.append(1); // little endian
    try encodings.append(1); // ELF version
    try encodings.append(0); // OS_ABI SYSV
    try encodings.append(0); // OS_ABI version
    // PAD
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // e_type => TYPE: EXECUTABLE
    try encodings.append(2);
    try encodings.append(0);
    // e_machine => i386
    try encodings.append(3);
    try encodings.append(0);
    // e_version
    try encodings.append(1);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // e_entry
    try encodings.append(0);
    try encodings.append(0x80);
    try encodings.append(4);
    try encodings.append(8);
    // e_phoff prgram header tables file offset
    try encodings.append(0x34);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // e_shoff section header tables file offset
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // e_flags
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // e_hsize ELF headers size
    try encodings.append(0x34);
    try encodings.append(0);
    // e_phentsize size of one entry in file program header
    try encodings.append(0x20);
    try encodings.append(0);
    // e_phnum
    try encodings.append(2);
    try encodings.append(0);
    // e_shentsize
    try encodings.append(0);
    try encodings.append(0);
    // e_shnum
    try encodings.append(0);
    try encodings.append(0);
    // e_shstrndx
    try encodings.append(0);
    try encodings.append(0);

    //
    // program headers
    //
    // Code segment
    // p_type
    try encodings.append(0x01);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_offset
    // ELF_header = 52 bytes +  2 program headers = 2 x 32 bytes
    try encodings.append(0x74);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_vaddr
    // save space, calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_padder
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_filesz
    // save space, calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_memsz
    // save space, calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_flags
    try encodings.append(0x05);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_align
    // calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);

    // data segment
    // p_type
    try encodings.append(0x01);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_offset
    // ELF_header = 52 bytes + 2 program headers = (52 + (2 x 32)) bytes
    // calculated at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_vaddr
    // save space, calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_padder
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_filesz
    // save space, calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_memsz
    // save space, calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_flags
    try encodings.append(0x06);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    // p_align
    // calculate at runtime
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
    try encodings.append(0);
}
