# Lin4Neuro - HCP Pipelines Docker Container

English | [日本語](#日本語)

---

## English

Lin4Neuro is a customized Ubuntu-based Linux distribution for neuroimaging analysis. This Docker container includes the Human Connectome Project (HCP) Pipelines and all necessary neuroimaging software tools.

### Included Software

- **HCP Pipelines** v6.0.0
- **FreeSurfer** 6.0.1
- **FSL** 6.0.7.23
- **Connectome Workbench** 2.2.1
- **MSM** (Multimodal Surface Matching) v3.0
- **MATLAB Runtime** R2022b
- **MRIcroGL** v1.2.20220720
- **dcm2niix** v1.0.20260416
- Python 3.12 (venv at `/opt/venv`) with numpy, pandas, matplotlib, seaborn, jupyter, nibabel, nipype, pcntoolkit, and more

### Prerequisites

1. Create a shared directory on your host machine
2. Save your FreeSurfer license file (`license.txt`) in this directory
   - You can obtain a FreeSurfer license from: https://surfer.nmr.mgh.harvard.edu/registration.html

### Starting the Container

1. Open a terminal (Linux/macOS) or PowerShell (Windows)
2. Navigate to your shared directory:

```bash
cd /path/to/your/shared/directory
```

3. Run the following command to start the container:

The same command works on Linux, macOS and Windows (`--privileged` is not needed):

```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

**Windows:** put the shared folder on an **NTFS** drive. exFAT and FAT32 cannot store Linux file ownership, so the `brain` user inside the container cannot write to it. On macOS, exFAT drives work as they are.

### Accessing the Desktop Environment

Open your web browser and navigate to:

```
http://127.0.0.1:6080/vnc.html
```

You will see the Lin4Neuro desktop environment with XFCE4.

### Setting up FreeSurfer License

FreeSurfer 6.0.1 requires the license file to be located at `/usr/local/freesurfer/6.0.1/license.txt`.

**Method 1: Copy from host to container**

```bash
docker cp license.txt l4n-hcp:/usr/local/freesurfer/6.0.1/
```

**Method 2: Copy from shared directory inside the container**

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

- **Linux:** the NVIDIA driver and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html). After installing the toolkit, run:
  ```bash
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  ```
- **Windows:** the NVIDIA driver for Windows and Docker Desktop with the WSL2 backend (no extra toolkit needed)
- **macOS:** not supported (no NVIDIA GPU)

Add `--gpus all` and `-e NVIDIA_DRIVER_CAPABILITIES=compute,utility` when starting the container:

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

`utility` makes `nvidia-smi` available in the container. FSL's `eddy` and `find_cuda_exe` use it to decide whether to run the CUDA version, so do not leave it out.

Check inside the container:

```bash
nvidia-smi                          # the GPU is listed
find_cuda_exe eddy_cuda eddy_cpu    # prints /usr/local/fsl/bin/eddy_cuda
```

In HCP Pipelines, `DiffPreprocPipeline.sh` uses `eddy_cuda` by default (`--gpu=True`). Without a GPU, pass `--gpu=False` to use `eddy_cpu`.

### Running Jobs with fsl_sub (Slurm)

A single-node Slurm runs inside the container, and `fsl_sub` submits to it. Nothing needs to be installed on the host. The CPUs and memory of the machine are detected each time the container starts (`docker logs` shows them).

In the HCP Pipelines batch scripts (`~/projects/HCPpipelines/Examples/Scripts/*Batch.sh`), set:

```bash
QUEUE="main"
```

Each subject then becomes one job. `fsl_sub` can also be used directly:

```bash
fsl_sub -q main -R 16 -l logs -N mytask command args   # -R: memory in GB
squeue                     # list jobs
scancel <job ID>           # cancel a job
```

- A job that does not give `-R` is counted as 8 GB, and jobs run as long as they fit in the memory (minus 2 GB for the desktop). Example: 64 GB → up to 7 jobs at once. The limit is only used for scheduling; actual memory use is not capped
- `docker stop` interrupts the running jobs. On `docker start`, Slurm runs them again **from the beginning**, and queued jobs stay in the queue. To abandon them, `scancel` them after the start
- `fsl_sub_report` does not work (there is no accounting database); use `squeue`
- To disable Slurm, start the container with `-e SLURM=off`. `fsl_sub` then runs jobs in place, as without a cluster

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

### Building the Image

The image is built from the single `Dockerfile` with BuildKit (the default since Docker 23).

The installers are not in the repository. Put these files in `build/packages/` first:

| File |
|---|
| `MATLAB_Runtime_R2022b_Update_7_glnxa64.zip` |
| `MRIcroGL_linux.zip` |
| `dcm2niix_lnx.zip` |
| `freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz` |
| `fsl-6.0.7.23-jammy.tar.gz` |
| `libpng12-0_1.2.54-1ubuntu1.1+1~ppa0~eoan_amd64.deb` |
| `msm_ubuntu_v3` |
| `workbench-linux64-v2.2.1.zip` |

`fsl-6.0.7.23-jammy.tar.gz` is a tarball of FSL 6.0.7.23 freshly installed with `fslinstaller.py` on Ubuntu 22.04. It holds the top-level directory `fsl/` (extracted to `/usr/local/fsl`) and leaves out the conda package cache `pkgs/`.

```bash
docker build --progress=plain -t kytk/l4n-hcppipelines:latest . 2>&1 | tee build.log
```

**Using an Ubuntu mirror (optional):** apt downloads from `archive.ubuntu.com` by default. A nearby mirror can be given with `UBUNTU_MIRROR`:

```bash
docker build --progress=plain \
  --build-arg UBUNTU_MIRROR=https://ftp.riken.jp/Linux/ubuntu \
  -t kytk/l4n-hcppipelines:latest . 2>&1 | tee build.log
```

- `https://` is recommended. On some networks (e.g. behind a caching proxy) HTTP downloads come back broken and apt stops with "Hash Sum mismatch"
- The mirror is used only during the build; the image's `/etc/apt/sources.list` still points to `archive.ubuntu.com`
- `security.ubuntu.com` is not replaced
- Changing the value rebuilds all stages, so keep using the same mirror

### Notes

- This Docker image is provided for research and educational purposes only
- Please comply with the license terms of all included software packages
- FreeSurfer requires registration and a valid license
- Container runs with user `brain` (password: `lin4neuro`)
- The shared directory is mounted at `/home/brain/share` inside the container

### Support

For issues and questions, please visit:
- GitHub Issues: https://github.com/kytk/l4n-HCPpipelines/issues
- Lin4Neuro website: https://www.nemotos.net

---

## 日本語

Lin4Neuro は、ニューロイメージング解析用にカスタマイズされた Ubuntu ベースの Linux ディストリビューションです。この Docker コンテナには、Human Connectome Project (HCP) Pipelines と必要なニューロイメージング解析ソフトウェアがすべて含まれています。

### 含まれるソフトウェア

- **HCP Pipelines** v6.0.0
- **FreeSurfer** 6.0.1
- **FSL** 6.0.7.23
- **Connectome Workbench** 2.2.1
- **MSM** (Multimodal Surface Matching) v3.0
- **MATLAB Runtime** R2022b
- **MRIcroGL** v1.2.20220720
- **dcm2niix** v1.0.20260416
- Python 3.12 (venv: `/opt/venv`)。numpy, pandas, matplotlib, seaborn, jupyter, nibabel, nipype, pcntoolkit など

### 事前準備

1. ホストマシン上に共有用のディレクトリを作成してください
2. FreeSurfer のライセンスファイル（`license.txt`）をこのディレクトリに保存してください
   - FreeSurfer のライセンスは以下から取得できます: https://surfer.nmr.mgh.harvard.edu/registration.html

### コンテナの起動

1. ターミナル（Linux/macOS）または PowerShell（Windows）を開きます
2. 共有ディレクトリに移動します：

```bash
cd 共有ディレクトリのパス
```

3. 以下のコマンドでコンテナを起動します：

Linux、macOS、Windows のいずれも同じコマンドで起動できます（`--privileged` は不要です）：

```bash
docker run \
  --shm-size=4g \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 127.0.0.1:6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipelines:latest
```

**Windows:** 共有フォルダは **NTFS** 形式のドライブに置いてください。exFAT や FAT32 は Linux のファイル所有者情報を保存できないため、コンテナ内の `brain` ユーザーが書き込めません。macOS では exFAT のドライブもそのまま使えます。

### デスクトップ環境へのアクセス

Web ブラウザで以下の URL にアクセスしてください：

```
http://127.0.0.1:6080/vnc.html
```

XFCE4 デスクトップ環境の Lin4Neuro が表示されます。

### FreeSurfer ライセンスの設定

FreeSurfer 6.0.1 は、ライセンスファイルが `/usr/local/freesurfer/6.0.1/license.txt` に配置されている必要があります。

**方法1: ホストからコンテナにコピー**

```bash
docker cp license.txt l4n-hcp:/usr/local/freesurfer/6.0.1/
```

**方法2: コンテナ内の共有ディレクトリからコピー**

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

- **Linux:** NVIDIA ドライバと [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。Toolkit を入れたあと、以下を実行します：
  ```bash
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  ```
- **Windows:** Windows 用の NVIDIA ドライバと、WSL2 バックエンドの Docker Desktop（Toolkit の追加は不要）
- **macOS:** 非対応（NVIDIA GPU がないため）

コンテナ起動時に `--gpus all` と `-e NVIDIA_DRIVER_CAPABILITIES=compute,utility` を付けます：

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

`utility` を指定すると、コンテナ内で `nvidia-smi` が使えるようになります。FSL の `eddy` や `find_cuda_exe` は `nvidia-smi` を使って CUDA 版を使うかどうかを決めるため、省略しないでください。

コンテナ内での確認：

```bash
nvidia-smi                          # GPU が表示される
find_cuda_exe eddy_cuda eddy_cpu    # /usr/local/fsl/bin/eddy_cuda と表示される
```

HCP Pipelines の `DiffPreprocPipeline.sh` は、既定で `eddy_cuda` を使います（`--gpu=True`）。GPU がない環境では `--gpu=False` を指定すると `eddy_cpu` が使われます。

### fsl_sub でジョブを流す（Slurm）

コンテナの中で 1 ノードの Slurm が動いていて、`fsl_sub` はそこにジョブを投げます。ホスト側に何かを入れる必要はありません。マシンの CPU 数とメモリは、コンテナを起動するたびに調べ直します（`docker logs` で確認できます）。

HCP Pipelines の Batch スクリプト（`~/projects/HCPpipelines/Examples/Scripts/*Batch.sh`）で、次のように設定します：

```bash
QUEUE="main"
```

これで被験者ごとに 1 つのジョブになります。`fsl_sub` を直接使うこともできます：

```bash
fsl_sub -q main -R 16 -l logs -N mytask コマンド 引数   # -R: メモリ（GB）
squeue                     # ジョブの一覧
scancel <ジョブ ID>        # ジョブの取り消し
```

- `-R` を指定しないジョブは 8 GB として数えます。メモリ（デスクトップ用に 2 GB を引いた残り）に収まるだけのジョブが同時に動きます。例: 64 GB → 最大 7 本。これは同時に流す本数を決めるためだけの値で、実際のメモリ使用量は制限されません
- `docker stop` で実行中のジョブは中断されます。`docker start` すると、Slurm はそれらを**最初から**実行し直します（待ち行列のジョブもそのまま残ります）。やめたいジョブは起動後に `scancel` してください
- `fsl_sub_report` は使えません（accounting のデータベースがないため）。`squeue` を使ってください
- Slurm を使わないときは、`-e SLURM=off` を付けてコンテナを起動します。この場合 `fsl_sub` は、クラスタがないときと同じようにその場でジョブを実行します

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

### イメージのビルド

イメージは 1 つの `Dockerfile` から BuildKit（Docker 23 以降の既定）でビルドします。

インストーラ類はリポジトリに含まれていません。先に次のファイルを `build/packages/` に置いてください：

| ファイル |
|---|
| `MATLAB_Runtime_R2022b_Update_7_glnxa64.zip` |
| `MRIcroGL_linux.zip` |
| `dcm2niix_lnx.zip` |
| `freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz` |
| `fsl-6.0.7.23-jammy.tar.gz` |
| `libpng12-0_1.2.54-1ubuntu1.1+1~ppa0~eoan_amd64.deb` |
| `msm_ubuntu_v3` |
| `workbench-linux64-v2.2.1.zip` |

`fsl-6.0.7.23-jammy.tar.gz` は、Ubuntu 22.04 に `fslinstaller.py` で新しくインストールした FSL 6.0.7.23 を tar にしたものです。最上位のディレクトリは `fsl/`（`/usr/local/fsl` に展開されます）で、conda のパッケージキャッシュ `pkgs/` は含めません。

```bash
docker build --progress=plain -t kytk/l4n-hcppipelines:latest . 2>&1 | tee build.log
```

**Ubuntu のミラーを使う（任意）：** apt は既定では `archive.ubuntu.com` から取得します。`UBUNTU_MIRROR` で近くのミラーを指定できます：

```bash
docker build --progress=plain \
  --build-arg UBUNTU_MIRROR=https://ftp.riken.jp/Linux/ubuntu \
  -t kytk/l4n-hcppipelines:latest . 2>&1 | tee build.log
```

- `https://` を推奨します。ネットワークによっては（キャッシュするプロキシの内側など）HTTP で取得したファイルが壊れていて、apt が「Hash Sum mismatch」で止まります
- ミラーを使うのはビルドの間だけです。イメージの `/etc/apt/sources.list` は `archive.ubuntu.com` のままです
- `security.ubuntu.com` は置き換えません
- 値を変えるとすべてのステージがビルドし直しになるので、同じミラーを使い続けてください

### 注意事項

- この Docker イメージは研究および教育目的でのみ提供されています
- 含まれるすべてのソフトウェアパッケージのライセンス条項を遵守してください
- FreeSurfer は登録と有効なライセンスが必要です
- コンテナは `brain` ユーザーで実行されます（パスワード: `lin4neuro`）
- 共有ディレクトリはコンテナ内の `/home/brain/share` にマウントされます

### サポート

問題や質問については、以下をご覧ください：
- GitHub Issues: https://github.com/kytk/l4n-HCPpipelines/issues
- Lin4Neuro ウェブサイト: https://www.nemotos.net

---

## License

This Docker container includes multiple software packages, each with its own license. Please ensure you comply with all applicable licenses:

- FreeSurfer: Requires registration and license agreement
- FSL: Requires registration and license agreement
- HCP Pipelines: Custom license by Washington University
- Other software: Various open-source licenses

**Author:** K. Nemoto
**Date:** 2026-01-04
