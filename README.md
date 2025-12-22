# Blender Dev Container 
# Dev Container 上の本物の Blender !

## 使い方
### 開発中の Extension が存在する場合

開発中の Blender Extension のディレクトリを [`/extensions/`](/extensions/) 直下に配置します。`.git/` はリポジトリのルートに残します。

```
/EXTENSION/blender_manifest.toml ---> /EXTENSION/extensions/EXTENSION/blender_manifest.toml
/EXTENSON/.git/ ---> /EXTENSION/.git/
```

リポジトリのルートディレクトリと、[`/extensions/`](/extensions/) [*](#環境変数)直下の拡張機能のパッケージとしてのディレクトリが、同名である必要があります。これを回避するには、 この後の手順で配置される [`/.devcontainer/devcontainer.json`](/.devcontainer/devcontainer.json) において、

```
    - "workspaceFolder": "/workspaces/development/extensions/${localWorkspaceFolderBasename}",
    + "workspaceFolder": "/workspaces/development/extensions/",
```

などとする必要があります。

### [`/.devcontainer.json`](/.devcontainer.json) をプロジェクトルートにコピーします。

```
curl -L -o .devcontainer.json https://raw.githubusercontent.com/peakys-org/blender-devcontainer/main/.devcontainer.json
```

### [`/blender_services.json`](/blender_services.json) で、使用する Blender のバージョンと Blender 毎のポートを指定します。

[`/blender_services.json`](/blender_services.json) は例えば次のように記述します。

```
{
    "blender-4.5-a": {"version": "4.5.4", "port": 5901, "resources": "../portable/"},
    "blender-4.5-b": {"version": "4.5.4", "port": 5902},
    "blender-5.0": {"version": "5.0.0", "port": 5903, "resources": "../portable/"}
}
```

```
curl -L -o blender_services.json https://raw.githubusercontent.com/peakys-org/blender-devcontainer/main/blender_services.json
```

#### [`blender_services.json`](/blender_services.json) リファレンス
```
{
    service: {"version": version, "port": port, "resources": resources}
}
```
- `service` は、 Blender を稼働するサービスコンテナの名前を lower_case で指定します。
- `version` は、 Blender のセマンティックバージョンを文字列で指定します。
- `port` は、 Blender を稼働するサービスコンテナに使用するポート番号を整数で指定します。ポートの重複にご注意ください。
- `resources` は、 Blender のユーザーディレクトリとしてマウントするパスを文字列で指定します。相対バスは [`/.devcontainer/compose.yaml`](/.devcontainer/compose.yaml) を基準とします。この属性は省略できます。

### [`/.devcontainer.json`](/.devcontainer.json) による Dev Container を開きます。

```
devcontainer up --workspace-folder .
```

または、 Visual Studio Code の場合、`Ctrl + Shift + P` で開くコマンドパレットにおいて、

```
> Dev Containers: Rebuild and Reopen in Container
```

とします。

### 以上のセットアップの代わりに、リポジトリ [`peakys-org/blender-devcontainer`](https://github.com/peakys-org/blender-devcontainer) をフォークしても良いです。

フォークしたリポジトリにおいて、[`/blender_servicess.json`](/blender_services.json) を設定したうえで、 
```
postStartCommand.sh
```
を実行してください。

### Blender Dev Container を開始します。
[`/.devcontainer/devcontainer.json`](/.devcontainer/devcontainer.json) による Dev Container を開きます。

```
devcontainer up --workspace-folder .
```

または、 Visual Studio Code の場合、`Ctrl + Shift + P` で開くコマンドパレットにおいて、

```
> Dev Containers: Rebuild and Reopen in Container
```

とすることをお勧めします。

エディタと接続せず、Docker Compose のみを稼働

```
docker compose --file .devcontainer/compose.yaml up
```

することもできます。リソースを削除するには
```
docker compose --file .devcontainer/compose.yaml down --volumes --remove-orphans --rmi all
```
などとします。

### ブラウザから、[`localhost:3000`](http://localhost:3000) にアクセスします。

接続するバージョンの Blender を選択します。

### Blender からの出力を標準出力します。
```
tail -f --retry /workspaces/development/output-*log
```


## 原理
### Docker Compose : [`/.devcontainer/compose.yaml`](/.devcontainer/compose.yaml)
Dev Container は次の三種の Docker コンテナから成る Docker Compose を基にします。
- `<blender-service>` : Blender GUI を提供する。
- `novnc` : `blender` コンテナからの VNC 接続をブラウザに配信する。
- `devcontainer` : Dev Container の接続先で、 Blender からの出力を提供する。

また、`<blender-service>` コンテナには同名の名前付きボリュームが `/workspaces/blender` としてマウントされます。名前付きボリューム `<blender-service>` は Blender 本体が置かれる場所です。`devcontainer` コンテナには同時に稼働する全ての `<blender-service>` 名前付きボリュームがマウントされます。マウントポイントは `/workspaces/<blender-service>` です。

#### `<blender-service>` コンテナ : [`/.devcontainer/blender/`](/.devcontainer/blender/)
ウィンドウシステムと Blender の GUI を提供するコンテナです。利用したソフトウェアは以下の通りです。
- [Arch Linux](https://registry-1.docker.io/v2/library/archlinux/manifests/latest) : OS、コンテナベースイメージ
- [Sway](https://swaywm.org) : Wayland コンポジタ、ウィンドウシステム
- [WayVNC](https://github.com/any1/wayvnc) : VNC
- Blender : [公式ビルド tarball](https://download.blender.org/release/) を利用します。

主なディレクトリ構成は次の通りです。    
- `/workspaces/development/`: リポジトリがマウントされます。
- [`/workspaces/development/extensions/`](/extensions/) [*](#環境変数): 直下のディレクトリが  Blender Extension パッケージです。このディレクトリを監視して Extension をホットリロードします。
- [`/workspaces/development/repository/`](/repository/) [*](#環境変数): Blender Extension のリモートリポジトリとして使われます。
- `/workspaces/blender/`: Blender が置かれます。

Docker コンテナ上の Sway については [github.com/stephanlensky/swayvnc-chrome](https://github.com/stephanlensky/swayvnc-chrome) を援用しました。[stephanlensky](https://github.com/stephanlensky/) 様に御礼申し上げます。

#### `novnc` コンテナ : [`/.devcontainer/novnc/`](/.devcontainer/novnc/)
VNC クライアントをブラウザに配信するコンテナです。[`/.devcontainer/novnc/`](/.devcontainer/novnc/) は [`/novnc_setup/`](/novnc_setup) および [`/novnc_setup/setup.sh`](/novnc_setup/setup.sh) によって完全に再現されます。

#### `devcontainer` コンテナ : [`/.devcontainer/devcontainer/`](/.devcontainer/devcontainer/)
Dev Container の接続先となるコンテナです。 `mcr.microsoft.com/devcontainers/base:ubuntu` をベースイメージとし、Blender CLI のための依存関係を備えています。Blender のインストール先となる名前付きボリュームコンテナをマウントしているので、Blender の CLI が使えます。

議論：`devcontainer` コンテナから Blender が使える必要はある？

主なディレクトリ構成は次の通りです。
- `/workspaces/development/`: リポジトリがマウントされます。以下は [`blender` コンテナ](#blender-service-コンテナ--devcontainerblender) と共通です。
- `/workspaces/<blender-service>`: 各 Blender が置かれます。

各 Blender からの出力をターミナルに標準出力してください。
```
tail -f --retry /workspaces/development/output-<blender-service>.log
```

## ショートカットキー
( noVNC の HTML へ注入する JavaScript として実装 )
- `ctrl + c` : 接続先のクリップボードのテキストを接続元のクリップボードにコピーします。
- `ctrl` : 接続元のクリップボードのテキストを接続先のクリップボードにコピーします。ただし、この動作はキーの押下に関わらず 0.1 秒に一度自動的に行われます。
- これらにより、`ctrl + c`, `ctrl + v` がほとんどの方々の期待する通りに動作します。

( Sway へのキーバインドとして実装 )
- `ESC` : Blender の現在のウィンドウを閉じます。

## Extensions ライフサイクル
### パッケージが Blender Extensions として有効であるかどうか確かめます[*](https://docs.blender.org/manual/ja/dev/advanced/command_line/extension_arguments.html#subcommand-build)。

```
/workspaces/<blender-service>/blender --command extension validate <package>
```

`<package>` は Blender Extension パッケージのフルパスです。

### Extension をビルドします[*](https://docs.blender.org/manual/ja/dev/advanced/command_line/extension_arguments.html#subcommand-build)。

```
/workspaces/<blender-service>/blender --command extension build --source-dir <package> --output-dir /workspaces/development/repository
```

`<package>` はBlender Extension パッケージのフルパスです。

### リポジトリを更新します[*](https://docs.blender.org/manual/ja/dev/advanced/command_line/extension_arguments.html#subcommand-server-generate)。

```
/workspaces/<blender-service>/blender --command extension server-generate --repo-dir /workspaces/development/repository
```

## ワークフロー [`/.github/workflows/`](/.github/workflows/)
- [`template.yaml`](/.github/workflows/template.yaml) : Dev Container Template を公開します。
- [`image.yaml`](/.github/workflows/image.yaml) : Dev Container を構成するコンテナイメージを公開します。
- [`release.yaml`](/.github/workflows/release.yaml) : `v*.*.0` というセマンティックバージョニングのタグに対し、リリースを作ります。
- [`depandabot_auto_merge.yaml`](/.github/workflows/depandabot_auto_merge.yaml) : [`depandabot.yaml`](/.github/depandabot.yaml) によりプルリクエストされた依存関係のバージョンアップを自動的にマージします。


## ユーティリティ [`/utils/`](/utils/)
### [`obfuscate/`](/utils/obfuscate/)
[PyArmor](https://pyarmor.readthedocs.io/en/stable/) により、Python を難読化します。

#### [`obfuscate.Dockerfile`](/utils/obfuscate/obfuscate.Dockerfile)

```
docker buildx build --output type=local,dest=. --file "./utils/obfuscate/obfuscate.Dockerfile" [--build-arg PACKAGES="<package1> <package2> ..."] .
```

のようにして使います。[`/extesions/`](/extensions/) を `./extensions/` として参照できる場所で実行するか、パスを指定してフラグ `--build-arg extensions/` を渡します。

`<package1>`, `<package2>`, ... は [`extensions/`](/extensions/) 直下のパッケージとなるディレクトリのベースネームです。
`[--build-arg PACKAGE="<package1> <package2> ..."]` は複数のパッケージを指定できます。
省略した場合は [`extensions/`](/extensions/) 直下の全てのパッケージが対象となります。

#### [`obfuscate.sh`](/utils/obfuscate/obfuscate.sh)

```
utils/obfuscate/obfuscate.sh [package1] [package2] ...
```
のようにして使います。

`[package1]`, `[package2]`, ... は [`extensions/`](/extensions/) 直下のパッケージのとなるディレクトリのベースネームです。0 個以上のパッケージを指定できます。指定されたパッケージが 0 個の場合、[`/extensions/`](extensions/) 直下の全てのパッケージが対象となります。

#### [`obfuscate.yaml`](/utils/obfuscate/obfuscate.yaml)
GitHub Actions ワークフローとして使います。

```
cp utils/obfuscate/obfuscate.yaml .github/workflows/obfuscate.yaml
```

`workflow_dispatch` は対象のパッケージを指定できます。それ以外の場合、
[`extensions/`](/extensions/) 直下の全てのパッケージが対象となります。

## 制限
### Visual Studio Code の拡張機能 `jacqueslucke.blender-development` は使えません。
Visual Studio Code による Blender Extensions 開発の白眉、Jacques Lucke 氏による Visual Studio Code 拡張機能 "Blender Development" ( [`jacqueslucke.blender-development`](https://github.com/JacquesLucke/blender_vscode) ) は使えません。

Visual Studio Code 拡張機能はローカルにインストールされるものであり、コンテナ上の Blender をこれに接続するのは容易ではないためです。

### ウィンドウの x (閉じる)ボタンはありません。
Sway はウィンドウのタイトルバーにボタンを描画しません[*](https://github.com/swaywm/sway/issues/956)。  Sway 上でウィンドウのタイトルバーにボタンを描画するには CSD を使う必要がありますが、Blender の公式ビルドはこれに対応していないようです。

Sway へのキーバインドにより、 `ESC` キーで Blender のフォーカスされたのウィンドウを閉じることができます。

前面ウィンドウ A と背面のウィンドウ B が表示されている場合、前面のウィンドウ A を閉じずに背面のウィンドウ B にフォーカスすると、フォーカスされたウィンドウ B が前面になり、背面のウィンドウ A を二度と見ることができなくなる場合があります。これを回避するには [`/.devcontainer/blender/sway/config`](/.devcontainer/blender/sway/config) において、
```
# Comment out if you are familiar with tiled windows.
for_window [app_id="blender"] floating enable
```
をコメントアウトしてください。

### GPU の利用は確立されていません。
[# 未対応エラー](#未対応エラー) を参照してください。エラーのほとんどは GPU に関連します。

GPU 利用の確立のためには、

- ホストマシン
- Docker
- Arch Linux
- Sway
- Blender

の全てのレイヤーをクリアする必要があります。

## 質疑応答

###  リモートデスクトップクライアントとして何故 noVNC を選んだか？
noVNC はブラウザから接続できる唯一の VNC クライアントであると了解しています[*](https://ja.wikipedia.org/wiki/Virtual_Network_Computing)。

GitHub Codespaces をブラウザから利用するときに、ブラウザの別タブから Blender を利用できます。

### ウィンドウシステムとして X Window System ではなく、何故 Wayland を選んだか？
将来においてウィドウシステムは Wayland が標準になると予想しています。長い将来に亘ってシステムの老朽化を避けたいという願望です。

また、X Window System のエコシステムは熟成し過ぎている印象を受けます。デスクトップ環境とその依存関係にはそれぞれ選択肢が無数に存在し、どれを選ぶべきかという選択に労力を奪われました。

Bledner と Wayland については、
- [Blender マニュアル](https://docs.blender.org/manual/en/latest/getting_started/installing/linux_windowing_environment.html)
- [Blender における Wayland サポート](https://code.blender.org/2022/10/wayland-support-on-linux/)

が参照されます。

### Wayland コンポジタとして何故 Sway を選んだか？
Wayland コンポジタに適したリモートデスクトップサーバーとしては、WayVNC が最も洗練されたツールであるように思いました。

Wayland における ネットワーク透過性については、
- [Wayland FAQ No.8](https://wayland.freedesktop.org/faq.html#heading_toc_j_8)

が参照されます。同記事において、WayVNC に直接言及する記述は次の一文のみです。

> WayVNC is a VNC server that works with compositors, like Sway, based on the wlroots library.

これにならい、Wayland - WayVNC - Sway の採用を進めることにしました。

## 環境変数
以下の環境変数を[`/.env`](/.env) ファイルに記述して設定できます。
### `EXTENSIONS`
```shell:.env
EXTENSIONS=/workspaces/development/extensions/
```
直下のディレクトリを Blender Extensions のパーッケージとします。

[`/.devconatiner/devcontainer.json`](/.devcontainer/devcontainer.json) において、次の部分を手動で書き換える必要があります。
```json: /.devcontainer/devcontainer.json
{
    "workspaceFolder": "/workspaces/development/extensions/${localWorkspaceFolderBasename}",
    "initializeCommand": "mkdir -p extensions/${localWorkspaceFolderBasename}",
}
```

### `REPOSITORY`
```shell:.env
REPOSITORY=/workspaces/development/repository/
```
Blender Extension のリポジトリとして利用するディレクトリです。

## 課題
- エラー対応
- GPU 対応
- MCP サーバー統合
- 共同作業モデル改善


## 未対応エラー
### `<blender-service>` コンテナ
#### Sway
##### `[ERROR] [wlr] [render/wlr_renderer.c:100] drmGetDevices2 failed: No such file or directory`
- GPU 不足によるエラー。
- [`WLR_RENDERER=pixman`](https://github.com/swaywm/wlroots/blob/master/docs/env_vars.md#wlroots-specific
) により、エラーは出なくなる。

#### WayVNC
##### `ERROR: ../wayvnc/src/ext-image-copy-capture.c: 448: No supported buffer formats were found`
- WayVNC と Sway の互換性に依るエラー。
- GPU 不足に関連する可能性あり。

#### Blender

##### `libEGL warning: failed to get driver name for fd -1`
- GPU 不足に関するエラー。
##### `libEGL warning: MESA-LOADER: failed to retrieve device information`
- GPU 不足に関するエラー。
##### `MESA: error: ZINK: vkCreateInstance failed (VK_ERROR_INCOMPATIBLE_DRIVER)`
- GPU 不足に関するエラー。
##### `libEGL warning: egl: failed to create dri2 screen`
- GPU 不足に関するエラー。
##### `EGL Error (0x3009): EGL_BAD_MATCH: Arguments are inconsistent (for example, a valid context requires buffers not supplied by a valid surface).`
- GPU 不足に関するエラー。

## 権利
©令和7年 株式会社 Peakys

[プライバシーポリシー](https://twinengine.jp/privacypolicy/)