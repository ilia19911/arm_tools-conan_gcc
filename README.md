# Motivation

The motivation for creating this build system comes from the availability of all necessary tools for building ARM32 projects freely on the internet, but the lack of any satisfactory build system implementation. I believe that a build system should allow easy switching between compilers, separation of hardware logic from business logic, and support multiple versions of CMSIS HAL without needing to copy them into each project.

Additionally, CMSIS often does not include precompiled NN and DSP libraries, so these must be compiled manually. Many users search for alternative ways to integrate DSP files into their projects for various reasons (e.g., large binary size), even though DSP/Source/CMakeLists.txt contains clear build instructions. Moreover, CMSIS can be built for a PC, simplifying algorithm testing.

CMSIS provides driver interface descriptions in C, but today, writing embedded projects purely in C for STM32 is becoming less common due to increasing algorithmic complexity. It’s essential to adapt to modern development needs. Furthermore, the compiler flags required to reduce binary size and apply proper processor settings remain a mystery to many users.

If you disagree with any of my points or have resources to share, I welcome any feedback or constructive criticism.

# Common

This project is designed to generate GCC packages within the Conan framework, simplifying the management of ARM32 project builds (or any platform project, such as Linux x86_64). It allows development teams to easily use the same compiler across all members without configuring the build environment on each machine, and to switch between compilers as needed. Additionally, it enables building static libraries for specific compiler releases, ensuring reliable linking and avoiding ABI compatibility issues.

The system makes it easy to switch between build targets and test the entire business logic on a PC using a proposed pattern for separating lower and upper levels of the program. The project also includes a CMake toolchain with pre-configured compilation flags (supporting both release and debug builds).

# Abstract overwiev

This package is part of a custom build system based on Conan, CMake, GCC, GTest, CMSIS, HAL tools, and libraries. GCC is at the core of the build system, serving as the toolchain for building other packages. Conan provides mechanisms for distributing GCC toolchains with different options (host/target), which is the main idea behind this project.

When building the project, you specify the required compiler version in the Conan settings. From there, all other dependencies built with the same compiler are automatically selected. This makes it easy to switch any project to different compiler versions simply by adjusting the Conan configuration.

The packages built are wrappers for precompiled binary files of the compilers. To simplify the process of writing the package build script, it is more convenient to gather all precompiled compilers in a single repository and organize them into folders based on compiler versions. Host and target details can then be determined by the specific naming conventions used by GCC when creating binary files. Naming rules can be found in the script or described at the end of the file. Artifactory can be used as the storage repository for binaries.

# Requirements
- Python 3 and required libraries (install the necessary ones for your system)
- Conan client installed (find instructions at https://conan.io/downloads)
  
# Fast start

  To use the package, add my repository to the list of Conan repositories, and you will be able to find the required GCC version with the necessary host and target options.
  
  ```
  conan remote add arm-tools  https://artifactory.nextcloud-iahve.ru/artifactory/api/conan/arm-tools
  ```
  To list available packages, use the command:

  ```
  conan list gcc/*:* -r=arm-tools
  ```
  Example output:
```
  $ conan list gcc/*:* -r=arm-tools
Found 1 pkg/version recipes matching gcc/* in arm-tools
arm-tools
  gcc
    gcc/13.3
      revisions
        70168a8ad109f7132e7e8a931d269e1c (2024-09-12 15:25:54 UTC)
          packages
            1432f61c080191ad1acbfa4e73b6b1206cab3511
              info
                settings
                  arch: x86_64
                  os: Linux
                settings_target
                  arch: x86_64
                  os: Linux
            06031bd62fef38041d78c0f0dd7d1a8f8ac8251d
              info
                settings
                  arch: x86_64
                  os: Linux
                settings_target
                  arch: armv7
                  os: baremetal
```

# Private Artifactory

If you want to set up your own build system, you will need to install your own JFrog Artifactory server. This can be done by following the instructions at JFrog Open Source. I use the Community Edition because it’s free and supports C/C++ packages (which is all I need). After installation, you can either build packages or fetch my existing ones to your PC and upload them to your private Artifactory.



# How to use
 You can find an example in another repository of mine, where I use several packages and separate logic from hardware using C++ drivers. (To-do: Add repo link).
# Build
To build the package, clone the repository:  *git clone https://github.com/ilia19911/arm_tools-conan_gcc.git*

It's important to have a network disk or web-accessible location where you keep toolchains, as the Python script conanfile.py will try to locate archive files in a specific format and sha256asc.txt files. Alternatively, you can use my repository as written in the script.

Conan provides an easy way to create packages with conanfile.py. Just navigate to the root of the repo and run:

```
conan create .
```
This will build the package for your system. For STM32, we need to create specific host/target options, so I designed a format for creating packages. You can improve this if you have time.

Example command:
 ```
  export URL="https://artifactory.nextcloud-iahve.ru/artifactory/arm-gcc/gcc_13.3/AArch32%20bare-metal%20target%20%28arm-none-eabi%29/" && conan create . -s  arch=armv7 -s  os=baremetal -s  compiler=gcc -s  compiler.version=13 -s  compiler.libcxx=libstdc++11 -s  compiler.cppstd=gnu23 -s  build_type=Release  -s:b  arch=x86_64 -s:b  os=Linux -s:b  compiler=gcc -s:b  compiler.version=13 -s:b  compiler.libcxx=libstdc++11 -s:b  compiler.cppstd=gnu23 -s:b  build_type=Release  --version=13.3 --build-require
 ```
 - https://artifactory.nextcloud-iahve.ru/artifactory/arm-gcc/gcc_13.3/AArch32%20bare-metal%20target%20%28arm-none-eabi%29/ is location of binaries of gcc compiler
 - also you need to specify separate options for host and targe where -s is for host and s:b for target
   
if you need linux native compiler package, you can use something like
 ```
export URL='https://artifactory.nextcloud-iahve.ru/artifactory/arm-gcc/gcc_13.3/linux_x86_native/' && conan create . -s  arch=x86_64 -s  os=Linux -s  compiler=gcc -s  compiler.version=13 -s  compiler.libcxx=libstdc++11 -s  compiler.cppstd=gnu23 -s  build_type=Release  -s:b  arch=x86_64 -s:b  os=Linux -s:b  compiler=gcc -s:b  compiler.version=13 -s:b  compiler.libcxx=libstdc++11 -s:b  compiler.cppstd=gnu23 -s:b  build_type=Release  --version=13.3 --build-require
 ```
after that you can use it localy or upload on your private server

 ```
conan upload gcc/* -r arm-gcc
```

# Naming format
*It's not the best code and you can do it better if you have a time*

To support multiple variations of host/target compilers, I implemented a list of mappings between target names and host names, which checks against the archive file name of the toolchain. This is simple to use:
 ```
target_info = {
    'arm-none-eabi': HostInfo(Architectures.arm, OperationSystems.Generic),
    'arm-none-linux-gnueabihf': HostInfo(Architectures.arm, OperationSystems.Linux),
    'aarch64-none-elf': HostInfo(Architectures.aarch64, OperationSystems.Generic),
    'aarch64-none-linux-gnu': HostInfo(Architectures.aarch64, OperationSystems.Linux),
    'aarch64_be-none-linux-gnu': HostInfo(Architectures.aarch64, OperationSystems.Linux),
    'x86_64-w64-mingw32': HostInfo(Architectures.x86_64, OperationSystems.Windows),
    'x86_64-linux-gnu': HostInfo(Architectures.x86_64, OperationSystems.Linux)
}

host_info = {
    'mingw-w64-i686': HostInfo(Architectures.x86_64, OperationSystems.Windows),
    'x86_64': HostInfo(Architectures.x86_64, OperationSystems.Linux),
    'aarch64': HostInfo(Architectures.aarch64, OperationSystems.Linux),
    'darwin-x86_64': HostInfo(Architectures.x86_64, OperationSystems.Macos),
    'darwin-arm64': HostInfo(Architectures.aarch64, OperationSystems.Macos)
}
 ```
To recognize them in the archive name, a regular expression pattern is used:

 ```
pattern = r'^.*?(arm-gnu-toolchain|windows-native|linux-native)-([\d\.]+\.rel\d+)-(mingw-w64-i686|x86_64|aarch64|darwin-x86_64|darwin-arm64)-(arm-none-eabi|arm-none-linux-gnueabihf|aarch64-none-elf|aarch64-none-linux-gnu|aarch64_be-none-linux-gnu|x86_64-w64-mingw32|x86_64-linux-gnu)\.(zip|tar\.xz|pkg)'
 ```
# WARRANTY

This project represents my personal vision of the best implementation of a build system for embedded projects, with testing functionality for open-source projects using tools that are legally and freely available online. It is completely open, and you are free to use it in any way. However, I do not take any responsibility for your hardware or any consequences that may arise from using my code.
# Sources
- arm gcc prebuild compillers https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
- gcc options https://gcc.gnu.org/onlinedocs/gcc-13.2.0/gcc/ARM-Options.html
- rdimon lib for stdio on stm32 https://developer.arm.com/documentation/109845/latest/
- mcu compiler tuning https://community.arm.com/arm-community-blogs/b/tools-software-ides-blog/posts/compiler-flags-across-architectures-march-mtune-and-mcpu
- conan https://docs.conan.io/2/reference/


