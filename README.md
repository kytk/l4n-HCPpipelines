# Lin4Neuro - HCP Pipeline Docker Container

English | [日本語](#日本語)

---

## English

Lin4Neuro is a customized Ubuntu-based Linux distribution for neuroimaging analysis. This Docker container includes the Human Connectome Project (HCP) Pipeline and all necessary neuroimaging software tools.

### Included Software

- **HCP Pipelines** v5.0.0
- **FreeSurfer** 6.0.1
- **FSL** 6.0.7.18
- **Connectome Workbench**
- **MSM** (Multimodal Surface Matching) v3.0
- **MATLAB Runtime** R2022b
- **MRIcroGL**
- **dcm2niix**
- Python packages: numpy, pandas, matplotlib, seaborn, jupyter, nibabel, nipype, and more

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

```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipeline:latest
```

### Accessing the Desktop Environment

Open your web browser and navigate to:

```
http://localhost:6080/vnc.html
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
  kytk/l4n-hcppipeline:latest
```

Default resolution: 1600x900x24

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

### Notes

- This Docker image is provided for research and educational purposes only
- Please comply with the license terms of all included software packages
- FreeSurfer requires registration and a valid license
- Container runs with user `brain` (password: `lin4neuro`)
- The shared directory is mounted at `/home/brain/share` inside the container

### Support

For issues and questions, please visit:
- GitHub Issues: https://github.com/kytk/l4n-HCPpipeline/issues
- Lin4Neuro website: https://www.nemotos.net

---

## 日本語

Lin4Neuro は、ニューロイメージング解析用にカスタマイズされた Ubuntu ベースの Linux ディストリビューションです。この Docker コンテナには、Human Connectome Project (HCP) Pipeline と必要なニューロイメージング解析ソフトウェアがすべて含まれています。

### 含まれるソフトウェア

- **HCP Pipelines** v5.0.0
- **FreeSurfer** 6.0.1
- **FSL** 6.0.7.18
- **Connectome Workbench**
- **MSM** (Multimodal Surface Matching) v3.0
- **MATLAB Runtime** R2022b
- **MRIcroGL**
- **dcm2niix**
- Python パッケージ: numpy, pandas, matplotlib, seaborn, jupyter, nibabel, nipype など

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

```bash
docker run \
  --shm-size=4g \
  --privileged \
  --platform linux/amd64 \
  --name l4n-hcp \
  -d -p 6080:6080 \
  -v .:/home/brain/share \
  kytk/l4n-hcppipeline:latest
```

### デスクトップ環境へのアクセス

Web ブラウザで以下の URL にアクセスしてください：

```
http://localhost:6080/vnc.html
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
  kytk/l4n-hcppipeline:latest
```

デフォルト解像度: 1600x900x24

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

### 注意事項

- この Docker イメージは研究および教育目的でのみ提供されています
- 含まれるすべてのソフトウェアパッケージのライセンス条項を遵守してください
- FreeSurfer は登録と有効なライセンスが必要です
- コンテナは `brain` ユーザーで実行されます（パスワード: `lin4neuro`）
- 共有ディレクトリはコンテナ内の `/home/brain/share` にマウントされます

### サポート

問題や質問については、以下をご覧ください：
- GitHub Issues: https://github.com/kytk/l4n-HCPpipeline/issues
- Lin4Neuro ウェブサイト: https://www.nemotos.net

---

## License

This Docker container includes multiple software packages, each with its own license. Please ensure you comply with all applicable licenses:

- FreeSurfer: Requires registration and license agreement
- FSL: Requires registration and license agreement
- HCP Pipelines: Custom license by Washington University
- Other software: Various open-source licenses

**Author:** K. Nemoto
**Date:** December 25, 2025
**Version:** 1.0
