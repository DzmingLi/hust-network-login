# HUST-Network-Login

极简主义的华中科技大学校园网络认证工具，支持有线和无线网络。下载即用，大小约为 400k，静态链接无依赖。为路由器等嵌入式设备开发，支持所有主流硬件软件平台。No Python, No Dependencies, No Bullshit.

## 使用

从 Release 下载对应硬件和操作系统平台的可执行文件。

配置文件只有两行, 第一行为用户名，第二行为密码，例如

```text
M2020123123
mypasswordmypassword
```

保存为 my.conf

然后运行

```shell
./hust-network-login ./my.conf
```

my.conf 是刚才的配置文件，你可以换成其他名字。

连接成功后，程序将会每间隔 15s 测试一次网络连通性。如果无法连接则进行重新登陆。

## NixOS 使用

本项目提供了 NixOS 模块和 Flake 支持，可以方便地在 NixOS 系统上使用。

### 使用 Flake

在你的 `flake.nix` 中添加：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hust-network-login.url = "github:black-binary/hust-network-login";
  };

  outputs = { self, nixpkgs, hust-network-login }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [
        hust-network-login.nixosModules.default
        {
          services.hust-network-login = {
            enable = true;
            username = "M2020123123";
            # 方式一：直接设置密码（不推荐，密码会存储在 Nix store）
            # password = "your-password";

            # 方式二：使用 passwordFile（推荐，支持 agenix）
            passwordFile = "/run/agenix/hust-network-login-password";

            # 指定程序包
            package = hust-network-login.packages.${pkgs.system}.default;
          };
        }
      ];
    };
  };
}
```

### 配合 agenix 使用

[agenix](https://github.com/ryantm/agenix) 是一个用于管理 NixOS 密钥的工具。使用 agenix 可以安全地管理密码：

1. 首先安装和配置 agenix
2. 创建加密的密码文件
3. 在配置中使用：

```nix
{
  age.secrets.hust-network-login-password = {
    file = ./secrets/hust-network-login-password.age;
  };

  services.hust-network-login = {
    enable = true;
    username = "M2020123123";
    passwordFile = config.age.secrets.hust-network-login-password.path;
    package = hust-network-login.packages.${pkgs.system}.default;
  };
}
```

### 直接运行

你也可以直接运行程序而不启用系统服务：

```shell
nix run github:black-binary/hust-network-login -- /path/to/config
```

或者通过环境变量：

```shell
export HUST_NETWORK_LOGIN_USERNAME="M2020123123"
export HUST_NETWORK_LOGIN_PASSWORD="your-password"
nix run github:black-binary/hust-network-login
```

## 编译

编译本地平台只需要使用 `cargo`。

```shell
cargo build --release
strip ./target/release/hust-network-login
```

strip 可以去除调试符号表，将体积减少到 500k 以下。

交叉编译推荐使用 `cross`，当然你也可以自己手动配置工具链。

```shell
cargo install cross
cross build --release --target mips-unknown-linux-musl
mips-linux-gnu-strip ./target/mips-unknown-linux-musl/release/hust-network-login
```

你应当根据自己的路由器平台选择硬件平台。支持的目标平台戳[这里](https://github.com/rust-embedded/cross)。
