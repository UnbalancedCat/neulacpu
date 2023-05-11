cmake_minimum_required(VERSION 3.12)
cmake_policy(SET CMP0074 NEW)
project(neula)

# 为 Verilator 设置环境变量
if(NOT DEFINED VERILATOR_ROOT)
  set(ENV{VERILATOR_ROOT} "/home/blur/gits/verilator")
endif()

# 设置编译器参数
if (${CMAKE_BUILD_TYPE} STREQUAL "Debug")
  message("Turn On Debugger")
  add_compile_options(-D DEBUG_MODE)
endif()

include_directories(${CMAKE_SOURCE_DIR}/include)

# ----- ----- 构建虚拟外设 ----- -----
set(LABUS labus)
set(LA_BUS_TARGET ${PROJECT_NAME}-bus)

# 包含头文件，以可以利用尖括号获取，辅助队友开发
include_directories(${CMAKE_SOURCE_DIR}/${LABUS}/include)

# 获取所有的 CXX 源文件
file(GLOB_RECURSE LABUS_SRC ${CMAKE_SOURCE_DIR}/${LABUS}/*.cc)

add_library(${LA_BUS_TARGET} ${LABUS_SRC})
link_libraries(${LA_BUS_TARGET})


# ----- ----- 构建虚拟处理器 ----- -----
set(LASIM lasim)
set(LA_SIM_TARGET ${PROJECT_NAME}-sim)

# 包含头文件，以可以利用尖括号获取，辅助队友开发
include_directories(${CMAKE_SOURCE_DIR}/${LASIM}/include)

# 获取所有的 CXX 源文件
file(GLOB_RECURSE LASIM_SRC ${CMAKE_SOURCE_DIR}/${LASIM}/*.cc)

add_executable(${LA_SIM_TARGET} ${LASIM_SRC})


# ----- ----- 构建操作系统 ----- -----
set(LAOS laos)
# add_custom_target(${LAOS} make build)


# ----- ----- 构建 Verilator 项目 ----- -----
set(LACPU lacpu)
set(LAVSIM lavsim)
set(LA_VSIM_TARGET ${PROJECT_NAME}-vsim)

include_directories(${verilator_DIR}/include)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})

if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found.")
endif()

# set default top module as top file
set(VSRC ${CMAKE_SOURCE_DIR}/${LACPU}/top.v)

# get all cxx source files from lavsim folder
file(GLOB_RECURSE LAVSIM_SRC ${CMAKE_SOURCE_DIR}/${LAVSIM}/*.cc)

add_executable(${LA_VSIM_TARGET} ${LAVSIM_SRC})

verilate(${LA_VSIM_TARGET}
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/${LACPU} ${VERILATOR_ROOT}/include
  SOURCES ${VSRC})