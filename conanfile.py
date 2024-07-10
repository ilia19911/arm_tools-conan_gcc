import os
import sys
import subprocess
import re
import requests
from urllib.parse import urljoin
from enum import Enum
try:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', "bs4"])
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', "conan"])
except subprocess.CalledProcessError as e:
    print(f"Error installing package bs4: {e}")
    sys.exit(1)

from conan import ConanFile
from conan.tools.files import get, copy
from bs4 import BeautifulSoup


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


def collect_nested_toolchains(base_url, auth=None):
    folders = []
    stack = [base_url]

    current_url = stack.pop()
    print(f"Processing URL: {current_url}")  # Print the URL being processed
    files = list_artifactory_folder(current_url, auth)

    for file in files:
        if file == '../' or not file.endswith('/'):  # Skip the parent directory link
            continue
        full_url = base_url + file if not file.startswith('http') else file
        if None is not have_sha256_and_filename(full_url):
            folders.append(full_url)
            stack.append(full_url)
        else:
            nested_urls = collect_nested_toolchains(full_url)
            folders.extend(nested_urls)
    return folders


class ArmGccConan(ConanFile):
    base_url = "http://192.168.71.113:8082/artifactory/arm-tools/GCC_13.2/"
    name = "arm-gcc"
    license = "GPL-3.0-only"
    homepage = ""
    url = ""
    author = "Ostanin <iahve1991@gmail.com>"
    description = "пакет кросскомпиляции ARM-GCC  для локального использования"
    topics = ("conan", "arm-gcc", "toolchain")
    settings = "os", "arch"
    package_type = "application"
    exports_sources = "arm-gcc-toolchain-template.cmake", "source_url.txt"

    # generators = "CMakeDeps"

    # def generate_config(self, template_path, dest_path, variables):
    #
    #     with open(template_path, "r") as template_file:
    #         template_content = template_file.read()
    #         for var, value in variables.items():
    #             template_content = template_content.replace(var, value)
    #         with open(dest_path, "w") as dest_file:
    #             dest_file.write(template_content)
    #             dest_file.close()
    #         template_file.close()

    def build_gcc(self, url, dest):
        print("toolchain_url: ", str(url))
        print("destination folder: ", str(dest))
        sha, filename = have_sha256_and_filename(str(url))
        # print(folder)
        host, target, vers, triple = parse_toolchain_filename(filename)
        try:
            print(f"SHA: {sha}")
            print(f"Filename: {filename}")
            get(self, f"{url}/{filename}", sha256=sha, strip_root=True, destination=dest)
        except FileNotFoundError as e:
            print(e)

    def config_options(self):
        print("GCC_CONFIG_OPTIONS")

    def validate(self):
        print("GCC_VALIDATION")
        # url = open(f"{self.source_folder}/source_url.txt", "r").read()
        # print("gcc url is:", url)
        # sha, filename = have_sha256_and_filename(str(url))
        # host, target, vers, triple = parse_toolchain_filename(filename)
        # if (host.os_conan() == self.settings.os and
        #         host.arch_conan() == self.settings.arch and
        #         target.os_conan() == self.settings_target.os and
        #         target.arch_conan() == self.settings_target.arch and
        #         self.version == vers):
        #     print("gcc has found")
        # else:
        #     raise "can't find gcc on the server"

    def system_requirements(self):
        print("GCC_SYSTEM_REQUIREMENTS")

    # def requirements(self):
    #     self.requires("bs4/4.10.0")


    def package_id(self):
        print("GCC_PACKAGE_ID")
        self.info.settings_target = self.settings_target
        # We only want the ``arch`` setting

        # self.info.settings_target.rm_safe("os")
        self.info.settings_target.rm_safe("compiler")
        self.info.settings_target.rm_safe("build_type")
        # self.options.rm_safe("bin_url")




    def source(self):
        print("GCC_SOURCE")
        url = os.getenv("URL")
        print("URL: ", url)
        with open(f"source_url.txt", "w") as file:
            file.write(url)

    def deploy(self):
        print("GCC_DEPLOY")
        # This method can be used to deploy files on the system after package is installed
        # For example, to copy binaries to a specific folder
        pass
    def export(self):
        print("GCC_EXPORT")
        # This method can be used to deploy files on the system after package is installed
        # For example, to copy binaries to a specific folder
        pass
    def imports(self):
        print("GCC_PACKAGE_INFO")

        # Add the path to the CMake modules
        url = open(self.package_folder + "/source_url.txt", "w").read()



    def build(self):
        print("GCC_BUILD")



    def package(self):
        print("GCC_PACKAGE")
        copy(self, "*.cmake", src=self.source_folder, dst=self.package_folder + "/cmake")
        copy(self, "source_url.txt", src=self.source_folder, dst=self.package_folder)


    def package_info(self):
        print("PACKAGE_INFO")
        toolchain_path = os.path.join(self.package_folder, "cmake/arm-gcc-toolchain.cmake")
        self.conf_info.define("tools.cmake.cmaketoolchain:user_toolchain", [toolchain_path])
        self.cpp_info.builddirs.append(os.path.join(self.package_folder, "cmake"))
        self.cpp_info.includedirs.append(os.path.join(self.package_folder, "include"))

        with open(self.package_folder + "/source_url.txt", "r") as file:
            toolchain_url = file.read()
        file.close()

        sha, filename = have_sha256_and_filename(str(toolchain_url))
        host, target, vers, triple = parse_toolchain_filename(filename)

        template_path = os.path.join(self.package_folder, "cmake/arm-gcc-toolchain-template.cmake")
        cmake_toolchain_path = os.path.join(self.package_folder, "cmake/arm-gcc-toolchain.cmake")
        gcc_path = f"{self.package_folder}/../GCC"
        # Используем регулярное выражение для удаления всех букв
        version_without_chars = re.sub(r'[a-zA-Z]', '', self.version)
        print("version: ", version_without_chars)
        variables = {
            "@TOOLS_PATH@": gcc_path,
            "@TRIPLET@": triple,
            "@PROCESSOR@": target.arch_cmake(),
            "@SYSTEM@": target.os_cmake(),
            "@VERSION@": version_without_chars,
            "@CROSSCOMPILING@": "FALSE" if target.os == host.os else "TRUE"
        }
        with open(template_path, "r") as template_file:
            template_content = template_file.read()
            template_file.close()
        for var, value in variables.items():
            template_content = template_content.replace(var, value)

        with open(cmake_toolchain_path, "w") as toolchain_file:
            toolchain_file.write(template_content)
            toolchain_file.close()
        if not os.path.exists(gcc_path):
            self.build_gcc(toolchain_url, gcc_path)




        # self.build_gcc(url)




    def generate(self):
        print("GCC_GENERATE")

#тестовая строка
#export URL="http://192.168.71.113:8082/artifactory/arm-tools/GCC_13.2/x86_64_Linux_hosted_cross_toolchains/AArch32%20bare-metal%20target%20%28arm-none-eabi%29/" && conan create . --profile:host=./profiles/armv7 --profile:build=./profiles/linux_x86_64 --build-require --version=13.2.rel1
#conan list arm-gcc/*:*
#conan upload arm-gcc/13.2.rel1 -r=arm-gcc
# export URL="http://192.168.71.113:8082/artifactory/arm-tools/GCC_13.2/x86_64_Linux_hosted_cross_toolchains/AArch32%20bare-metal%20target%20%28arm-none-eabi%29/" && conan create . -s  arch=armv7 -s  os=baremetal -s  compiler=gcc -s  compiler.version=13 -s  compiler.libcxx=libstdc++11 -s  compiler.cppstd=gnu23 -s  build_type=Release  -s:b  arch=x86_64 -s:b  os=Linux -s:b  compiler=gcc -s:b  compiler.version=13 -s:b  compiler.libcxx=libstdc++11 -s:b  compiler.cppstd=gnu23 -s:b  build_type=Release  --version=13.2.rel1 --build-require

