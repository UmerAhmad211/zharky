const std = @import("std");

pub fn tgELF(encodings: *std.ArrayList(u8)) void {
    // e_indent => magic numbers
    encodings.append(0x7F);
    encodings.append(0x45); // 'E'
    encodings.append(0x4C); // 'L'
    encodings.append(0x46); // 'F'
    encodings.append(1); // 32 bit
    encodings.append(1); // little endian
    encodings.append(1); // ELF version
    encodings.append(0); // OS_ABI SYSV
    encodings.append(0); // OS_ABI version
    // PAD
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // e_type => TYPE: EXECUTABLE
    encodings.append(2);
    encodings.append(0);
    // e_machine => i386
    encodings.append(3);
    encodings.append(0);
    // e_version
    encodings.append(1);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // e_entry
    encodings.append(0);
    encodings.append(90);
    encodings.append(4);
    encodings.append(8);
    // e_phoff prgram header tables file offset
    encodings.append(0x34);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // e_shoff section header tables file offset
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // e_flags
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // e_hsize ELF headers size
    encodings.append(0x34);
    encodings.append(0);
    // e_phentsize size of one entry in file program header
    encodings.append(0x20);
    encodings.append(0);
    // e_phnum
    encodings.append(2);
    encodings.append(0);
    // e_shentsize
    encodings.append(0x28);
    encodings.append(0);
    // e_shnum
    encodings.append(0);
    encodings.append(0);
    // e_shstrndx
    encodings.append(0);
    encodings.append(0);

    //
    // program headers
    //
    // Code segment
    // p_type
    encodings.append(0x01);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_offset
    // ELF_header = 52 bytes, 2 program headers = 2 x 32 bytes
    encodings.append(0x74);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_vaddr
    // save space, calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_padder
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_filesz
    // save space, calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_memsz
    // save space, calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_flags
    encodings.append(0x05);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_align
    // calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);

    // data segment
    // p_type
    encodings.append(0x01);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_offset
    // ELF_header = 52 bytes + 2 program headers = 2 x 32 bytes + size of .text
    // calculated at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_vaddr
    // save space, calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_padder
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_filesz
    // save space, calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_memsz
    // save space, calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_flags
    encodings.append(0x06);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    // p_align
    // calculate at runtime
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
    encodings.append(0);
}
