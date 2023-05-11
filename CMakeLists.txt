cmake_minimum_required(VERSION 3.12)
cmake_policy(SET CMP0074 NEW)
project(lacpu)

# set environment variables for verilator
# remove if already install one
set(verilator_DIR "/home/blur/gits/verilator")
set(ENV{VERILATOR_ROOT} ${verilator_DIR})

find_package(verilator)

if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found.")
endif()

# set default top module as top file
set(VSRC ${CMAKE_SOURCE_DIR}/vsrc/top.v)

# get all cxx source files from cxxsrc
file(GLOB_RECURSE CXXSRC ${CMAKE_SOURCE_DIR}/cxxsrc/*.cc)

add_executable(${CMAKE_PROJECT_NAME} ${CXXSRC})

verilate(${CMAKE_PROJECT_NAME}
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/vsrc ${verilator_DIR}/include
  SOURCES ${VSRC})