#!/bin/sh

DEVSPACE_VERSION="latest"


npm install -g pnpm tsx taze

ARCH_SHORT="arm64"
ARCH=$(arch)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_SHORT="amd64"
fi

echo "Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH_SHORT/kubectl"
chmod +x kubectl
install -p kubectl /usr/local/bin;
rm kubectl

echo "Installing helm"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
rm get_helm.sh

echo "Installing devspace"
curl -s "https://api.github.com/repos/loft-sh/devspace/releases/$DEVSPACE_VERSION" | grep "browser_download_url.*devspace-linux-$ARCH_SHORT" | cut -d : -f 2,3 | tr -d \" | grep -v '.sha256' | wget -O devspace -qi -chmod +x devspace
install -p devspace /usr/local/bin;
rm devspace

devspace add plugin https://github.com/loft-sh/loft-devspace-plugin

curl -s https://api.github.com/repos/loft-sh/loft/releases/latest | grep "browser_download_url.*loft-linux-$ARCH_SHORT" | cut -d : -f 2,3 | tr -d \" | grep -v '.sha256' | wget -O loft -qi -
chmod +x loft
install -p loft /usr/local/bin;
rm loft

kubectl version
helm version
devspace version
echo "Installation complete"