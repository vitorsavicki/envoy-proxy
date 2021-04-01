// Main variables (Do not modify, they are here just to be documented)
println "BUILD_TAG: " + BUILD_TAG
println "BRANCH_NAME: " + BRANCH_NAME
println "JOB_NAME: " + JOB_NAME
println "JOB_BASE_NAME " + JOB_BASE_NAME
println "BUILD_NUMBER: " + BUILD_NUMBER
println "BUILD_TAG: " + BUILD_TAG

// Common Defs
APP_NAME = 'envoy-proxy'
REGION = 'sa-east-1'
APP_BUCKET = "builds-${REGION}"
CLUSTER_NAME_INTEGRATION = "cluster-integration"
CLUSTER_NAME_STAGE = "cluster-stage"
CLUSTER_NAME_PRODUCTION = "cluster-production"
CLUSTER_SERVICE="envoy-proxy-bradesco"
DEPLOYTARGET = ['production', 'integration', 'stage']

// Environment-specifc variables
switch(JOB_BASE_NAME) { 
  case 'production':
    ENVIRONMENT = 'production'
  break
  case 'stage':
    ENVIRONMENT = 'stage'
  break
  case 'integration':
    ENVIRONMENT = 'integration'
  break
}

properties([disableConcurrentBuilds(), pipelineTriggers([])])
node {
    clearBuilds()

    scmCheckout()


    if (JOB_BASE_NAME in DEPLOYTARGET) {
    
      fetchSettings()

      buildImageDocker()

      tagAndSendToERC()

      deployEcs()
    }
}

def clearBuilds() {
  stage("Clean previous builds") {
    deleteDir()
  }
}

def scmCheckout() {
  stage("Checkout") {
    checkout scm
  }
}

def fetchSettings() {
  stage("Fetch settings from S3") {
    settingsBucket = "s3://projects/settings/${APP_NAME}/${ENVIRONMENT}"
    sh "aws s3 cp ${settingsBucket}/bradesco-sandbox-private.key ./bradesco-sandbox-private.key" 
    sh "aws s3 cp ${settingsBucket}/bradesco-sandbox-public.crt ./bradesco-sandbox-public.crt" 
    sh "aws s3 cp ${settingsBucket}/bradesco-sandbox.pem ./bradesco-sandbox.pem"

  }
}

def buildImageDocker() {
  stage("Build image from Dockerfile") {
    sh '''#!/bin/bash
    $(aws ecr get-login --no-include-email --region sa-east-1)
    '''
    sh "docker build -t rc-${ENVIRONMENT}/${APP_NAME} --build-arg host=0.0.0.0 ."
  }
}

def tagAndSendToERC() {
  stage("Tag image") {
    sh "docker tag rc-${ENVIRONMENT}/${APP_NAME}:latest 240167814999.dkr.ecr.sa-east-1.amazonaws.com/rc-${ENVIRONMENT}/${APP_NAME}:${BUILD_NUMBER}"
  }
  stage("Send image to ECR") {
    sh "docker push 240167814999.dkr.ecr.sa-east-1.amazonaws.com/rc-${ENVIRONMENT}/${APP_NAME}:${BUILD_NUMBER}"
  }
}

def deployEcs() {
  stage("Update task and deploy") {

    switch(JOB_BASE_NAME) {
      case 'production':
        createNewTask("${ENVIRONMENT}", "${BUILD_NUMBER}")
        sh "aws ecs update-service --cluster ${CLUSTER_NAME_PRODUCTION} --service ${CLUSTER_SERVICE} --task-definition ${APP_NAME}-${ENVIRONMENT} --force-new-deployment"
      break
      case 'stage':
        createNewTask("${ENVIRONMENT}", "${BUILD_NUMBER}")
        sh "aws ecs update-service --cluster ${CLUSTER_NAME_STAGE} --service ${CLUSTER_SERVICE} --task-definition ${APP_NAME}-${ENVIRONMENT} --force-new-deployment"
      break
      case 'integration':
        createNewTask("${ENVIRONMENT}", "${BUILD_NUMBER}")
        sh "aws ecs update-service --cluster ${CLUSTER_NAME_INTEGRATION} --service ${CLUSTER_SERVICE} --task-definition ${APP_NAME}-${ENVIRONMENT} --force-new-deployment"
      break
    }
  }
}

def createNewTask(env, build) {
  stage("Fetch settings from S3") {
    settingsBucket = "s3://projects/settings/${APP_NAME}/${ENVIRONMENT}"
    sh "aws s3 cp ${settingsBucket}/task-definition.json .devops/tasks/${env}/task.json"
  }
  def input = readJSON file: ".devops/tasks/${env}/task.json" 
  input.containerDefinitions[0].image = "240167814999.dkr.ecr.sa-east-1.amazonaws.com/rc-${env}/${APP_NAME}:${build}".toString()
  writeJSON file: ".devops/tasks/${env}/task.json", json: input
  sh "aws ecs register-task-definition --cli-input-json file://.devops/tasks/${env}/task.json"
}

