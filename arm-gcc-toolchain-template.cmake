#Тулчейн для использования в СТЦ БРЭО.
#документация по версии GCC 13.2.rel1 #https://developer.arm.com/documentation/109845/latest/
#Документация по опциям GCC https://gcc.gnu.org/onlinedocs/gcc-13.2.0/gcc/ARM-Options.html
SET(CMAKE_SYSTEM_NAME @SYSTEM@)
SET(CMAKE_SYSTEM_PROCESSOR @PROCESSOR@) #arm, x86, x86_64, aarch64
SET(CMAKE_CROSSCOMPILING @CROSSCOMPILING@)
SET(CMAKE_VERBOSE_MAKEFILE TRUE)
SET(CMAKE_C_COMPILER_ID "GNU")
SET(CMAKE_CXX_COMPILER_ID "GNU")
SET(CMAKE_ASM_COMPILER_ID "GNU")
SET(ASM_OPTIONS "-x assembler-with-cpp")
set(GCC ON)

if(GCC_VERBOSE)
    set(V "-v")
endif ()

if(CMAKE_CROSSCOMPILING)
    INCLUDE(CMakeForceCompiler)
    set(CMAKE_C_COMPILER_ID_RUN TRUE CACHE INTERNAL "to invoke work check of compiler")
    set(CMAKE_C_COMPILER_FORCED TRUE CACHE INTERNAL "to invoke work check of compiler")
    set(CMAKE_C_COMPILER_WORKS TRUE CACHE INTERNAL "to invoke work check of compiler")
    set(CMAKE_CXX_COMPILER_WORKS TRUE CACHE INTERNAL "to invoke work check of compiler")
    # Where is the target environment
    #SET(CMAKE_FIND_ROOT_PATH "${tools}")
    # Search for programs in the build host directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    # For libraries and headers in the target directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
else ()
    SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
    SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
    SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
endif ()

function(get_last_multi_lib mode)
    # Вызов arm-none-eabi-gcc для получения списка мультибиблиотек
    execute_process(
            COMMAND ${CMAKE_C_COMPILER} -mcpu=${ARM_CPU} -mfpu=auto -mfloat-abi=${mode} --print-multi-dir
            OUTPUT_VARIABLE MULTI_LIBS
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    # Разбиваем вывод по строкам
    string(REPLACE "/" ";" MULTI_LIBS_LIST "${MULTI_LIBS}")
    # Получаем последнюю строку после /
    list(GET MULTI_LIBS_LIST -1 mode)
    message("available mfloat_abi /: ${mode}")
    set(ABI_MODE ${mode} PARENT_SCOPE)
endfunction()


set(CMAKE_C_COMPILER @TOOLS_PATH@/bin/@TRIPLET@-gcc@PREFIX@)
set(CMAKE_CXX_COMPILER @TOOLS_PATH@/bin/@TRIPLET@-g++@PREFIX@)
SET(CMAKE_LINKER @TOOLS_PATH@/bin/@TRIPLET@-g++@PREFIX@)
SET(CMAKE_ASM_COMPILER @TOOLS_PATH@/bin/@TRIPLET@-gcc@PREFIX@)
SET(CMAKE_AR @TOOLS_PATH@/bin/@TRIPLET@-ar@PREFIX@)
SET(CMAKE_C_COMPILER_AR @TOOLS_PATH@/bin/@TRIPLET@-ar@PREFIX@)
SET(CMAKE_CXX_COMPILER_AR @TOOLS_PATH@/bin/@TRIPLET@-ar@PREFIX@)
SET(CMAKE_RANLIB @TOOLS_PATH@/bin/@TRIPLET@-ranlib@PREFIX@)
SET(CMAKE_OBJCOPY  @TOOLS_PATH@/bin/@TRIPLET@-objcopy@PREFIX@)
SET(CMAKE_OBJDUMP @TOOLS_PATH@/bin/@TRIPLET@-objdump@PREFIX@)
SET(CMAKE_SIZE @TOOLS_PATH@/bin/@TRIPLET@-size@PREFIX@)
SET(CMAKE_DEBUGER @TOOLS_PATH@/bin/@TRIPLET@-gdb@PREFIX@)
SET(CMAKE_CPPFILT @TOOLS_PATH@/bin/@TRIPLET@-c++filt@PREFIX@)

SET(CMAKE_NM @TOOLS_PATH@/bin/@TRIPLET@-nm@PREFIX@)
SET(CMAKE_STRIP @TOOLS_PATH@/bin/@TRIPLET@-strip@PREFIX@)
#set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_FILE})


SET(CMAKE_C_LINK_EXECUTABLE     "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
SET(CMAKE_CXX_LINK_EXECUTABLE   "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
SET(CMAKE_C_OUTPUT_EXTENSION    .o)
SET(CMAKE_CXX_OUTPUT_EXTENSION  .o)
SET(CMAKE_ASM_OUTPUT_EXTENSION  .o)
# When library defined as STATIC, this line is needed to describe how the .a file must be
# create. Some changes to the line may be needed.
SET(CMAKE_C_CREATE_STATIC_LIBRARY   "<CMAKE_AR> -crs <TARGET> <LINK_FLAGS> <OBJECTS>" )
SET(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> -crs <TARGET> <LINK_FLAGS> <OBJECTS>" )

set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -std=gnu11"  CACHE INTERNAL "c compiler flags ")
#common release or debbug flags
SET(CMAKE_C_FLAGS_DEBUG             "-Og -g -gdwarf-2"  CACHE INTERNAL "c compiler flags debug")
SET(CMAKE_CXX_FLAGS_DEBUG           "-Og -g -gdwarf-2"  CACHE INTERNAL "cxx compiler flags debug")
SET(CMAKE_ASM_FLAGS_DEBUG           "-g"                CACHE INTERNAL "asm compiler flags debug")
SET(CMAKE_EXE_LINKER_FLAGS_DEBUG    ""                  CACHE INTERNAL "linker flags debug")
SET(CMAKE_C_FLAGS_RELEASE           " -Ofast"         CACHE INTERNAL "c compiler flags release")
SET(CMAKE_CXX_FLAGS_RELEASE         " -Ofast"         CACHE INTERNAL "cxx compiler flags release")
SET(CMAKE_ASM_FLAGS_RELEASE         ""                  CACHE INTERNAL "asm compiler flags release")
SET(CMAKE_EXE_LINKER_FLAGS_RELEASE  "-flto"             CACHE INTERNAL "linker flags release")

#cmake не находит стандартные библиотеки при билде под windows-windows . Не очень правильное решение, но пока лучше не нашел
if(NOT CMAKE_SYSTEM_PROCESSOR  STREQUAL arm )
#    set(GCC_LIBRARY_PATHS "-L@TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@")
endif ()

set(GCC_LINKER_FLAGS "${GCC_LIBRARY_PATHS} -Wl,--gc-sections -Wl,--print-memory-usage -Wl,-V -Wl,--cref ${V}")
SET(GCC_COMPILE_FLAGS "${GCC_LIBRARY_PATHS} -Wall -fomit-frame-pointer -ffunction-sections -fdata-sections ${V}")
SET(GCC_ASM_COMPILE_FLAGS "${V}")
set(GCC_SYSTEM_INCLUDE
#        @TOOLS_PATH@/lib
#        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include/c++
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include/c++/@TRIPLET@
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include-fixed
        @TOOLS_PATH@/@TRIPLET@/include CACHE STRING "include gcc files")

include_directories( ${GCC_SYSTEM_INCLUDE})

if(CMAKE_SYSTEM_PROCESSOR STREQUAL arm )
    set(GCC_COMPILE_FLAGS "${GCC_COMPILE_FLAGS} -mthumb  -masm-syntax-unified ")
    set(GCC_LINKER_FLAGS "${GCC_LINKER_FLAGS}  ")
    SET(CMAKE_EXE_LINKER_FLAGS_DEBUG    "${CMAKE_EXE_LINKER_FLAGS_DEBUG} --specs=rdimon.specs"                  CACHE INTERNAL "linker flags debug")
    # дополнительное описание переопределения стандартного ввода и вывода --specs=rdimon.specs и прочее
    #https://developer.arm.com/documentation/109845/latest/
endif ()

set(CMAKE_C_FLAGS   "${GCC_COMPILE_FLAGS} -std=gnu11"  CACHE INTERNAL "c compiler flags ")
set(CMAKE_CXX_FLAGS "${GCC_COMPILE_FLAGS} "  CACHE INTERNAL "cpp compiler flags ")
SET(CMAKE_ASM_FLAGS "${GCC_ASM_COMPILE_FLAGS}" CACHE INTERNAL "ASM compiler common flags")
SET(CMAKE_EXE_LINKER_FLAGS "${GCC_LINKER_FLAGS} "  CACHE INTERNAL "linker flags")
#set(CMAKE_STATIC_LINKER_FLAGS "${GCC_LINKER_FLAGS} "  CACHE INTERNAL "linker flags")

#СПЕЦИАЛЬНЫЕ ФЛАГИ КОМПИЛЯЦИИ ARM: -mtune -march -mcpu .
#-mcpu имеет меньший приоритет для компилятора (но более приоритетен в использовании) и будет переписан флагами -mtune и -march
# следует использовать либо -mcpu, либо -march + -mtune но никак не вместе, иначе оптимизация не будет применена или будет непредсказуемой
# -mcpu точно говорит компилятору под какой процессор надо оптимизировать, тогда как -march + -mtune будут давать приближенный, но возможно не точный результат оптимизации
# информация по теме https://community.arm.com/arm-community-blogs/b/tools-software-ides-blog/posts/compiler-flags-across-architectures-march-mtune-and-mcpu
function(MAKE_GCC_INTERFACE NAME ARM_CPU)
    set(SPECIFIC_PLATFORM_FLAGS "")
    #    message(STATUS "You use ARM_CPU and it's perfect!")
    set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfpu=auto")
    #    set(ABI_MODE hard)
    get_last_multi_lib("hard")
    if(ABI_MODE STREQUAL hard)
        set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfloat-abi=hard")
    else ()
        #        set(ABI_MODE soft)
        get_last_multi_lib("soft")
        if(ABI_MODE STREQUAL soft OR ABI_MODE STREQUAL nofp )
            set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfloat-abi=soft")
        else ()
            message(FATAL_ERROR "Wrong processor name ${ARM_CPU}")
        endif ()
    endif ()
    SET(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mcpu=${ARM_CPU}")

    add_library(${NAME} INTERFACE)
    string(REPLACE " " ";" SPECIFIC_PLATFORM_FLAGS_LIST "${SPECIFIC_PLATFORM_FLAGS}")

    target_compile_options(${NAME} INTERFACE $<$<COMPILE_LANGUAGE:C>: ${SPECIFIC_PLATFORM_FLAGS_LIST}>)
    # Устанавливаем флаги для C++ кода
    target_compile_options(${NAME} INTERFACE $<$<COMPILE_LANGUAGE:CXX>: ${SPECIFIC_PLATFORM_FLAGS_LIST}>)
    # Устанавливаем флаги для ASM кода
    target_compile_options(${NAME} INTERFACE $<$<COMPILE_LANGUAGE:ASM>: ${SPECIFIC_PLATFORM_FLAGS_LIST}>)
    # Устанавливаем флаги для линкера
    target_link_options(${NAME} INTERFACE ${SPECIFIC_PLATFORM_FLAGS_LIST})


endfunction()

function(ADD_GLOB_COMPILE_OPTIONS ARM_CPU)
    set(SPECIFIC_PLATFORM_FLAGS "")
    #    message(STATUS "You use ARM_CPU and it's perfect!")
    set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfpu=auto")
    #    set(ABI_MODE hard)
    get_last_multi_lib("hard")
    if(ABI_MODE STREQUAL hard)
        set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfloat-abi=hard")
    else ()
        #        set(ABI_MODE soft)
        get_last_multi_lib("soft")
        if(ABI_MODE STREQUAL soft OR ABI_MODE STREQUAL nofp )
            set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfloat-abi=soft")
        else ()
            message(FATAL_ERROR "Wrong processor name ${ARM_CPU}")
        endif ()
    endif ()
    SET(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mcpu=${ARM_CPU}")

    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} ${SPECIFIC_PLATFORM_FLAGS} -std=gnu11"  PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SPECIFIC_PLATFORM_FLAGS} "  PARENT_SCOPE)
    SET(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${SPECIFIC_PLATFORM_FLAGS}" PARENT_SCOPE)
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${SPECIFIC_PLATFORM_FLAGS}"  PARENT_SCOPE)
    message("SPECIFIC_PLATFORM_FLAGS: " ${SPECIFIC_PLATFORM_FLAGS})

endfunction()

if(CMAKE_SYSTEM_PROCESSOR STREQUAL arm)
    MAKE_GCC_INTERFACE(CORTEX_M0 cortex-m0)
    MAKE_GCC_INTERFACE(CORTEX_M1 cortex-m1)
    MAKE_GCC_INTERFACE(CORTEX_M3 cortex-m3)
    MAKE_GCC_INTERFACE(CORTEX_M4 cortex-m4)
    MAKE_GCC_INTERFACE(CORTEX_M7 cortex-m7)

endif ()

#add_link_options("-Wl,--start-group")

MESSAGE(STATUS "CMAKE_SYSTEM_NAME: " ${CMAKE_SYSTEM_NAME})
MESSAGE(STATUS "CMAKE_SYSTEM_PROCESSOR: " ${CMAKE_SYSTEM_PROCESSOR})
MESSAGE(STATUS "CMAKE_CROSSCOMPILING: " ${CMAKE_CROSSCOMPILING})
MESSAGE(STATUS "CMAKE_C_FLAGS: " ${CMAKE_C_FLAGS})
MESSAGE(STATUS "CMAKE_CXX_FLAGS: " ${CMAKE_CXX_FLAGS})
MESSAGE(STATUS "CMAKE_ASM_FLAGS: " ${CMAKE_ASM_FLAGS})
MESSAGE(STATUS "CMAKE_EXE_LINKER_FLAGS: " ${CMAKE_EXE_LINKER_FLAGS})
MESSAGE(STATUS "GCC_VERBOSE: " ${GCC_VERBOSE})
MESSAGE(STATUS "CMAKE_TOOLCHAIN_FILE: " ${CMAKE_TOOLCHAIN_FILE})




FUNCTION(STM32_ADD_HEX_BIN_TARGETS TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
        SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
        SET(FILENAME "${TARGET}")
    ENDIF()
    ADD_CUSTOM_TARGET(${TARGET}.hex ALL DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -v -Oihex ${FILENAME} ${FILENAME}.hex)
    #    ADD_CUSTOM_TARGET(${TARGET}.he ALL DEPENDS ${TARGET} COMMAND ${CMAKE_HOOK} -Oihex ${FILENAME} ${FILENAME}.he)
    message(">>> STM32_ADD_HEX_BIN_TARGETS " ${TARGET})
    message(">>>  " ${CMAKE_OBJCOPY})
    message(">>>  " ${FILENAME})

    ADD_CUSTOM_TARGET(${TARGET}.bin ALL DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -v -Obinary ${FILENAME} ${FILENAME}.bin)
ENDFUNCTION()

FUNCTION(STM32_ADD_DUMP_TARGET TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
        SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
        SET(FILENAME "${TARGET}")
    ENDIF()

    message(">>> STM32_ADD_DUMP_TARGET " ${TARGET})
    message(">>>  " ${CMAKE_OBJDUMP})
    message(">>>  " ${FILENAME})


    ADD_CUSTOM_TARGET(${TARGET}.dump ALL DEPENDS ${TARGET} COMMAND ${CMAKE_OBJDUMP} -x -D -S -s ${FILENAME} | ${CMAKE_CPPFILT} > ${FILENAME}.dump)
ENDFUNCTION()

FUNCTION(STM32_PRINT_SIZE_OF_TARGETS TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
        SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
        SET(FILENAME "${TARGET}")
    ENDIF()
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_SIZE} ${FILENAME})
    #    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_HOOK} ${FILENAME})

    message(">>> STM32_PRINT_SIZE_OF_TARGETS " ${TARGET})
    message(">>>  " ${CMAKE_SIZE})
    message(">>>  " ${FILENAME})


ENDFUNCTION()
