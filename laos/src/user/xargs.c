#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>

void remove_tail_newline(char *str, int len) {
    if (len == 0) {
        return;
    }
    if (str[len - 1] == '\n') {
        str[len - 1] = '\0';
    }
}

int main(int argc, char *argv[]) {
    if (argc < 1) {
        exit(EXIT_FAILURE);
    }

    char **args = malloc(argc * sizeof(char *));
    memcpy(args, &argv[1], (argc - 1) * sizeof(char *));
    argc -= 1;

    const char *filename = argv[1];
    char input[128];
    read(STDIN_FILENO, input, 128);
    remove_tail_newline(input, strlen(input));

    char *tok = strtok(input, " ");
    while (tok) {
        if (*tok != '\n') {
            args = realloc(args, (argc + 1) * sizeof(char *));
            args[argc] = tok;
            argc += 1;
        }
        tok = strtok(NULL, " ");
    }

    if (fork() == 0) {
        execvp(filename, args);
        exit(EXIT_FAILURE);
    }

    wait(NULL);
    free(args);

    return 0;
}