# kytk/l4n-hcppipelines - Lin4Neuro HCP Pipeline Docker Container

[English](#english) | [日本語](#japanese)

---

## English

### Overview
`kytk/l4n-hcppipelines` is a comprehensive Docker container for neuroimaging analysis with the Human Connectome Project (HCP) Pipeline. The container provides a complete desktop environment with pre-installed neuroimaging software packages. The container runs an XFCE4 desktop accessible via web browser through noVNC.

### Features
- **Complete Desktop Environment**: XFCE4 desktop with web browser access
- **Pre-installed Neuroimaging Software**:
  - HCP Pipelines v5.0.0
  - FreeSurfer 6.0.1
  - FSL 6.0.7.18
  - Connectome Workbench
  - MSM (Multimodal Surface Matching) v3.0
  - MATLAB Runtime R2022b
  - MRIcroGL
  - dcm2niix
- **Development Tools**: Python 3, Jupyter Notebook, Git
- **Python Packages**: numpy, pandas, matplotlib, seaborn, nibabel, nipype, and more
- **Multi-language Support**: English and Japanese fonts/locales

### Quick Start

#### Prerequisites
- Docker installed on your system
- FreeSurfer license file (`license.txt`)
  - You can obtain a FreeSurfer license from: https://surfer.nmr.mgh.harvard.edu/registration.html

#### Basic Usage (GUI Mode)
```bash
# Place your FreeSurfer license.txt in the current directory
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

#### Interactive Shell Mode
```bash
docker run -it \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  -e MODE=bash \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### Access the Desktop
1. Open your web browser
2. Navigate to `http://localhost:6080/vnc.html`
3. Enter password: `lin4neuro`

### Environment Modes

#### GUI Mode (Default)
- Starts XFCE4 desktop environment
- Accessible via web browser at `http://localhost:6080/vnc.html`
- Password: `lin4neuro`

#### Bash Mode
- Provides interactive command-line access
- Use `-e MODE=bash` flag
- All neuroimaging tools available in PATH
- HCP Pipelines and all dependencies are pre-configured

### Volume Mounts

#### Required: Shared Directory
```bash
-v .:/home/brain/share
```
**Important**: Your FreeSurfer `license.txt` must be in the mounted directory.

#### Optional: Data Directory
```bash
-v /path/to/your/data:/home/brain/data
```

### FreeSurfer License Setup

FreeSurfer 6.0.1 requires the license file to be located at `/usr/local/freesurfer/6.0.1/license.txt`.

#### Method 1: Copy from host to container
```bash
docker cp license.txt l4n-hcp:/usr/local/freesurfer/6.0.1/
```

#### Method 2: Copy from shared directory inside the container
After accessing the container desktop, open a terminal and run:
```bash
sudo cp /home/brain/share/license.txt /usr/local/freesurfer/6.0.1/
```

### Custom Resolution

You can specify a custom resolution when starting the container by setting the `RESOLUTION` environment variable:

```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 6080:6080 \
  -e RESOLUTION=1920x1080x24 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

Default resolution: 1600x900x24

### Port Mapping
- Port `6080`: noVNC web interface

### Default User
- Username: `brain`
- Password: `lin4neuro`
- Home directory: `/home/brain`

### Software Paths and Environment Variables
- **HCP Pipelines**: `/opt/HCP-Pipelines` (HCPPIPEDIR set)
- **FreeSurfer**: `/usr/local/freesurfer/6.0.1` (automatically configured)
- **FSL**: `/usr/local/fsl` (FSLDIR set)
- **Connectome Workbench**: Available in PATH
- **MSM**: Available in PATH
- **MATLAB Runtime**: `/usr/local/MATLAB/MATLAB_Runtime/R2022b`

### Example Commands

#### Run with data mount
```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -d -p 6080:6080 \
  -v .:/home/brain/share \
  -v /path/to/neuroimaging/data:/home/brain/data \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### Interactive session
```bash
docker run -it \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  -e MODE=bash \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest \
  /bin/bash
```

#### With custom resolution and memory limit
```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -d -p 6080:6080 \
  -e RESOLUTION=1920x1080x24 \
  -v .:/home/brain/share \
  -m 8g \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

### Container Management

**Stop the container:**
```bash
docker stop l4n-hcp
```

**Start the container again:**
```bash
docker start l4n-hcp
```

**Remove the container:**
```bash
docker rm -f l4n-hcp
```

### Troubleshooting
- If GUI doesn't load, wait 30 seconds for all services to start
- Check container logs: `docker logs l4n-hcp`
- Restart container: `docker restart l4n-hcp`
- Ensure FreeSurfer license is properly installed at `/usr/local/freesurfer/6.0.1/license.txt`

---

## Japanese

### 概要
`kytk/l4n-hcppipelines` は、Human Connectome Project (HCP) Pipeline を含む神経画像解析のための統合Dockerコンテナです。事前にインストールされた神経画像解析ソフトウェアパッケージを含む完全なデスクトップ環境を提供し、noVNCを通じてWebブラウザからXFCE4デスクトップにアクセスできます。

### 特徴
- **完全なデスクトップ環境**: WebブラウザアクセスでXFCE4デスクトップ
- **事前インストール済み神経画像解析ソフトウェア**:
  - HCP Pipelines v5.0.0
  - FreeSurfer 6.0.1
  - FSL 6.0.7.18
  - Connectome Workbench
  - MSM (Multimodal Surface Matching) v3.0
  - MATLAB Runtime R2022b
  - MRIcroGL
  - dcm2niix
- **開発ツール**: Python 3, Jupyter Notebook, Git
- **Python パッケージ**: numpy, pandas, matplotlib, seaborn, nibabel, nipype など
- **多言語サポート**: 英語・日本語フォント/ロケール

### クイックスタート

#### 前提条件
- システムにDockerがインストールされていること
- FreeSurferライセンスファイル（`license.txt`）
  - FreeSurfer のライセンスは以下から取得できます: https://surfer.nmr.mgh.harvard.edu/registration.html

#### 基本使用方法（GUIモード）
```bash
# FreeSurferのlicense.txtを現在のディレクトリに配置
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

#### 対話型シェルモード
```bash
docker run -it \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  -e MODE=bash \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### デスクトップへのアクセス
1. Webブラウザを開く
2. `http://localhost:6080/vnc.html` にアクセス
3. パスワードを入力: `lin4neuro`

### 環境モード

#### GUIモード（デフォルト）
- XFCE4デスクトップ環境を開始
- Webブラウザから `http://localhost:6080/vnc.html` でアクセス
- パスワード: `lin4neuro`

#### Bashモード
- 対話型コマンドラインアクセスを提供
- `-e MODE=bash` フラグを使用
- すべての神経画像解析ツールがPATHで利用可能
- HCP Pipelines とすべての依存関係が事前設定済み

### ボリュームマウント

#### 必須: 共有ディレクトリ
```bash
-v .:/home/brain/share
```
**重要**: FreeSurferの `license.txt` がマウントされたディレクトリに存在する必要があります。

#### オプション: データディレクトリ
```bash
-v /path/to/your/data:/home/brain/data
```

### FreeSurfer ライセンスの設定

FreeSurfer 6.0.1 は、ライセンスファイルが `/usr/local/freesurfer/6.0.1/license.txt` に配置されている必要があります。

#### 方法1: ホストからコンテナにコピー
```bash
docker cp license.txt l4n-hcp:/usr/local/freesurfer/6.0.1/
```

#### 方法2: コンテナ内の共有ディレクトリからコピー
コンテナのデスクトップにアクセスした後、ターミナルを開いて以下を実行：
```bash
sudo cp /home/brain/share/license.txt /usr/local/freesurfer/6.0.1/
```

### カスタム解像度

コンテナ起動時に `RESOLUTION` 環境変数を設定することで、カスタム解像度を指定できます：

```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 6080:6080 \
  -e RESOLUTION=1920x1080x24 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

デフォルト解像度: 1600x900x24

### ポートマッピング
- ポート `6080`: noVNC Webインターフェース

### デフォルトユーザー
- ユーザー名: `brain`
- パスワード: `lin4neuro`
- ホームディレクトリ: `/home/brain`

### ソフトウェアパスと環境変数
- **HCP Pipelines**: `/opt/HCP-Pipelines` (HCPPIPEDIR設定済み)
- **FreeSurfer**: `/usr/local/freesurfer/6.0.1` (自動設定)
- **FSL**: `/usr/local/fsl` (FSLDIR設定済み)
- **Connectome Workbench**: PATH利用可能
- **MSM**: PATH利用可能
- **MATLAB Runtime**: `/usr/local/MATLAB/MATLAB_Runtime/R2022b`

### コマンド例

#### データマウントありで実行
```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -d -p 6080:6080 \
  -v .:/home/brain/share \
  -v /path/to/neuroimaging/data:/home/brain/data \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### 対話セッション
```bash
docker run -it \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  -e MODE=bash \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest \
  /bin/bash
```

#### カスタム解像度とメモリ制限あり
```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  -d -p 6080:6080 \
  -e RESOLUTION=1920x1080x24 \
  -v .:/home/brain/share \
  -m 8g \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

### コンテナ管理

**コンテナの停止:**
```bash
docker stop l4n-hcp
```

**コンテナの再起動:**
```bash
docker start l4n-hcp
```

**コンテナの削除:**
```bash
docker rm -f l4n-hcp
```

### トラブルシューティング
- GUIが読み込まれない場合は、すべてのサービスが開始されるまで30秒お待ちください
- コンテナログを確認: `docker logs l4n-hcp`
- コンテナを再起動: `docker restart l4n-hcp`
- FreeSurferライセンスが `/usr/local/freesurfer/6.0.1/license.txt` に正しくインストールされていることを確認してください

---

## Technical Details

### System Requirements
- RAM: 8GB minimum, 16GB+ recommended (for HCP Pipeline processing)
- Disk space: ~20GB for container image
- Supported platforms: Linux (x86_64), macOS (x86_64), Windows with WSL2
- Docker flags required: `--shm-size=4g --privileged --platform linux/amd64`

### Container Details
- Base image: Ubuntu 22.04 LTS
- Desktop environment: XFCE4
- VNC server: x11vnc
- Web interface: noVNC
- Default user: brain (non-root)
- Default resolution: 1600x900x24 (customizable via RESOLUTION environment variable)

### Included Software Versions
- HCP Pipelines: v5.0.0
- FreeSurfer: 6.0.1
- FSL: 6.0.7.18
- Connectome Workbench: Latest
- MSM: v3.0
- MATLAB Runtime: R2022b

### License
This container includes multiple software packages, each with its own license. Users are responsible for ensuring compliance with all applicable licenses:

- FreeSurfer: Requires registration and license agreement
- FSL: Requires registration and license agreement
- HCP Pipelines: Custom license by Washington University
- Other software: Various open-source licenses

### Support
- Author: K. Nemoto
- GitHub: https://github.com/kytk/l4n-HCPpipelines
- Lin4Neuro website: https://www.nemotos.net
- Issues: https://github.com/kytk/l4n-HCPpipelines/issues

### Version History
- v1.0 (December 2025): Initial release with HCP Pipelines v5.0.0 and complete neuroimaging analysis environment
