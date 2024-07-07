from conan import ConanFile
from conan.tools.files import get, copy
import os
from enum import Enum
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import requests
import re


#имя это название в conan , значение в cmake
class OperationSystems(Enum):
    Linux = 'Linux'
    Windows = 'Windows'
    Macos = 'Macos'
    Generic = 'baremetal'


#имя это название в conan , значение в cmake
class Architectures(Enum):
    arm = "armv7"
    aarch64 = "armv8"
    x86_64 = "x86_64"


class HostInfo:
    # version = {}
    def __init__(self, arch, os):
        self.arch = arch
        self.os = os

    def arch_conan(self):
        return self.arch.value

    def arch_cmake(self):
        return self.arch.name

    def os_conan(self):
            return self.os.value

    def os_cmake(self):
        return self.os.name

    def __str__(self):
        return f"arch: {self.arch_conan()}, os: {self.os_conan()}"


# Создаем массивы экземпляров классов
target_info = {
    'arm-none-eabi': HostInfo(Architectures.arm, OperationSystems.Generic),
    'arm-none-linux-gnueabihf': HostInfo(Architectures.arm, OperationSystems.Linux),
    'aarch64-none-elf': HostInfo(Architectures.aarch64, OperationSystems.Generic),
    'aarch64-none-linux-gnu': HostInfo(Architectures.aarch64, OperationSystems.Linux),
    'aarch64_be-none-linux-gnu': HostInfo(Architectures.aarch64, OperationSystems.Linux)
}

host_info = {
    'mingw-w64-i686': HostInfo(Architectures.x86_64, OperationSystems.Windows),
    'x86_64': HostInfo(Architectures.x86_64, OperationSystems.Linux),
    'aarch64': HostInfo(Architectures.aarch64, OperationSystems.Linux),
    'darwin-x86_64': HostInfo(Architectures.x86_64, OperationSystems.Macos),
    'darwin-arm64': HostInfo(Architectures.aarch64, OperationSystems.Macos)
}


def have_sha256_and_filename(folder_url, auth=None):
    files = list_artifactory_folder(folder_url)
    for file in files:
        if (file.endswith('zip.sha256asc') or file.endswith('.sha256asc') or file.endswith('.tar.xz.sha256asc') ) and (not file.endswith('exe.sha256asc') and not file.endswith('pkg.sha256asc')):
            print(folder_url)
            print(file)
            file_str = str(file)
            folder_url_str = str(folder_url)
            file_url = urljoin(folder_url_str, file_str)
            response = requests.get(file_url, auth=auth)
            response.raise_for_status()

            # Предполагается, что файл содержит строку вида:
            # "6cd1bbc1d9ae57312bcd169ae283153a9572bd6a8e4eeae2fedfbc33b115fdbb  arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-eabi.tar.xz"
            content = response.text.strip()
            sha, filename = content.split()
            if filename.startswith('*'):
                filename = filename[1:]
            return sha, filename

    return None


def list_artifactory_folder(folder_url, auth=None):
    try:
        response = requests.get(folder_url, auth=auth)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        files = [link.get('href') for link in soup.find_all('a')]
        return files
    except requests.exceptions.HTTPError as e:
        print(f"HTTP Error: {e} for URL: {folder_url}")
        return []


def parse_toolchain_filename(filename):
    # Определяем паттерн для имени файла
    pattern = r'^.*?arm-gnu-toolchain-([\d\.]+\.rel\d+)-(mingw-w64-i686|x86_64|aarch64|darwin-x86_64|darwin-arm64)-(arm-none-eabi|arm-none-linux-gnueabihf|aarch64-none-elf|aarch64-none-linux-gnu|aarch64_be-none-linux-gnu)\.(zip|tar\.xz|pkg)'
    match = re.match(pattern, filename)

    if not match:
        return None

    version, host_arch, target_arch, _ = match.groups()

    return host_info[host_arch], target_info[target_arch], version, target_arch


class ArmGccConan(ConanFile):
    name = "arm-gcc"
    # version = "13.2.rel1"
    license = "GPL-3.0-only"
    homepage = ""
    url = ""
    author = "Ostanin <iahve1991@gmail.com>"
    description = "пакет кросскомпиляции ARM-GCC  для локального использования"
    topics = ("conan", "arm-gcc", "toolchain")
    # options = {"source_url": ["ANY"]}
    # default_options = {"source_url": "None"}
    settings = "os", "arch"
    package_type = "application"
    programs = {}
    sha = {}
    archive_name = {}
    exports_sources = "arm_gcc_toolchain_template.cmake"

    # generators = "CMakeDeps"

    def system_requirements(self):
        print("PYTHON_REQUIREMENTS")
        import subprocess
        import sys
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', "bs4"])
        except subprocess.CalledProcessError as e:
            print(f"Error installing package bs4: {e}")
            sys.exit(1)

    # def requirements(self):
    #     self.requires("bs4/4.10.0")
    def validate(self):
        print("VALIDATION")
        # self.options.source_url = str(self.options.source_url)

    def package_id(self):
        print("PACKAGE_ID")
        self.info.settings_target = self.settings_target
        # We only want the ``arch`` setting

        # self.info.settings_target.rm_safe("os")
        self.info.settings_target.rm_safe("compiler")
        self.info.settings_target.rm_safe("build_type")

    def source(self):
        print("SOURCE")

    def build(self):
        print("BUILD")

    def package(self):
        print("PACKAGE")
        if not os.getenv("URL"):
            raise ValueError(f"Set valid gcc url in options. now in is {os.getenv("URL")}")
        try:
            files = list_artifactory_folder(os.getenv("URL"))
            self.sha, self.archive_name = have_sha256_and_filename(os.getenv("URL"))
            print(f"SHA: {self.sha}")
            print(f"Filename: {self.archive_name}")
        except FileNotFoundError as e:
            print(e)
        get(self, f"{os.getenv("URL")}/{self.archive_name}",
            sha256=self.sha, strip_root=True)
        host, target, vers, triple = parse_toolchain_filename(self.archive_name)
        dirs_to_copy = [triple, "bin", "include", "lib", "libexec"]
        copy(self, "*.cmake", src=self.source_folder, dst=self.package_folder + "/cmake")
        for dir_name in dirs_to_copy:
            copy(self, pattern=f"{dir_name}/*", src=self.build_folder, dst=self.package_folder, keep_path=True)
        template_path = os.path.join(self.package_folder, "cmake/arm_gcc_toolchain_template.cmake")
        with open(template_path, "r+") as template_file:
            template_content = template_file.read()
            variables = {
                "@TRIPLET@": triple,
                "@PROCESSOR@": target.arch_cmake(),
                "@SYSTEM@": target.os_cmake(),
                "@CROSSCOMPILING@": "FALSE" if target.os == host.os else "TRUE"
            }
            for var, value in variables.items():
                template_content = template_content.replace(var, value)
            template_file.seek(0)
            template_file.write(template_content)
            # Обрезаем файл до текущей позиции курсора, чтобы удалить старое содержимое
            template_file.truncate()
            template_file.close()


    def source(self):
        print("SOURCE")

    def package_info(self):
        print("PACKAGE_INFO")

        # self.cpp_info.bindirs.append(os.path.join(self.package_folder, "arm-none-eabi", "bin"))

        # Read the template file
        template_path = os.path.join(self.package_folder, "cmake/arm_gcc_toolchain_template.cmake")
        with open(template_path, "r") as template_file:
            template_content = template_file.read()
            # Replace placeholders with actual values
            config_content = template_content.replace("@TOOLS_PATH@", self.package_folder)
            template_file.close()

        toolchain_path = os.path.join(self.package_folder, "cmake/arm-gcc-toolchain.cmake")
        with open(toolchain_path, "w") as toolchain_file:
            toolchain_file.write(config_content)
            toolchain_file.close()


        self.conf_info.define("tools.cmake.cmaketoolchain:user_toolchain", [toolchain_path])

        # Add the path to the CMake modules
        self.cpp_info.builddirs.append(os.path.join(self.package_folder, "cmake"))
        self.cpp_info.includedirs.append(os.path.join(self.package_folder, "include"))

    def generate(self):
        print("GENERATE")

#тестовая строка
#export URL="http://artifactory.local:80/artifactory/arm-tools/GCC_13.2/x86_64%20Linux%20hosted%20cross%20toolchains/AArch32%20bare-metal%20target%20%28arm-none-eabi%29/" && conan create . --profile:host=./profiles/armv7 --profile:build=./profiles/linux_x86_64 --build-require --version=13.2.rel1.
