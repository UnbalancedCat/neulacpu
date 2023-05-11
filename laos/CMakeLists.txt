cmake_minimum_required(VERSION 3.12)

set(LA_OS_TARGET ${PROJECT_NAME}-os)

# get all cxx source files from lasim folder
file(GLOB_RECURSE LAOS_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.c)

add_executable(${LA_OS_TARGET} ${LAOS_SRC})