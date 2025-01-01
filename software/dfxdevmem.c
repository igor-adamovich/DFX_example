/* vim: set syntax=cpp et ts=4 sw=4: */

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

const size_t page_size = 4096;
const unsigned int en_offset = 0x0;
const unsigned int dfx_offset = 0x1;
const useconds_t config_time = 50;

int main (int argc, char ** argv) {
    int opt;
    uint64_t bar = 0;
    const char * file_name = NULL;
    opterr = 0;
    while ((opt = getopt(argc, argv, "b:f:h")) != -1) {
        switch (opt) {
            case 'b':
                bar = strtoull(optarg, NULL, 0);
                break;
            case 'f':
                file_name = optarg;
                break;
            case 'h':
                printf("Usage: %s -b BAR [-f FILE] [-h]\n", argv[0]);
                return 0;
            default:
                fprintf(stderr, "Error: invalid option -%c\n", optopt);
                return -1;
        }
    }
    if (bar == 0) {
        fprintf(stderr, "Error: no BAR specified\n");
        return -1;
    }
    int devmem_fd = open("/dev/mem", O_RDWR);
    if (devmem_fd == 0) {
        fprintf(stderr, "Error: open '%s' failed: %s\n", "/dev/mem", strerror(errno));
        return -1;
    }
    void * addr = mmap(NULL, page_size, PROT_READ|PROT_WRITE, MAP_SHARED, devmem_fd, bar);
    if (addr == MAP_FAILED) {
        fprintf(stderr, "Error: mmap '%s' failed: %s\n", "/dev/mem", strerror(errno));
        close(devmem_fd);
        return -1;
    }
    if (file_name) {
        int file_fd = open(file_name, O_RDONLY);
        if (file_fd == -1) {
            fprintf(stderr, "Error: open '%s' failed: %s\n", file_name, strerror(errno));
            munmap(addr, page_size);
            close(devmem_fd);
            return -1;
        }
        ((volatile uint32_t *)addr)[en_offset] = 0;
        do {
            uint32_t data;
            ssize_t size = read(file_fd, &data, sizeof(data));
            if (size != sizeof(data)) {
                break;
            }
            ((volatile uint32_t *)addr)[dfx_offset] = data;
        } while (true);
        usleep(config_time);
        ((volatile uint32_t *)addr)[en_offset] = 1;
        close(file_fd);
    } else {
        uint32_t data = *(volatile uint32_t *)addr;
        printf("0x%08" PRIX32 "\n", data);
    }
    munmap(addr, page_size);
    close(devmem_fd);
    return 0;
}
