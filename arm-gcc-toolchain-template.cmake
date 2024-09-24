SET(CMAKE_SYSTEM_NAME @SYSTEM@)
SET(CMAKE_SYSTEM_PROCESSOR @PROCESSOR@) # arm, x86, x86_64, aarch64
SET(CMAKE_CROSSCOMPILING @CROSSCOMPILING@)
SET(CMAKE_VERBOSE_MAKEFILE TRUE)
SET(CMAKE_C_COMPILER_ID "GNU")
SET(CMAKE_CXX_COMPILER_ID "GNU")
SET(CMAKE_ASM_COMPILER_ID "GNU")
SET(ASM_OPTIONS "-x assembler-with-cpp")
set(GCC ON)

if(GCC_VERBOSE)
    set(V "-v")
endif()

if(CMAKE_CROSSCOMPILING)
    INCLUDE(CMakeForceCompiler)
    set(CMAKE_C_COMPILER_ID_RUN TRUE CACHE INTERNAL "to invoke work check of compiler")
    set(CMAKE_C_COMPILER_FORCED TRUE CACHE INTERNAL "to invoke work check of compiler")
    set(CMAKE_C_COMPILER_WORKS TRUE CACHE INTERNAL "to invoke work check of compiler")
    set(CMAKE_CXX_COMPILER_WORKS TRUE CACHE INTERNAL "to invoke work check of compiler")
    # Where is the target environment
    #SET(CMAKE_FIND_ROOT_PATH "${tools}")
    # Search for programs in the build host directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER CACHE INTERNAL "")
    # For libraries and headers in the target directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY CACHE INTERNAL "")
    SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY CACHE INTERNAL "")
    SET(CMAKE_C_OUTPUT_EXTENSION .o CACHE INTERNAL "")
    SET(CMAKE_CXX_OUTPUT_EXTENSION .o CACHE INTERNAL "")
    SET(CMAKE_ASM_OUTPUT_EXTENSION .o CACHE INTERNAL "")
else()
    SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH CACHE INTERNAL "")
    SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH CACHE INTERNAL "")
    SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH CACHE INTERNAL "")
endif()

function(get_last_multi_lib mode)
    # Call arm-none-eabi-gcc to get a list of multi-libraries
    execute_process(
            COMMAND ${CMAKE_C_COMPILER} -mcpu=${ARM_CPU} -mfpu=auto -mfloat-abi=${mode} --print-multi-dir
            OUTPUT_VARIABLE MULTI_LIBS
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    # Split the output by lines
    string(REPLACE "/" ";" MULTI_LIBS_LIST "${MULTI_LIBS}")
    # Get the last line after "/"
    list(GET MULTI_LIBS_LIST -1 mode)
    message("available mfloat_abi /: ${mode}")
    set(ABI_MODE ${mode} PARENT_SCOPE)
endfunction()

set(CMAKE_C_COMPILER @TOOLS_PATH@/bin/@TRIPLET@-gcc@PREFIX@ CACHE INTERNAL "")
set(CMAKE_CXX_COMPILER @TOOLS_PATH@/bin/@TRIPLET@-g++@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_LINKER @TOOLS_PATH@/bin/@TRIPLET@-g++@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_ASM_COMPILER @TOOLS_PATH@/bin/@TRIPLET@-gcc@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_AR @TOOLS_PATH@/bin/@TRIPLET@-ar@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_C_COMPILER_AR @TOOLS_PATH@/bin/@TRIPLET@-ar@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_CXX_COMPILER_AR @TOOLS_PATH@/bin/@TRIPLET@-ar@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_RANLIB @TOOLS_PATH@/bin/@TRIPLET@-ranlib@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_OBJCOPY @TOOLS_PATH@/bin/@TRIPLET@-objcopy@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_OBJDUMP @TOOLS_PATH@/bin/@TRIPLET@-objdump@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_SIZE @TOOLS_PATH@/bin/@TRIPLET@-size@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_DEBUGER @TOOLS_PATH@/bin/@TRIPLET@-gdb@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_CPPFILT @TOOLS_PATH@/bin/@TRIPLET@-c++filt@PREFIX@ CACHE INTERNAL "")

SET(CMAKE_NM @TOOLS_PATH@/bin/@TRIPLET@-nm@PREFIX@ CACHE INTERNAL "")
SET(CMAKE_STRIP @TOOLS_PATH@/bin/@TRIPLET@-strip@PREFIX@ CACHE INTERNAL "")
#set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_FILE})

SET(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>" CACHE INTERNAL "")
SET(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>" CACHE INTERNAL "")

# When the library is defined as STATIC, this line describes how the .a file must be created.
# Some changes may be needed.
SET(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> -crs <TARGET> <LINK_FLAGS> <OBJECTS>" CACHE INTERNAL "")
SET(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> -crs <TARGET> <LINK_FLAGS> <OBJECTS>" CACHE INTERNAL "")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu11" CACHE INTERNAL "c compiler flags")
# Common release or debug flags
SET(CMAKE_C_FLAGS_DEBUG "-Og -g -gdwarf-2" CACHE INTERNAL "c compiler flags debug")
SET(CMAKE_CXX_FLAGS_DEBUG "-Og -g -gdwarf-2" CACHE INTERNAL "cxx compiler flags debug")
SET(CMAKE_ASM_FLAGS_DEBUG "-g" CACHE INTERNAL "asm compiler flags debug")
SET(CMAKE_EXE_LINKER_FLAGS_DEBUG "" CACHE INTERNAL "linker flags debug")
SET(CMAKE_C_FLAGS_RELEASE " -Ofast" CACHE INTERNAL "c compiler flags release")
SET(CMAKE_CXX_FLAGS_RELEASE " -Ofast" CACHE INTERNAL "cxx compiler flags release")
SET(CMAKE_ASM_FLAGS_RELEASE "" CACHE INTERNAL "asm compiler flags release")
SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "-flto" CACHE INTERNAL "linker flags release")

# CMake does not find standard libraries when building under windows-windows.
# This is not a perfect solution, but it works for now.
if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL arm)
    #    set(GCC_LIBRARY_PATHS "-L@TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL Generic)
    set(GCC_LINKER_FLAGS "${GCC_LIBRARY_PATHS} -Wl,-V -Wl,--cref -Wl,--gc-sections -Wl,--print-memory-usage ")
    SET(GCC_COMPILE_FLAGS "${GCC_LIBRARY_PATHS} -fomit-frame-pointer -ffunction-sections -fdata-sections")
endif ()
set(GCC_LINKER_FLAGS "${GCC_LIBRARY_PATHS}  ${V}")
SET(GCC_COMPILE_FLAGS "${GCC_LIBRARY_PATHS} -Wall ${V}")
SET(GCC_ASM_COMPILE_FLAGS "${V}")
set(GCC_SYSTEM_INCLUDE
        #        @TOOLS_PATH@/lib
        #        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include/c++
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include/c++/@TRIPLET@
        @TOOLS_PATH@/lib/gcc/@TRIPLET@/@VERSION@/include-fixed
        @TOOLS_PATH@/@TRIPLET@/include CACHE STRING "include gcc files")

include_directories(${GCC_SYSTEM_INCLUDE})
set(CMAKE_OSX_SYSROOT /doesn't/needed)

if(CMAKE_SYSTEM_NAME STREQUAL Generic)
    set(GCC_COMPILE_FLAGS "${GCC_COMPILE_FLAGS} -mthumb -masm-syntax-unified")
    set(GCC_LINKER_FLAGS "${GCC_LINKER_FLAGS}")
    SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} --specs=nosys.specs" CACHE INTERNAL "linker flags release")
    SET(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} --specs=rdimon.specs" CACHE INTERNAL "linker flags debug")
    # Additional description of overriding standard input and output --specs=rdimon.specs
    # https://developer.arm.com/documentation/109845/latest/
endif()

set(CMAKE_C_FLAGS "${GCC_COMPILE_FLAGS} -std=gnu11" CACHE INTERNAL "c compiler flags")
set(CMAKE_CXX_FLAGS "${GCC_COMPILE_FLAGS}" CACHE INTERNAL "cpp compiler flags")
SET(CMAKE_ASM_FLAGS "${GCC_ASM_COMPILE_FLAGS}" CACHE INTERNAL "ASM compiler common flags")
SET(CMAKE_EXE_LINKER_FLAGS "${GCC_LINKER_FLAGS}" CACHE INTERNAL "linker flags")
#set(CMAKE_STATIC_LINKER_FLAGS "${GCC_LINKER_FLAGS}" CACHE INTERNAL "linker flags")

# SPECIAL ARM COMPILATION FLAGS: -mtune -march -mcpu.
# -mcpu takes precedence for the compiler and will override -mtune and -march.
# You should use either -mcpu or -march + -mtune, but not both together.
# More information: https://community.arm.com/arm-community-blogs/b/tools-software-ides-blog/posts/compiler-flags-across-architectures-march-mtune-and-mcpu
function(MAKE_GCC_INTERFACE NAME ARM_CPU)
    set(SPECIFIC_PLATFORM_FLAGS "")
    #    message(STATUS "You use ARM_CPU and it's perfect!")
    set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfpu=auto")
    #    set(ABI_MODE hard)
    get_last_multi_lib("hard")
    if(ABI_MODE STREQUAL hard)
        set(SPECIFIC_PLATFORM_FLAGS "${SPECIFIC_PLATFORM_FLAGS} -mfloat-abi=hard")
    else()
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

if(CMAKE_SYSTEM_NAME STREQUAL Generic)
    MAKE_GCC_INTERFACE(CORTEX_M0 cortex-m0)
    MAKE_GCC_INTERFACE(CORTEX_M1 cortex-m1)
    MAKE_GCC_INTERFACE(CORTEX_M3 cortex-m3)
    MAKE_GCC_INTERFACE(CORTEX_M4 cortex-m4)
    MAKE_GCC_INTERFACE(CORTEX_M7 cortex-m7)

endif ()


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