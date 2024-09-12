# COMMON

The project is designed for generating GCC packages within the Conan framework, making it easier to manage ARM32 project builds (or any platform project as linux x86_64). It allows the development team to effortlessly use the same compiler across all members without configuring the build environment on each machine, and to easily switch between compilers as needed. Additionally, it enables building static libraries for a specific compiler release, ensuring reliable linking by avoiding ABI compatibility issues. It simplifies switching between build targets and testing the entire business logic on a PC using the proposed pattern for separating the lower and upper levels of the program. The project includes a CMake toolchain with pre-configured compilation flags (supporting both release and debug builds).

# ABSTRACT OVERVIEW
This package is part of the overall design of a custom build system based on Conan, CMake, GCC, GTest, CMSIS, HAL tools, and libraries. GCC is at the core of the build system, serving as the toolchain for building other packages. Conan provides mechanisms for distributing GCC toolchains with different options (host/target) alongside other binary packages, which is the core idea behind this.

When building the project, the required compiler version is specified in the Conan settings, and from there, all other dependencies built with the same compiler are automatically selected. This way, any project can be easily switched to different compiler versions simply by changing the Conan configuration.

The packages being built are wrappers for precompiled binary files of the compilers. To simplify the process of writing the package build script, it’s more convenient to gather all precompiled compilers in a single repository, organizing them into different folders corresponding to the compiler versions. After that, host and target can be determined by the specific names that GCC uses when creating binary files. The naming rules can be found in the script or will be described at the end of the file. It's convenient to use the same Artifactory repository that will be used for storing other binaries as the storage.

# REQUIREMENTS
- this package requires Python3 and some libraries (it's better to install specific libraries that your system requires)
- also you need installed conan client. how to do it you can find here https://conan.io/downloads
- to build package you need to clone repository =) *git clone https://github.com/ilia19911/arm_tools-conan_gcc.git*
- It's important to have some network disk or something with web access where you keep toolchains, couse python scrypt conanfile.py will try to find specific format of archive and sha256asc.txt files there. Or, you can just use mine as written in the script 


# BUILD


**ARM_CPU**

- Устанавливает конкретный процессор для которого будет происходить компиляция. Используется вместо ARM_ARCH ARM_TUNE ARM_FVP .Более приоритетный режим работы из-за более точной оптимизации. 

**ARM_ARCH**
- установка архитектуру процессора под который нужна компиляция. При использовании данного флага нужно так же указывать ARM_TUNE и ARM_FVP. Рекомендуется использовать ARM_CPU для лучшей оптимизации

**ARM_TUNE**
- Используется вместе с ARM_ARCH ARM_FVP. Указывает компилятору какой процессор должен исполнять код, но не включает hardware фичи. Рекомендуется использовать ARM_CPU

**ARM_FVP**
- Указывает флаги fvp сопроцессора в виде 
    
  ```
  -mfloat-abi=hard -v  -mfpu=fpv4-sp-d16
  ```

**GCC_VERBOSE**
- включает подробный вывод. Включается с помощью
    
       option(GCC_VERBOSE "Enable verbose GCC output" ON)

**ИСПОЛЬЗОВАНИЕ**

Запустить скрипт make_toolchains.py . Он просмотрит содержимое директории https://artifactory.local/artifactory/arm-tools/ (можно поменять переменную base_url)на наличие доступных тулчейнов arm-none-eabi aarch64-none-elf и прочего. 
Соберет для каждого библиотеку генерируя тулчейн нужным образом. После, пока что, руками добавить библиотеки на сервер. Если были другие попытки сборки, то можно удалить локальные библиотеки командой
    
    rm -r  /home/iahve/.conan2/p
командой 

    conan upload arm-gcc/* -r arm-gcc

если пока репо артифактория не добавлен, то добавить командой

    conan remote add arm-gcc http://192.168.71.113:8081/artifactory/api/conan/arm-gcc

URL может поменяться, узнавать у, типа "devops" разрабов 

Тулчейн имеет краткий вывод по установленным режимам работы компилятора и флагам в виде

    -- CMAKE_SYSTEM_NAME: Generic
    -- CMAKE_SYSTEM_PROCESSOR: arm
    -- CMAKE_CROSSCOMPILING: TRUE
    -- CMAKE_C_FLAGS: -Wall -ffunction-sections -fdata-sections  -specs=nano.specs -specs=nosys.specs -mthumb  -mfpu=auto -mfloat-abi=hard -mcpu=cortex-m7
    -- CMAKE_CXX_FLAGS: -Wall -ffunction-sections -fdata-sections  -specs=nano.specs -specs=nosys.specs -mthumb  -mfpu=auto -mfloat-abi=hard -mcpu=cortex-m7
    -- CMAKE_ASM_FLAGS:   -mfpu=auto -mfloat-abi=hard -mcpu=cortex-m7
    -- CMAKE_EXE_LINKER_FLAGS: -Wl,--gc-sections -Wl,--print-memory-usage -Wl,-V -Wl,--cref  -specs=nano.specs -specs=nosys.specs  -mfpu=auto -mfloat-abi=hard -mcpu=cortex-m7
    -- GCC_VERBOSE:

документация по версии GCC 13.2.rel1 
https://developer.arm.com/documentation/109845/latest/

Документация по опциям GCC
https://gcc.gnu.org/onlinedocs/gcc-13.2.0/gcc/ARM-Options.html

Документация по conan
https://docs.conan.io/2/reference/
