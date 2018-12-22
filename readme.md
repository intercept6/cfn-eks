# EKSのセットアップ

## 初回セットアップ

### クライアントサイド

1. 実行ファイルを格納するディレクトリの作成とパス設定
   ```bash
   mkdir ~/bin
   echo 'export PATH=$HOME/bin:$PATH' >> ~/.bash_profile
   source ~/.bash_profile
   ```
2. kubectlのダウンロード
   ```bash
   curl -o ~/bin/eks-kubectl-1.10.3 https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/darwin/amd64/kubectl
   curl -o ~/bin/eks-kubectl-1.11.5    https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.   5/2018-12-06/bin/darwin/amd64/kubectl
   chmod +x ~/bin/eks-kubectl-1.10.3
   chmod +x ~/bin/eks-kubectl-1.11.5
   ```
3. authenticatorのダウンロード
   ```bash
   curl -o ~/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/darwin/amd64/aws-iam-authenticator
   chmod +x ~/bin/aws-iam-authenticator
   ```
4. AWS認証情報と```KUBECONFIG```を[direnv](https://dev.classmethod.jp/tool/direnv/)を使って環境変数に設定  
[assume\-role](https://github.com/remind101/assume-role)を使用  
```KUBECONFIG```は設定しなければ```$HOME```に作成される好みで設定する  
   ```bash
   vi .envrc
   ```

   ```bash
   eval $(assume-role default)
   export KUBECONFIG=.kube/config
   alias kubectl="~/bin/eks-kubectl-1.10.3"
   ```

### サーバーサイド

1. 対象AWSリージョンにKeyPairを作成する
2. スタック名やクラスタのバージョンなど環境変数を設定する(envs)
    ```bash
    cp envs.sample envs
    vi envs
    ```
3. 初回セットアップの実行
   ```bash
   ./initial_eks_deploy.sh
   aws eks update-kubeconfig --name ${K8S_CLUSTER_NAME}
   ```
4. ワーカーノードをクラスターと結合
   ```bash
   curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-08-30/aws-auth-cm.yaml
   #  <ARN of instance role (not instance profile)>をインスタンスロールに置換
   vi aws-auth-cm.yaml
   kubectl apply -f aws-auth-cm.yamls
   ```
5. ワーカーノードがReadyになるのを確認する
   ```bash
   kubectl get nodes --watch
   ```
6. 完了