# sbc31750\_loader
A ROM monitor for Dynex SBC31750 SBC, receive Intel HEX file.

给Dynex SBC31750 单板机配套的引导ROM，可以实现下载接收Intel HEX格式的目标码并运行。

目标码通过串口发送到单板机的串口2.

已经过时的工具，当时是为了给GCC－1750配套的，原版SBC31750的ROM接收的是LDM格式。通过这个工具接收GCC的Hex文件后，再经过迭代自举开发，用C语言编写了同样功能的高级版本，固化到ROM里，取代了本工具。

仅供参考。纪念一下2000年之前自己的工作。

CASM.EXE 是运行在DOS下的汇编器。

---- -----------
Yao Fei  姚飞 