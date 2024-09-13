# Motivation

The reason for creating such a build system is the availability of all the necessary tools for building ARM32 projects freely on the internet, but the lack of any satisfactory build system implementation. In my opinion, a build system is needed where it is easy to switch compilers, separate hardware logic, and have different versions of CMSIS HAL in the system without the need to copy them into the project. Also, CMSIS typically does not include precompiled NN and DSP libraries, which means they must be compiled manually. However, people often look for alternative ways to integrate DSP files into the project for various reasons (e.g., large binary size), even though there is a DSP/Source/CMakeLists.txt with full instructions.

Additionally, CMSIS can easily be built for a PC, which simplifies algorithm testing. CMSIS provides driver interface descriptions, but they are written in C. Nowadays, writing projects in pure C for STM32 is becoming a thing of the past due to the increasing complexity of algorithms, and it is necessary to adapt. Furthermore, the compilation flags required to reduce binary size and use the correct processor settings remain a mystery to most users.

If for any reason you believe I am wrong, I would be happy to hear criticism or be directed to resources.

# Common

The project is designed for generating GCC packages within the Conan framework, making it easier to manage ARM32 project builds (or any platform project as linux x86_64). It allows the development team to effortlessly use the same compiler across all members without configuring the build environment on each machine, and to easily switch between compilers as needed. Additionally, it enables building static libraries for a specific compiler release, ensuring reliable linking by avoiding ABI compatibility issues. It simplifies switching between build targets and testing the entire business logic on a PC using the proposed pattern for separating the lower and upper levels of the program. The project includes a CMake toolchain with pre-configured compilation flags (supporting both release and debug builds).

# Abstract overwiev
This package is part of the overall design of a custom build system based on Conan, CMake, GCC, GTest, CMSIS, HAL tools, and libraries. GCC is at the core of the build system, serving as the toolchain for building other packages. Conan provides mechanisms for distributing GCC toolchains with different options (host/target) alongside other binary packages, which is the core idea behind this.

When building the project, the required compiler version is specified in the Conan settings, and from there, all other dependencies built with the same compiler are automatically selected. This way, any project can be easily switched to different compiler versions simply by changing the Conan configuration.

The packages being built are wrappers for precompiled binary files of the compilers. To simplify the process of writing the package build script, it’s more convenient to gather all precompiled compilers in a single repository, organizing them into different folders corresponding to the compiler versions. After that, host and target can be determined by the specific names that GCC uses when creating binary files. The naming rules can be found in the script or will be described at the end of the file. It's convenient to use the same Artifactory repository that will be used for storing other binaries as the storage.

# Requirements
- this package requires Python3 and some libraries (it's better to install specific libraries that your system requires)
- also you need installed conan client. how to do it you can find here https://conan.io/downloads
  
# Fast start

  To use the package, simply add my repository to the list of Conan repositories, and you will be able to find the required GCC version with the necessary host and target options.
  
  ```
  conan remote add arm-tools  https://artifactory.nextcloud-iahve.ru/artifactory/api/conan/arm-tools
  ```
  To list available packages, use command

  ```
  conan list gcc/*:* -r=arm-tools
  ```
  and you will see
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

# YOUR PRIVATE ARTIFACTORY

  If you want to set up your own build system, you need to install your own JFrog Artifactory server. This can be done by following the instructions https://jfrog.com/community/open-source/  . I use communitu edition version couse it's free and contains c c++ packages (it's all I need).
  After this, you need to build package or fetch mine to your pc and than upload to your private artifactory



# How to use
 you can find example in my another repo where i use few packages and separate logic and hardware using c++ drivers. # todo add repo
# Build
- to build package you need to clone repository  *git clone https://github.com/ilia19911/arm_tools-conan_gcc.git*
- It's important to have some network disk or something with web access where you keep toolchains, couse python scrypt conanfile.py will try to find specific format of archive and sha256asc.txt files there. Or, you can just use mine as written in the script
  
  conan provides simple way to create packages with conanfile.py. You just need to enter to root path of repo and enter *conan create .* and it start build package for your system. But in case with stm32 we need to create different host/target options so I designed some format for creation packages. You can make it better if you have a time.
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

To support multiple variations of host/target compilers, I implemented a list of mappings between target names and host names, which checks against the archive file name of the toolchain. It’s quite simple to use:
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


