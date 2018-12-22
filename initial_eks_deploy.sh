#!/bin/bash -e

echo "Set environments"

source envs

echo "Validate CloudFormation templetes"

aws cloudformation validate-template --template-body=file://template-eks-vpc.yaml
aws cloudformation validate-template --template-body=file://template-eks-controllplane.yaml
aws cloudformation validate-template --template-body=file://template-eks-nodegroup.yaml

echo "Create VPC for k8s"

aws cloudformation create-stack \
--stack-name ${VPC_STACK_NAME} \
--template-body=file://template-eks-vpc.yaml

echo "Wait stack create complete"

aws cloudformation wait stack-create-complete \
--stack-name ${VPC_STACK_NAME}

export CONTROLLPLANE_SECURITYGROUP_IDS=$( \
aws cloudformation describe-stacks \
--stack-name ${VPC_STACK_NAME} | \
jq -r '.Stacks[].Outputs[] | select(.OutputKey == "SecurityGroups")' | \
jq -r '.OutputValue')

export VPC_ID=$( \
aws cloudformation describe-stacks \
--stack-name ${VPC_STACK_NAME} | \
jq -r '.Stacks[].Outputs[] | select(.OutputKey == "VpcId")' | \
jq -r '.OutputValue')

export SUBNET_IDS=$( \
aws cloudformation describe-stacks \
--stack-name ${VPC_STACK_NAME} | \
jq -r '.Stacks[].Outputs[] | select(.OutputKey == "SubnetIds")' | \
jq -r '.OutputValue')

echo "Create parameter file for k8s controll plane"

jo -a \
$(jo ParameterKey=Version  -s ParameterValue=${K8S_VERSION}) \
$(jo ParameterKey=ClusterRoleName ParameterValue=${K8S_CLUSTER_ROLENNAME}) \
$(jo ParameterKey=SubnetIds ParameterValue=${SUBNET_IDS}) \
$(jo ParameterKey=SecurityGroupIds ParameterValue=${CONTROLLPLANE_SECURITYGROUP_IDS}) \
> parameter-eks-controllplane.json

echo "Create k8s controll plane"

aws cloudformation create-stack \
--stack-name ${CONTROLLPLANE_STACK_NAME} \
--template-body=file://template-eks-controllplane.yaml \
--parameters=file://parameter-eks-controllplane.json  \
--capabilities CAPABILITY_NAMED_IAM

echo "Wait stack create complete"

aws cloudformation wait stack-create-complete \
--stack-name ${CONTROLLPLANE_STACK_NAME}

export K8S_CLUSTER_NAME=$( \
aws cloudformation describe-stacks \
--stack-name ${CONTROLLPLANE_STACK_NAME} | \
jq -r '.Stacks[].Outputs[] | select(.OutputKey == "ClusterName")' | \
jq -r '.OutputValue')

echo "Create parameter file for k8s nodegroup"

jo -a \
$(jo ParameterKey=KeyName ParameterValue=${KEY_NAME}) \
$(jo ParameterKey=NodeImageId ParameterValue=${NODE_IMAGE_ID}) \
$(jo ParameterKey=Subnets ParameterValue=${SUBNET_IDS}) \
$(jo ParameterKey=NodeVolumeSize -s ParameterValue=${NODE_VOLUME_SIZE}) \
$(jo ParameterKey=NodeGroupName ParameterValue=${NODE_GROUP_NAME}) \
$(jo ParameterKey=ClusterControlPlaneSecurityGroup ParameterValue=${CONTROLLPLANE_SECURITYGROUP_IDS}) \
$(jo ParameterKey=VpcId ParameterValue=${VPC_ID}) \
$(jo ParameterKey=ClusterName ParameterValue=${K8S_CLUSTER_NAME}) \
> parameter-eks-nodegroup.json

echo "Create k8s nodegroup"

aws cloudformation create-stack \
--stack-name ${NODEGROUP_STACK_NAME} \
--template-body=file://template-eks-nodegroup.yaml \
--parameters=file://parameter-eks-nodegroup.json  \
--capabilities CAPABILITY_IAM

echo "Wait stack create complete"

aws cloudformation wait stack-create-complete \
--stack-name ${NODEGROUP_STACK_NAME}

export K8S_NODE_INSTANCE_ROLE=$( \
aws cloudformation describe-stacks \
--stack-name ${NODEGROUP_STACK_NAME} | \
jq -r '.Stacks[].Outputs[] | select(.OutputKey == "NodeInstanceRole")' | \
jq -r '.OutputValue')

echo "NodeInstanceRole"
echo ${K8S_NODE_INSTANCE_ROLE}