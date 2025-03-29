section .text
    global _start

_start:
    mov eax, 0x9D    
    mov ebx, eax    
    nop             
    mov ecx, 0x4C00     
    mov eax, 1         
    xor ebx, ebx      
    int 0x80          
