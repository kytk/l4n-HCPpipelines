# kytk/l4n-hcppipelines - Lin4Neuro HCP Pipeline Docker Container

[English](#english) | [日本語](#japanese)

---

## English

### Overview
Lin4Neuro is a customized Ubuntu-based Linux distribution for neuroimaging analysis. `kytk/l4n-hcppipelines` is a comprehensive Docker container that includes the Human Connectome Project (HCP) Pipelines and all necessary neuroimaging software tools. The container provides a complete desktop environment with pre-installed neuroimaging software packages. The container runs an XFCE4 desktop accessible via web browser through noVNC.

### Features
- **Complete Desktop Environment**: XFCE4 desktop with web browser access
- **Pre-installed Neuroimaging Software**:
  - HCP Pipelines v6.0.0
  - FreeSurfer 6.0.1
  - FSL 6.0.7.23
  - Connectome Workbench 2.2.1
  - MSM (Multimodal Surface Matching) v3.0
  - MATLAB Runtime R2022b
  - MRIcroGL v1.2.20220720
  - dcm2niix v1.0.20260416
- **Development Tools**: Python 3.12 (venv at `/opt/venv`), Jupyter Notebook, Git
- **Python Packages**: numpy, pandas, matplotlib, seaborn, nibabel, nipype, pcntoolkit, and more
- **Multi-language Support**: English and Japanese fonts/locales

### Quick Start

#### Prerequisites
- Docker installed on your system
- FreeSurfer license file (`license.txt`)
  - You can obtain a FreeSurfer license from: https://surfer.nmr.mgh.harvard.edu/registration.html

#### Basic Usage (GUI Mode)

The same command works on Linux, macOS and Windows:
```bash
# Place your FreeSurfer license.txt in the current directory
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

- `-p 127.0.0.1:6080:6080` makes the desktop reachable only from your own computer (the VNC password is public).
- `--privileged` is not needed on any platform.

#### Shared Folder Format (Windows)
On Windows, the shared folder must be on an **NTFS** drive. exFAT and FAT32 cannot store Linux file ownership, so the `brain` user inside the container cannot write to the folder. If your external drive is exFAT, back up its contents and reformat it as NTFS. On macOS, exFAT drives work as they are.

#### Interactive Shell Mode
```bash
docker run -it \
  --shm-size=4g \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### Access the Desktop
1. Open your web browser
2. Navigate to `http://127.0.0.1:6080/vnc.html`
3. Enter password: `lin4neuro`

### Environment Modes

#### GUI Mode (Default)
- Starts XFCE4 desktop environment
- Accessible via web browser at `http://127.0.0.1:6080/vnc.html`
- Password: `lin4neuro`

#### Bash Mode
- Provides interactive command-line access
- Start the container with `-it` instead of `-d` (no `-p` needed): a shell as `brain` opens instead of the desktop
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

### Data path

Modified scripts assumes that your data is saved under `~/share/HCPpipelines_ExampleData` . Please prepare "HCPpipelines_ExampleData" directory under your shared path.

### Custom Resolution

You can specify a custom resolution when starting the container by setting the `RESOLUTION` environment variable:

```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -e RESOLUTION=1600x900x24 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

Default resolution: 1920x1080x24. The value must be `WIDTHxHEIGHTxDEPTH` (depth 8, 16, 24 or 32); anything else falls back to the default (see `docker logs`).

### Using an NVIDIA GPU

The FSL CUDA programs (`eddy_cuda`, `bedpostx_gpu`, `xfibres_gpu`, `probtrackx2_gpu`, `mmorf_cuda`) are included. To run them on the GPU, the host needs:

- **Linux:** the NVIDIA driver and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html), then `sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker`
- **Windows:** the NVIDIA driver for Windows and Docker Desktop with the WSL2 backend
- **macOS:** not supported

```bash
docker run \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

`utility` makes `nvidia-smi` available in the container; FSL's `eddy` and `find_cuda_exe` use it to decide whether to run the CUDA version. Check with `nvidia-smi` and `find_cuda_exe eddy_cuda eddy_cpu` (prints `/usr/local/fsl/bin/eddy_cuda`). `DiffPreprocPipeline.sh` uses `eddy_cuda` by default (`--gpu=True`); without a GPU, pass `--gpu=False`.

### Port Mapping
- Port `6080`: noVNC web interface

### Default User
- Username: `brain`
- Password: `lin4neuro`
- Home directory: `/home/brain`

### Software Paths and Environment Variables
- **HCP Pipelines**: `/home/brain/projects/HCPpipelines` (HCPPIPEDIR set in `Examples/Scripts/SetUpHCPPipeline.sh`)
- **FreeSurfer**: `/usr/local/freesurfer/6.0.1` (automatically configured)
- **FSL**: `/usr/local/fsl` (FSLDIR set)
- **Connectome Workbench**: `/usr/local/workbench` (in PATH)
- **MSM**: Available in PATH
- **MATLAB Runtime**: `/usr/local/MATLAB/MCR/R2022b`

### Example Commands

#### Run with data mount
```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  -v /path/to/neuroimaging/data:/home/brain/data \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### Interactive session
```bash
docker run -it \
  --shm-size=4g \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### With custom resolution and memory limit
```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  -d -p 127.0.0.1:6080:6080 \
  -e RESOLUTION=1600x900x24 \
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
Lin4Neuro は、ニューロイメージング解析用にカスタマイズされた Ubuntu ベースの Linux ディストリビューションです。`kytk/l4n-hcppipelines` は、Human Connectome Project (HCP) Pipelines と必要なニューロイメージング解析ソフトウェアがすべて含まれた統合Dockerコンテナです。事前にインストールされた神経画像解析ソフトウェアパッケージを含む完全なデスクトップ環境を提供し、noVNCを通じてWebブラウザからXFCE4デスクトップにアクセスできます。

### 特徴
- **完全なデスクトップ環境**: WebブラウザアクセスでXFCE4デスクトップ
- **事前インストール済み神経画像解析ソフトウェア**:
  - HCP Pipelines v6.0.0
  - FreeSurfer 6.0.1
  - FSL 6.0.7.23
  - Connectome Workbench 2.2.1
  - MSM (Multimodal Surface Matching) v3.0
  - MATLAB Runtime R2022b
  - MRIcroGL v1.2.20220720
  - dcm2niix v1.0.20260416
- **開発ツール**: Python 3.12 (venv: `/opt/venv`), Jupyter Notebook, Git
- **Python パッケージ**: numpy, pandas, matplotlib, seaborn, nibabel, nipype, pcntoolkit など
- **多言語サポート**: 英語・日本語フォント/ロケール

### クイックスタート

#### 前提条件
- システムにDockerがインストールされていること
- FreeSurferライセンスファイル（`license.txt`）
  - FreeSurfer のライセンスは以下から取得できます: https://surfer.nmr.mgh.harvard.edu/registration.html

#### 基本使用方法（GUIモード）

Linux、macOS、Windows のいずれも同じコマンドで起動できます:
```bash
# FreeSurferのlicense.txtを現在のディレクトリに配置
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

- `-p 127.0.0.1:6080:6080` とすることで、デスクトップには自分のコンピュータからのみ接続できます（VNC のパスワードは公開されているため）。
- どの OS でも `--privileged` は不要です。

#### 共有フォルダの形式（Windows）
Windows では、共有フォルダは **NTFS** 形式のドライブに置いてください。exFAT や FAT32 は Linux のファイル所有者情報を保存できないため、コンテナ内の `brain` ユーザーが共有フォルダに書き込めません。外付けドライブが exFAT の場合は、中身をバックアップしてから NTFS で再フォーマットしてください。macOS では exFAT のドライブもそのまま使えます。

#### 対話型シェルモード
```bash
docker run -it \
  --shm-size=4g \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### デスクトップへのアクセス
1. Webブラウザを開く
2. `http://127.0.0.1:6080/vnc.html` にアクセス
3. パスワードを入力: `lin4neuro`

### 環境モード

#### GUIモード（デフォルト）
- XFCE4デスクトップ環境を開始
- Webブラウザから `http://127.0.0.1:6080/vnc.html` でアクセス
- パスワード: `lin4neuro`

#### Bashモード
- 対話型コマンドラインアクセスを提供
- `-d` の代わりに `-it` を付けて起動します（`-p` は不要）。デスクトップの代わりに `brain` ユーザーのシェルが開きます
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

### データのパス

修正したスクリプトは、HCP Pipelinesの解析データが  `~/share/HCPpipelines_ExampleData` にあると想定しています。したがって、 "HCPpipelines_ExampleData" ディレクトリを共有ディレクトリの直下に準備してください。

### カスタム解像度

コンテナ起動時に `RESOLUTION` 環境変数を設定することで、カスタム解像度を指定できます：

```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -e RESOLUTION=1600x900x24 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

デフォルト解像度: 1920x1080x24。値は `幅x高さx色深度`（色深度は 8, 16, 24, 32 のいずれか）の形式で指定してください。それ以外の値の場合はデフォルトが使われます（`docker logs` で確認できます）。

### NVIDIA GPU を使う

FSL の CUDA 版プログラム（`eddy_cuda`、`bedpostx_gpu`、`xfibres_gpu`、`probtrackx2_gpu`、`mmorf_cuda`）が入っています。GPU で動かすには、ホスト側に以下が必要です。

- **Linux:** NVIDIA ドライバと [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。入れたあと `sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker` を実行
- **Windows:** Windows 用の NVIDIA ドライバと、WSL2 バックエンドの Docker Desktop
- **macOS:** 非対応

```bash
docker run \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

`utility` を指定すると、コンテナ内で `nvidia-smi` が使えます。FSL の `eddy` や `find_cuda_exe` はこれを使って CUDA 版を使うか決めます。`nvidia-smi` と `find_cuda_exe eddy_cuda eddy_cpu`（`/usr/local/fsl/bin/eddy_cuda` と表示される）で確認できます。`DiffPreprocPipeline.sh` は既定で `eddy_cuda` を使います（`--gpu=True`）。GPU がない環境では `--gpu=False` を指定してください。

### ポートマッピング
- ポート `6080`: noVNC Webインターフェース

### デフォルトユーザー
- ユーザー名: `brain`
- パスワード: `lin4neuro`
- ホームディレクトリ: `/home/brain`

### ソフトウェアパスと環境変数
- **HCP Pipelines**: `/home/brain/projects/HCPpipelines` (HCPPIPEDIR は `Examples/Scripts/SetUpHCPPipeline.sh` で設定)
- **FreeSurfer**: `/usr/local/freesurfer/6.0.1` (自動設定)
- **FSL**: `/usr/local/fsl` (FSLDIR設定済み)
- **Connectome Workbench**: `/usr/local/workbench` (PATH設定済み)
- **MSM**: PATH利用可能
- **MATLAB Runtime**: `/usr/local/MATLAB/MCR/R2022b`

### コマンド例

#### データマウントありで実行
```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  -v /path/to/neuroimaging/data:/home/brain/data \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### 対話セッション
```bash
docker run -it \
  --shm-size=4g \
  --platform linux/amd64 \
  -v .:/home/brain/share \
  --name l4n-hcp \
  kytk/l4n-hcppipelines:latest
```

#### カスタム解像度とメモリ制限あり
```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  -d -p 127.0.0.1:6080:6080 \
  -e RESOLUTION=1600x900x24 \
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
- Disk space: ~31GB for container image
- Supported platforms: Linux (x86_64), macOS (x86_64), Windows with WSL2
- Docker flags required: `--shm-size=4g --platform linux/amd64` (no `--privileged` needed)
- Shared folder on Windows: NTFS drive required (exFAT/FAT32 cannot store Linux file ownership)
- GPU (optional): NVIDIA GPU with the NVIDIA Container Toolkit (Linux) or Docker Desktop + WSL2 (Windows); start with `--gpus all`

### Container Details
- Base image: Ubuntu 22.04 LTS
- Desktop environment: XFCE4
- VNC server: x11vnc
- Web interface: noVNC
- Default user: brain (non-root)
- Default resolution: 1920x1080x24 (customizable via RESOLUTION environment variable)

### Included Software Versions
- HCP Pipelines: v6.0.0
- FreeSurfer: 6.0.1
- FSL: 6.0.7.23
- Connectome Workbench: 2.2.1
- MSM: v3.0
- MATLAB Runtime: R2022b
- MRIcroGL: v1.2.20220720
- dcm2niix: v1.0.20260416

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
- 2026-10-03: Connectome Workbench 2.2.1 (official build), octave removed, noVNC no longer hangs before the password prompt, "Neuroimaging" submenu in the desktop menu.
- 2026-09-27: HCP Pipelines v6.0.0 (FreeSurfer 6.0.1 kept), FSL 6.0.7.23, Python 3.12 venv (`/opt/venv`), MATLAB steps use the compiled runtime (MatlabMode=0), smaller image. The shared folder is always `/home/brain/share` (NTFS on Windows); `--privileged` is no longer needed.
- 2026-01-04: modify scripts so that data can be saved outside containers.
- 2025-12-25: Initial release with HCP Pipelines v5.0.0 and complete neuroimaging analysis environment
