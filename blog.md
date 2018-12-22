# EKSのアップデート方法を検証してみた

## 検証用EKSの作成

### 環境変数の設定

AWS認証情報と```KUBECONFIG```を[direnv](https://dev.classmethod.jp/tool/direnv/)を使って環境変数に設定します｡  
[assume\-role](https://github.com/remind101/assume-role)を使用しています｡  

[bash title=".envrc"]
eval $(assume-role default)
export KUBECONFIG=.kube/config
alias kubectl="~/bin/eks-kubectl-1.10.3"
[/bash]

## クラスタの作成

[weaveworks/eksctl: a CLI for Amazon EKS](https://github.com/weaveworks/eksctl)	

eksctlを使ってEKSを構築します｡Homebrewからインストールしました｡  

```bash
brew install weaveworks/tap/eksctl
```


```bash
eksctl create cluster \
--region=us-west-2 \
--name=update-test \
--version=1.10 \
--node-type=t3.medium \
--nodes=3
```


```bash
curl -o ~/bin/eks-kubectl-1.10.3 https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/darwin/amd64/kubectl
curl -o ~/bin/eks-kubectl-1.11.5 https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/darwin/amd64/kubectl
chmod +x ~/bin/eks-kubectl-1.10.3
chmod +x ~/bin/eks-kubectl-1.11.5
```