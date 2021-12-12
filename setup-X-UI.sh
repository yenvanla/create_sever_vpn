xanh='\033[1;35m'
red='\033[1;35m'
green='\033[1;35m'
yellow='\033[1;34m'
plain='\033[0m'
cur_dir=$(pwd)  

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Chú ý：${plain}Tập lệnh này phải được chạy với tư cách người dùng gốc(root)! \n ${xanh}➫Vui Lòng Gõ Lệnh: ${yellow}sudo -i \n ➬Để Kích Hoạt Root, và thử lại lần nữa " && exit 1
# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/vaxilu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}检测 x-ui 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 x-ui 版本安装${plain}"
            exit 1
        fi
        echo -e "检测到 x-ui 最新版本：${last_version}，开始安装"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "开始安装 x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
clear
    echo -e "${green}x-ui v${last_version}${plain} Quá trình cài đặt hoàn tất, bảng điều khiển đã bắt đầu,"
    echo -e ""
    echo -e "${yellow}Nếu đó là cài đặt mới, cổng web mặc định là: ${green}54321${plain} "
    echo -e "${yellow}Tên người dùng và mật khẩu đều theo mặc định là: ${green}admin${plain} "
    echo -e "Hãy đảm bảo rằng cổng này không bị các chương trình khác chiếm giữ."
    echo -e "${yellow}Và chắc rằng Cổng 54321 đã được mở ${plain}"
#   echo -e "Nếu bạn muốn 54321 Sửa đổi thành cổng khác, nhập lệnh x-ui để sửa đổi, cũng đảm bảo rằng cổng bạn sửa đổi cũng được phép"
    echo -e ""
    echo -e "Nếu đó là để cập nhật bảng điều khiển, hãy truy cập bảng điều khiển như bạn đã làm trước đây "
    echo -e ""
    echo -e "Cách sử dụng tập lệnh quản lý: x-ui "
    echo -e "----------------------------------------------"
    echo -e "》x-ui              ➪ ${xanh}Menu quản lý x-ui (nhiều chức năng hơn)${plain} "
    echo -e "》x-ui start        ➪ ${xanh}Khởi chạy bảng điều khiển x-ui${plain} "
    echo -e "》x-ui stop         ➪ ${xanh}Dừng bảng điều khiển x-ui${plain} "
    echo -e "》x-ui restart      ➪ ${xanh}Khởi động lại bảng điều khiển x-ui${plain} "
    echo -e "》x-ui status       ➪ ${xanh}Xem trạng thái x-ui${plain} "
    echo -e "》x-ui enable       ➪ ${xanh}Đặt x-ui tự động khởi động, sau khi khởi động ${plain} "
    echo -e "》x-ui disable      ➪ ${xanh}Hủy khởi động x-ui để bắt đầu tự động.${plain} "
    echo -e "》x-ui log          ➪ ${xanh}Xem nhật ký x-ui${plain} "
    echo -e "》x-ui v2-ui        ➪ ${xanh}Di chuyển dữ liệu v2-ui của máy này sang x-ui.${plain} "
    echo -e "》x-ui update       ➪ ${xanh}Cập nhật bảng điều khiển x-ui${plain}"
    echo -e "》x-ui install      ➪ ${xanh}Cài đặt bảng điều khiển x-ui${plain}"
    echo -e "》x-ui uninstall    ➪ ${xanh}Gỡ cài đặt bảng điều khiển x-ui${plain}"
}

   echo -e "${yellow}Bắt Đầu Cài Đặt X-UI${plain}"
install_base
install_x-ui $1
