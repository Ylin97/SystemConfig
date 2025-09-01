**MSVC编译时需要指定源文件编码为 utf-8**。CMake编译是可以通过下面的配置设置：

```cmake
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /utf-8)
endif()
```
