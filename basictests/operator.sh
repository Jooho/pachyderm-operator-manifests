#!/bin/bash

source $TEST_DIR/common

MY_DIR=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)

source ${MY_DIR}/../util
source ${TEST_DIR}/../env.sh

ODS_CI_REPO_ROOT=${ODS_CI_REPO_ROOT:-"${HOME}/src/ods-ci"}
JUPYTER_NOTEBOOK_PATH=${JUPYTER_NOTEBOOK_PATH:-"manifests-test/notebooks/tensorflow/TensorFlow-MNIST-Minimal.ipynb"}
GIT_REPO_URL=${MANIFESTS_GIT_REPO_URL:-"https://github.com/Jooho/manifests-test"}


os::test::junit::declare_suite_start "$MY_SCRIPT"

function test_operator() {
    header "Testing ISV Operator installation"
    os::cmd::expect_success "oc project ${TEST_NAMESPACE}"

    runningpods=($(oc get pod --field-selector='status.phase=Running' -o jsonpath="{$.items[*].metadata.name}"))
    os::cmd::expect_success_and_text "echo ${#runningpods[@]}" "4"
    createdpvcs=($(oc get pvc --no-headers|grep Bound|awk '{printf "%s ", $1}'))
    os::cmd::expect_success_and_text "echo ${#createdpvcs[@]}" "2"
}

function test_ods_ci() {
    header "Running Integration Test(Jupyterhub using ODS-CI automation)"

    os::cmd::expect_success "oc project redhat-ods-applications"
    ODH_JUPYTERHUB_URL="https://"$(oc get route jupyterhub -o jsonpath='{.spec.host}' -n redhat-ods-applications)
    pushd ${HOME}/src/ods-ci
    os::cmd::expect_success "run_robot_test.sh --test-artifact-dir ${ARTIFACT_DIR} --test-case ${MY_DIR}/../resources/ods-ci/integration-test-jupyter-git-notebook.robot --test-variables-file ${MY_DIR}/../resources/ods-ci/test-variables.yml --test-variable 'ODH_JUPYTERHUB_URL:${ODH_JUPYTERHUB_URL}' --test-variable RESOURCE_PATH:${PWD}/tests/Resources --test-variable 'JUPYTER_NOTEBOOK_PATH:${JUPYTER_NOTEBOOK_PATH}' --test-variable 'GIT_REPO_URL:${GIT_REPO_URL}'"
    popd
}

test_operator
test_ods_ci

os::test::junit::declare_suite_end
