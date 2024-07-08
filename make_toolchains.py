import conanfile as tc_info
import subprocess

def comand_maker(pref, info, vers):
    result = ""
    result += f"{pref} arch={info.arch_conan()} "
    result += f"{pref} os={info.os_conan()} "
    result += f"{pref} compiler=gcc "
    result += f"{pref} compiler.version={vers} "
    result += f"{pref} compiler.libcxx=libstdc++11 "
    result += f"{pref} compiler.cppstd=gnu23 "
    result += f"{pref} build_type=Release "
    return result


def collect_nested_toolchains(base_url, auth=None):
    folders = []
    stack = [base_url]

    current_url = stack.pop()
    print(f"Processing URL: {current_url}")  # Print the URL being processed
    files = tc_info.list_artifactory_folder(current_url, auth)

    for file in files:
        if file == '../' or not file.endswith('/'):  # Skip the parent directory link
            continue
        full_url = base_url + file if not file.startswith('http') else file
        if None is not tc_info.have_sha256_and_filename(full_url):
            folders.append(full_url)
            stack.append(full_url)
        else:
            nested_urls = collect_nested_toolchains(full_url)
            folders.extend(nested_urls)
    return folders




# Example usage
# base_url = 'http://artifactory.local:80/artifactory/arm-tools/GCC_13.2/'
base_url = "http://192.168.71.113:8082/artifactory/arm-tools/GCC_13.2/"
folders = collect_nested_toolchains(base_url)
for folder in folders:
    # folder = "http://artifactory.local:80/artifactory/arm-tools/GCC_13.2/x86_64%20Linux%20hosted%20cross%20toolchains/AArch32%20bare-metal%20target%20(arm-none-eabi)/"
    sha, filename = tc_info.have_sha256_and_filename(folder)
    # print(folder)
    host, target, version, _ = tc_info.parse_toolchain_filename(filename)
    # print(host.os, target.os)
    # if host.os == tc_info.OperationSystems.Linux and host.arch == tc_info.Architectures.x86_64 and target.os\
    #         == tc_info.OperationSystems.Generic and target.arch == tc_info.Architectures.arm:
    v = version.split('.')[0]
    s = "-s "
    s_b = "-s:b "
    comand = f"export URL=\"{folder}\" && conan create . {comand_maker(s, target, v)} {comand_maker(s_b, host, v)} --version={version} --build-require"
    print(comand)
    result = subprocess.run(comand, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    # print(result)
    if result.returncode == 0:
        print("Команда завершилась успешно")
        print("Вывод команды:", result.stdout)
        # comand = f"conan upload arm-gcc/{version} -r arm-gcc"
        # print(comand)
        # result = subprocess.run(comand, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode !=0:
        print("Команда завершилась с ошибкой")
        print("Ошибка:", result.stderr)
        raise ValueError(f"сборка пакета не удалась, почините скрипт сборки")