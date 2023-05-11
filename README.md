# LoongArch CPU

龙芯处理器设计

## 文件组织建议

|文件夹名称|文件夹用处|
|-|-|
|lacpu          | 龙芯处理器设计 Verilog |
|lasim          | 龙芯模拟 软件模拟 C++ |
|lavsim         | 龙芯模拟 Verilator 模拟 |
|labus          | 龙芯虚拟外设 |
|laos           | 龙芯操作系统 |

除了 `lavsim` 和 `lacpu` 是在一起编译成一个文件，其余都会编译成单独的二进制文件

### lacpu

### lasim

`lasim` 模拟龙芯行为，主要用于操作系统的软件模拟，通过软件角度对龙芯的基本硬件特性进行模拟，以辅助操作系统设计。

### lavsim

`lavsim` 主要用于测试 Verilog 设计的正确性。

### labus

`labus` 模拟外设行为，主要用于设计虚拟外设以软件模拟外设行为是否正确。

### laos

`laos` 自主设计操作系统，会参考其他项目进行设计。