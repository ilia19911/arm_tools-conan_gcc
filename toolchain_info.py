import re
import conanfile as tc_info

def parse_toolchain_filename(filename):
    # Определяем паттерн для имени файла
    pattern = r'^.*?arm-gnu-toolchain-([\d\.]+\.rel\d+)-(mingw-w64-i686|x86_64|aarch64|darwin-x86_64|darwin-arm64)-(arm-none-eabi|arm-none-linux-gnueabihf|aarch64-none-elf|aarch64-none-linux-gnu|aarch64_be-none-linux-gnu)\.(zip|tar\.xz|pkg)'
    match = re.match(pattern, filename)

    if not match:
        return None

    version, host_arch, target_arch, _ = match.groups()

    return tc_info.host_info[host_arch], tc_info.target_info[target_arch], version


strings = {
    "arm-gnu-toolchain-13.3.rel1-mingw-w64-i686-arm-none-eabi.zip",
    "arm-gnu-toolchain-13.3.rel1-mingw-w64-i686-arm-none-linux-gnueabihf.zip",
    "arm-gnu-toolchain-13.3.rel1-mingw-w64-i686-aarch64-none-elf.zip",
    "arm-gnu-toolchain-13.3.rel1-mingw-w64-i686-aarch64-none-linux-gnu.zip",
    "arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz",
    "arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz",
    "arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-elf.tar.xz",
    "arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz",
    "arm-gnu-toolchain-13.3.rel1-x86_64-aarch64_be-none-linux-gnu.tar.xz",
    "arm-gnu-toolchain-13.3.rel1-aarch64-arm-none-eabi.tar.xz",
    "arm-gnu-toolchain-13.3.rel1-aarch64-arm-none-linux-gnueabihf.tar.xz"
    "arm-gnu-toolchain-13.3.rel1-aarch64-aarch64-none-elf.tar.xz",
    "arm-gnu-toolchain-13.3.rel1-darwin-x86_64-arm-none-eabi.pkg",
    "arm-gnu-toolchain-13.3.rel1-darwin-x86_64-aarch64-none-elf.pkg",
    "arm-gnu-toolchain-13.3.rel1-darwin-arm64-arm-none-eabi.pkg",
    "arm-gnu-toolchain-13.3.rel1-darwin-arm64-aarch64-none-elf.pkg",

}

for item in strings:
    host, target, version = parse_toolchain_filename(item)
    if host:
        print(item, host)
    else:
        print("Не удалось разобрать имя файла")
