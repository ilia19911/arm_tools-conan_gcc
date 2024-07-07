# GCC

Проект для сборки пакета GCC для conan. 
Автоматически собирает пакеты GCC и тулчейны для cmake.

Фичей является автоматический выбор работы fvp сопроцессора при передаче ARM_CPU

Возможные аргументы тулчейна

**ARM_CPU**

- Устанавливает конкретный процессор для которого будет происходить компиляция. Используется вместо ARM_ARCH ARM_TUNE ARM_FVP .Более приоритетный режим работы из-за более точной оптимизации. 

**ARM_ARCH**
- установка архитектуру процессора под который нужна компиляция. При использовании данного флага нужно так же указывать ARM_TUNE и ARM_FVP. Рекомендуется использовать ARM_CPU для лучшей оптимизации

**ARM_TUNE**
- Используется вместе с ARM_ARCH ARM_FVP. Указывает компилятору какой процессор должен исполнять код, но не включает hardware фичи. Рекомендуется использовать ARM_CPU

**ARM_FVP**
- Указывает флаги fvp сопроцессора в виде 
    
        "-mfloat-abi=hard -v  -mfpu=fpv4-sp-d16"

**GCC_VERBOSE**
- включает подробный вывод. Включается с помощью
    
       option(GCC_VERBOSE "Enable verbose GCC output" ON)

**ИСПОЛЬЗОВАНИЕ**

Запустить скрипт make_toolchains.py . Он просмотрит содержимое директории https://artifactory.local/artifactory/arm-tools/ (можно поменять переменную base_url)на наличие доступных тулчейнов arm-none-eabi aarch64-none-elf и прочего. 
Соберет для каждого библиотеку генерируя тулчейн нужным образом. После, пока что, руками добавить библиотеки на сервер. Если были другие попытки сборки, то можно удалить локальные библиотеки командой
    
    rm -r  /home/iahve/.conan2/p
командой 

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