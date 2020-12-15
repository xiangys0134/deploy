/*
 * _______________#########_______________________ 
 * ______________############_____________________ 
 * ______________#############____________________ 
 * _____________##__###########___________________ 
 * ____________###__######_#####__________________ 
 * ____________###_#######___####_________________ 
 * ___________###__##########_####________________ 
 * __________####__###########_####_______________ 
 * ________#####___###########__#####_____________ 
 * _______######___###_########___#####___________ 
 * _______#####___###___########___######_________ 
 * ______######___###__###########___######_______ 
 * _____######___####_##############__######______ 
 * ____#######__#####################_#######_____ 
 * ____#######__##############################____ 
 * ___#######__######_#################_#######___ 
 * ___#######__######_######_#########___######___ 
 * ___#######____##__######___######_____######___ 
 * ___#######________######____#####_____#####____ 
 * ____######________#####_____#####_____####_____ 
 * _____#####________####______#####_____###______ 
 * ______#####______;###________###______#________ 
 * ________##_______####________####______________ 
 * 
 * @Author: Strange
 * @Date: 2020-11-26 15:57:10
 * @LastEditTime: 2020-11-26 18:56:29
 * @LastEditors: Strange
 * @Description: 
 * @FilePath: \Jenkinsfile\gohalserver2020112616.Jenkinsfile
 */


// 镜像仓库地址(已修改)
def registry = "xxxxxx"
// 命名空间
def namespace = "xxxx"
// 镜像仓库项目
def project = "xxxx"
// 镜像名称
def app_name = "citest"
// 镜像完整名称
def image_name = "${registry}/${namespace}/${project}"
// git仓库地址
def git_address_main = "https://xxx"
def git_address_base_comm = "https://xxx"
def git_address_comm_proto = "https://xxx"

// 阿里云hub认证(已修改)
def aliyunhub_auth = "xxxx"
//gitlab认证(已修改)
def gitlab_auth = "bxxxx"
// K8s认证（已修改）
def k8s_auth = "0e170xxx"
// aliyun仓库secret_name
//def aliyun_registry_secret = "xxxxt"
// k8s部署后暴露的nodePort
//def nodePort = "30666"


podTemplate(
    label: 'jenkins-agent', 
    cloud: 'kubernetes-aws-dev', 
    containers: [
       //containerTemplate(name: 'jnlp', image: "jenkins/jnlp-slave:latest"),
       containerTemplate(name: 'jnlp', image: 'registry-intl.cn-hongkong.aliyuncs.com/base-images-repo/jnlp-slave:1.3', imagePullSecrets: 'aly-repo'),
       containerTemplate(name: 'docker', image: 'docker:19.03.1-dind', ttyEnabled: true, command: 'cat')
    ],
    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
    ]){
    node('jenkins-agent'){
        stage('拉取api_service代码') { // for display purposes
            checkout([$class: 'GitSCM',
                branches: [[name: "${params.GIT_MAIN_BRANCH_TAG}"]], 
                doGenerateSubmoduleConfigurations: false, 
                extensions: [[$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true]],
                submoduleCfg: [],
                userRemoteConfigs: [[credentialsId: "${gitlab_auth}", 
                url: "${git_address_main}"]]])
        }
        stage('拉取git_base_comm代码') { // for display purposes
            checkout([$class: 'GitSCM', 
                branches: [[name: "${params.GIT_MAIN_BRANCH_TAG}"]], 
                doGenerateSubmoduleConfigurations: false,
                extensions: [[$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true],
                [$class: 'RelativeTargetDirectory', relativeTargetDir: 'base_comm']],
                submoduleCfg: [],
                userRemoteConfigs: [[credentialsId: "${gitlab_auth}", 
                url: "${git_address_base_comm}"]]])
        }
        stage('拉取git_comm_proto代码') { // for display purposes
            checkout([$class: 'GitSCM', 
                branches: [[name: '*/master']], 
                doGenerateSubmoduleConfigurations: false,
                extensions: [[$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true],
                [$class: 'RelativeTargetDirectory', relativeTargetDir: 'comm_proto']],
                submoduleCfg: [],
                userRemoteConfigs: [[credentialsId: "${gitlab_auth}", 
                url: "${git_address_comm_proto}"]]])
        }
        stage('拉取Dockerfile'){
            sh '''
                # 拉取 Dockerfile
                curl --header "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" $INFRA_FILE_PATH/Dockerfile%2Fgo%2F${JOB_NAME}%2Fnew.Dockerfile/raw?ref=master --output Dockerfile
                # 拉取 .dockerignore
                curl --header "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" $INFRA_FILE_PATH/Dockerfile%2Fgo%2F${JOB_NAME}%2F.dockerignore/raw?ref=master  --output .dockerignore
            '''
        }
        stage('代码编译') {
        //    sh "mvn clean package -Dmaven.test.skip=true"
            sh "ls"
        }
        stage('构建镜像') {
            container('docker') {
                stage('打包镜像') {
                   withCredentials([usernamePassword(credentialsId: "${aliyunhub_auth}", passwordVariable: 'password', usernameVariable: 'username')]) {
                   sh """
                      docker build -t ${image_name}:${up}-${BUILD_NUMBER} .
                      docker login -u ${username} -p '${password}' ${registry}
                      docker push ${image_name}:${up}-${BUILD_NUMBER}
                    """
                    }
                }  
            }    
        }
        stage('部署到K8s'){
            sh '''
                kubeconfig="--kubeconfig=/home/jenkins/config"
                #判断nodeport值
                nodePort=31603


                CHART=${JOB_NAME}-0.1.0.tgz
                # 拉取 helm chart
                curl --header "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" $INFRA_FILE_PATH/helm%2Fcharts%2F${CHART}/raw?ref=master --output $CHART   
                # deploy
                helm upgrade --install --atomic --reset-values --cleanup-on-fail --timeout 10m0s $kubeconfig --namespace ${up} --set-string site=${up} --set service.type=NodePort,service.nodePort=$nodePort,image.repository=$DOCKER_REGISTRY/test-pipeline/${JOB_NAME},image.tag=${up}-${BUILD_NUMBER},imagePullSecrets[0].name=ali-pipeline-docker ${JOB_NAME} ${CHART}
            '''
        }
    }
}
